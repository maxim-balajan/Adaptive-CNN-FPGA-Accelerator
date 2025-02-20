library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libutil.all;
use work.libmatrix.all;

entity lenet_accel is
	generic (
		--! general generics that are necessary
		vector_length               : natural              := 8;
		accumulator_length          : natural              := 24;
		input_width                 : natural              := 32;
		input_height                : natural              := 32;
		kernel_size                 : natural              := 5;
		pooling_size                : integer range 2 to 2 := 2;
		enable_clip_adder           : integer range 0 to 1 := 1;
		total_input_channel_conv_1  : natural              := 1;
		total_input_channel_conv_2  : natural              := 6;
		total_output_channel_conv_2 : natural              := 16;
		scale_path                  : string               := "../data/scale_values.data";
		conv_shift_ids              : int_list             := (1, 2);
		dense_shift_ids             : int_list             := (3, 4, 5);
		dense_weight_widths         : int_list             := (400, 120, 84);
		dense_weight_heights        : int_list             := (120, 84, 10);
		conv_weight_paths           : string_list          := ("../data/layer_weight_0.data",
                                                               "../data/layer_weight_1.data");
		dense_weight_paths          : string_list          := ("../data/layer_weight_2.data",
										                       "../data/layer_weight_3.data",
										                       "../data/layer_weight_4.data")
	);
	port (
		clk           : in std_logic;
		reset         : in std_logic;
		pixel_stream  : in std_logic_vector(vector_length - 1 downto 0);
		valid_pixel   : in std_logic;
		image_label   : out std_logic_vector(integer(ceil(log2(real(dense_weight_heights(dense_weight_heights'high))))) - 1 downto 0);
		comp_complete : out std_logic
	);
end entity lenet_accel;

architecture rtl of lenet_accel is

	-- Signals between Convolution and Dense-Layer
	signal s_conv_to_dense_stream   : std_logic_vector(vector_length - 1 downto 0);
	signal s_conv_to_dense_valid    : std_logic;
	signal s_conv_to_dense_complete : std_logic;

	-- Signals between Dense-Layer and Softmax-Unit
	signal s_dense_to_softmax_stream : matrix_1d(0 to dense_weight_heights(dense_weight_heights'high) - 1)(vector_length - 1 downto 0);
	signal s_dense_complete          : std_logic;

begin

	CONV_COMB_INST : entity work.conv_combined
		generic map (
			vector_length               => vector_length,
			accumulator_length          => accumulator_length,
			input_width                 => input_width,
			input_height                => input_height,
			kernel_size                 => kernel_size,
			pooling_size                => pooling_size,
			enable_clip_adder           => enable_clip_adder,
			total_input_channel_conv_1  => total_input_channel_conv_1,
			total_input_channel_conv_2  => total_input_channel_conv_2,
			total_output_channel_conv_2 => total_output_channel_conv_2,
			weight_path_conv_1          => conv_weight_paths(0),
			weight_path_conv_2          => conv_weight_paths(1),
			scales                      => conv_shift_ids,
			scale_path                  => scale_path
		)
		port map (
			clk                => clk,
			reset              => reset,
			pixel_stream       => pixel_stream,
			valid_pixel        => valid_pixel,
			new_pixel_stream   => s_conv_to_dense_stream,
			new_valid_pixel    => s_conv_to_dense_valid,
			new_pixel_complete => s_conv_to_dense_complete
		);

	DENSE_LAYER_COMB_INST : entity work.dense_layer_combined
		generic map (
			vector_length     => vector_length,
			max_weight_width  => dense_weight_widths(dense_weight_widths'low),
			max_weight_height => dense_weight_heights(dense_weight_heights'low),
			shift_path        => scale_path,
			shift_ids         => dense_shift_ids,
			weight_widths     => dense_weight_widths,
			weight_heights    => dense_weight_heights,
			weight_paths      => dense_weight_paths
		)
		port map (
			clk           => clk,
			reset         => reset,
			en            => s_conv_to_dense_valid and not s_conv_to_dense_complete,
			input         => s_conv_to_dense_stream,
			results       => s_dense_to_softmax_stream,
			comp_complete => s_dense_complete
		);

	SOFTMAX_INST : entity work.softmax_unit
		generic map (
			input_length => vector_length,
			input_amount => dense_weight_heights(dense_weight_heights'high)
		)
		port map (
			clk           => clk,
			reset         => reset,
			en            => s_dense_complete,
			input         => s_dense_to_softmax_stream,
			max_index     => image_label,
			comp_complete => comp_complete
		);

end architecture rtl;
