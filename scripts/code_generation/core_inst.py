from common_utils import safe_read, get_nth_key
import os

C_TAB = " " * 4
C_PADDING = 45

class CoreInst():
    def __init__(self, name: str, core_dict: dict, iteration: int):
        core_architecture_dict = core_dict[get_nth_key(core_dict, iteration)]
        self.entity_name = name
        self.architecture_name = get_nth_key(core_dict, iteration)
        self.amount = safe_read(core_architecture_dict, 'amount', 1)
        self.pool_or_conv = safe_read(core_architecture_dict, 'pool_or_conv', 1)
        self.clip_adder = safe_read(core_architecture_dict, 'enable_clip_adder', 1)
        self.multiplication_line = safe_read(core_architecture_dict, 'enable_multiplication_line', 0)
        self.shift = safe_read(core_architecture_dict, 'enable_shift', 0)
        self.relu = safe_read(core_architecture_dict, 'enable_relu', 1)
        self.i_length = safe_read(core_architecture_dict, 'input_length')
        self.o_length = safe_read(core_architecture_dict, 'output_length')
        self.i_amount = safe_read(core_architecture_dict, 'input_amount')
        self.compile_lib = safe_read(core_architecture_dict, 'compile_lib', "work")

        global_dict = core_dict['global']
        self.max_core_amount = safe_read(global_dict, 'max_core_amount')
        self.max_input_amount = safe_read(global_dict, 'max_input_amount')
        self.max_input_length = safe_read(global_dict, 'max_input_length')
        # only via instantiation_to_string the start_address can be set!
        self.start_address = -1


    def instantiation_to_string(self, am_start: int, wm_start: int, control_start: int, out_start: int) -> str:
        template_path = os.path.join(os.getenv('PRJ_SCRIPTS'), 'code_generation', 'templates', 'core_bundle_inst.vhd')
        template = ""
        with open(template_path) as f:
            template = f.read()

        # am_start and wm_start are currently equal (and will probably always be that way)
        self.start_address = am_start

        template = template.replace('%%CORE_ENTITY_NAME%%', str(self.entity_name))
        template = template.replace('%%CORE_ARCHITECTURE_NAME%%', str(self.architecture_name))
        template = template.replace("%%CORE_COMPILE_LIB%%", str(self.compile_lib))
        template = template.replace("%%CORE_TYPE%%", "Adder" if self.pool_or_conv else "Comparator")
        template = template.replace("%%CORE_AMOUNT%%", str(self.amount))

        activation_matrix_line = '\n'.join([f'{f"{3 * C_TAB}i_activation_matrix_line({i})".ljust(C_PADDING)} => i_activation_matrix_line({am_start + i})({self.i_length - 1} downto 0),' for i in range(self.max_core_amount * self.max_input_amount)])
        template = template.replace("%%CORE_ACTIVATION_MATRIX_LINE%%", activation_matrix_line)

        weight_matrix_line = ""
        if self.pool_or_conv:
            weight_matrix_line = '\n'.join([f'{f"{3 * C_TAB}i_weight_matrix_line({i})".ljust(C_PADDING)} => i_weight_matrix_line({wm_start + i})({self.i_length - 1} downto 0),' for i in range(self.max_core_amount * self.max_input_amount)])
        else:
            weight_matrix_line += f'{f"{3 * C_TAB}i_weight_matrix_line".ljust(C_PADDING)} => (others => (others => \'0\')),'
        template = template.replace("%%CORE_WEIGHT_MATRIX_LINE%%", weight_matrix_line)

        shamt_line = ""
        if self.pool_or_conv and self.shift:
            shamt_line = '\n'.join([f'{f"{3 * C_TAB}i_shamt_line({i})".ljust(C_PADDING)} => i_shamt_line({control_start + i})({self.i_length - 1} downto 0),' for i in range(self.max_core_amount)])
        else:
            shamt_line += f'{f"{3 * C_TAB}i_shamt_line".ljust(C_PADDING)} => (others => (others => \'0\')),'
        template = template.replace("%%CORE_SHAMT_LINE%%", shamt_line)

        bias_line = ""
        bias_line += f'{f"{3 * C_TAB}i_bias_line".ljust(C_PADDING)} => (others => (others => \'0\')),'
        template = template.replace("%%CORE_BIAS_LINE%%", bias_line)

        kernel_en_line = '\n'.join([f'{f"{3 * C_TAB}i_kernel_en_line({i})".ljust(C_PADDING)} => i_kernel_en_line({control_start + i}),' for i in range(self.max_core_amount)])
        kernel_complete_line = '\n'.join([f'{f"{3 * C_TAB}i_kernel_complete_line({i})".ljust(C_PADDING)} => i_kernel_complete_line({control_start + i}),' for i in range(self.max_core_amount)])
        template = template.replace("%%CORE_KERNEL_EN_LINE%%", kernel_en_line)
        template = template.replace("%%CORE_KERNEL_COMPLETE_LINE%%", kernel_complete_line)

        pixel_line = '\n'.join([f'{f"{3 * C_TAB}o_pixel_line({i})".ljust(C_PADDING)} => o_pixel_line({out_start + i})({self.o_length - 1} downto 0),' for i in range(self.max_core_amount)])
        valid_pixel_line = '\n'.join([f'{f"{3 * C_TAB}o_valid_pixel_line({i})".ljust(C_PADDING)} => o_valid_pixel_line({out_start + i}),' for i in range(self.max_core_amount)])
        comp_complete_pixel_line = '\n'.join([f'{f"{3 * C_TAB}o_comp_complete_line({i})".ljust(C_PADDING)} => o_comp_complete_line({out_start + i}),' for i in range(self.max_core_amount)])
        template = template.replace("%%CORE_PIXEL_LINE%%", pixel_line)
        template = template.replace("%%CORE_VALID_PIXEL_LINE%%", valid_pixel_line)
        template = template.replace("%%CORE_COMP_COMPLETE_LINE%%", comp_complete_pixel_line[:-1:])

        return template
             
    def entity_to_string(self) -> str:
        template_path = os.path.join(os.getenv('PRJ_SCRIPTS'), 'code_generation', 'templates', 'core_bundle_entity.vhd')
        template = ""
        with open(template_path) as f:
            template = f.read()

        template = template.replace("%%CORE_COMPILE_LIB%%", str(self.compile_lib))
        template = template.replace("%%CORE_ENTITY_NAME%%", str(self.entity_name))
        template = template.replace("%%CORE_MAX_AMOUNT%%", str(self.max_core_amount))
        template = template.replace("%%CORE_MAX_INPUT_AMOUNT%%", str(self.max_input_amount))
        template = template.replace("%%CORE_MAX_INPUT_LENGTH%%", str(self.max_input_length))

        return template


    def architecture_to_string(self) -> str:
        template_path = os.path.join(os.getenv('PRJ_SCRIPTS'), 'code_generation', 'templates', 'core_bundle_architecture.vhd')
        template = ""
        with open(template_path) as f:
            template = f.read()

        template = template.replace("%%CORE_COMPILE_LIB%%", str(self.compile_lib))
        template = template.replace("%%CORE_ENTITY_NAME%%", str(self.entity_name))
        template = template.replace("%%CORE_ARCHITECTURE_NAME%%", str(self.architecture_name))
        template = template.replace("%%CORE_AMOUNT%%", str(self.amount))
        template = template.replace("%%CORE_TYPE%%", str(self.pool_or_conv))
        template = template.replace("%%CORE_CLIP_ADDER%%", str(self.clip_adder))
        template = template.replace("%%CORE_MULTIPLICATION_LINE%%", str(self.multiplication_line))
        template = template.replace("%%CORE_SHIFT%%", str(self.shift))
        template = template.replace("%%CORE_BIAS%%", "0")
        template = template.replace("%%CORE_RELU%%", str(self.relu))
        template = template.replace("%%CORE_INPUT_AMOUNT%%", str(self.i_amount))
        template = template.replace("%%CORE_INPUT_LENGTH%%", str(self.i_length))
        template = template.replace("%%CORE_OUTPUT_LENGTH%%", str(self.o_length))

        activation_matrix_line = '\n'.join([f'{f"{4 * C_TAB}activation_matrix({i})".ljust(C_PADDING)} => i_activation_matrix_line(i + {i})({self.i_length - 1} downto 0),' for i in range(self.i_amount)])
        template = template.replace("%%CORE_ACTIVATION_MATRIX%%", activation_matrix_line)

        weight_matrix_line = ""
        if self.pool_or_conv:
            weight_matrix_line = '\n'.join([f'{f"{4 * C_TAB}weight_matrix({i})".ljust(C_PADDING)} => i_weight_matrix_line(i + {i})({self.i_length - 1} downto 0),' for i in range(self.i_amount)])
        else:
            weight_matrix_line += f'{f"{4 * C_TAB}weight_matrix".ljust(C_PADDING)} => (others => (others => \'0\')),'
        template = template.replace("%%CORE_WEIGHT_MATRIX%%", weight_matrix_line)

        return template     
    

    def module_to_file(self) -> None:
        template = self.entity_to_string() + self.architecture_to_string()

        with open(os.path.join(os.getenv('PRJ_SCRIPTS'), 'code_generation', 'export', f'{self.entity_name}.vhd'), 'w') as f:
            f.write(template)