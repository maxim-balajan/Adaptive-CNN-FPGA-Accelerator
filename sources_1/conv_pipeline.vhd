library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;
use work.libmemory.all;

entity conv_pipeline is
	generic (
		--! general generics that are necessary
		input_length : natural              := 8;
		input_width  : natural              := 32;
		input_height : natural              := 32;
		kernel_size  : natural              := 5;

        --! this value indicates how many values are streamed into the pipeline. If enable_weights = 1 this should probably be kernel_size**2
		--! otherwise it could also be a totally different value (e.g. 6)
		input_amount   : natural              := 25;
		enable_weights : integer range 0 to 1 := 1;

		--! generics used for initializing BRAM Weight Memory
		total_input_channel  : natural              := 1;
		total_output_channel : natural              := 1;
		current_channel      : natural              := 1;
		init_type            : integer range 0 to 1 := 0;
		weight_path          : string               := "../data/layer_weight_0.data";
		current_scale        : natural              := 1;
		scale_path           : string               := "../data/scale_values.data";
		scale_length         : natural              := input_length;

		--! generics used for convolution_comp_unit
		enable_clip_adder          : integer range 0 to 1                                                  := 1;
		enable_multiplication_line : integer range 0 to 1                                                  := 1;
		enable_shift               : integer range 0 to 1                                                  := 1;
		enable_relu                : integer range 0 to 1                                                  := 1;
		output_length              : integer range 0 to ((3 ** enable_multiplication_line)) * input_length := 8
	);
	port (
		clk               : in std_logic;
		reset             : in std_logic;
		activation_matrix : in matrix_1d(0 to input_amount - 1)(input_length - 1 downto 0);
		kernel_en         : in std_logic;
		kernel_complete   : in std_logic;
		base_addr         : in std_logic_vector(integer(ceil(log2(real(input_amount * total_input_channel ** (1 - init_type) * total_output_channel ** (init_type))))) - 1 downto 0);
		weights_valid     : out std_logic;
		new_pixel         : out std_logic_vector(output_length - 1 downto 0);
		valid_pixel       : out std_logic;
		comp_complete     : out std_logic
	);
end entity conv_pipeline;

architecture rtl of conv_pipeline is

	-- Value used for scaling in the Conv_Comp_Unit
	constant c_scale_value : std_logic_vector(input_length - 1 downto 0) := read_scale_value(scale_path, input_length, scale_length, current_scale);

	signal s_weight_matrix : matrix_1d(0 to input_amount - 1)(input_length - 1 downto 0);

begin

	-- For second convolution weights should be disabled because there wont be a multiplication line for the combining pipeline

	WEIGHT_GEN : if enable_weights = 1 generate

		WEIGHT_MEM : entity work.conv_weight_memory
			generic map (
				vector_length        => input_length,
				input_amount         => input_amount,
				total_input_channel  => total_input_channel,
				total_output_channel => total_output_channel,
				current_channel      => current_channel,
				init_type            => init_type,
				data_path            => weight_path
			)
			port map (
				clk           => clk,
				reset         => reset,
				base_addr     => base_addr,
				mem_valid     => weights_valid,
				weight_matrix => s_weight_matrix
			);

	else generate
		weights_valid   <= '0';
		s_weight_matrix <= (others => (others => '0'));
	end generate WEIGHT_GEN;

	CONV_COMP_UNIT : entity work.kernel_computation_unit
		generic map (
			pool_or_conv               => 1,
			enable_clip_adder          => enable_clip_adder,
			enable_multiplication_line => enable_multiplication_line,
			enable_shift               => enable_shift,
			-- Bias is always disabled for us
			enable_bias   => 0,
			enable_relu   => enable_relu,
			input_length  => input_length,
			output_length => output_length,
			input_amount  => input_amount
		)
		port map (
			clk               => clk,
			reset             => reset,
			activation_matrix => activation_matrix,
			weight_matrix     => s_weight_matrix,
			shamt             => c_scale_value,
			bias              => (others => '0'),
			kernel_en         => kernel_en,
			kernel_complete   => kernel_complete,
			new_pixel         => new_pixel,
			valid_pixel       => valid_pixel,
			comp_complete     => comp_complete
		);


end architecture rtl;
