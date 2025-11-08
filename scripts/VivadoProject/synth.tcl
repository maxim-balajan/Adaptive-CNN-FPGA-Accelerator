# Run synthesis
launch_runs synth_1
wait_on_run synth_1

# Run implementation
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

# Export the bitstream file
set BIT_FILE "${PROJECT_DIR}/${PROJECT_NAME}.runs/impl_1/${PROJECT_NAME}.bit"
puts "Bitstream generated at: $BIT_FILE"

write_hw_platform -include_bit -fixed -force "${PROJECT_DIR}/${PROJECT_NAME}.xsa"
puts "Hardware platform was created at ${PROJECT_DIR}/${PROJECT_NAME}.xsa"

