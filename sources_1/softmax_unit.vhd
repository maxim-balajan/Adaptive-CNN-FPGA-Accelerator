library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity softmax_unit is
	generic (
		input_length : natural := 8;
		input_amount : natural := 10
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		en    : in std_logic;
		input : in matrix_1d(0 to input_amount - 1)(input_length - 1 downto 0);

		max_index     : out std_logic_vector(integer(ceil(log2(real(input_amount)))) - 1 downto 0);
		max_value     : out std_logic_vector(input_length - 1 downto 0);
		comp_complete : out std_logic
	);
end entity softmax_unit;

architecture rtl of softmax_unit is

	-- This constant stores the amount of convolution steps that are needed
	-- constant c_conv_step_count : integer := integer(ceil(log2(real(input_amount))));

	-- Amount of inputs that are unused (and therefore set to 0)
	-- constant unused_inputs : integer := integer(c_conv_step_count ** 2 - input_amount);

	-- This signal is for all pipelined values that are used for the convolution computation
	-- it also contains double the amount of signals because it is easier to write that way and shouldn't result in more HW
	-- signal s_pipeline_values : matrix_2d(0 to c_conv_step_count)(0 to input_amount - 1)(input_length - 1 downto 0);

begin

	-- Generate all layers for softmax computation
	-- Basically works like the "Divide by 2"-Algorithm

	-- KERNEL_STEP_GEN : for i in 0 to c_conv_step_count - 1 generate

	-- 	KERNEL_STEP_INST : entity work.softmax_layer
	-- 		generic map (
	-- 			vector_length => input_length,
	-- 			input_width   => integer(ceil(real(input_amount) / real(2 ** i)))
	-- 		)
	-- 		port map (
	-- 			clk                 => clk,
	-- 			reset               => reset,
	-- 			input_matrix        => s_pipeline_values(i)(0 to integer(ceil(real(input_amount) / real(2 ** i))) - 1),
	-- 			kernel_en           => s_kernel_en_line(i),
	-- 			kernel_complete     => s_kernel_complete_line(i),
	-- 			output_matrix       => s_pipeline_values(i + 1)(0 to integer(ceil(real(input_amount) / real(2 ** (i + 1)))) - 1),
	-- 			kernel_en_del       => s_kernel_en_line(i + 1),
	-- 			kernel_complete_del => s_kernel_complete_line(i + 1)
	-- 		);

	-- end generate KERNEL_STEP_GEN;

end architecture rtl;
