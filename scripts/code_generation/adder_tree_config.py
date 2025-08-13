from core_inst import CoreInst
import yaml
from common_utils import safe_read

class AdderTreeConfig():
    def __init__(self, config_path, template_dir, export_dir):
        with open(config_path, 'r') as f:
            config_dict = yaml.safe_load(f)
        self.i_dataline_amount = safe_read(config_dict, 'matrix_input_amount')
        self.i_dataline_width = safe_read(config_dict, 'input_max_bit_width')
        self.o_dataline_width = safe_read(config_dict, 'output_max_bit_width')
        self.max_core_amount = safe_read(config_dict, 'max_core_amount')
        self.compile_lib = safe_read(config_dict, 'compile_lib', 'work')
        self.route_configs = safe_read(config_dict, 'route_configs')
        self.cores: list[CoreInst] = []

        try:
            for name, core_dict in config_dict['cores'].items():
                core = CoreInst(name, core_dict, template_dir, export_dir, safe_read(config_dict, 'iteration', 0))
                self.cores.append(core)
        except KeyError:
            raise NameError(f'Error: Could not find necessary key "cores" in Config! Abort...')