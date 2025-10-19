import os
from core_tree import CoreTree
from kernel_cores import KernelCores
from math import sqrt

class TopCNNWrapper():
    def __init__(self, kernel_cores: KernelCores, core_tree: CoreTree):
        self.kernel_cores = kernel_cores
        self.core_tree = core_tree


    def module_to_string(self):
        template_path = os.path.join(self.kernel_cores.template_dir, 'top_level_cnn_wrapper_template.vhd')
        template = ""
        with open(template_path) as f:
            template = f.read()
        
        # Mapping of Kernel Core Wildcards
        template = template.replace("%%CORE_COMPILE_LIB%%", str(self.kernel_cores.config.compile_lib))
        template = template.replace("%%CORE_INPUT_LENGTH%%", str(self.core_tree.input_width))
        template = template.replace("%%CORE_OUTPUT_LENGTH%%", str(self.core_tree.output_width))
        template = template.replace("%%MAX_CORE_AMOUNT%%", str(self.kernel_cores.config.max_core_amount))

        # Mapping of Routing Core Wildcards
        template = template.replace("%%OUTPUT_CHANNEL%%", str(self.core_tree.output_channel))
        template = template.replace("%%INPUT_DATA_BYTE_WIDTH%%", str(self.core_tree.input_data_byte_width))
        template = template.replace("%%DWC_OUTPUT_BYTE_WIDTH%%", str((self.core_tree.input_data_byte_width // self.core_tree.input_channel_per_iteration) * self.core_tree.input_channel_per_iteration))
        template = template.replace("%%ROUTE_INPUT_CHANNEL_PER_ITERATION%%", str(self.core_tree.input_channel_per_iteration))
        template = template.replace("%%MAX_KERNEL_SIZE%%", str(self.core_tree.max_kernel_size))
        template = template.replace("%%KERNEL_SIZE%%", str(int(sqrt(self.core_tree.input_amount))))
        template = template.replace("%%PADDING_SIZE%%", str(self.core_tree.padding))
        template = template.replace("%%CS_PIPELINE_STEPS%%", str(self.core_tree.configurable_routing_ps))
        template = template.replace("%%LINE_BUFFER_AMOUNT%%", str(self.core_tree.line_buffer_amount))


        return template
    
    def module_to_file(self):
        template = self.module_to_string()

        with open(os.path.join(self.core_tree.export_dir, f'top_level_cnn_wrapper.vhd'), 'w') as f:
            f.write(template)

