import os
from core_tree import CoreTree
from kernel_cores import KernelCores

class RoutedKernelCores():
    def __init__(self, kernel_cores: KernelCores, core_tree: CoreTree):
        self.kernel_cores = kernel_cores
        self.core_tree = core_tree


    def module_to_string(self):
        template_path = os.path.join(self.kernel_cores.template_dir, 'routed_kernel_cores_template.vhd')
        template = ""
        with open(template_path) as f:
            template = f.read()
        
        # Mapping of Kernel Core Wildcards
        template = template.replace("%%CORE_COMPILE_LIB%%", str(self.kernel_cores.config.compile_lib))
        template = template.replace("%%INPUT_AMOUNT%%", str(self.kernel_cores.config.i_dataline_amount))
        template = template.replace("%%CORE_MAX_INPUT_LENGTH%%", str(self.kernel_cores.config.i_dataline_width))
        template = template.replace("%%CORE_INPUT_LENGTH%%", str(self.core_tree.input_width))
        template = template.replace("%%CORE_MAX_OUTPUT_LENGTH%%", str(self.kernel_cores.config.o_dataline_width))
        template = template.replace("%%CORE_OUTPUT_LENGTH%%", str(self.core_tree.output_width))
        template = template.replace("%%MAX_CORE_AMOUNT%%", str(self.kernel_cores.config.max_core_amount))

        # Mapping of Routing Core Wildcards
        template = template.replace("%%ROUTE_ARCHITECTURE_NAME%%", str(self.core_tree.architecture_name))
        template = template.replace("%%MAX_OUTPUT_CHANNELS%%", str(self.core_tree.max_output_channels))
        template = template.replace("%%MAX_KERNEL_SIZE%%", str(self.core_tree.max_kernel_size))
        template = template.replace("%%LINE_BUFFER_AMOUNT%%", str(self.core_tree.line_buffer_amount))


        return template
    
    def module_to_file(self):
        template = self.module_to_string()

        with open(os.path.join(self.core_tree.export_dir, f'routed_kernel_cores.vhd'), 'w') as f:
            f.write(template)

