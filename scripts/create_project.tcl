# Check if the PRJ_ROOT_PATH environment variable is set
if {![info exists ::env(PRJ_ROOT_PATH)]} {
    puts "ERROR: Environment variable PRJ_ROOT_PATH is not set."
    exit 1
}
set PRJ_ROOT_PATH $::env(PRJ_ROOT_PATH)
set HOME $::env(HOME)
set PROJECT_NAME "AlexNet-Accelerator"
set PROJECT_DIR "${PRJ_ROOT_PATH}/${PROJECT_NAME}"
set board_repo_path "${PRJ_ROOT_PATH}/bdf"

create_project $PROJECT_NAME $PROJECT_DIR -part xczu3eg-sbva484-1-e -force

set obj [current_project]
#set_property -name "board_part_repo_paths" -value "[file normalize "$board_repo_path"]" -objects $obj
#set_property -name "board_part" -value "avnet.com:ultra96v2:part0:1.2" -objects $obj
set_property -name "default_lib" -value "work" -objects $obj
set_property -name "enable_resource_estimation" -value "0" -objects $obj
set_property -name "enable_vhdl_2008" -value "1" -objects $obj
set_property -name "feature_set" -value "FeatureSet_Classic" -objects $obj
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" -value "$PROJECT_DIR/${PROJECT_NAME}.cache/ip" -objects $obj
set_property -name "mem.enable_memory_map_generation" -value "1" -objects $obj
set_property -name "platform.board_id" -value "ultra96v2" -objects $obj
set_property -name "revised_directory_structure" -value "1" -objects $obj
set_property -name "sim.central_dir" -value "$PROJECT_DIR/${PROJECT_NAME}.ip_user_files" -objects $obj
set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
set_property -name "simulator_language" -value "VHDL" -objects $obj
set_property -name "sim_compile_state" -value "1" -objects $obj
set_property -name "target_language" -value "VHDL" -objects $obj
set_property -name "webtalk.xsim_launch_sim" -value "3" -objects $obj

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


set_property top generic_slider [current_fileset]


update_compile_order -fileset sources_1

puts "Project $PROJECT_NAME created successfully at $PROJECT_DIR"

