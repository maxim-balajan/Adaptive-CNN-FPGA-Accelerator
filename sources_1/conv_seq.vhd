library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

-- This unit computes all output channels for a given input channel;
-- If you want to parallelize an entire convolution step you need to instantiate this unit #total_input_channel times

entity conv_seq is
	generic (
		--! general generics that are necessary
		vector_length      : natural              := 8;
		accumulator_length : natural              := 24;
		input_width        : natural              := 14;
		input_height       : natural              := 14;
		kernel_size        : natural              := 5;
		pooling_size       : integer range 2 to 2 := 2;
		enable_clip_adder  : integer range 0 to 1 := 1;

		--! generics used for initializing BRAM Weight Memory
		total_input_channel  : natural := 6;
		total_output_channel : natural := 16;
		weight_path          : string  := "../data/layer_weight_1.data";
		current_scale        : natural := 1;
		scale_path           : string  := "../data/scale_values.data"
	);
	port (
		clk                      : in std_logic;
		reset                    : in std_logic;
		pixel_stream             : in matrix_1d(0 to total_input_channel - 1)(vector_length - 1 downto 0);
		valid_pixel              : in std_logic;
		new_pixels_stream        : out std_logic_vector(vector_length - 1 downto 0);
		new_valid_pixel          : out std_logic;
		new_pixel_complete       : out std_logic;
		new_pixel_output_channel : out std_logic_vector(integer(ceil(log2(real(total_output_channel)))) - 1 downto 0)
	);
end entity conv_seq;

architecture rtl of conv_seq is

	-- control signals
	signal s_channel_comp_complete  : std_logic;
	signal s_new_pixel_complete     : std_logic;
	signal s_current_output_channel : unsigned(integer(ceil(log2(real(total_output_channel)))) - 1 downto 0);
	signal s_channel_reset          : std_logic;

	-- fifo control signals
	signal s_streaming_fifo_rd_en     : std_logic;
	signal s_streaming_fifo_last_read : std_logic_vector(0 to total_input_channel - 1);

	-- fifo -> conv slider
	signal s_fifo_conv_pixel_stream : matrix_1d(0 to total_input_channel - 1)(vector_length - 1 downto 0);
	signal s_fifo_conv_pixel_valid  : std_logic_vector(0 to total_input_channel - 1);

	-- conv slider -> conv pipeline
	signal s_conv_slider_conv_pipeline_kernel_complete          : std_logic_vector(0 to total_input_channel - 1);
	signal s_conv_slider_conv_pipeline_kernel_en                : std_logic_vector(0 to total_input_channel - 1);
	signal s_conv_slider_conv_pipeline_kernel_activation_matrix : matrix_2d(0 to total_input_channel - 1)(0 to kernel_size ** 2 - 1)(vector_length - 1 downto 0);

	-- conv pipeline -> max pool pipeline
	signal s_conv_pipeline_pool_pipeline_kernel_complete          : std_logic_vector(0 to total_input_channel - 1);
	signal s_conv_pipeline_pool_pipeline_kernel_en                : std_logic_vector(0 to total_input_channel - 1);
	signal s_conv_pipeline_pool_pipeline_kernel_activation_matrix : matrix_1d(0 to total_input_channel - 1)(accumulator_length - 1 downto 0);

begin

	new_pixel_complete       <= s_new_pixel_complete;
	new_pixel_output_channel <= std_logic_vector(s_current_output_channel);

	process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_current_output_channel <= (others => '0');
				s_streaming_fifo_rd_en   <= '0';
				s_new_pixel_complete     <= '0';
				s_channel_reset          <= '1';
			else

				-- If Channel is finished and no reset is set, make a channel reset or finish computation
				if s_channel_comp_complete ?= '1' and s_channel_reset ?= '0' then
					if s_current_output_channel < total_output_channel - 1 then
						s_current_output_channel <= s_current_output_channel + 1;
						s_channel_reset          <= '1';
					else
						s_new_pixel_complete <= '1';
					end if;

					-- don't read during reset (but this could also be omitted)
					s_streaming_fifo_rd_en <= '0';
				end if;

				-- Always try to read from fifo, if reads are illegal, they are blocked by fifo itself
				if s_channel_comp_complete ?= '0' and s_channel_reset ?= '1' then
					s_channel_reset <= '0';
					s_streaming_fifo_rd_en <= '1';
				end if;
			end if;
		end if;

	end process;

	PIPELINE_GEN : for i in 0 to total_input_channel - 1 generate

		STREAMING_FIFO_INST : entity work.bram_streaming_fifo
			generic map (
				vector_length => vector_length,
				depth         => input_width * input_height
			)
			port map (
				clk        => clk,
				reset      => reset,
				read_reset => s_channel_reset,
				wr_en      => valid_pixel,
				rd_en      => s_streaming_fifo_rd_en,
				full       => open,
				empty      => open,
				dout_valid => s_fifo_conv_pixel_valid(i),
				din        => pixel_stream(i),
				dout       => s_fifo_conv_pixel_stream(i)

			);

		CONV_SLIDER : entity work.convolution_slider
			generic map (
				vector_length => vector_length,
				input_width   => input_width,
				input_height  => input_height,
				kernel_size   => kernel_size
			)
			port map (
				clk                      => clk,
				reset                    => s_channel_reset,
				pixel_stream             => s_fifo_conv_pixel_stream(i),
				valid_pixel              => s_fifo_conv_pixel_valid(i),
				kernel_complete          => s_conv_slider_conv_pipeline_kernel_complete(i),
				kernel_en                => s_conv_slider_conv_pipeline_kernel_en(i),
				kernel_activation_matrix => s_conv_slider_conv_pipeline_kernel_activation_matrix(i)
			);

		CONV_PIPELINE_INST : entity work.conv_pipeline
			generic map (
				input_amount         => kernel_size ** 2,
				input_length         => vector_length,
				input_width          => input_width - (kernel_size - 1),
				input_height         => input_height - (kernel_size - 1),
				kernel_size          => kernel_size,
				enable_weights       => 1,
				total_input_channel  => total_input_channel,
				total_output_channel => total_output_channel,
				-- important: this has to start from 1
				current_channel => i + 1,
				init_type       => 1,
				weight_path     => weight_path,

				-- not used
				current_scale => current_scale,
				scale_path    => scale_path,

				enable_clip_adder          => 1,
				enable_multiplication_line => 1,
				enable_shift               => 0,
				enable_relu                => 0,
				output_length              => accumulator_length
			)
			port map (
				clk               => clk,
				reset             => s_channel_reset,
				activation_matrix => s_conv_slider_conv_pipeline_kernel_activation_matrix(i),
				kernel_en         => s_conv_slider_conv_pipeline_kernel_en(i),
				kernel_complete   => s_conv_slider_conv_pipeline_kernel_complete(i),
				base_addr         => std_logic_vector(to_unsigned(kernel_size ** 2 * to_integer(s_current_output_channel), kernel_size ** 2 * total_output_channel)),
				weights_valid     => open,
				new_pixel         => s_conv_pipeline_pool_pipeline_kernel_activation_matrix(i),
				valid_pixel       => s_conv_pipeline_pool_pipeline_kernel_en(i),
				comp_complete     => s_conv_pipeline_pool_pipeline_kernel_complete(i)
			);

	end generate PIPELINE_GEN;

	PIPELINE_INST : entity work.conv_pool_pipeline
		generic map (
			input_length               => accumulator_length,
			input_amount               => total_input_channel,
			input_width                => input_width - (kernel_size - 1),
			input_height               => input_height - (kernel_size - 1),
			kernel_size                => 1,
			pooling_size               => pooling_size,
			enable_weights             => 0,
			total_input_channel        => total_input_channel,
			total_output_channel       => 1,
			current_channel            => 1,
			init_type                  => 0,
			weight_path                => "",
			current_scale              => current_scale,
			scale_path                 => scale_path,
			scale_length               => vector_length,
			enable_clip_adder          => enable_clip_adder,
			enable_multiplication_line => 0,
			enable_shift               => 1,
			enable_relu                => 1,
			output_length              => vector_length
		)
		port map (
			clk               => clk,
			reset             => s_channel_reset,
			activation_matrix => s_conv_pipeline_pool_pipeline_kernel_activation_matrix,
			kernel_en         => or s_conv_pipeline_pool_pipeline_kernel_en,
			kernel_complete   => or s_conv_pipeline_pool_pipeline_kernel_complete,
			base_addr         => (others => '0'),
			weights_valid     => open,
			new_pixel         => new_pixels_stream,
			valid_pixel       => new_valid_pixel,
			comp_complete     => s_channel_comp_complete
		);

end architecture rtl;
