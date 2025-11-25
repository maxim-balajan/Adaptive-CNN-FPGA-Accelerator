#!/bin/bash

# Initialize our own variables
OPTIND=1         # Reset in case getopts has been used previously in the shell.
GUI=""

# Parsing of arguments
while getopts "h?g" opt; do
    case "$opt" in
    h|\?)
        echo "Usage: $0 -g"
        exit 0
        ;;
    g)  GUI="-g"
        ;;
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift

TB=$1
shift $((OPTIND-1))

if [ "$TB" == "bram_fifo" ]; then
    $PRJ_SCRIPTS/simulation/generic_simulation_run.sh ${GUI} bram_fifo \
        $PRJ_HW_SOURCES_PATH/libmatrix.vhd \
        $PRJ_HW_SOURCES_PATH/bram_fifo.vhd \
        $PRJ_HW_SIMS_PATH/bram_fifo_tb.vhd
elif [ "$TB" == "line_buffer" ]; then
    $PRJ_SCRIPTS/simulation/generic_simulation_run.sh ${GUI} line_buffer \
        $PRJ_HW_SOURCES_PATH/libmatrix.vhd   \
        $PRJ_HW_SOURCES_PATH/bram_fifo.vhd   \
        $PRJ_HW_SOURCES_PATH/line_buffer.vhd \
        $PRJ_HW_SIMS_PATH/line_buffer_tb.vhd
elif [ "$TB" == "kernel_slider" ]; then
    $PRJ_SCRIPTS/simulation/generic_simulation_run.sh ${GUI} kernel_slider \
        $PRJ_HW_SOURCES_PATH/libmatrix.vhd      \
        $PRJ_HW_SOURCES_PATH/bram_fifo.vhd      \
        $PRJ_HW_SOURCES_PATH/line_buffer.vhd    \
        $PRJ_HW_SOURCES_PATH/kernel_slider.vhd  \
        $PRJ_HW_SIMS_PATH/kernel_slider_tb.vhd  
elif [ "$TB" == "generic_slider" ]; then
    $PRJ_SCRIPTS/simulation/generic_simulation_run.sh ${GUI} generic_slider \
        $PRJ_HW_SOURCES_PATH/libmatrix.vhd              \
        $PRJ_HW_SOURCES_PATH/bram_fifo.vhd              \
        $PRJ_HW_SOURCES_PATH/line_buffer.vhd            \
        $PRJ_HW_SOURCES_PATH/kernel_slider.vhd          \
        $PRJ_HW_SOURCES_PATH/generic_slider.vhd         \
        $PRJ_HW_SIMS_PATH/generic_slider_tb.vhd  
elif [ "$TB" == "line_unit" ]; then
    $PRJ_SCRIPTS/simulation/generic_simulation_run.sh ${GUI} line_unit \
        $PRJ_HW_SOURCES_PATH/libmatrix.vhd              \
        $PRJ_HW_SOURCES_PATH/bram_fifo.vhd              \
        $PRJ_HW_SOURCES_PATH/line_buffer.vhd            \
        $PRJ_HW_SOURCES_PATH/line_unit.vhd              \
        $PRJ_HW_SIMS_PATH/line_unit_tb.vhd  
elif [ "$TB" == "line_control_unit" ]; then
    $PRJ_SCRIPTS/simulation/generic_simulation_run.sh ${GUI} line_control_unit \
        $PRJ_HW_SOURCES_PATH/libmatrix.vhd              \
        $PRJ_HW_SOURCES_PATH/line_control_unit.vhd      \
        $PRJ_HW_SIMS_PATH/line_control_unit_tb.vhd  
elif [ "$TB" == "configurable_slider" ]; then
    $PRJ_SCRIPTS/simulation/generic_simulation_run.sh ${GUI} configurable_slider \
        $PRJ_HW_SOURCES_PATH/libmatrix.vhd              \
        $PRJ_HW_SOURCES_PATH/line_control_unit.vhd      \
        $PRJ_HW_SOURCES_PATH/bram_fifo.vhd              \
        $PRJ_HW_SOURCES_PATH/line_buffer.vhd            \
        $PRJ_HW_SOURCES_PATH/line_unit.vhd              \
        $PRJ_HW_SOURCES_PATH/line_route_unit.vhd        \
        $PRJ_HW_SOURCES_PATH/configurable_slider.vhd    \
        $PRJ_HW_SIMS_PATH/configurable_slider_tb.vhd  
elif [ "$TB" == "adder_tree_gen" ]; then
    $PRJ_SCRIPTS/simulation/generic_simulation_run.sh ${GUI} adder_tree_gen \
        $PRJ_HW_SOURCES_PATH/libmatrix.vhd                                                 \
        $PRJ_HW_SOURCES_PATH/libutil.vhd                                                   \
        $PRJ_HW_SOURCES_PATH/clip_adder.vhd                                                \
        $PRJ_HW_SOURCES_PATH/kernel_computation_step.vhd                                   \
        $PRJ_HW_SOURCES_PATH/kernel_computation_unit.vhd                                   \
        $PRJ_HW_SIMS_PATH/adder_tree_simulation/generated_source/Five_adder_plus_mult.vhd  \
        $PRJ_HW_SIMS_PATH/adder_tree_simulation/generated_source/Three_adder_no_mult.vhd   \
        $PRJ_HW_SIMS_PATH/adder_tree_simulation/generated_source/Nine_pooling.vhd          \
        $PRJ_HW_SIMS_PATH/adder_tree_simulation/generated_source/kernel_cores.vhd          \
        $PRJ_HW_SIMS_PATH/adder_tree_simulation/generated_source/routing_cores.vhd         \
        $PRJ_HW_SIMS_PATH/adder_tree_simulation/generated_source/routed_kernel_cores.vhd   \
        $PRJ_HW_SIMS_PATH/adder_tree_simulation/adder_tree_gen_tb.vhd 
elif [ "$TB" == "memory_test" ]; then
    $PRJ_SCRIPTS/simulation/generic_simulation_run.sh ${GUI} memory_test \
        $PRJ_HW_SOURCES_PATH/libmatrix.vhd                \
        $PRJ_HW_SOURCES_PATH/memory_test.vhd              \
        $PRJ_HW_SOURCES_PATH/memory_test_wrapper.vhd      \
        $PRJ_HW_SIMS_PATH/memory_test_tb.vhd  
elif [ "$TB" == "temp_layer_accumulator" ]; then
    $PRJ_SCRIPTS/simulation/generic_simulation_run.sh ${GUI} temp_layer_accumulator \
        $PRJ_HW_SOURCES_PATH/libmatrix.vhd              \
        $PRJ_HW_SOURCES_PATH/bram_fifo.vhd              \
        $PRJ_HW_SOURCES_PATH/clip_adder.vhd             \
        $PRJ_HW_SOURCES_PATH/temp_layer_accumulator.vhd \
        $PRJ_HW_SIMS_PATH/temp_layer_accumulator_tb.vhd  
elif [ "$TB" == "kernel_comp_unit" ]; then
    $PRJ_SCRIPTS/simulation/generic_simulation_run.sh ${GUI} kernel_computation_unit \
        $PRJ_HW_SOURCES_PATH/libmatrix.vhd              \
        $PRJ_HW_SOURCES_PATH/clip_adder.vhd             \
        $PRJ_HW_SOURCES_PATH/kernel_computation_step.vhd              \
        $PRJ_HW_SOURCES_PATH/kernel_computation_unit.vhd \
        $PRJ_HW_SIMS_PATH/kernel_computation_unit_tb.vhd  
elif [ "$TB" == "config_unit" ]; then
    $PRJ_SCRIPTS/simulation/generic_simulation_run.sh ${GUI} config_unit \
        $PRJ_HW_SOURCES_PATH/config_unit.vhd \
        $PRJ_HW_SIMS_PATH/config_unit_tb.vhd    
else
    echo "Unknown Testbench: $TB"
    echo "Usage: $0 [Top-Unit] [Source-Files...]"
    exit 1
fi
