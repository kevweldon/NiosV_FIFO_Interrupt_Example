# Kevin Weldon - 09/2023

set GENERATE_SIM_SCRIPTS 1
set RUN_MODELSIM 1
set OPEN_MODELSIM 0

set PROJECT top
set REVISION top
#set SIMULATION_DIRECTORY simulation
set SIM_SCRIPTS ./sim_scripts

set OS [lindex $tcl_platform(os) 0]
if { $OS == "Windows" } {
    set sep "&"
    set rm "del"
    set cp "copy"
} else {
    set sep ";"
    set rm "rm"
    set cp "cp"
}

# Generate simulation setup script for IP
if {$GENERATE_SIM_SCRIPTS} {
    qexec "cd .. $sep ip-setup-simulation --quartus-project=$PROJECT --revision=$REVISION --output-directory=$SIM_SCRIPTS --compile-to-work --use-relative-paths"
}

if {$RUN_MODELSIM} {
    qexec "cd ../; make app"
    qexec "$cp -f ../data_instruction_ram.hex ."
    # Remove current wlf file
    qexec "$rm -f vsim.wlf"
    # Run simulation in ModelSim
    qexec "vsim -c -do 'source run_sim.tcl'"
    # Open QuestaSim and view waves
    qexec "$cp transcript sim_transcript"
}

if {$OPEN_MODELSIM} {
    qexec "vsim -gui -view vsim.wlf -do 'wave.do' &"
}
