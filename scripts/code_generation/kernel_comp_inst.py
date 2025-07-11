from adder_tree_gen import AdderTreeConfig
from types import SimpleNamespace

from core_inst import CoreInst

import os

class KernelCompBundle():
    def __init__(self, config: CoreInst, compile_lib: str):
        self.core_metadata = config
        self.compile_lib = compile_lib
        


    def instantiation_to_string(self):
        template_path = os.path.join(os.getenv('PRJ_SCRIPTS'), 'code_generation', 'templates', 'kernel_comp_unit_inst.vhd')
        template = ""
        with open(template_path) as f:
            template = f.read()

        template = template.replace("%%CORE_COMPILE_LIB%%", str(self.compile_lib))
        template = template.replace("%%CORE_NAME%%", str(self.core_metadata.name))
        template = template.replace("%%CORE_AMOUNT%%", str(self.core_metadata.amount))
        template = template.replace("\%\%CORE_INPUT_LENGTH%%", str(self.core_metadata.i_amount))
        template = template.replace("%%CORE_TYPE%%", str(self.core_metadata.pool_or_conv))
        template = template.replace("%%CORE_CLIP_ADDER%%", str(self.core_metadata.clip_adder))
        template = template.replace("%%CORE_MULTIPLICATION_LINE%%", str(self.core_metadata.multiplication_line))
        template = template.replace("%%CORE_SHIFT%%", str(self.core_metadata.shift))
        template = template.replace("%%CORE_BIAS%%", "0")
        template = template.replace("%%CORE_RELU%%", str(self.core_metadata.relu))
        template = template.replace("%%CORE_INPUT_AMOUNT%%", str(self.core_metadata.i_amount))
        template = template.replace("%%CORE_INPUT_LENGTH%%", str(self.core_metadata.i_length))
        template = template.replace("%%CORE_OUTPUT_LENGTH%%", str(self.core_metadata.o_length))

        with open(os.path.join(os.getenv('PRJ_SCRIPTS'), 'code_generation', 'export', f'{self.core_metadata.name}.vhd'), 'w') as f:
            f.write(template)

        return template
