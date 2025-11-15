# Setup synthesis for ooc mode
read_xdc "$PRJ_ROOT_PATH/scripts/VivadoProject/ooc_constraints.xdc"

puts "Start OOC synthesis for $PROJECT_NAME ..."
synth_design -top top_level_cnn_wrapper -part xczu3eg-sbva484-1-i

puts "Start OOC routing for $PROJECT_NAME ..."
opt_design
place_design
route_design

puts "Finished OOC implementation for $PROJECT_NAME !"
