from common_utils import safe_read, get_nth_key, get_nth_key_name
import os, sys
import copy
from core_inst import CoreInst
from core_node import CoreNode
from adder_tree_config import AdderTreeConfig
from math import ceil

class CoreTree():
    def __init__(self, adder_tree_config: AdderTreeConfig, route_dicts: dict, templates_dir: str, export_dir: str, iteration: int):

        self.template_dir = templates_dir
        self.export_dir = export_dir
        route_dict = route_dicts[get_nth_key(route_dicts, iteration)]
        self.architecture_name = get_nth_key_name(route_dicts, iteration)
        self.max_output_channels = safe_read(route_dicts['global'], 'max_output_channels', 1)
        self.max_kernel_size = safe_read(route_dicts['global'], 'max_kernel_size', 12)
        self.max_pipeline_steps = safe_read(route_dicts['global'], 'max_pipeline_steps', 1)
        
        self.line_buffer_amount = safe_read(route_dicts['global'], 'line_buffer_amount', 180)
        self.adder_tree_config = adder_tree_config
        self.input_channel = safe_read(route_dict, 'input_channel')
        self.output_channel = safe_read(route_dict, "output_channel", 1)
        self.input_amount = safe_read(route_dict, "input_amount")
        self.pool_or_conv = safe_read(route_dict, "pool_or_conv", 1)
        # Only use cores that are useful
        self.unused_cores = {}
        self.used_cores = {}
        self.output_channel_list = [[] for _ in range(self.output_channel)]
        i = 0
        for core in adder_tree_config.cores:
            if core.pool_or_conv == self.pool_or_conv:
                # Bundle all equivalent core bundles together to make routing less fragmented
                for name, core_bundle in self.unused_cores.items():
                    if len(core_bundle) > 0 and core_bundle[0] == core:
                        core_bundle \
                            += [CoreNode(core, core.in_start_address + i * core.i_amount, core.out_start_address + i) for i in range(core.amount)]
                        self.unused_cores[name] = core_bundle
                        break
                else:
                    self.unused_cores[f'bundle_{i}'] \
                        = [CoreNode(core, core.in_start_address + i * core.i_amount, core.out_start_address + i) for i in range(core.amount)]
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
            input_amount: int,
            bit_width: int
    ) -> tuple[int, int, str, list[CoreNode]]:
        current_core_bundle = None
        current_name = ""
        distance = -1
        if len(core_bundles) <= 0:
            raise StopIteration(f"No core bundle with for with_multiplier == {with_multiplier} found!")
        
        for name, core_bundle in core_bundles.items():
            if with_multiplier == core_bundle[0].multiplication_line and (bit_width is None or core_bundle[0].i_length == bit_width):
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
        current_inputs = self.input_channel * self.input_amount if self.pool_or_conv == 1 else self.input_amount
        child_cores: list[CoreNode] = []
        iteration_count = 0
        # Int for marking the address if input should be taken from i_kernel_activation_matrix
        configurable_slider_input_id = oc_id * self.input_amount
        print(f"\n##############################")
        print(f"### Start of Routing of OC {oc_id}:")
        print(f"##############################\n")
        while (current_inputs > 1):
            try:
                    bit_width = None if not child_cores else child_cores[0].o_length
                    distance, cores_needed, bundle_name, bundle = self.find_most_fitting_core_bundle(self.unused_cores, not iteration_count and self.pool_or_conv, current_inputs, bit_width)
                    print(f"Iteration: {iteration_count}")
                    print(f"{cores_needed} Cores of bundle '{bundle_name}'")
                    print(f"{len(child_cores)} Child Cores")
                    print(f'Bundle Meta:')
                    print(f"   Multplication: {bundle[0].multiplication_line}")
                    print(f"   Input-Amount.: {bundle[0].i_amount}")
                    print(f"   Input-Width..: {bundle[0].i_length}")
                    print(f"   Output-Width.: {bundle[0].o_length}")
                    print("")

                    current_cores = bundle[0:cores_needed:]

                    # Set correct children if its not the first iteration
                    if iteration_count > 0:
                        for core in current_cores:
                            for i in range(len(core.children)):
                                if len(child_cores) <= 0:
                                    break
                                core.children[i] = child_cores.pop(0)
                                core.children[i].parent = core
                            else:
                                continue
                            break
                    else:
                        # Set i_kernel_activation_matrix inputs, if its the first iteration
                        for core in current_cores:
                            for i in range(len(core.children)):
                                core.children[i] = configurable_slider_input_id
                                configurable_slider_input_id += 1

                    # Identify which port nodes should be empty
                    for i in range(distance):
                        current_cores[-1].children[-(i+1)] = -1

                    # Remove current_cores from unused cores and add them to used bucket
                    if self.used_cores.get(bundle_name) is None:
                        self.used_cores[bundle_name] = []
                    self.used_cores[bundle_name] += current_cores
                    self.unused_cores[bundle_name] = bundle[cores_needed::]
                    if not self.unused_cores[bundle_name]:
                        self.unused_cores.pop(bundle_name)

                    # Add current_cores to output_channel_list
                    self.output_channel_list[oc_id] += current_cores

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

    
    def entity_to_string(self) -> str:
        template_path = os.path.join(self.template_dir, 'routing_cores_entity.vhd')
        template = ""
        with open(template_path) as f:
            template = f.read()

        template = template.replace("%%CORE_COMPILE_LIB%%", str(self.adder_tree_config.compile_lib))
        template = template.replace("%%INPUT_AMOUNT%%", str(self.adder_tree_config.i_dataline_amount))
        template = template.replace("%%MAX_CORE_AMOUNT%%", str(self.adder_tree_config.max_core_amount))
        template = template.replace("%%CORE_MAX_INPUT_LENGTH%%", str(self.adder_tree_config.i_dataline_width))
        template = template.replace("%%CORE_MAX_OUTPUT_LENGTH%%", str(self.adder_tree_config.o_dataline_width))
        template = template.replace("%%MAX_OUTPUT_CHANNELS%%", str(self.max_output_channels))
        template = template.replace("%%MAX_KERNEL_SIZE%%", str(self.max_kernel_size))
        template = template.replace("%%LINE_BUFFER_AMOUNT%%", str(self.line_buffer_amount))

        return template

    
    def architecture_to_string(self):
        template_path = os.path.join(self.template_dir, 'routing_cores_architecture.vhd')
        template = ""
        with open(template_path) as f:
            template = f.read()

        template = template.replace("%%MAX_PIPELINE_STEPS%%", str(self.max_pipeline_steps))
        template = template.replace("%%ROUTE_ARCHITECTURE_NAME%%", str(self.architecture_name))

        C_TAB = 4 * " "
        C_PADDING = 35
        output_string = ""
        final_cores = []
        for i, oc in enumerate(self.output_channel_list):
            output_string += f'\n{C_TAB}-- Output Channel {i} Routing...\n'
            for core_node in oc:
                is_start_node = False
                # Check if final core was found
                if core_node.parent is None:
                    final_cores.append((i, core_node))
                # set children nodes
                for cid, children in enumerate(core_node.children):
                    # child is either start signal or empty
                    if isinstance(children, int):
                        if children < 0 :
                            output_string += f'{f"{C_TAB}o_activation_matrix_line({core_node.in_start_address + cid})".ljust(C_PADDING)} <= (others => \'0\');\n'
                            output_string += f'{f"{C_TAB}o_weight_matrix_line({core_node.in_start_address + cid})".ljust(C_PADDING)} <= (others => \'0\');\n'
                        else:
                            # If one child is a configurable slider output, then all children are configurable slider output (or empty...)
                            is_start_node = True 
                            output_string += f'{f"{C_TAB}o_activation_matrix_line({core_node.in_start_address + cid})".ljust(C_PADDING)} <= s_cs_kernel_matrix({children});\n'
                            output_string += f'{f"{C_TAB}o_weight_matrix_line({core_node.in_start_address + cid})".ljust(C_PADDING)} <= s_wm_weight_matrix({children});\n'
                    else:
                        output_string += f'{f"{C_TAB}o_activation_matrix_line({core_node.in_start_address + cid})".ljust(C_PADDING)} <= s_kc_pixel_line({children.pipeline_steps})({children.out_start_address});\n'
                        output_string += f'{f"{C_TAB}o_weight_matrix_line({core_node.in_start_address + cid})".ljust(C_PADDING)} <= (others => \'0\');\n'
                
                # bias and shamt assignment
                output_string += f'{f"{C_TAB}o_bias_line({core_node.out_start_address})".ljust(C_PADDING)} <= s_wm_bias_line({core_node.out_start_address});\n'
                output_string += f'{f"{C_TAB}o_shamt_line({core_node.out_start_address})".ljust(C_PADDING)} <= s_wm_shamt_line({core_node.out_start_address});\n'
                
                # kernel_en and kernel_complete assignment
                if is_start_node:
                    output_string += f'{f"{C_TAB}o_kernel_en_line({core_node.out_start_address})".ljust(C_PADDING)} <= s_cs_kernel_en;\n'
                    output_string += f'{f"{C_TAB}o_kernel_complete_line({core_node.out_start_address})".ljust(C_PADDING)} <= s_cs_kernel_complete;\n'
                else:
                    # CL from children necessary! All of them should be timed equally -> only take the enable signal of the first child
                    output_string += f'{f"{C_TAB}o_kernel_en_line({core_node.out_start_address})".ljust(C_PADDING)} <= s_kc_valid_line({core_node.children[0].pipeline_steps})({core_node.children[0].out_start_address});\n'
                    output_string += f'{f"{C_TAB}o_kernel_complete_line({core_node.out_start_address})".ljust(C_PADDING)} <= s_kc_comp_line({core_node.children[0].pipeline_steps})({core_node.children[0].out_start_address});\n'

        template = template.replace("%%ROUTE_SIGNAL_OUTPUT%%", output_string)

        # Make final output for cores with no parent
        output_string = ""
        # only take kernel_complete and of fist child
        output_string += f'{C_TAB}o_kernel_complete <= s_kc_comp_line({final_cores[0][1].pipeline_steps})({final_cores[0][1].out_start_address});\n'
        output_string += f'{C_TAB}o_kernel_valid    <= s_kc_valid_line({final_cores[0][1].pipeline_steps})({final_cores[0][1].out_start_address});\n'
        for oc_id, core in final_cores:
            output_string += f'{C_TAB}o_pixel_line({oc_id})   <= s_kc_pixel_line({core.pipeline_steps})({core.out_start_address});\n'


        template = template.replace("%%ROUTE_SIGNAL_FINAL_OUTPUT%%", output_string)

        return template

    def module_to_file(self) -> None:
        template = self.entity_to_string() + self.architecture_to_string()

        with open(os.path.join(self.export_dir, f'routing_cores.vhd'), 'w') as f:
            f.write(template)
