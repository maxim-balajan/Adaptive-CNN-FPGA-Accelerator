library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity configurable_slider is
	generic (
		vector_length        : natural := 8;
		G_IMG_MAX_LENGTH     : natural := 55;
		G_KERNEL_SIZE        : natural := 5;
		G_MAX_KERNEL_SIZE    : natural := 12;
		G_LINE_BUFFER_AMOUNT : natural := 12 * 3 * 5;
		G_PIPELINE_STEPS     : natural := 2
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		--
		valid_pixel_streams : in std_logic;
		pixel_streams       : in matrix_1d(0 to G_LINE_BUFFER_AMOUNT - 1)(vector_length - 1 downto 0);
		--
		input_image_length  : in std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
		output_image_length : in std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
		-- normally padding size would not be necessary, but it enables skipping a lot of initialization
		kernel_size     : in std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
		padding_size    : in std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
		stride_bit_mask : in std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
		--
		kernel_complete          : out std_logic;
		kernel_en                : out std_logic;
		kernel_activation_matrix : out matrix_1d(0 to G_MAX_KERNEL_SIZE ** 2 - 1)(vector_length - 1 downto 0)
	);
end entity configurable_slider;

architecture rtl of configurable_slider is

	-- Control signals
	signal s_init_complete       : std_logic;
	signal s_full_stream_line    : std_logic_vector(0 to G_LINE_BUFFER_AMOUNT - 1);

	-- The main inputs every linebuffer or line_unit gets from the routing unit
	signal s_line_buffer_streams : matrix_1d(0 to G_LINE_BUFFER_AMOUNT - 1)(vector_length - 1 downto 0);
	signal s_line_buffer_enables : std_logic_vector(0 to G_LINE_BUFFER_AMOUNT - 1);

	-- Signals for transporting the activation and enable matrices provided by the linebuffers
	signal s_activation_matrix        : matrix_2d(0 to G_LINE_BUFFER_AMOUNT - 1)(0 to G_MAX_KERNEL_SIZE - 1)(vector_length - 1 downto 0);
	signal s_activation_matrix_nulled : matrix_2d(0 to G_LINE_BUFFER_AMOUNT - 1)(0 to G_MAX_KERNEL_SIZE - 1)(vector_length - 1 downto 0);
	signal s_enable_matrix            : matrix_1d(0 to G_LINE_BUFFER_AMOUNT - 1)(0 to G_MAX_KERNEL_SIZE - 1);

begin

	-- Control unit for correctly setting when the kernels are valid and when the computation has finished
	line_control_unit_inst : entity work.line_control_unit
		generic map (
			vector_length     => vector_length,
			G_IMG_MAX_LENGTH  => G_IMG_MAX_LENGTH,
			G_KERNEL_MAX_SIZE => G_MAX_KERNEL_SIZE
		)
		port map (
			clk   => clk,
			reset => reset,
			--
			valid_pixel   => valid_pixel_streams,
			init_complete => s_init_complete,
			--
			input_image_length  => input_image_length,
			output_image_length => output_image_length,
			kernel_size         => kernel_size,
			padding_size        => padding_size,
			stride_bit_mask     => stride_bit_mask,
			--
			kernel_en       => kernel_en,
			kernel_complete => kernel_complete
		);

	line_route_unit_inst : entity work.line_route_unit
		generic map (
			vector_length        => vector_length,
			G_KERNEL_SIZE        => G_KERNEL_SIZE,
			G_MAX_KERNEL_SIZE    => G_MAX_KERNEL_SIZE,
			G_LINE_BUFFER_AMOUNT => G_LINE_BUFFER_AMOUNT,
			G_PIPELINE_STEPS     => G_PIPELINE_STEPS
		)
		port map (
			clk   => clk,
			reset => reset,
			--
			valid_pixel_streams => valid_pixel_streams,
			pixel_streams_in    => pixel_streams,
			activation_matrix   => s_activation_matrix,
			enable_matrix       => s_enable_matrix,
			--
			init_complete         => s_init_complete,
			activation_matrix_out => s_activation_matrix_nulled,
			pixel_streams_out     => s_line_buffer_streams,
			set_full_stream_out   => s_full_stream_line,
			enable_stream_out     => s_line_buffer_enables
		);

	LINE_BUFFER_GEN : for i in 0 to G_LINE_BUFFER_AMOUNT - 1 generate

		LINE_BUFFER_INST : entity work.line_unit
			generic map (
				vector_length     => vector_length,
				G_IMG_MAX_LENGTH  => G_IMG_MAX_LENGTH,
				G_KERNEL_MAX_SIZE => G_MAX_KERNEL_SIZE
			)
			port map (
				clk   => clk,
				reset => reset,
				--
				set_line_buffer_full => s_full_stream_line(i),
				-- The pipelined steps need to be subtracted in order to get correct timing
				-- As always Ungabunga -1 to solve the additional timing problem
				-- And another -1 for the implicit buffering created by the routing unit
				line_buffer_depth => std_logic_vector(unsigned(input_image_length) - G_PIPELINE_STEPS - 1),
				din               => s_line_buffer_streams(i),
				en                => valid_pixel_streams,
				wr_en             => s_line_buffer_enables(i),
				--
				pixel_window_line  => s_activation_matrix(i),
				enable_window_line => s_enable_matrix(i)
			);

	end generate LINE_BUFFER_GEN;

	-- Flatten and mirroring output of nulled activation matrix from matrix_2d to matrix_1d

	Y_GEN : for y in 0 to G_MAX_KERNEL_SIZE - 1 generate

		X_GEN : for x in 0 to G_MAX_KERNEL_SIZE - 1 generate
			kernel_activation_matrix((G_MAX_KERNEL_SIZE - 1 - y) * G_MAX_KERNEL_SIZE + G_MAX_KERNEL_SIZE - 1 - x)
 				<= s_activation_matrix_nulled(x)(y);
		end generate X_GEN;

	end generate Y_GEN;

end architecture rtl;
