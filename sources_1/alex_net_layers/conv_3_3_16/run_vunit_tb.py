from os import environ
from os.path import join, dirname, abspath, isfile
import sys


# basic setup
cur_path = dirname(__file__)
vunit_path = abspath(environ["PRJ_VUNIT_PATH"])
source_path = abspath(environ["PRJ_HW_SOURCES_PATH"])
sim_path = abspath(environ["PRJ_HW_SIMS_PATH"])

# add VUnit to the system path variable
sys.path.append(join(vunit_path))
sys.path.append(join(abspath(join(vunit_path, 'python_scripts'))))

# import VUnit and project specific libraries
from vunit import VUnit

local_modelsim_ini = abspath(join(cur_path, 'modelsim.ini'))
if isfile(local_modelsim_ini) :
    environ["VUNIT_MODELSIM_INI"] = local_modelsim_ini


# TB setup

try:
    my_vunit = VUnit.from_argv(compile_builtins=False)
    my_vunit.add_vhdl_builtins()
except:
    my_vunit = VUnit.from_argv()


my_vunit.add_osvvm()
my_vunit.add_verification_components()


#############
# setup TB ##
#############

tb_lib = my_vunit.add_library("tb_lib", vhdl_standard="2008")
tb_lib.add_source_files(join(source_path, "*.vhd"))
tb_lib.add_source_files(join(cur_path, "*.vhd"))
tb_lib.add_source_files(join(sim_path, "top_level", "testbench", "*.vhd"))

# add test bench configurations

test_bench = tb_lib.test_bench("top_level_cnn_tb")

# TODO: when using as actual cfg string, change output_channel_size and input_channel_per_iteration (if needed)
test_bench.add_config(name="tb_conv_384_256_3_3", generics=dict(G_CONFIG_STR='07000103001000a900020100000d000d'))
test_bench.add_config(name="tb_conv_384_384_3_3", generics=dict(G_CONFIG_STR='07000103001000a900020180000d000d'))
test_bench.add_config(name="tb_conv_256_384_3_3", generics=dict(G_CONFIG_STR='07000103001000a900020180000d000d'))

################
## execute TB ##
################

my_vunit.main()
