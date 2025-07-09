from adder_tree_gen import AdderTreeConfig
from types import SimpleNamespace

class KernelCompInst():
    def __init__(self, config: SimpleNamespace, compile_lib: str, i_signals: list, o_signal: str):
        self.i_signals = i_signals
        self.o_signal = o_signal
        self.core_metadata = config
        self.compile_lib = compile_lib
        # Sanity Check
        if len(i_signals) != self.core_metadata.i_amount:
            raise ValueError(f'Wrong amount of input signals! Expected {self.core_metadata.i_amount} and got {len(i_signals)}')
        


    def instantiation_to_string(self):
        