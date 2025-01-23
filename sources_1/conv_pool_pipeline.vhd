library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity conv_pool_pipeline is
	generic (
		--! general generics that are necessary
		vector_length : natural              := 8;
		input_width   : natural              := 32;
		input_height  : natural              := 32;
		kernel_size   : natural              := 5;
		pooling_size  : integer range 2 to 2 := 2;

		--! generics used for initializing BRAM Weight Memory
		total_input_channel  : natural              := 1;
		total_output_channel : natural              := 1;
		current_channel      : natural              := 1;
		init_type            : integer range 0 to 1 := 0;
		weight_path          : string               := "../data/layer_weight_0.data";
		current_scale        : natural              := 1;
		scale_path           : string               := "../data/scale_values.data";

		--! generics used for convolution_comp_unit
		enable_multiplication_line : integer range 0 to 1                                                   := 1;
		enable_shift               : integer range 0 to 1                                                   := 1;
		enable_relu                : integer range 0 to 1                                                   := 1;
		output_length              : integer range 0 to ((3 ** enable_multiplication_line)) * vector_length := 8
	);
	port (
		clk               : in std_logic;
		reset             : in std_logic;
		activation_matrix : in matrix_2d(0 to kernel_size - 1)(0 to kernel_size - 1)(vector_length - 1 downto 0);
		kernel_en         : in std_logic;
		kernel_complete   : in std_logic;
		new_pixel         : out std_logic_vector(output_length - 1 downto 0);
		valid_pixel       : out std_logic;
		comp_complete     : out std_logic
	);
end entity conv_pool_pipeline;

architecture rtl of conv_pool_pipeline is

begin

	-- TODO

end architecture;