library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity axis_2_configurable_slider_wrapper is
	generic (
		-- Shared Generics
		G_VECTOR_BYTE_LENGTH : natural := 1;
		G_IMG_MAX_LENGTH     : natural := 300;
		G_KERNEL_SIZE        : natural := 5;
		G_PADDING_SIZE       : natural := 2;
		-- AXIS_2_PXS Generics
		G_INPUT_BYTE_WIDTH            : integer range 1 to 128 := 16;
		G_OUTPUT_BYTE_WIDTH           : integer range 1 to 128 := 15;
		G_INPUT_CHANNEL_PER_ITERATION : natural                := 3;
		G_MAX_FIFO_DEPTH              : natural                := 512;
		G_NEAR_FULL_THRESHOLD         : natural                := 0;
		-- CONFIGURABLE SLIDER GENERICS
		G_MAX_KERNEL_SIZE    : natural := 11;
		G_LINE_BUFFER_AMOUNT : natural := 16 * 5;
		G_PIPELINE_STEPS     : natural := 1
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		--
		i_rst_axis_2_pxs          : in std_logic;
		i_rst_configurable_slider : in std_logic;
		--
		i_en : in std_logic;
		-- AXIS INPUT
		i_s_axis_tdata  : in std_logic_vector(G_INPUT_BYTE_WIDTH * 8 - 1 downto 0);
		i_s_axis_tkeep  : in std_logic_vector(G_INPUT_BYTE_WIDTH - 1 downto 0);
		i_s_axis_tlast  : in std_logic;
		o_s_axis_tready : out std_logic;
		i_s_axis_tvalid : in std_logic;
		-- Control Inputs [REGISTERED after reset]
		i_image_input_length  : in std_logic_vector(15 downto 0);
		i_image_output_length : in std_logic_vector(15 downto 0);
		i_kernel_size         : in std_logic_vector(7 downto 0);
		i_padding_size        : in std_logic_vector(7 downto 0);
		i_pool_or_conv : in std_logic;
		i_stride_bit_mask     : in std_logic_vector(7 downto 0);
		-- Control Inputs [Not REGISTERED after reset]
		i_wt_init : in std_logic;
		-- CONFIGURABLE SLIDER OUTPUTS
		o_kernel_complete          : out std_logic;
		o_kernel_en                : out std_logic;
		o_kernel_activation_matrix : out matrix_1d(0 to G_MAX_KERNEL_SIZE * G_LINE_BUFFER_AMOUNT - 1)(G_VECTOR_BYTE_LENGTH * 8 - 1 downto 0)
	);
end entity axis_2_configurable_slider_wrapper;

architecture rtl of axis_2_configurable_slider_wrapper is

	signal s_cs_init     : std_logic;
	signal s_cs_init_del : std_logic;
	signal s_wt_init     : std_logic;

	signal s_valid_pixel_streams : std_logic;
	signal s_pixel_streams       : matrix_1d(0 to G_LINE_BUFFER_AMOUNT - 1)(G_VECTOR_BYTE_LENGTH * 8 - 1 downto 0);

	signal s_input_image_length  : std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
	signal s_output_image_length : std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
	signal s_kernel_size         : std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
	signal s_padding_size        : std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
	signal s_stride_bit_mask     : std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);

begin

	DELAY_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_cs_init_del <= '0';
				s_wt_init     <= '0';
			else
				s_cs_init_del <= s_cs_init;
				s_wt_init     <= i_wt_init;
			end if;
		end if;

	end process DELAY_PROC;

	----------------------------------------
	-- Asynchronous signals
	----------------------------------------

	-- Set rest of pixel streams that will never be mapped to 0s
	s_pixel_streams(G_INPUT_BYTE_WIDTH to s_pixel_streams'high) <= (others => (others => '0'));
	-- Resize all config registers to be fitting for configurable slider
	s_input_image_length  <= std_logic_vector(resize(unsigned(i_image_input_length), s_input_image_length'length));
	s_output_image_length <= std_logic_vector(resize(unsigned(i_image_output_length), s_output_image_length'length));
	s_kernel_size         <= std_logic_vector(resize(unsigned(i_kernel_size), s_kernel_size'length));
	s_padding_size        <= std_logic_vector(resize(unsigned(i_padding_size), s_padding_size'length));
	s_stride_bit_mask     <= std_logic_vector(resize(unsigned(i_stride_bit_mask), s_stride_bit_mask'length));

	----------------------------------------
	-- Instantiation of axis interface
	----------------------------------------

	axis_2_pxs_inst : entity work.axis_2_pxs
		generic map (
			G_INPUT_BYTE_WIDTH            => G_INPUT_BYTE_WIDTH,
			G_OUTPUT_BYTE_WIDTH           => G_OUTPUT_BYTE_WIDTH,
			G_BRAM_BYTE_WIDTH             => G_VECTOR_BYTE_LENGTH,
			G_INPUT_CHANNEL_PER_ITERATION => G_INPUT_CHANNEL_PER_ITERATION,
			G_IMG_MAX_LENGTH              => G_IMG_MAX_LENGTH,
			G_MAX_FIFO_DEPTH              => G_MAX_FIFO_DEPTH,
			G_NEAR_FULL_THRESHOLD         => G_NEAR_FULL_THRESHOLD
		)
		port map (
			clk   => clk,
			reset => reset or i_rst_axis_2_pxs,
			--
			i_en => i_en,
			-- AXIS INPUT
			i_s_axis_tdata  => i_s_axis_tdata,
			i_s_axis_tkeep  => i_s_axis_tkeep,
			i_s_axis_tlast  => i_s_axis_tlast,
			o_s_axis_tready => o_s_axis_tready,
			i_s_axis_tvalid => i_s_axis_tvalid,
			-- Control Inputs [REGISTERED after reset]
			i_image_input_length => i_image_input_length,
			i_padding_size       => i_padding_size,
			i_pool_or_conv => i_pool_or_conv,
			-- Control Inputs [Not REGISTERED after reset]
			i_wt_init => s_wt_init,
			i_cs_init => s_cs_init_del,
			-- Pixel Stream Output
			o_valid_pixel_streams => s_valid_pixel_streams,
			o_pixel_streams       => s_pixel_streams(0 to G_INPUT_BYTE_WIDTH - 1)
		);

	----------------------------------------
	-- Instantiation of configurable
	-- line buffer structure
	----------------------------------------

	configurable_slider_inst : entity work.configurable_slider
		generic map (
			vector_length        => G_VECTOR_BYTE_LENGTH * 8,
			G_IMG_MAX_LENGTH     => G_IMG_MAX_LENGTH,
			G_KERNEL_SIZE        => G_KERNEL_SIZE,
			G_PADDING_SIZE       => G_PADDING_SIZE,
			G_MAX_KERNEL_SIZE    => G_MAX_KERNEL_SIZE,
			G_LINE_BUFFER_AMOUNT => G_LINE_BUFFER_AMOUNT,
			G_PIPELINE_STEPS     => G_PIPELINE_STEPS,
			G_DEBUG_FLAG         => '0'
		)
		port map (
			clk   => clk,
			reset => reset or i_rst_configurable_slider,
			--
			valid_pixel_streams => s_valid_pixel_streams,
			pixel_streams       => s_pixel_streams,
			--
			input_image_length  => s_input_image_length,
			output_image_length => s_output_image_length,
			kernel_size         => s_kernel_size,
			padding_size        => s_padding_size,
			stride_bit_mask     => s_stride_bit_mask,
			--
			init_complete     => open,
			init_complete_1ce => open,
			init_complete_2ce => s_cs_init,
			--
			kernel_complete          => o_kernel_complete,
			kernel_en                => o_kernel_en,
			kernel_activation_matrix => o_kernel_activation_matrix
		);

end architecture rtl;
