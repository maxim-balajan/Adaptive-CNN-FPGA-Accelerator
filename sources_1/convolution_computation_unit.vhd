library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity convolution_computation_unit is
	generic (
		vector_length : integer := 8;
		kernel_size   : integer := 5
	);
	port (
		clk               : in std_logic;
		reset             : in std_logic;
		activation_matrix : in matrix_2d(0 to kernel_size - 1)(0 to kernel_size - 1)(vector_length - 1 downto 0);
		weight_matrix     : in matrix_2d(0 to kernel_size - 1)(0 to kernel_size - 1)(vector_length - 1 downto 0);
		kernel_en         : in std_logic;
		kernel_complete   : in std_logic;
		new_pixel         : out std_logic_vector(vector_length - 1 downto 0);
		valid_pixel       : out std_logic;
		comp_complete     : out std_logic
	);
end entity convolution_computation_unit;

architecture rtl of convolution_computation_unit is

	-- This constant stores the amount of convolution steps that are needed
	constant c_conv_step_count : integer := integer(ceil(log2(real(kernel_size ** 2))));
	-- This signal is for all pipelined values that are used for the convolution computation
	-- it also contains double the amount of signals because it is easier to write that way and shouldn't result in more HW
	signal s_pipeline_values : matrix_2d(0 to c_conv_step_count)(0 to kernel_size ** 2 - 1)(3 * vector_length - 1 downto 0);
	alias  s_pipeline_end    is s_pipeline_values(s_pipeline_values'high)(s_pipeline_values'low);
	-- This signal contains all multiplications
	signal s_multiplication_line : matrix_1d(0 to kernel_size ** 2 - 1)(3 * vector_length - 1 downto 0);
	-- These are just the pipelined controll signes
	signal s_kernel_en_line       : std_logic_vector(0 to c_conv_step_count);
	signal s_kernel_complete_line : std_logic_vector(0 to c_conv_step_count);

begin

	-- Multiplication line that computes all the multiplications for the convolution

	MULT_GEN_1 : for i in activation_matrix'range generate

		MULT_GEN_2 : for j in activation_matrix(0)'range generate

			-- resize necessary because target signal has to exactly match resulting size of multiplication
			s_multiplication_line(i * kernel_size + j) <= std_logic_vector(resize(signed(activation_matrix(i)(j)), 2 * activation_matrix(i)(j)'length) * signed(weight_matrix(i)(j)));

		end generate MULT_GEN_2;

	end generate MULT_GEN_1;

	-- Generate all convolutions steps that are necessary for the addition of all multiplied values
	-- Basically works like the "Divide by 2"-Algorithm

	CONV_STEP_GEN : for i in 0 to c_conv_step_count - 1 generate

		Conv_step_inst : entity work.convolution_computation_step
			generic map (
				vector_length => 3 * vector_length,
				input_width   => integer(ceil(real(kernel_size ** 2) / real(2 ** i)))
			)
			port map (
				clk                 => clk,
				reset               => reset,
				input_matrix        => s_pipeline_values(i)(0 to integer(ceil(real(kernel_size ** 2) / real(2 ** i))) - 1),
				kernel_en           => s_kernel_en_line(i),
				kernel_complete     => s_kernel_complete_line(i),
				output_matrix       => s_pipeline_values(i + 1)(0 to integer(ceil(real(kernel_size ** 2) / real(2 ** (i + 1)))) - 1),
				kernel_en_del       => s_kernel_en_line(i + 1),
				kernel_complete_del => s_kernel_complete_line(i + 1)
			);

	end generate CONV_STEP_GEN;

	-- Set inputs of pipeline
	s_pipeline_values(s_pipeline_values'low)           <= s_multiplication_line;
	s_kernel_en_line(s_kernel_en_line'low)             <= kernel_en;
	s_kernel_complete_line(s_kernel_complete_line'low) <= kernel_complete;

	-- Set outputs of pipeline
	valid_pixel   <= s_kernel_en_line(s_kernel_en_line'high);
	comp_complete <= s_kernel_complete_line(s_kernel_complete_line'high);
	-- Clips the value and integrates ReLu step
	new_pixel <= (others => '0') when signed(s_pipeline_end) < 0 else
	             std_logic_vector(to_signed(127, new_pixel'length)) when signed(s_pipeline_end) > 127 else
	             s_pipeline_end(vector_length - 1 downto 0);

end architecture rtl;
