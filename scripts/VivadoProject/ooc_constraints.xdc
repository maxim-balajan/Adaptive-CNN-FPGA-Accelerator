# create virtual clock for OOC synthesis
# ---------------------------------------

create_clock -period 3.33 [get_ports clk]

# constraint input and output delays
# ----------------------------------

set delay_tolerance 0.1

set main_clock [get_clocks -of_objects [get_ports cmd_clk]]
set period_main_clk [get_property PERIOD $main_clock]
set clock_delay [expr { $period_main_clk * $delay_tolerance }]

# reset delay
set_input_delay -clock $main_clock $clock_delay [get_ports reset]
 
# debug ports 
set_output_delay -clock $main_clock $clock_delay [get_ports o_*]

# Weight bus delay
set_input_delay -clock $main_clock $clock_delay [get_ports wt_s_* -filter {DIRECTION == IN}]
set_output_delay -clock $main_clock $clock_delay [get_ports wt_s_* -filter {DIRECTION == OUT}]

# Pixel delay
set_input_delay -clock $main_clock $clock_delay [get_ports px_* -filter {DIRECTION == IN}]
set_output_delay -clock $main_clock $clock_delay [get_ports px_* -filter {DIRECTION == OUT}]
