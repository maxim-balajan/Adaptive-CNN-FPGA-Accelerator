from adder_tree_gen import safe_read

class CoreInst():
    def __init__(self, name: str, core_dict: dict):
        self.name = name
        self.amount = safe_read(core_dict, 'amount', 1)
        self.pool_or_conv = safe_read(core_dict, 'pool_or_conv', 1)
        self.clip_adder = safe_read(core_dict, 'enable_clip_adder', 1)
        self.multiplication_line = safe_read(core_dict, 'enable_multiplication_line', 0)
        self.shift = safe_read(core_dict, 'enable_shift', 0)
        self.relu = safe_read(core_dict, 'enable_relu', 1)
        self.i_length = safe_read(core_dict, 'input_length')
        self.o_length = safe_read(core_dict, 'output_length')
        self.i_amount = safe_read(core_dict, 'input_amount')

        
