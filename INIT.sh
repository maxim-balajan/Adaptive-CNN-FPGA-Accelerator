#!/bin/bash

# Set the name of the virtual environment
ENV_NAME=".venv"

# Set the python executable (explicitly Python 3.10)
PYTHON_VER="3.10.16"
PYTHON_BIN="$HOME/.pyenv/versions/$PYTHON_VER/bin/python"


export PRJ_ROOT_PATH=($PWD)
export PRJ_GENERATED_PATH="$PRJ_ROOT_PATH/_generated"
export PRJ_TRAIN_PATH="$PRJ_ROOT_PATH/reference/training"
export PRJ_SIM_PATH="$PRJ_ROOT_PATH/reference/simulation"
export PRJ_WAVE_CFG="$PRJ_ROOT_PATH/wave_config"
export PRJ_SCRIPTS="$PRJ_ROOT_PATH/scripts"
export PRJ_HW_SOURCES_PATH="$PRJ_ROOT_PATH/sources_1"
export PRJ_HW_SIMS_PATH="$PRJ_ROOT_PATH/sim_1"

# Various directory changes abstracted into new commands
alias cd_root="cd $PRJ_ROOT_PATH" 
alias cd_train="cd $PRJ_TRAIN_PATH"
alias cd_sim="cd $PRJ_SIM_PATH"
alias cd_hw_sources="cd $PRJ_HW_SOURCES_PATH"
alias cd_hw_sims="cd $PRJ_HW_SIMS_PATH"

# Simulate Aliases
alias prj_simulate_bram_fifo="'$PRJ_SCRIPTS/simulation/bram_fifo.sh'      | tee '$PRJ_GENERATED_PATH/bram_fifo_sim.log'"
alias prj_simulate_line_buffer="'$PRJ_SCRIPTS/simulation/line_buffer.sh'     | tee '$PRJ_GENERATED_PATH/line_buffer_sim.log'"
alias prj_simulate_kernel_slider="'$PRJ_SCRIPTS/simulation/kernel_slider.sh' | tee '$PRJ_GENERATED_PATH/kernel_slider.log'"

prj_simulate_help() {
    echo "####################################################################"
    echo "# prj_simulate_help.........: Print all possible simulation runs"
    echo "# prj_simulate_bram_fifo....: Run Testbench for BRAM FIFO"
    echo "# prj_simulate_line_buffer..: Run Testbench for a Line Buffer"
    echo "# prj_simulate_kernel_slider: Run Testbench for a Kernel Slider"
    echo "####################################################################"
}


# Script for executing the Training of the Model
prj_train() {
    python -u "$PRJ_TRAIN_PATH/training.py" "$@" | tee "$PRJ_GENERATED_PATH/training_debug.log"
}


# Build and run functions for executing the C++ Simulation
prj_build_simulation() {
    local CWD="$PWD"

    rm -rf "$PRJ_SIM_PATH/build"
    if [ ! -d "$PRJ_SIM_PATH/build" ]; then
        echo "# Removed old building directory located at $PRJ_SIM_PATH/build" | tee "$PRJ_GENERATED_PATH/simulation_build_debug.log"
    else
        echo "# Error while removing old directory located at $PRJ_SIM_PATH/build ! Abort..." | tee "$PRJ_GENERATED_PATH/simulation_build_debug.log"
        cd "$CWD"
        return 1
    fi
     
    mkdir "$PRJ_SIM_PATH/build"
    if [ $? -ne 0 ] ; then
        echo "# Could not create new building directory located at $PRJ_SIM_PATH/build" | tee -a "$PRJ_GENERATED_PATH/simulation_build_debug.log"
        cd "$CWD"
        return 1
    else
        echo "# Created new building directory located at $PRJ_SIM_PATH/build" | tee -a "$PRJ_GENERATED_PATH/simulation_build_debug.log"
    fi
    cd "$PRJ_SIM_PATH/build"
    cmake .. | tee -a "$PRJ_GENERATED_PATH/simulation_build_debug.log" || {
        echo "# CMake failed while compiling the Simulation! Abort..." | tee -a "$PRJ_GENERATED_PATH/simulation_build_debug.log"
        cd "$CWD"
        return 1
    }
    make | tee -a "$PRJ_GENERATED_PATH/simulation_build_debug.log" || {
        echo "# Make failed while compiling the Simulation! Abort..." | tee -a "$PRJ_GENERATED_PATH/simulation_build_debug.log"
        cd "$CWD"
        return 1
    }
    cd "$CWD"
    echo "# Finished building process for simulation successfully!" | tee -a "$PRJ_GENERATED_PATH/simulation_build_debug.log"
}


prj_run_simulation() {
    local CWD="$PWD"

    cd $PRJ_SIM_PATH/build || {
        echo "$PRJ_SIM_PATH/build does not exist! Run prj_build_simulation first and try again..." | tee $PRJ_GENERATED_PATH/simulation_run_debug.log
        return 1
    }
    $PRJ_SIM_PATH/build/simulation "$@" | tee $PRJ_GENERATED_PATH/simulation_run_debug.log
    cd $CWD
}


# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script must be sourced, not executed directly!" | tee "$PRJ_GENERATED_PATH/init_debug.log"
    echo "Use: source ./INIT.sh" | tee -a "$PRJ_GENERATED_PATH/init_debug.log"
    exit 1
fi

# Check if generated folder exist and creates it if necessary
if [ ! -d "$PRJ_ROOT_PATH/_generated" ]; then
    mkdir "$PRJ_ROOT_PATH/_generated"
    if [ $? -ne 0 ] ; then
        echo "# Could not create new logging directory located at $PRJ_ROOT_PATH/_generated" | tee "$PRJ_GENERATED_PATH/init_debug.log"
        exit 1
    else
        echo "# Created new logging directory located at $PRJ_ROOT_PATH/_generated" | tee "$PRJ_GENERATED_PATH/init_debug.log"
        echo "" | tee -a "$PRJ_GENERATED_PATH/init_debug.log"
    fi
else
    echo "# Logging Directory at $PRJ_ROOT_PATH/_generated already exists!" | tee "$PRJ_GENERATED_PATH/init_debug.log"  
    echo "" | tee -a "$PRJ_GENERATED_PATH/init_debug.log"  
fi

# Start logging manually
exec 3>&1 4>&2
exec > >(tee -a "$PRJ_GENERATED_PATH/init_debug.log") 2>&1


RESULT="SUCCESS"

echo "####################################################################"
echo "# Start INIT Script...:"
echo "####################################################################"
echo ""; echo ""

if [ ! -f "$PYTHON_BIN" ]; then
    echo "$PYTHON_BIN does not exist!"
    echo "Install it via 'pyenv install $PYTHON_VER' first..."
    echo ""; echo ""
    RESULT="FAILURE"
else

    # Create the virtual environment
    $PYTHON_BIN -m venv $ENV_NAME

    # Activate the virtual environment
    source $ENV_NAME/bin/activate

    # Upgrade pip
    echo "####################################################################"
    echo "# Upgrading pip...:"
    echo "####################################################################"
    python -m pip install --upgrade pip
    echo "####################################################################"
    echo ""; echo ""

    # Install all necessary packages
    echo "####################################################################"
    echo "# Package installs...:"
    echo "####################################################################"
    python -m pip install torch==2.1.0 torchvision==0.16.0 torchaudio==2.1.0 --index-url https://download.pytorch.org/whl/cu121
    python -m pip install onnx2pytorch
    python -m pip install tensorboard
    python -m pip install brevitas
    python -m pip install matplotlib
    python -m pip install numpy
    python -m pip install ipykernel
    python -m pip install onnx onnxruntime onnxoptimizer
    echo "####################################################################"
    echo ""; echo ""


    # Confirm installation for every package
    echo "####################################################################"
    echo "# Version checks...:"
    echo "####################################################################"
    python -c "import torch;             print('# PyTorch version.....:', torch.__version__)"
    python -c "import tensorboard;       print('# Tensorboard version.:', tensorboard.__version__)"
    python -c "import onnx2pytorch;      print('# Onnx2PyTorch version:', onnx2pytorch.__version__)"
    python -c "import brevitas;          print('# Brevitas version....:', brevitas.__version__)"
    python -c "import matplotlib as mpl; print('# Matplotlib version..:', mpl.__version__)"
    python -c "import numpy as np;       print('# Numpy version.......:', np.__version__)"
    python -c "import ipykernel;         print('# Ipykernel version...:', ipykernel.__version__)"
    python -c "import onnx;              print('# Onnx version........:', onnx.__version__)"
    echo "####################################################################"
    echo ""; echo ""

    echo "####################################################################"
    echo "# Virtual environment '$ENV_NAME' is ready with Packages installed."
    echo "####################################################################"
    echo ""

fi

echo "####################################################################"
echo "# Environmental variables...:"
echo "####################################################################"
echo "# PRJ_ROOT_PATH......: $PRJ_ROOT_PATH"
echo "# PRJ_TRAIN_PATH.....: $PRJ_TRAIN_PATH"
echo "# PRJ_SIM_PATH.......: $PRJ_SIM_PATH"
echo "# PRJ_WAVE_CFG.......: $PRJ_WAVE_CFG"
echo "# PRJ_HW_SOURCES_PATH: $PRJ_HW_SOURCES_PATH"
echo "# PRJ_HW_SIMS_PATH...: $PRJ_HW_SIMS_PATH"
echo "####################################################################"
echo ""; echo ""

echo "####################################################################"
echo "# Environmental aliases...:"
echo "####################################################################"
echo "# prj_train...........: Run the Training Script of the AlexNet Model"
echo "# prj_build_simulation: Run the building process for the" 
echo "#                       C++ reference implementation"
echo "# prj_run_simulation..: Run the C++ reference implementation"
prj_simulate_help
echo "# cd_root.............: Change CWD to project root:"
echo "#                       [$PRJ_ROOT_PATH]"
echo "# cd_train............: Change CWD to path of training folder:"
echo "#                       [$PRJ_TRAIN_PATH]" 
echo "# cd_sim..............: Change CWD to path of simulation folder:"
echo "#                       [$PRJ_SIM_PATH]" 
echo "# cd_hw_sources.......: Change CWD to path containing VHDL sources:"
echo "#                       [$PRJ_HW_SOURCES_PATH]" 
echo "# cd_hw_sims..........: Change CWD to path containing test benches:"
echo "#                       [$PRJ_HW_SIMS_PATH]" 
echo "####################################################################"
echo ""; echo ""

echo "####################################################################"
echo "# Initialization result...: $RESULT"
echo "####################################################################"
echo ""

# Restore output
exec 1>&3 2>&4
