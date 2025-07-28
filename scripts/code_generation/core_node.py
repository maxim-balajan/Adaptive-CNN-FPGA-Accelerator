
from core_inst import CoreInst

class CoreNode():
    def __init__(self, core: CoreInst):
        self.core = core
        self.parent: CoreInst = None
        self.children: list[CoreInst] = [None for i in range(core.amount)]


    def set_parent(self, parent):
        self.parent = parent

    def set_child(self, child, id: int):
        self.children[id] = child

        