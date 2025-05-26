#!/bin/bash

# Remove all prior bram_fifo simulation if they exist
rm -rf /tmp/vivado_sim.kernel_slider.*

# Use a temporary directory for sim artifacts
CURRENT_PWD=$(pwd)
SIM_TEMP_DIR=$(mktemp -d /tmp/vivado_sim.kernel_slider.XXXXXX)
CONFIG=$PRJ_WAVE_CFG/kernel_slider_tb.wcfg

echo "#####################################################"
echo "# Using temporary path....: $SIM_TEMP_DIR"
echo "# Using config (if exists): $CONFIG"
echo "#####################################################"
echo ""

# Change to temporary dir
cd "$SIM_TEMP_DIR" || {
    echo "# Could not create directory $SIM_PATH. Abort..."
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
xvhdl -2008 $PRJ_HW_SOURCES_PATH/line_buffer.vhd
xvhdl -2008 $PRJ_HW_SOURCES_PATH/kernel_slider.vhd
xvhdl -2008 $PRJ_HW_SIMS_PATH/kernel_slider_tb.vhd

echo ""
echo "#####################################################"
echo "# Starting Elaboration...:                          #"
echo "#####################################################"
echo ""
xelab kernel_slider_tb -s kernel_slider_tb_sim --debug typical || {
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

echo "#####################################################"
echo "# Starting Simulation...:                           #"
echo "#####################################################"
echo ""
xsim kernel_slider_tb_sim -gui -tclbatch wave_auto.tcl || {
    echo "# Simulation failed due to previous errors! Abort..."
    cd $CURRENT_PWD
    exit 1
}
