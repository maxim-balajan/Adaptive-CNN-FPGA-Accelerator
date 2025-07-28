from common_utils import safe_read, get_nth_key
import os
import copy
from core_inst import CoreInst
from core_node import CoreNode

class CoreTree():
    def __init__(self, cores: list[CoreInst], route_dicts: dict, iteration: int):

        route_dict = route_dicts[get_nth_key(route_dicts, iteration)]
        self.input_channel = safe_read(route_dict, 'input_channel')
        self.output_channel = safe_read(route_dict, "output_channel", self.input_channel)
        self.pool_or_conv = safe_read(route_dict, "pool_or_conv", 1)
        # Only use cores that are useful
        self.unused_cores = []
        self.used_cores = []
        for core in cores:
            if core.pool_or_conv == self.pool_or_conv:
                for _ in range(core.amount):
                    self.unused_cores.append(copy.deepcopy(core))
        # sorted from largest core to 
        self.unused_cores = sorted(self.unused_cores, lambda c: c.core.i_amount, reverse=True)


    def route(self):
        pass
    