#!/bin/bash

# Set the name of the virtual environment
ENV_NAME="venv"

# Set the python executable (explicitly Python 3.10)
PYTHON_BIN="$HOME/.pyenv/versions/3.10.16/bin/python"

if [ ! -f "$PYTHON_BIN" ]; then
    echo "$PYTHON_BIN does not exist!"
    echo "Install it via 'pyenv install <Version-Number>' first..."
else

    # Create the virtual environment
    $PYTHON_BIN -m venv $ENV_NAME

    # Activate the virtual environment
    source $ENV_NAME/bin/activate

    # Upgrade pip
    $PYTHON_BIN -m pip install --upgrade pip

    # Install all necessary packages
    echo "####################################################################"
    echo "# Package installs...:"
    echo "####################################################################"
    $PYTHON_BIN -m pip install torch==2.1.0 torchvision==0.16.0 torchaudio==2.1.0 --index-url https://download.pytorch.org/whl/cu121
    $PYTHON_BIN -m pip install tensorboard
    $PYTHON_BIN -m pip install brevitas
    $PYTHON_BIN -m pip install matplotlib
    $PYTHON_BIN -m pip install numpy
    $PYTHON_BIN -m pip install ipykernel
    $PYTHON_BIN -m pip install onnx onnxruntime onnxoptimizer netron
    echo "####################################################################"
    echo ""; echo ""


    # Confirm installation for every package
    echo "####################################################################"
    echo "# Version checks...:"
    echo "####################################################################"
    $PYTHON_BIN -c "import torch; print('# PyTorch version:', torch.__version__)"
    $PYTHON_BIN -c "import tensorboard; print('# Tensorboard version:', tensorboard.__version__)"
    $PYTHON_BIN -c "import brevitas; print('# Brevitas version:', brevitas.__version__)"
    $PYTHON_BIN -c "import matplotlib as mpl; print('# Matplotlib version:', mpl.__version__)"
    $PYTHON_BIN -c "import numpy as np; print('# Numpy version:', np.__version__)"
    $PYTHON_BIN -c "import ipykernel; print('# Ipykernel version:', ipykernel.__version__)"
    $PYTHON_BIN -c "import onnx; print('# Onnx version:', onnx.__version__)"
    echo "####################################################################"
    echo ""; echo ""

    echo "####################################################################"
    echo "# Virtual environment '$ENV_NAME' is ready with Packages installed."
    echo "####################################################################"

fi



