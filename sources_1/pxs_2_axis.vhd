library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity pxs_2_axis is
	generic (
		G_OUTPUT_CHANNELS     : natural;
		G_DATA_BYTE_WIDTH     : integer range 1 to 128 := 16;
		G_BRAM_BYTE_WIDTH     : integer range 1 to 128 := 1;
		G_BRAM_MAX_DEPTH      : natural                := 512;
		G_NEAR_FULL_THRESHOLD : natural                := 5
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		--
		o_en : out std_logic;
		-- ROUTING CORES OUTPUTS
		i_kernel_complete : out std_logic;
		i_kernel_valid    : in std_logic;
		i_pixel_line      : in matrix_1d(0 to G_DATA_BYTE_WIDTH - 1)(G_BRAM_BYTE_WIDTH * 8 - 1 downto 0);
		-- Control Logic
		o_accel_finished : out std_logic;
		-- AXIS OUTPUT INTERFACE
		o_px_m_axis_tdata  : out std_logic_vector(G_DATA_BYTE_WIDTH * 8 - 1 downto 0);
		o_px_m_axis_tkeep  : out std_logic_vector(G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);
		o_px_m_axis_tlast  : out std_logic;
		i_px_m_axis_tready : in std_logic;
		o_px_m_axis_tvalid : out std_logic
	);
end entity pxs_2_axis;

architecture rtl of pxs_2_axis is

	-- Write Signals to BRAM
	signal s_bram_input_stream : std_logic_vector(G_DATA_BYTE_WIDTH * 8 - 1 downto 0);
	signal s_bram_wr_en        : std_logic_vector(G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);

	-- Control Signals of BRAM
	signal s_bram_rd_en       : std_logic_vector(G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);
	signal s_bram_rd_en_del   : std_logic_vector(G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);
	signal s_bram_empty       : std_logic_vector(G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);
	signal s_bram_empty_del   : std_logic_vector(G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);
	signal s_bram_nearly_full : std_logic_vector(G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);

	-- AXIS PS1 <-> PS3
	signal s_ps1_2_ps2_axis_tdata  : std_logic_vector(G_DATA_BYTE_WIDTH * 8 - 1 downto 0);
	signal s_ps1_2_ps2_axis_tkeep  : std_logic_vector(G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);
	signal s_ps1_2_ps2_axis_tlast  : std_logic;
	signal s_ps1_2_ps2_axis_tready : std_logic;
	signal s_ps1_2_ps2_axis_tvalid : std_logic;

	-- AXIS PS2 <-> PS3
	signal s_ps2_2_ps3_axis_tdata  : std_logic_vector(G_DATA_BYTE_WIDTH * 8 - 1 downto 0);
	signal s_ps2_2_ps3_axis_tkeep  : std_logic_vector(G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);
	signal s_ps2_2_ps3_axis_tlast  : std_logic;
	signal s_ps2_2_ps3_axis_tready : std_logic;
	signal s_ps2_2_ps3_axis_tvalid : std_logic;

	-- Signal for flushing the bram
	signal s_flush_line : std_logic_vector(0 to 2);

	-- Signal for controlling enabling everything
	signal s_en : std_logic;

	signal s_bram_output_stream : std_logic_vector(G_DATA_BYTE_WIDTH * 8 - 1 downto 0);

begin

	FLUSH_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_flush_line     <= (others => '0');
				s_bram_rd_en_del <= (others => '0');
				s_bram_empty_del <= (others => '0');
			else
				s_flush_line(0)      <= i_kernel_complete;
				s_flush_line(1 to 2) <= s_flush_line(0 to 1);
				s_bram_rd_en_del     <= s_bram_rd_en;
				s_bram_empty_del     <= s_bram_empty;
			end if;
		end if;

	end process FLUSH_PROC;

	pxs_2_axis_demux_inst : entity work.pxs_2_axis_demux
		generic map (
			G_OUTPUT_CHANNELS => G_OUTPUT_CHANNELS,
			G_DATA_BYTE_WIDTH => G_DATA_BYTE_WIDTH,
			G_BRAM_BYTE_WIDTH => G_BRAM_BYTE_WIDTH
		)
		port map (
			clk   => clk,
			reset => reset,
			--
			i_en => s_en,
			--
			i_kernel_complete => i_kernel_complete,
			i_kernel_valid    => i_kernel_valid,
			i_pixel_line      => i_pixel_line,
			--
			o_input_stream => s_bram_input_stream,
			o_wr_en        => s_bram_wr_en
		);

	bram_fifo_array_inst : entity work.bram_fifo_array
		generic map (
			G_DATA_BYTE_WIDTH     => G_DATA_BYTE_WIDTH,
			G_BRAM_BYTE_WIDTH     => G_BRAM_BYTE_WIDTH,
			G_MAX_DEPTH           => G_BRAM_MAX_DEPTH,
			G_NEAR_FULL_THRESHOLD => G_NEAR_FULL_THRESHOLD
		)
		port map (
			clk   => clk,
			reset => reset,
			--
			i_input_stream => s_bram_input_stream,
			i_wr_en        => s_bram_wr_en,
			i_rd_en        => s_bram_rd_en,
			--
			o_output_stream => s_bram_output_stream,
			o_full          => open,
			o_nearly_full   => s_bram_nearly_full,
			o_empty         => s_bram_empty
		);

	axis_pipeline_step_1_inst : entity work.axis_pipeline_step
		generic map (
			G_BYTE_WIDTH => G_DATA_BYTE_WIDTH
		)
		port map (
			clk   => clk,
			reset => reset,
			-- AXIS INPUT
			i_s_axis_tdata  => s_bram_output_stream,
			i_s_axis_tkeep  => s_bram_empty_del,
			i_s_axis_tlast  => s_flush_line(s_flush_line'high),
			o_s_axis_tready => open,
			i_s_axis_tvalid => or s_bram_rd_en_del,
			-- AXIS OUTPUT
			o_m_axis_tdata  => s_ps1_2_ps2_axis_tdata,
			o_m_axis_tkeep  => s_ps1_2_ps2_axis_tkeep,
			o_m_axis_tlast  => s_ps1_2_ps2_axis_tlast,
			i_m_axis_tready => s_ps1_2_ps2_axis_tready,
			o_m_axis_tvalid => s_ps1_2_ps2_axis_tvalid
		);

	axis_pipeline_step_2_inst : entity work.axis_pipeline_step
		generic map (
			G_BYTE_WIDTH => G_DATA_BYTE_WIDTH
		)
		port map (
			clk   => clk,
			reset => reset,
			-- AXIS INPUT
			i_s_axis_tdata  => s_ps1_2_ps2_axis_tdata,
			i_s_axis_tkeep  => s_ps1_2_ps2_axis_tkeep,
			i_s_axis_tlast  => s_ps1_2_ps2_axis_tlast,
			o_s_axis_tready => s_ps1_2_ps2_axis_tready,
			i_s_axis_tvalid => s_ps1_2_ps2_axis_tvalid,
			-- AXIS OUTPUT
			o_m_axis_tdata  => s_ps2_2_ps3_axis_tdata,
			o_m_axis_tkeep  => s_ps2_2_ps3_axis_tkeep,
			o_m_axis_tlast  => s_ps2_2_ps3_axis_tlast,
			i_m_axis_tready => s_ps2_2_ps3_axis_tready,
			o_m_axis_tvalid => s_ps2_2_ps3_axis_tvalid
		);

	axis_pipeline_step_3_inst : entity work.axis_pipeline_step
		generic map (
			G_BYTE_WIDTH => G_DATA_BYTE_WIDTH
		)
		port map (
			clk   => clk,
			reset => reset,
			-- AXIS INPUT
			i_s_axis_tdata  => s_ps2_2_ps3_axis_tdata,
			i_s_axis_tkeep  => s_ps2_2_ps3_axis_tkeep,
			i_s_axis_tlast  => s_ps2_2_ps3_axis_tlast,
			o_s_axis_tready => s_ps2_2_ps3_axis_tready,
			i_s_axis_tvalid => s_ps2_2_ps3_axis_tvalid,
			-- AXIS OUTPUT
			o_m_axis_tdata  => o_px_m_axis_tdata,
			o_m_axis_tkeep  => o_px_m_axis_tkeep,
			o_m_axis_tlast  => o_px_m_axis_tlast,
			i_m_axis_tready => i_px_m_axis_tready,
			o_m_axis_tvalid => o_px_m_axis_tvalid
		);

	----------------------------------------
	-- Asynchronous signals
	----------------------------------------
	s_bram_rd_en <= (others => s_ps2_2_ps3_axis_tready and (not (and s_bram_empty) or s_flush_line(s_flush_line'high - 1)));
	s_en         <= not (and s_bram_nearly_full);

	----------------------------------------
	-- Set outputs
	----------------------------------------
	o_en             <= s_en;
	o_accel_finished <= (and s_bram_empty) and s_flush_line(s_flush_line'high);

end architecture rtl;
