# Check if the PRJ_ROOT_PATH environment variable is set
if {![info exists ::env(PRJ_ROOT_PATH)]} {
    puts "ERROR: Environment variable PRJ_ROOT_PATH is not set."
    exit 1
}
set PRJ_ROOT_PATH $::env(PRJ_ROOT_PATH)
set HOME $::env(HOME)
set PROJECT_NAME "Conv-2-KS5"
set PROJECT_DIR "${PRJ_ROOT_PATH}/AlexNet-Layers/OOC_KS/${PROJECT_NAME}"

create_project $PROJECT_NAME $PROJECT_DIR -part xczu3eg-sbva484-1-i -force

set origin_dir "."

set obj [current_project]
set_property -name "board_part_repo_paths" -value "[file normalize "$PRJ_ROOT_PATH/bdf"]" -objects $obj
set_property -name "board_part" -value "avnet.com:ultra96v2:part0:1.2" -objects $obj
set_property target_language VHDL -objects $obj
set_property simulator_language VHDL -objects $obj


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

# Add all source files from this conv/pool config
set SOURCE_DIR "$PRJ_ROOT_PATH/sources_1/alex_net_layers/ooc/kernel_size/ks_5/"
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

set_property file_type "VHDL" [get_files "${PRJ_ROOT_PATH}/sources_1/alex_net_layers/ooc/kernel_size/ks_5/top_level_cnn_wrapper.vhd"]

# Set the wrapper as the top module
set_property top top_level_cnn_wrapper [current_fileset]

# Update compile order
update_compile_order -fileset sources_1

puts "Project $PROJECT_NAME created successfully at $PROJECT_DIR"

puts "Starting OOC Synthesis and Implementation Runs for $PROJECT_NAME"

source "$PRJ_ROOT_PATH/scripts/VivadoProject/synth_ooc.tcl"
