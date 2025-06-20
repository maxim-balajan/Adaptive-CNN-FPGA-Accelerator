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
    g)  GUI="-gui"
        ;;
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift

# Remove all prior simulation folders if they exist
TB=$1
shift $((OPTIND-1))
rm -rf /tmp/vivado_sim.$TB*

# Use a temporary directory for sim artifacts
CURRENT_PWD=$(pwd)
SIM_TEMP_DIR=$(mktemp -d "/tmp/vivado_sim.$TB.XXXXXX")
CONFIG="$PRJ_WAVE_CFG/${TB}_tb.wcfg"

echo ""
echo "####################################################################"
echo "#"
echo "# Elaboration and Simulation of ${TB}_tb"
echo "#"
echo "####################################################################"
echo ""


echo "####################################################################"
echo "# Removed older tmp projects at: /tmp/vivado_sim.$TB.*"
echo "# Using temporary path.........: $SIM_TEMP_DIR"
echo "# Using config (if exists).....: $CONFIG"
echo "####################################################################"

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
for src_file in "$@"
do
  xvhdl -2008 $src_file
done


echo ""
echo "#####################################################"
echo "# Starting Elaboration...:                          #"
echo "#####################################################"
echo ""

xelab "${TB}_tb" -s "${TB}_tb_sim" --debug typical || {
    echo "# Elaboration failed due to previous errors! Abort..."
    cd $CURRENT_PWD
    exit 1
}

cat <<EOF > wave_auto.tcl
$(if [[ -f "$CONFIG" ]]; then
  echo "open_wave_config \"$CONFIG\""
else
  echo 'puts "No File Config is used..."'
fi)
run all
EOF

echo ""
echo "#####################################################"
echo "# Starting Simulation...:                           #"
echo "#####################################################"

xsim "${TB}_tb_sim" $GUI -tclbatch wave_auto.tcl || {
    echo "# Simulation failed due to previous errors! Abort..."
    cd $CURRENT_PWD
    exit 1
}
