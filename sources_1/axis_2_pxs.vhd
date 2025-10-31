library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity axis_2_pxs is
	generic (
		G_INPUT_BYTE_WIDTH            : INTEGER range 1 to 128 := 16;
		G_OUTPUT_BYTE_WIDTH           : INTEGER range 1 to 128 := 15;
		G_BRAM_BYTE_WIDTH             : natural                := 1;
		G_INPUT_CHANNEL_PER_ITERATION : natural                := 3;
		G_IMG_MAX_LENGTH              : natural                := 300;
		G_MAX_FIFO_DEPTH              : natural                := 512;
		G_NEAR_FULL_THRESHOLD         : natural                := 0
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		--
		i_rst_axis_2_pxs          : in std_logic;
		i_rst_cfg_slider : in std_logic;
		--
		i_en : in std_logic;
		-- AXIS INPUT
		i_s_axis_tdata  : in std_logic_vector(G_INPUT_BYTE_WIDTH * 8 - 1 downto 0);
		i_s_axis_tkeep  : in std_logic_vector(G_INPUT_BYTE_WIDTH - 1 downto 0);
		i_s_axis_tlast  : in std_logic;
		o_s_axis_tready : out std_logic;
		i_s_axis_tvalid : in std_logic;
		-- Control Inputs [REGISTERED after reset]
		i_image_input_length : in std_logic_vector(15 downto 0);
		i_padding_size       : in std_logic_vector(7 downto 0);
		i_pool_or_conv       : in std_logic;
		-- Control Inputs [Not REGISTERED after reset]
		i_wt_init : in std_logic;
		i_cs_init : in std_logic;
		-- Pixel Stream Output
		o_valid_pixel_streams : out std_logic;
		o_pixel_streams       : out matrix_1d(0 to G_INPUT_BYTE_WIDTH - 1)(G_BRAM_BYTE_WIDTH * 8 - 1 downto 0)
	);
end entity axis_2_pxs;

architecture rtl of axis_2_pxs is

	-- AXIS DWC <-> AXIS Pipeline Step
	signal s_dwc_2_ps_axis_tdata  : std_logic_vector(G_INPUT_BYTE_WIDTH * 8 - 1 downto 0);
	signal s_dwc_2_ps_axis_tkeep  : std_logic_vector(G_INPUT_BYTE_WIDTH - 1 downto 0);
	signal s_dwc_2_ps_axis_tlast  : std_logic;
	signal s_dwc_2_ps_axis_tready : std_logic;
	signal s_dwc_2_ps_axis_tvalid : std_logic;

	-- AXIS Pipeline Step <-> BRAM FIFO Array
	signal s_ps_2_bfa_axis_tdata  : std_logic_vector(G_INPUT_BYTE_WIDTH * 8 - 1 downto 0);
	signal s_ps_2_bfa_axis_tkeep  : std_logic_vector(G_INPUT_BYTE_WIDTH - 1 downto 0);
	signal s_ps_2_bfa_axis_tlast  : std_logic;
	signal s_bfa_wr_en            : std_logic_vector(G_INPUT_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);
	signal s_bfa_full             : std_logic_vector(G_INPUT_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);
	signal s_ps_2_bfa_axis_tvalid : std_logic;
	signal s_ps_2_bfa_axis_tready : std_logic;

	-- BRAM FIFO Array <-> DEMUX Unit
	signal s_bfa_rd_en       : std_logic_vector(G_INPUT_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);
	signal s_bfa_empty       : std_logic_vector(G_INPUT_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);
	signal s_bfa_empty_del   : std_logic_vector(G_INPUT_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);
	signal s_bfa_data_stream : std_logic_vector(G_INPUT_BYTE_WIDTH * 8 - 1 downto 0);
	signal s_bfa_data_stream_del : std_logic_vector(G_INPUT_BYTE_WIDTH * 8 - 1 downto 0);

begin

	DELAY_PROC : process (clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				s_bfa_empty_del <= (others => '0');
				s_bfa_data_stream_del <= (others => '0');  
			else
				s_bfa_empty_del <= s_bfa_empty;
				s_bfa_data_stream_del <= s_bfa_data_stream;
			end if;
		end if;
	end process;

	axis_data_width_converter_inst : entity work.axis_data_width_converter
		generic map (
			G_INPUT_BYTE_WIDTH  => G_INPUT_BYTE_WIDTH,
			G_OUTPUT_BYTE_WIDTH => G_OUTPUT_BYTE_WIDTH
		)
		port map (
			clk   => clk,
			reset => reset or i_rst_axis_2_pxs,
			--
			i_s_axis_tdata  => i_s_axis_tdata,
			i_s_axis_tkeep  => i_s_axis_tkeep,
			i_s_axis_tlast  => i_s_axis_tlast,
			o_s_axis_tready => o_s_axis_tready,
			i_s_axis_tvalid => i_s_axis_tvalid,
			--
			o_m_axis_tdata  => s_dwc_2_ps_axis_tdata,
			o_m_axis_tkeep  => s_dwc_2_ps_axis_tkeep,
			o_m_axis_tlast  => s_dwc_2_ps_axis_tlast,
			i_m_axis_tready => s_dwc_2_ps_axis_tready,
			o_m_axis_tvalid => s_dwc_2_ps_axis_tvalid
		);

	axis_pipeline_step_inst : entity work.axis_pipeline_step
		generic map (
			G_BYTE_WIDTH => G_INPUT_BYTE_WIDTH
		)
		port map (
			clk   => clk,
			reset => reset or i_rst_axis_2_pxs,
			-- AXIS INPUT
			i_s_axis_tdata  => s_dwc_2_ps_axis_tdata,
			i_s_axis_tkeep  => s_dwc_2_ps_axis_tkeep,
			i_s_axis_tlast  => s_dwc_2_ps_axis_tlast,
			o_s_axis_tready => s_dwc_2_ps_axis_tready,
			i_s_axis_tvalid => s_dwc_2_ps_axis_tvalid,
			-- AXIS OUTPUT
			o_m_axis_tdata  => s_ps_2_bfa_axis_tdata,
			o_m_axis_tkeep  => s_ps_2_bfa_axis_tkeep,
			o_m_axis_tlast  => s_ps_2_bfa_axis_tlast,
			i_m_axis_tready => s_ps_2_bfa_axis_tready,
			o_m_axis_tvalid => s_ps_2_bfa_axis_tvalid
		);

	-- Only be ready if all brams have atleast one slot or if all will have at least one slot after the read
	s_ps_2_bfa_axis_tready <= not (or s_bfa_full) or (not (or (not (s_bfa_full xor s_bfa_rd_en))));
	-- make a vector out of bit value to conform bram fifo array inst
	-- only read if axi handshake was performed
	s_bfa_wr_en <= (others => s_ps_2_bfa_axis_tvalid and s_ps_2_bfa_axis_tready);

	bram_fifo_array_inst : entity work.bram_fifo_array
		generic map (
			G_DATA_BYTE_WIDTH     => G_INPUT_BYTE_WIDTH,
			G_BRAM_BYTE_WIDTH     => G_BRAM_BYTE_WIDTH,
			G_MAX_DEPTH           => G_MAX_FIFO_DEPTH,
			G_NEAR_FULL_THRESHOLD => G_NEAR_FULL_THRESHOLD
		)
		port map (
			clk   => clk,
			reset => reset or i_rst_axis_2_pxs,
			--
			i_input_stream  => s_ps_2_bfa_axis_tdata,
			i_wr_en         => s_bfa_wr_en,
			i_rd_en         => s_bfa_rd_en,
			o_output_stream => s_bfa_data_stream,
			o_full          => s_bfa_full,
			o_empty         => s_bfa_empty
		);

	configurable_slider_input_demux_inst : entity work.configurable_slider_input_demux
		generic map (
			G_DATA_BYTE_WIDTH             => G_INPUT_BYTE_WIDTH,
			G_BRAM_BYTE_WIDTH             => G_BRAM_BYTE_WIDTH,
			G_INPUT_CHANNEL_PER_ITERATION => G_INPUT_CHANNEL_PER_ITERATION,
			G_IMG_MAX_LENGTH              => G_IMG_MAX_LENGTH
		)
		port map (
			clk   => clk,
			reset => reset,
			--
			i_rst_cfg_slider => i_rst_cfg_slider,
			i_rst_axis_2_pxs => i_rst_axis_2_pxs,
			--
			i_en => i_en,
			--
			i_image_input_length => i_image_input_length,
			i_padding_size       => i_padding_size,
			i_pool_or_conv       => i_pool_or_conv,
			i_wt_init            => i_wt_init,
			i_cs_init            => i_cs_init,
			--
			o_rd_en       => s_bfa_rd_en,
			i_data_stream => s_bfa_data_stream_del,
			i_empty       => s_bfa_empty_del,
			--
			o_valid_pixel_streams => o_valid_pixel_streams,
			o_pixel_streams       => o_pixel_streams
		);

end architecture rtl;
