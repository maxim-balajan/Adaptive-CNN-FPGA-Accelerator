library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

-- This unit computes all output channels for a given input channel;
-- If you want to parallelize an entire convolution step you need to instantiate this unit #total_input_channel times

entity conv_par is
	generic (
		--! general generics that are necessary
		vector_length     : natural              := 8;
		input_width       : natural              := 32;
		input_height      : natural              := 32;
		kernel_size       : natural              := 5;
		pooling_size      : integer range 2 to 2 := 2;
		enable_clip_adder : integer range 0 to 1 := 1;

		--! generics used for initializing BRAM Weight Memory
		total_input_channel  : natural := 1;
		total_output_channel : natural := 6;
		weight_path          : string  := "../data/layer_weight_0.data";
		current_scale        : natural := 1;
		scale_path           : string  := "../data/scale_values.data"
	);
	port (
		clk               : in std_logic;
		reset             : in std_logic;
		pixel_stream      : in std_logic_vector(vector_length - 1 downto 0);
		valid_pixel       : in std_logic;
		new_pixels_stream : out matrix_1d(0 to total_output_channel - 1)(vector_length - 1 downto 0);
		new_valid_pixels  : out std_logic_vector(0 to total_output_channel - 1)
	);
end entity conv_par;

architecture rtl of conv_par is

	-- Output of the Convolution Slider
	signal s_kernel_en         : std_logic;
	signal s_kernel_complete   : std_logic;
	signal s_activation_matrix : matrix_2d(0 to kernel_size - 1)(0 to kernel_size - 1)(vector_length - 1 downto 0);

	-- Output of the Pipelines
	signal s_new_valid_pixels    : std_logic_vector(0 to total_output_channel - 1);
	signal s_new_pixels_complete : std_logic_vector(0 to total_output_channel - 1);

begin

	CONV_SLIDER : entity work.convolution_slider
		generic map (
			vector_length => vector_length,
			input_width   => input_width,
			input_height  => input_height,
			kernel_size   => kernel_size
		)
		port map (
			clk                      => clk,
			reset                    => reset,
			pixel_stream             => pixel_stream,
			valid_pixel              => valid_pixel,
			kernel_complete          => s_kernel_complete,
			kernel_en                => s_kernel_en,
			kernel_activation_matrix => s_activation_matrix
		);

	PIPELINE_GEN : for i in 0 to total_output_channel - 1 generate

		PIPELINE_INST : entity work.conv_pool_pipeline
			generic map (
				input_length         => vector_length,
				input_width          => input_width,
				input_height         => input_height,
				kernel_size          => kernel_size,
				pooling_size         => pooling_size,
				enable_weights       => 1,
				total_input_channel  => total_input_channel,
				total_output_channel => total_output_channel,
				current_channel      => i,
				init_type            => 0,
				weight_path          => weight_path,
				current_scale        => current_scale,
				scale_path           => scale_path,
				enable_clip_adder    => enable_clip_adder,
				-- Maybe make the following three generics to generics of this unit?
				-- For now keep it as is
				enable_multiplication_line => 1,
				enable_shift               => 1,
				enable_relu                => 1,
				output_length              => vector_length
			)
			port map (
				clk               => clk,
				reset             => reset,
				activation_matrix => s_activation_matrix,
				kernel_en         => s_kernel_en,
				kernel_complete   => s_kernel_complete,
				base_addr         => (others => '0'),
				-- Weights valid is not necessary for this unit
				-- but could be usefull in sequential comp.
				weights_valid => open,
				new_pixel     => new_pixels_stream(i),
				valid_pixel   => s_new_valid_pixels(i),
				comp_complete => s_new_pixels_complete(i)
			);

		-- Map control signals to output port
		new_valid_pixels(i) <= s_new_valid_pixels(i) and not s_new_pixels_complete(i);
	end generate PIPELINE_GEN;

end architecture rtl;
