`define AMM_BFM top_tb.dut.sys.mm_master_bfm.sys_mm_master_bfm

`define NUM_OF_PACKETS_TO_SEND 2
`define PACKET_SIZE 4

module top_tb;
   
   import verbosity_pkg::*;
   import avalon_mm_pkg::*;

   timeunit 1ns;
   timeprecision 10ps;

   parameter FIFO_IN_ADDR = 32'h00000000;
   parameter CSR_RAM_ADDR = 32'h00100000;

   logic [31:0] avalon_read_data [256];
   
   logic clk;
   logic [31:0] fifo_data;

   initial
     begin
	clk = 0;
	#0;
	forever #10 clk = ~clk;
     end

   initial
     begin
	$timeformat(-9, 2, "ns", 1);

	// Configure Avalon BFM
	`AMM_BFM.set_response_timeout(500);
        `AMM_BFM.set_command_timeout(500);
	`AMM_BFM.init();

	force dut.sys.jtag_master.master_reset_reset=1;
	force dut.issp_reset_wire = 1;
	repeat (20) @(posedge clk);
	force dut.sys.jtag_master.master_reset_reset=0;
	force dut.issp_reset_wire = 0;
	repeat (20) @(posedge clk);

	repeat (200000) @(posedge clk);

	// Write four word packet into the FIFO
	for (int pkt_cnt=0; pkt_cnt<`NUM_OF_PACKETS_TO_SEND; pkt_cnt++)
	  begin
	     for (int i; i<`PACKET_SIZE; i++)
	       begin
		  if (i==0)
		    begin
		       fifo_data = CSR_RAM_ADDR + (pkt_cnt * (`PACKET_SIZE-1) * 4);
		    end
		  else
		    begin
		       fifo_data = i + (pkt_cnt*(`PACKET_SIZE-1));
		    end
		  master_write(FIFO_IN_ADDR, fifo_data, 4'hf);
	       end
	     repeat (200000) @(posedge clk);
	  end
	
	repeat (200000) @(posedge clk);
	for (int word_cnt=0; word_cnt<`NUM_OF_PACKETS_TO_SEND * (`PACKET_SIZE-1); word_cnt++)
	  begin
	     master_read(CSR_RAM_ADDR+(word_cnt*4),1, avalon_read_data);
	  end
   
	repeat (200) @(posedge clk);

	stop_sim();
     end // initial begin

   top dut (.*);

   task stop_sim;
     begin
	$display("Simulation stopped at %t", $time);
	$stop;
     end
   endtask // stop_sim

   task master_write;
      input [31:0] address;
      input [31:0] data;
      input [3:0]  byteenable;
      begin
	 `AMM_BFM.set_command_data(data, 0);
	 `AMM_BFM.set_command_byte_enable(byteenable, 0);
	 `AMM_BFM.set_command_idle(0, 0);
	 `AMM_BFM.set_command_address(address);
	 `AMM_BFM.set_command_burst_count('h1);
	 `AMM_BFM.set_command_burst_size('h1);
	 `AMM_BFM.set_command_init_latency(0);
	 `AMM_BFM.set_command_request(REQ_WRITE);
	 `AMM_BFM.push_command();
	 wait(`AMM_BFM.signal_response_complete);
	 `AMM_BFM.pop_response();
	 //$display("top_tb: [%t] Response Request: %s", $time,`AMM_BFM.get_response_request());
	 $display("top_tb: [%t] Wrote Data %h to address %h, byteenable=%h", 
		  $time, `AMM_BFM.get_response_data(0),`AMM_BFM.get_response_address(), 
		  `AMM_BFM.get_response_byte_enable(0));
      end
   endtask // master_write

   task master_read;
      input [31:0] address;
      input [7:0] burst_size;
      output [31:0] data_out [256];
      begin
	 `AMM_BFM.set_command_address(address);
	 `AMM_BFM.set_command_byte_enable({64{1'b1}}, 0);
	 `AMM_BFM.set_command_burst_count(burst_size);
	 `AMM_BFM.set_command_burst_size(burst_size);
	 `AMM_BFM.set_command_data('h0, 0);
	 `AMM_BFM.set_command_idle(0, 0);
	 `AMM_BFM.set_command_init_latency(0);
	 `AMM_BFM.set_command_request(REQ_READ);
	 `AMM_BFM.push_command();
	 wait(`AMM_BFM.signal_response_complete);	 
	 `AMM_BFM.pop_response();
	 for (int i=0; i<burst_size; i++)
	   begin
	      data_out[i] = `AMM_BFM.get_response_data(i);
	      $display("top_tb: [%t] Read Data %h from address %h", $time, 
		       `AMM_BFM.get_response_data(i),`AMM_BFM.get_response_address());
	   end
      end
   endtask // master_read

   task poll;
      input [31:0] address;
      input [31:0] desired_value;
      input [31:0] mask;
      begin
	 static int POLL_COUNT=25;
	 int 	    i;
	 $display("top_tb: Polling address %X for data %X using mask %X at (%t)",
		  address, desired_value, mask, $time);
	 for (i=1; i<=POLL_COUNT; i=i+1)
	   begin
	      master_read(address, 1, avalon_read_data);
	      if ((avalon_read_data[0] & mask) == desired_value)
		break;
	   end
	 if(i==POLL_COUNT+1)
	   begin
	      $display("top_tb: Polling address %X for data %X using mask %X at (%t)",
		       address, desired_value, mask, $time);
	      $display("top_tb: Timed out after %d attempts (%t)", POLL_COUNT, $time);
	      $stop();
	   end
      end
   endtask // poll
   
   task read_mod_write;
      input [31:0] address;
      input [31:0] write_data;
      input [31:0] write_mask;
      logic [31:0] new_write_data;
      begin
	 $display("top_tb: Read-Modify-Write at address %X. Data=%X, Mask=%X (%t)",
		  address,write_data,write_mask, $time);
	 master_read(address, 1, avalon_read_data);
	 new_write_data = (avalon_read_data[0] & ~write_mask) | write_data;
	 master_write(address, new_write_data, 4'hF);
      end
   endtask // read_mod_write
   
   
endmodule: top_tb
