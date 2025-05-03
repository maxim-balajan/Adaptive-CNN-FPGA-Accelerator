#!/bin/bash

# Set the name of the virtual environment
ENV_NAME=".venv"

# Set the python executable (explicitly Python 3.10)
PYTHON_VER="3.10.16"
PYTHON_BIN="$HOME/.pyenv/versions/$PYTHON_VER/bin/python"

if [ ! -f "$PYTHON_BIN" ]; then
    echo "$PYTHON_BIN does not exist!"
    echo "Install it via 'pyenv install $PYTHON_VER' first..."
else

    # Create the virtual environment
    $PYTHON_BIN -m venv $ENV_NAME

    # Activate the virtual environment
    source $ENV_NAME/bin/activate

    echo "####################################################################"
    echo "# Define Enviormental variables...:"
    echo "####################################################################"
    export PRJ_ROOT_PATH=($PWD)
    export PRJ_TRAIN_PATH="$PRJ_ROOT_PATH/reference/training/"
    export PRJ_SIM_PATH="$PRJ_ROOT_PATH/reference/simulation/"
    export PRJ_HW_SOURCES_PATH="$PRJ_ROOT_PATH/sources_1/"
    export PRJ_HW_SIMS_PATH="$PRJ_ROOT_PATH/sim_1/"

    alias cd_root="cd $PRJ_ROOT_PATH" 
    alias cd_train="cd $PRJ_TRAIN_PATH"
    alias cd_sim="cd $PRJ_SIM_PATH"
    alias cd_hw_sources="cd $PRJ_HW_SOURCES_PATH"
    alias cd_hw_sims="cd $PRJ_HW_SIMS_PATH"

    TODO="Add more aliases"
    echo "####################################################################"
    echo ""; echo ""

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
    python -m pip install tensorboard
    python -m pip install brevitas
    python -m pip install matplotlib
    python -m pip install numpy
    python -m pip install ipykernel
    python -m pip install onnx onnxruntime onnxoptimizer netron
    echo "####################################################################"
    echo ""; echo ""


    # Confirm installation for every package
    echo "####################################################################"
    echo "# Version checks...:"
    echo "####################################################################"
    python -c "import torch; print('# PyTorch version:', torch.__version__)"
    python -c "import tensorboard; print('# Tensorboard version:', tensorboard.__version__)"
    python -c "import brevitas; print('# Brevitas version:', brevitas.__version__)"
    python -c "import matplotlib as mpl; print('# Matplotlib version:', mpl.__version__)"
    python -c "import numpy as np; print('# Numpy version:', np.__version__)"
    python -c "import ipykernel; print('# Ipykernel version:', ipykernel.__version__)"
    python -c "import onnx; print('# Onnx version:', onnx.__version__)"
    echo "####################################################################"
    echo ""; echo ""

    echo "####################################################################"
    echo "# Virtual environment '$ENV_NAME' is ready with Packages installed."
    echo "####################################################################"

fi
