# Setup synthesis for ooc mode
add_files -fileset constrs_1 -norecurse "$PRJ_ROOT_PATH/scripts/VivadoProject/ooc_constraints.xdc"

puts "Create OOC Runs for $PROJECT_NAME ..."
create_run synth_ooc -flow {Vivado Synthesis 2023}
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_ooc]
current_run synth_ooc

create_run impl_ooc -parent_run synth_ooc -flow {Vivado Implementation 2023}
current_run impl_ooc

puts "Start OOC synthesis for $PROJECT_NAME ..."
launch_runs synth_ooc
wait_on_run synth_ooc

puts "Start OOC routing for $PROJECT_NAME ..."
launch_runs impl_ooc
wait_on_run impl_ooc

puts "Finished OOC implementation for $PROJECT_NAME !"
