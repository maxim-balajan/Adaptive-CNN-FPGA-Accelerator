#!/bin/bash

# Set the name of the virtual environment
ENV_NAME=".venv"

# Set the python executable (explicitly Python 3.10)
PYTHON_VER="3.10.16"
PYTHON_BIN="$HOME/.pyenv/versions/$PYTHON_VER/bin/python"

export PRJ_ROOT_PATH=($PWD)
export PRJ_TRAIN_PATH="$PRJ_ROOT_PATH/reference/training"
export PRJ_SIM_PATH="$PRJ_ROOT_PATH/reference/simulation"
export PRJ_HW_SOURCES_PATH="$PRJ_ROOT_PATH/sources_1"
export PRJ_HW_SIMS_PATH="$PRJ_ROOT_PATH/sim_1"

# Various directory changes abstracted into new commands
alias cd_root="cd $PRJ_ROOT_PATH" 
alias cd_train="cd $PRJ_TRAIN_PATH"
alias cd_sim="cd $PRJ_SIM_PATH"
alias cd_hw_sources="cd $PRJ_HW_SOURCES_PATH"
alias cd_hw_sims="cd $PRJ_HW_SIMS_PATH"
# Script for executing the Training of the Model
alias prj_train="python -u $PRJ_TRAIN_PATH/training.py"
# Build and run aliases for execturing the C++ Simulation
alias prj_build_simulation="rm -rf $PRJ_SIM_PATH/build; mkdir $PRJ_SIM_PATH/build; cd $PRJ_SIM_PATH/build; cmake ..; make"
alias prj_run_simulation="$PRJ_SIM_PATH/build/simulation"

RESULT="SUCCESS"

if [ ! -f "$PYTHON_BIN" ]; then
    echo "$PYTHON_BIN does not exist!"
    echo "Install it via 'pyenv install $PYTHON_VER' first..."
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
echo "# Enviormental variables...:"
echo "####################################################################"
echo "# PRJ_ROOT_PATH Directory......: $PRJ_ROOT_PATH"
echo "# PRJ_TRAIN_PATH Directory.....: $PRJ_TRAIN_PATH"
echo "# PRJ_SIM_PATH Directory.......: $PRJ_SIM_PATH"
echo "# PRJ_HW_SOURCES_PATH Directory: $PRJ_HW_SOURCES_PATH"
echo "# PRJ_HW_SIMS_PATH Directory...: $PRJ_HW_SIMS_PATH"
echo "####################################################################"
echo ""; echo ""

echo "####################################################################"
echo "# Enviormental aliases...:"
echo "####################################################################"
echo "# prj_train...........: Run the Training Script of the AlexNet Model"
echo "# prj_build_simulation: Run the building process for the" 
echo "#                       C++ reference implementation"
echo "# prj_run_simulation..: Run the C++ reference implementaion"
echo "####################################################################"
echo "# cd_root.............: Change PWD to project root:"
echo "#                       [$PRJ_ROOT_PATH]"
echo "# cd_train............: Change PWD to path of training folder:"
echo "#                       [$PRJ_TRAIN_PATH]" 
echo "# cd_sim..............: Change PWD to path of simulation folder:"
echo "#                       [$PRJ_SIM_PATH]" 
echo "# cd_hw_sources.......: Change PWD to path containing VHDL sources:"
echo "#                       [$PRJ_HW_SOURCES_PATH]" 
echo "# cd_hw_sims..........: Change PWD to path containing test benches:"
echo "#                       [$PRJ_HW_SIMS_PATH]" 
echo "####################################################################"
echo ""; echo ""

echo "####################################################################"
echo "# Initialization result...: $RESULT"
echo "####################################################################"
echo ""
