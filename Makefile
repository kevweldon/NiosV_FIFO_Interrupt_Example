# Kevin Weldon
# 1.0 - 01/03/21

SOURCE_FILES       := control.c
BSP_DIRECTORY      := software/cpu_hal_bsp
BSP_FILE           := $(BSP_DIRECTORY)/settings.bsp
APP_DIRECTORY      := software/cpu_hal_app
ELF_FILE           := control.elf
HEX_FILE_BASE_ADDR := 0x0
HEX_FILE_END_ADDR  := 0x0007FFFF
HEX_FILE_WIDTH     := 32

QUARTUS_PROJECT          := top
PLATFORM_DESIGNER_SYSTEM := sys.qsys
HEX_FILE                 := data_instruction_ram.hex


help :
fpga : $(QUARTUS_PROJECT).sof
app : $(HEX_FILE)

$(BSP_FILE) : $(PLATFORM_DESIGNER_SYSTEM)
	mkdir -p $(BSP_DIRECTORY)
	niosv-bsp -c --quartus-project=$(QUARTUS_PROJECT).qpf --qsys=$(PLATFORM_DESIGNER_SYSTEM) --type=hal $(BSP_FILE)

$(APP_DIRECTORY)/CMakeLists.txt : $(BSP_FILE) $(SOURCE_FILES)
	mkdir -p $(APP_DIRECTORY)
	cp -f $(SOURCE_FILES) $(APP_DIRECTORY)
	niosv-app --bsp-dir=$(BSP_DIRECTORY) --app-dir=$(APP_DIRECTORY) --srcs=$(APP_DIRECTORY) --elf-name=$(ELF_FILE)

$(APP_DIRECTORY)/build/Makefile : $(APP_DIRECTORY)/CMakeLists.txt
	cd $(APP_DIRECTORY); cmake -B build -G "Unix Makefiles"

$(APP_DIRECTORY)/build/$(ELF_FILE) : $(APP_DIRECTORY)/build/Makefile
	cd $(APP_DIRECTORY); make -C build

$(HEX_FILE) : $(APP_DIRECTORY)/build/$(ELF_FILE)
	elf2hex $(APP_DIRECTORY)/build/$(ELF_FILE) -o $(HEX_FILE) -b $(HEX_FILE_BASE_ADDR) -w $(HEX_FILE_WIDTH) -e $(HEX_FILE_END_ADDR)

$(QUARTUS_PROJECT).sof : $(HEX_FILE) $(PLATFORM_DESIGNER_SYSTEM)
	quartus_sh --flow compile $(QUARTUS_PROJECT)

reset_and_start:
	@echo Resetting the design...
	quartus_stp -t toggle_issp.tcl
	@echo Capture stdout...
	juart-terminal

program :
	@echo Programming FPGA...
	quartus_stp_tcl -t program_fpga.tcl
	make reset_and_start

update: 
	@echo Downloading .elf file
	niosv-download -r $(APP_DIRECTORY)/build/$(ELF_FILE)
	make reset_and_start

restore :
	quartus_sh --restore top_24_1_0_115.qar

clean :

	rm -f *.rpt *.sof *.summary *.smsg *.pin *~
	rm -f *.qsf *.qpf *.qws *.v *.sv *.sdc *.done *.qsys
	rm -f *.cdf *.sld *.qarlog *.legacy
	rm -f *.json *.qdf #*#
	rm -f *.info
	rm -f *.h *.log *.save *.rec
	rm -f *.hex *.xml *.inc serv_req_info.txt *.sldtmp
	rm -rf tmp-clearbox software db
	rm -rf dni
	rm -rf sim_scripts support_logic
	rm -rf .qsys_edit ip sys qdb dni sandboxes

help :
	@echo ""
	@echo " Recognized targets are:"
	@echo ""
	@echo " |====================================================================================|"
	@echo " |   fpga            : Build software application and compile FPGA                    |"
	@echo " |   program         : Program the .sof file into the FPGA                            |"
	@echo " |====================================================================================|"
	@echo " |   app             : Build software application (.elf and .hex file only)           |"
	@echo " |   update          : Program the .elf file into the FPGA                            |"
	@echo " |====================================================================================|"
	@echo " |   clean           : Remove all unarchived and generated files                      |"
	@echo " |   restore         : Unarchive Quartus project file                                 |"
	@echo " |====================================================================================|"
	@echo " |   help            : Display help menu                                              |"
	@echo " |====================================================================================|"
	@echo ""
