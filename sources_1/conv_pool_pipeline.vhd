library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;
use work.libmemory.all;

entity conv_pool_pipeline is
	generic (
		--! general generics that are necessary
		input_length   : natural              := 8;
		input_width    : natural              := 32;
		input_height   : natural              := 32;
		kernel_size    : natural              := 5;
		pooling_size   : integer range 2 to 2 := 2;
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
		base_addr         : in std_logic_vector(input_amount * total_input_channel ** (1 - init_type) * total_output_channel ** (init_type) - 1 downto 0);
		weights_valid     : out std_logic;
		new_pixel         : out std_logic_vector(output_length - 1 downto 0);
		valid_pixel       : out std_logic;
		comp_complete     : out std_logic
	);
end entity conv_pool_pipeline;

architecture rtl of conv_pool_pipeline is

	-- Value used for scaling in the Conv_Comp_Unit
	constant c_scale_value : std_logic_vector(input_length - 1 downto 0) := read_scale_value(scale_path, input_length, current_scale);

	signal s_weight_matrix : matrix_1d(0 to input_amount - 1)(input_length - 1 downto 0);

	-- Signal for the output of the Conv_Comp_Unit
	signal s_conv_pixel    : std_logic_vector(output_length - 1 downto 0);
	signal s_conv_en       : std_logic;
	signal s_conv_complete : std_logic;

	-- Signal for the output of the Pooling_Slider
	signal s_pool_en       : std_logic;
	signal s_pool_complete : std_logic;
	signal s_pool_matrix   : matrix_1d(0 to pooling_size ** 2 - 1)(output_length - 1 downto 0);

	signal s_flatten_activation_matrix : matrix_1d(0 to input_amount - 1)(input_length - 1 downto 0);

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
			new_pixel         => s_conv_pixel,
			valid_pixel       => s_conv_en,
			comp_complete     => s_conv_complete
		);

	POOL_SLIDER : entity work.pooling_slider
		generic map (
			-- Has to be output length if you want to keep e.g. 24-bits
			vector_length => output_length,
			input_width   => input_width - kernel_size + 1,
			input_height  => input_height - kernel_size + 1,
			pooling_size  => pooling_size
		)
		port map (
			clk          => clk,
			reset        => reset,
			pixel_stream => s_conv_pixel,
			-- if complete signal is set, do not pipeline any more valid data
			valid_pixel              => s_conv_en and not s_conv_complete,
			kernel_complete          => s_pool_complete,
			kernel_en                => s_pool_en,
			kernel_activation_matrix => s_pool_matrix
		);

	MAXPOOL_UNIT : entity work.kernel_computation_unit
		generic map (
			-- Other generics don't need to be mapped because they will not be considered
			pool_or_conv  => 0,
			input_length  => output_length,
			output_length => output_length,
			input_amount  => pooling_size ** 2
		)
		port map (
			clk               => clk,
			reset             => reset,
			activation_matrix => s_pool_matrix,
			weight_matrix     => (others => (others => '0')),
			shamt             => (others => '0'),
			bias              => (others => '0'),
			kernel_en         => s_pool_en,
			kernel_complete   => s_pool_complete,
			new_pixel         => new_pixel,
			valid_pixel       => valid_pixel,
			comp_complete     => comp_complete
		);

end architecture rtl;
