# Tcl script to assist with programming from the command line
# in an environment with multiple programming hardware and
# multiple devices attached to the programming hardware.
#
# Kevin Weldon 04/04/21
#
set FORCE_SELECTION_OF_FIRST_DEVICE_IN_CHAIN 1
# Options: 24M, 16M, 6M
set JTAG_CLK_FREQ "24M"
set ISSP_INDEX 0
set RESET_MS 100

#############################################
# Code to detect Hardware and Device number #
#############################################
puts ""
set hardware [get_hardware_names]
if {[llength $hardware]==1} {
    set hardware2use [lindex $hardware 0]
    set cable_number 1
} else {
    puts "Please select the number of your desired prgramming hardware:"
    for {set i 0} {$i < [llength $hardware]} {incr i} {
	set display [expr $i + 1]
	puts "$display: [lindex $hardware $i]"
	foreach device_name [get_device_names -hardware_name [lindex $hardware $i]] {
	    puts "\tDevice attached: $device_name"
	}
    }
    set sel [gets stdin]
    set cable_number $sel
    set hardware2use [lindex $hardware [expr $sel-1]]
}
puts "\nSelected programming hardware: $hardware2use\n";

puts "jtagconfig --setparam $cable_number JtagClock $JTAG_CLK_FREQ"
qexec "jtagconfig --setparam $cable_number JtagClock $JTAG_CLK_FREQ"

set devices [get_device_names -hardware_name $hardware2use]
if {[llength $devices]==1 || $FORCE_SELECTION_OF_FIRST_DEVICE_IN_CHAIN} {
    set device 1
} else {
    puts "Please select the number of the device to program:"
    for {set i 0} {$i < [llength $devices]} {incr i} {
	set display [expr $i + 1]
	puts "$display: [lindex $devices $i]"
    }
    set device [gets stdin]
}

############################################
# Write internal reset register using ISSP #
############################################
puts "\nResetting FPGA using intenral reset register and ISSP\n"
start_insystem_source_probe -hardware_name $hardware2use -device_name $device

write_source_data -instance_index $ISSP_INDEX -value "1"
after $RESET_MS
write_source_data -instance_index $ISSP_INDEX -value "0"

end_insystem_source_probe
