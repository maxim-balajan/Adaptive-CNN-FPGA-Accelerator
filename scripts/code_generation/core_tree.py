from common_utils import safe_read, get_nth_key
import os, sys
import copy
from core_inst import CoreInst
from core_node import CoreNode
from math import ceil

class CoreTree():
    def __init__(self, cores: list[CoreInst], route_dicts: dict, iteration: int):

        route_dict = route_dicts[get_nth_key(route_dicts, iteration)]
        self.input_channel = safe_read(route_dict, 'input_channel')
        self.output_channel = safe_read(route_dict, "output_channel", 1)
        self.input_amount = safe_read(route_dict, "input_amount")
        self.pool_or_conv = safe_read(route_dict, "pool_or_conv", 1)
        # Only use cores that are useful
        self.unused_cores = {}
        self.used_cores = {}
        i = 0
        for core in cores:
            if core.pool_or_conv == self.pool_or_conv:
                # Bundle all equivalent core bundles together to make routing less fragmented
                for name, core_bundle in self.unused_cores.items():
                    if len(core_bundle) > 0 and core_bundle[0] == core:
                        core_bundle \
                            += [CoreNode(core, core.start_address + i * core.i_amount) for i in range(core.amount)]
                        self.unused_cores[name] = core_bundle
                        break
                else:
                    self.unused_cores[f'bundle_{i}'] \
                        = [CoreNode(core, core.start_address + i * core.i_amount) for i in range(core.amount)]
                    self.used_cores[f'bundle_{i}'] = []
                    i += 1
    

    def find_largest_core_bundle(
            self,
            core_bundles: dict[list[CoreNode]],
            with_multiplier: bool,
            input_amount: int
    ) -> tuple[str, list[CoreNode]]:
        current_core_bundle = None
        current_name = ""
        for name, core_bundle in core_bundles.items():
            if len(core_bundle) > 0 and with_multiplier == core_bundle[0].multiplication_line:
                total_i_amount = core_bundle[0].i_amount * len(core_bundle)
                # Only update if a larger bundle has been found with sufficient hardware
                if (current_core_bundle is None 
                    or (current_core_bundle[0].i_amount < core_bundle[0].i_amount 
                    and total_i_amount >= input_amount)
                ):
                    current_core_bundle = core_bundle
                    current_name = name

        if current_core_bundle is None:
            raise StopIteration(f"No core bundle with for with_multiplier == {with_multiplier} found!")

        return current_name, current_core_bundle  


    def find_most_fitting_core_bundle(
            self,
            core_bundles: dict[list[CoreNode]],
            with_multiplier: int,
            input_amount: int
    ) -> tuple[int, int, str, list[CoreNode]]:
        current_core_bundle = None
        current_name = ""
        distance = -1
        if len(core_bundles) <= 0:
            raise StopIteration(f"No core bundle with for with_multiplier == {with_multiplier} found!")
        
        for name, core_bundle in core_bundles.items():
            if with_multiplier == core_bundle[0].multiplication_line:
                cores_needed = ceil(input_amount / core_bundle[0].i_amount)
                if cores_needed > len(core_bundle):
                    continue
                new_distance = cores_needed * core_bundle[0].i_amount - input_amount
                # Only update if distance is smaller then new distance
                if (current_core_bundle is None or 0 <= new_distance < distance):
                    current_core_bundle = core_bundle
                    current_name = name
                    distance = new_distance

        if current_core_bundle is None:
            raise StopIteration(f"No core bundle with for with_multiplier == {with_multiplier} found!")
        

        return distance, cores_needed, current_name, current_core_bundle 


    def route_single_oc(self, oc_id: int):
        current_inputs = self.input_channel * self.input_amount
        child_cores = []
        iteration_count = 0
        while (current_inputs > 1):
            try:
                    distance, cores_needed, bundle_name, bundle = self.find_most_fitting_core_bundle(self.unused_cores, not iteration_count, current_inputs)
                    print(f"Iteration: {iteration_count}")
                    print(f"{cores_needed} Cores of bundle '{bundle_name}'")
                    print(f'Bundle Meta:')
                    print(f"   Multplication: {bundle[0].multiplication_line}")
                    print(f"   Input-Amount.: {bundle[0].i_amount}")
                    print(f"   Input-Width..: {bundle[0].i_length}")
                    print(f"   Output-Width.: {bundle[0].o_length}")
                    print("")

                    current_cores = bundle[0:cores_needed:]

                    # Identify which port nodes should be empty
                    if distance > 0:
                        empty_childs = current_cores[-1].children[-distance:len(current_cores[-1].children):]
                        for i in range(len(empty_childs)):
                            empty_childs[i] = -1
                    # Set correct children if its not the first iteration
                    if iteration_count > 0:
                        for core in current_cores:
                            for i in range(len(core.children)):
                                if len(child_cores) <= 0:
                                    break
                                core.children[i] = child_cores.pop(0)
                                core.children[i].parent = core
                            else:
                                break
                    # Remove current_cores from unused cores and add them to used bucket
                    if self.used_cores.get(bundle_name) is None:
                        self.used_cores[bundle_name] = []
                    self.used_cores[bundle_name] += current_cores
                    self.unused_cores[bundle_name] = bundle[cores_needed::]

                    # Set current_cores as new children for next iteration
                    child_cores = current_cores
                    current_inputs = len(current_cores)
                    iteration_count += 1
            except StopIteration as si:
                print("Resources exhausted! Can't continue the routing")
                sys.exit(1)
                

        print(f"Routing for OC {oc_id} finished successfully!")

    def route(self):
        for i in range(self.output_channel):
            self.route_single_oc(i)

        print("Entire Routing finished successfully!")
    