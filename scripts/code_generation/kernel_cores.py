from adder_tree_config import AdderTreeConfig
import os

class KernelCores():
    def __init__(self, config: AdderTreeConfig, architecture_name='rtl'):
        self.architecture_name = architecture_name
        self.config = config


    def entity_to_string(self) -> str:
        template_path = os.path.join(os.getenv('PRJ_SCRIPTS'), 'code_generation', 'templates', 'kernel_cores_entity.vhd')
        template = ""
        with open(template_path) as f:
            template = f.read()

        template = template.replace("%%CORE_COMPILE_LIB%%", str(self.config.compile_lib))
        template = template.replace("%%INPUT_AMOUNT%%", str(self.config.i_dataline_amount))
        template = template.replace("%%CORE_MAX_INPUT_LENGTH%%", str(self.config.i_dataline_width))
        template = template.replace("%%CORE_MAX_OUTPUT_LENGTH%%", str(self.config.o_dataline_width))
        template = template.replace("%%MAX_CORE_AMOUNT%%", str(self.config.max_core_amount))

        return template
    

    def architecture_to_string(self) -> str:
        template_path = os.path.join(os.getenv('PRJ_SCRIPTS'), 'code_generation', 'templates', 'kernel_cores_architecture.vhd')
        template = ""
        with open(template_path) as f:
            template = f.read()

        template = template.replace("%%KERNEL_CORES_ARCHITECTURE_NAME%%", str(self.architecture_name))

        am_offset = 0
        wm_offset = 0
        control_offset = 0
        out_offset = 0
        core_instances = ""
        for core in self.config.cores:
            core_instances += core.instantiation_to_string(am_offset, wm_offset, control_offset, out_offset)
            am_offset += core.max_input_amount * core.max_core_amount
            wm_offset += core.max_input_amount * core.max_core_amount
            control_offset += core.max_core_amount
            out_offset += core.max_core_amount

        template = template.replace("%%CORE_INSTANCES%%", core_instances)
        

        return template
    

    def module_to_file(self) -> None:
        template = self.entity_to_string() + self.architecture_to_string()

        with open(os.path.join(os.getenv('PRJ_SCRIPTS'), 'code_generation', 'export', f'kernel_cores.vhd'), 'w') as f:
            f.write(template)

