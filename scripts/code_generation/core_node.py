
from core_inst import CoreInst

class CoreNode():
    def __init__(self, core: CoreInst, start_address: int):
        self.pool_or_conv = core.pool_or_conv
        self.clip_adder = core.clip_adder
        self.multiplication_line = core.multiplication_line
        self.shift = core.shift
        self.relu = core.relu
        self.i_length = core.i_length
        self.o_length = core.o_length
        self.i_amount = core.i_amount

        self.start_address = start_address

        self.parent: CoreInst = None
        self.children: list[CoreInst] = [None for _ in range(self.i_amount)]

    def __eq__(self, other):
        return self.pool_or_conv == other.pool_or_conv and self.clip_adder == other.clip_adder \
            and self.multiplication_line == other.multiplication_line and self.shift == other.shift \
            and self.relu == other.relu and self.i_length == other.i_length and self.o_length == other.o_length \
            

    def set_parent(self, parent):
        self.parent = parent

    def set_child(self, child, id: int):
        self.children[id] = child

        