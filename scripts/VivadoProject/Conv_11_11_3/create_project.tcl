# Check if the PRJ_ROOT_PATH environment variable is set
if {![info exists ::env(PRJ_ROOT_PATH)]} {
    puts "ERROR: Environment variable PRJ_ROOT_PATH is not set."
    exit 1
}
set PRJ_ROOT_PATH $::env(PRJ_ROOT_PATH)
set HOME $::env(HOME)
set PROJECT_NAME "Conv-11-11-3"
set PROJECT_DIR "${PRJ_ROOT_PATH}/AlexNet-Layers/${PROJECT_NAME}"

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
set SOURCE_DIR "$PRJ_ROOT_PATH/sources_1/alex_net_layers/conv_11_11_3"
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

set_property file_type "VHDL" [get_files "${PRJ_ROOT_PATH}/sources_1/alex_net_layers/conv_11_11_3/top_level_cnn_wrapper.vhd"]

# ============================================================
# Include the Block Design TCL script
# ============================================================
source "$PRJ_ROOT_PATH/scripts/VivadoProject/Top_Level_bd_300MHz.tcl"

# Validate and Save the block design
validate_bd_design
save_bd_design

# ============================================================
# Generate wrapper from the BD and set it as top
# ============================================================
set bd_path "$PROJECT_DIR/${PROJECT_NAME}.srcs/sources_1/bd/Top_Level/Top_Level.bd"

# Generate HDL wrapper
make_wrapper -files [get_files $bd_path] -top

# Add the generated wrapper to the project
add_files "$PROJECT_DIR/${PROJECT_NAME}.gen/sources_1/bd/Top_Level/hdl/Top_Level_wrapper.vhd"

# Set the wrapper as the top module
set_property top Top_Level_wrapper [current_fileset]

# Update compile order
update_compile_order -fileset sources_1

puts "Project $PROJECT_NAME created successfully at $PROJECT_DIR"

puts "Starting Synthesis and Implementation Runs for $PROJECT_NAME"

source "$PRJ_ROOT_PATH/scripts/VivadoProject/synth.tcl"

