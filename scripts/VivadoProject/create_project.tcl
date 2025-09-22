# Check if the PRJ_ROOT_PATH environment variable is set
if {![info exists ::env(PRJ_ROOT_PATH)]} {
    puts "ERROR: Environment variable PRJ_ROOT_PATH is not set."
    exit 1
}
set PRJ_ROOT_PATH $::env(PRJ_ROOT_PATH)
set HOME $::env(HOME)
set PROJECT_NAME "AlexNet-Accelerator"
set PROJECT_DIR "${PRJ_ROOT_PATH}/${PROJECT_NAME}"

create_project $PROJECT_NAME $PROJECT_DIR -part xczu3eg-sbva484-1-i -force

set origin_dir "."

set obj [current_project]
set_property -name "board_part_repo_paths" -value "[file normalize "$PRJ_ROOT_PATH/bdf"]" -objects $obj
set_property -name "board_part" -value "avnet.com:ultra96v2:part0:1.2" -objects $obj
set_property target_language VHDL -objects $obj
set_property simulator_language VHDL -objects $obj

#add_files {"${PRJ_ROOT_PATH}/bd/Memory_Retrival/Memory_Retrival.bd"}

# Add all source files from $PRJ_ROOT_PATH/sources_1
set SOURCE_DIR "$PRJ_ROOT_PATH/sources_1"
if {[file exists $SOURCE_DIR]} {
    set sources [glob -nocomplain -directory $SOURCE_DIR -types f *.{vhd}]
    if {[llength $sources] > 0} {
        add_files -norecurse $sources
        foreach file $sources {
            set_property file_type "VHDL 2008" [get_files $file]
        }
    } else {
        puts "WARNING: No source files found in $SOURCE_DIR"
    }
} else {
    puts "WARNING: Source directory $SOURCE_DIR does not exist."
}

set_property file_type "VHDL" [get_files "${PRJ_ROOT_PATH}/sources_1/memory_test_wrapper.vhd"]

# Add simulation sources from $PRJ_ROOT_PATH/sim_1
set SIM_DIR "$PRJ_ROOT_PATH/sim_1"
if {[file exists $SIM_DIR]} {
    set sim_files [glob -nocomplain -directory $SIM_DIR -types f *.{vhd}]
    if {[llength $sim_files] > 0} {
        add_files -fileset sim_1 -norecurse $sim_files
        foreach file $sim_files {
            set_property file_type "VHDL 2008" [get_files -of_objects [get_filesets sim_1] $file]
        }
    } else {
        puts "WARNING: No simulation files found in $SIM_DIR"
    }
} else {
    puts "WARNING: Simulation directory $SIM_DIR does not exist."
}

# ============================================================
# Include the Block Design TCL script
# ============================================================
source ./Memory_Retrieval_with_ILA.tcl

# Validate and Save the block design
validate_bd_design
save_bd_design

# ============================================================
# Generate wrapper from the BD and set it as top
# ============================================================
set bd_path "$PROJECT_DIR/${PROJECT_NAME}.srcs/sources_1/bd/Memory_Retrieval/Memory_Retrieval.bd"

# Generate HDL wrapper
make_wrapper -files [get_files $bd_path] -top

# Add the generated wrapper to the project
add_files "$PROJECT_DIR/${PROJECT_NAME}.srcs/sources_1/bd/Memory_Retrieval/hdl/Memory_Retrieval_wrapper.vhd"

# Set the wrapper as the top module
set_property top Memory_Retrieval_wrapper [current_fileset]

# Update compile order
update_compile_order -fileset sources_1

puts "Project $PROJECT_NAME created successfully at $PROJECT_DIR"

