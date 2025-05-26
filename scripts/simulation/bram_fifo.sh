#!/bin/bash

# Remove all prior bram_fifo simulation if they exist
rm -rf /tmp/vivado_sim.bram_fifo*

# Use a temporary directory for sim artifacts
SIM_PATH=/tmp/vivado_sim.bram_fifo
SIM_TEMP_DIR=$(mkdir /tmp/vivado_sim.bram_fifo)
CONFIG=$PRJ_WAVE_CFG/bram_fifo_tb.wcfg

# Clean up on exit
cleanup() {
  rm -rf "$SIM_TEMP_DIR"
}
trap cleanup EXIT

echo ""
echo " # Using temporary path....: $SIM_TEMP_DIR"
echo " # Using config (if exists): $CONFIG"
echo ""

# Change to temporary dir
cd "$SIM_TEMP_DIR" || exit 1

# Compile VHDL sources
xvhdl -2008 $PRJ_HW_SOURCES_PATH/libmatrix.vhd
xvhdl -2008 $PRJ_HW_SOURCES_PATH/bram_fifo.vhd
xvhdl -2008 $PRJ_HW_SIMS_PATH/bram_fifo_tb.vhd

# Elaborate the testbench
xelab bram_fifo_tb -s bram_fifo_tb_sim --debug typical

cat <<EOF > wave_auto.tcl
$(if [[ -f "$CONFIG" ]]; then
  echo "open_wave_config \"$CONFIG\""
else
  echo "add_wave -recursive /"
fi)
run all
EOF

# Launch simulation in GUI and automatically run xsim.tcl
xsim bram_fifo_tb_sim -gui -tclbatch wave_auto.tcl

