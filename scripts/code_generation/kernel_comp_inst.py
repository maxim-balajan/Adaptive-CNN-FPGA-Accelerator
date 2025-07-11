from adder_tree_gen import AdderTreeConfig
from types import SimpleNamespace

from core_inst import CoreInst

import os

class KernelCompBundle():
    def __init__(self, config: CoreInst, compile_lib: str, i_signals: list, o_signal: str):
        self.i_signals = i_signals
        self.o_signal = o_signal
        self.core_metadata = config
        self.compile_lib = compile_lib
        # Sanity Check
        if len(i_signals) != self.core_metadata.i_amount:
            raise ValueError(f'Wrong amount of input signals! Expected {self.core_metadata.i_amount} and got {len(i_signals)}')
        


    def instantiation_to_string(self):
        template_path = os.path(os.getenv('PRJ_SCRIPTS'), 'code_generation', 'templates', 'kernel_comp_unit_inst.vhd')
        template = ""
        with open(template_path) as f:
            template = f.read()

        template.replace("%%")