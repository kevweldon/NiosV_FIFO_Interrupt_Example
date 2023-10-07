onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /top_tb/dut/clk
add wave -noupdate /top_tb/dut/reset
add wave -noupdate /top_tb/dut/issp_reset_wire
add wave -noupdate -expand -group CSR_RAM /top_tb/dut/sys/csr_ram/clk
add wave -noupdate -expand -group CSR_RAM /top_tb/dut/sys/csr_ram/clken
add wave -noupdate -expand -group CSR_RAM /top_tb/dut/sys/csr_ram/address
add wave -noupdate -expand -group CSR_RAM /top_tb/dut/sys/csr_ram/byteenable
add wave -noupdate -expand -group CSR_RAM /top_tb/dut/sys/csr_ram/chipselect
add wave -noupdate -expand -group CSR_RAM /top_tb/dut/sys/csr_ram/readdata
add wave -noupdate -expand -group CSR_RAM /top_tb/dut/sys/csr_ram/write
add wave -noupdate -expand -group CSR_RAM /top_tb/dut/sys/csr_ram/writedata
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 286
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {8405407500 ps}
