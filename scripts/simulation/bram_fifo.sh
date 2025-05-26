#!/bin/bash

# Remove all prior bram_fifo simulation if they exist
rm -rf /tmp/vivado_sim.bram_fifo*

# Use a temporary directory for sim artifacts
CURRENT_PWD=$(pwd)
SIM_TEMP_DIR=$(mktemp -d /tmp/vivado_sim.bram_fifo.XXXXXX)
CONFIG=$PRJ_WAVE_CFG/bram_fifo_tb.wcfg


echo "####################################################################"
echo "# Removed older tmp projects at: /tmp/vivado_sim.bram_fifo.*"
echo "# Using temporary path.........: $SIM_TEMP_DIR"
echo "# Using config (if exists).....: $CONFIG"
echo "####################################################################"
echo ""

# Change to temporary dir
cd "$SIM_TEMP_DIR" || {
    echo "# Could not create directory $SIM_TEMP_DIR. Abort..."
    cd $CURRENT_PWD
    exit 1
}


echo ""
echo "#####################################################"
echo "# Starting Compilation...:                          #"
echo "#####################################################"
echo ""
xvhdl -2008 $PRJ_HW_SOURCES_PATH/libmatrix.vhd
xvhdl -2008 $PRJ_HW_SOURCES_PATH/bram_fifo.vhd
xvhdl -2008 $PRJ_HW_SIMS_PATH/bram_fifo_tb.vhd


echo ""
echo "#####################################################"
echo "# Starting Elaboration...:                          #"
echo "#####################################################"
echo ""

xelab bram_fifo_tb -s bram_fifo_tb_sim --debug typical || {
    echo "# Elaboration failed due to previous errors! Abort..."
    cd $CURRENT_PWD
    exit 1
}

cat <<EOF > wave_auto.tcl
$(if [[ -f "$CONFIG" ]]; then
  echo "open_wave_config \"$CONFIG\""
else
  echo "add_wave -recursive /"
fi)
run all
EOF

echo ""
echo "#####################################################"
echo "# Starting Simulation...:                           #"
echo "#####################################################"
echo ""

xsim bram_fifo_tb_sim -gui -tclbatch wave_auto.tcl || {
    echo "# Simulation failed due to previous errors! Abort..."
    cd $CURRENT_PWD
    exit 1
}
