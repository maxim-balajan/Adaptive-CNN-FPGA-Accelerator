library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libutil.all;
use work.libmatrix.all;

entity conv_combined is
	generic (
		--! general generics that are necessary
		vector_length      : natural              := 8;
		accumulator_length : natural              := 24;
		input_width        : natural              := 32;
		input_height       : natural              := 32;
		kernel_size        : natural              := 5;
		pooling_size       : integer range 2 to 2 := 2;
		enable_clip_adder  : integer range 0 to 1 := 1;

		--! generics used for initializing BRAM Weight Memory
		total_input_channel_conv_1  : natural  := 1;
		total_input_channel_conv_2  : natural  := 6;
		total_output_channel_conv_2 : natural  := 16;
		weight_path_conv_1          : string   := "../data/layer_weight_0.data";
		weight_path_conv_2          : string   := "../data/layer_weight_1.data";
		scales                      : int_list := (1, 2);
		scale_path                  : string   := "../data/scale_values.data"
	);
	port (
		clk                : in std_logic;
		reset              : in std_logic;
		pixel_stream       : in std_logic_vector(vector_length - 1 downto 0);
		valid_pixel        : in std_logic;
		new_pixel_stream   : out std_logic_vector(vector_length - 1 downto 0);
		new_valid_pixel    : out std_logic;
		new_pixel_complete : out std_logic
	);
end entity conv_combined;

architecture rtl of conv_combined is

	signal s_intermediate_pixel_stream   : matrix_1d(0 to total_input_channel_conv_2 - 1)(vector_length - 1 downto 0);
	signal s_intermediate_valid_pixel    : std_logic;
	signal s_intermediate_pixel_complete : std_logic;

begin

	CONV_PAR_INST : entity work.conv_par
		generic map (
			vector_length        => vector_length,
			input_width          => input_width,
			input_height         => input_height,
			kernel_size          => kernel_size,
			pooling_size         => pooling_size,
			enable_clip_adder    => enable_clip_adder,
			total_input_channel  => total_input_channel_conv_1,
			total_output_channel => total_input_channel_conv_2,
			weight_path          => weight_path_conv_1,
			current_scale        => scales(0),
			scale_path           => scale_path
		)
		port map (
			clk                => clk,
			reset              => reset,
			pixel_stream       => pixel_stream,
			valid_pixel        => valid_pixel,
			new_pixels_stream  => s_intermediate_pixel_stream,
			new_valid_pixel    => s_intermediate_valid_pixel,
			new_pixel_complete => s_intermediate_pixel_complete
		);

	CONV_SEQ_INST : entity work.conv_seq
		generic map (
			vector_length        => vector_length,
			accumulator_length   => accumulator_length,
			input_width          => (input_width - kernel_size + 1) / 2,
			input_height         => (input_height - kernel_size + 1) / 2,
			kernel_size          => kernel_size,
			pooling_size         => pooling_size,
			enable_clip_adder    => enable_clip_adder,
			total_input_channel  => total_input_channel_conv_2,
			total_output_channel => total_output_channel_conv_2,
			weight_path          => weight_path_conv_2,
			current_scale        => scales(1),
			scale_path           => scale_path
		)
		port map (
			clk                      => clk,
			reset                    => reset,
			pixel_stream             => s_intermediate_pixel_stream,
			valid_pixel              => s_intermediate_valid_pixel and not s_intermediate_pixel_complete,
			new_pixels_stream        => new_pixel_stream,
			new_valid_pixel          => new_valid_pixel,
			new_pixel_complete       => new_pixel_complete,
			new_pixel_output_channel => open
		);

end architecture rtl;
