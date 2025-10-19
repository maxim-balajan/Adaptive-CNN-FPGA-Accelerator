from os import environ
from os.path import join, dirname, abspath, isfile
import sys


# basic setup
cur_path = dirname(__file__)
vunit_path = abspath(environ["PRJ_VUNIT_PATH"])
source_path = abspath(environ["PRJ_HW_SOURCES_PATH"])

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
tb_lib.add_source_files(join(cur_path, "..", "sources", "*.vhd"))
tb_lib.add_source_files(join(cur_path, "testbench", "*.vhd"))

# add test bench configurations

test_bench = tb_lib.test_bench("top_level_cnn_tb")
test_bench.add_config(name="tb_cfg_0", generics=dict())

################
## execute TB ##
################

my_vunit.main()
