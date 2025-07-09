import yaml
import sys, os
import types

class AdderTreeConfig():
    def __init__(self, config_path):
        with open(config_path, 'r') as f:
            config_dict = yaml.safe_load(f)
        self.i_dataline_amount = self.__safe_read(config_dict, 'input_amount')
        self.o_dataline_amount = self.__safe_read(config_dict, 'output_amount')
        self.i_dataline_width = self.__safe_read(config_dict, 'input_max_bit_width')
        self.o_dataline_width = self.__safe_read(config_dict, 'output_max_bit_width')
        self.compile_lin = self.__safe_read(config_dict, 'compile_lib', 'work')
        self.cores = []

        try:
            for name, core_dict in config_dict['cores'].items():
                core = types.SimpleNamespace()
                core.name = name
                core.amount = self.__safe_read(core_dict, 'amount', 1)
                core.pool_or_conv = self.__safe_read(core_dict, 'pool_or_conv', 1)
                core.clip_adder = self.__safe_read(core_dict, 'enable_clip_adder', 1)
                core.multiplication_line = self.__safe_read(core_dict, 'enable_multiplication_line', 0)
                core.shift = self.__safe_read(core_dict, 'enable_shift', 0)
                core.relu = self.__safe_read(core_dict, 'enable_relu', 1)
                core.i_length = self.__safe_read(core_dict, 'input_length')
                core.o_length = self.__safe_read(core_dict, 'output_length')
                core.i_amount = self.__safe_read(core_dict, 'input_amount')

                self.cores.append(core)
        except KeyError:
            raise NameError(f'Error: Could not find necessary key "cores" in Config! Abort...')
    

    def __safe_read(self, config:dict, key: str, default=None):
        try:
            return config[key]
        except KeyError:
            if default is not None:
                return default
            else:
                raise NameError(f'Error: Could not find necessary key "{key}" in Config! Abort...')


def main():

    adder_config = AdderTreeConfig(os.path.join(os.getenv('PRJ_SCRIPTS'), 'code_generation', 'adder_tree_config.yaml'))
    return 0



if __name__ == "__main__":
    main()