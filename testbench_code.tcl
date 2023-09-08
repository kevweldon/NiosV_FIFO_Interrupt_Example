

proc main {} {
    set NUM_OF_PACKETS_TO_SEND 2
    set PACKET_SIZE 4

    set FIFO_IN_ADDR 0x00000000
    set CSR_RAM_ADDR 0x00100000

    #########################
    # Open the service path #
    #########################
    set jm [get_jtag_master];
    puts "Opening master: $jm\n"
    open_service master $jm
    
    # Write four word packet into the FIFO
    for {set pkt_cnt 0} {$pkt_cnt<$NUM_OF_PACKETS_TO_SEND} {incr pkt_cnt} {
	for {set i 0} {$i<$PACKET_SIZE} {incr i} {
	    if {$i==0} {
		set fifo_data [expr $CSR_RAM_ADDR + ($pkt_cnt * ($PACKET_SIZE-1) * 4)]
	    } else {
		set fifo_data [expr $i + ($pkt_cnt*($PACKET_SIZE-1))]
	    }
	    master_write_32 $jm $FIFO_IN_ADDR $fifo_data
	    puts "Wrote data $fifo_data to address $FIFO_IN_ADDR"
	}
    }

    after 1000;

    for {set word_cnt 0} {$word_cnt<[expr $NUM_OF_PACKETS_TO_SEND * ($PACKET_SIZE-1)]} {incr word_cnt} {
	set addr [format 0x%x [expr $CSR_RAM_ADDR+($word_cnt*4)]]
	set read_value [master_read_32 $jm $addr 1]
	puts "Read Data $read_value from address $addr"
    }
    
    close_service master $jm

    return 0;
}

proc get_jtag_master {} {
    #########################
    # Open the service path #
    #########################
    # You may need to adjust the value of the MASTER_INDEX
    set MASTER_INDEX 0
    puts "Opening JTAG master service path..."
    set i 0
    # Print all the masters found in the system. Here we need
    # to select the jtag2avalon master
    puts "I found the following masters:"
    foreach master [get_service_paths master] {
	puts "$i. $master"
	incr i
    }
    set jm [ lindex [ get_service_paths master ] $MASTER_INDEX ]
    return $jm
}

main;
