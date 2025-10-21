library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity pxs_2_axis is
	generic (
		G_OUTPUT_CHANNELS      : natural;
		G_DATA_BYTE_WIDTH      : integer range 1 to 128 := 16;
		G_BRAM_BYTE_WIDTH      : integer range 1 to 128 := 1;
		G_BRAM_MAX_DEPTH       : natural                := 512;
		G_NEAR_FULL_THRESHOLD  : natural                := 5;
		G_NEAR_EMPTY_THRESHOLD : natural                := 1
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		--
		o_en : out std_logic;
		-- ROUTING CORES OUTPUTS
		i_kernel_complete : in std_logic;
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
	signal s_bram_rd_en        : std_logic_vector(G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);
	signal s_bram_empty        : std_logic_vector(G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);
	signal s_bram_nearly_full  : std_logic_vector(G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);
	signal s_bram_nearly_empty : std_logic_vector(G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);

	-- AXIS PS INPUTS
	signal s_ps_axis_tkeep  : std_logic_vector(G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);
	signal s_ps_axis_tlast  : std_logic;
	signal s_ps_axis_tready : std_logic;
	signal s_ps_axis_tvalid : std_logic;

	-- Signal for controlling enabling everything
	signal s_en : std_logic;

	signal s_bram_output_stream : std_logic_vector(G_DATA_BYTE_WIDTH * 8 - 1 downto 0);

	-- Helper signals for determining when transfer was finished
	signal s_px_m_axis_tvalid  : std_logic;
	signal s_px_m_axis_tlast   : std_logic;
	signal s_accel_finish      : std_logic;
	signal s_transfer_finished : std_logic;

begin

	FINISH_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_accel_finish <= '0';
			elsif (i_px_m_axis_tready and s_px_m_axis_tvalid and s_px_m_axis_tlast) = '1' then
				s_accel_finish <= '1';
			end if;
		end if;

	end process FINISH_PROC;

	AXIS_CONTROL_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_ps_axis_tvalid    <= '0';
				s_ps_axis_tlast     <= '0';
				s_ps_axis_tkeep     <= (others => '0');
				s_transfer_finished <= '0';
			else
				if s_ps_axis_tlast = '1' and s_ps_axis_tready = '1' and s_ps_axis_tvalid = '1' then
					s_transfer_finished <= '1';
				end if;
				if s_transfer_finished = '0' and not (s_ps_axis_tlast = '1' and s_ps_axis_tready = '1' and s_ps_axis_tvalid = '1') then 
					if s_ps_axis_tready = '1' then
						s_ps_axis_tvalid <= '0';
						s_ps_axis_tkeep  <= (others => '0');
					end if;

					if s_bram_rd_en(s_bram_rd_en'low) = '1' then
						s_ps_axis_tvalid <= '1';
						s_ps_axis_tkeep  <= not s_bram_nearly_empty;
						if i_kernel_complete = '1' then
							s_ps_axis_tlast <= '1';
						end if;
					end if;
				else
					s_ps_axis_tvalid <= '0';
					s_ps_axis_tlast <= '0';
					s_ps_axis_tkeep <= (others => '0');
				end if; 
			end if;
		end if;

	end process AXIS_CONTROL_PROC;

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
			G_DATA_BYTE_WIDTH      => G_DATA_BYTE_WIDTH,
			G_BRAM_BYTE_WIDTH      => G_BRAM_BYTE_WIDTH,
			G_MAX_DEPTH            => G_BRAM_MAX_DEPTH,
			G_NEAR_FULL_THRESHOLD  => G_NEAR_FULL_THRESHOLD,
			G_NEAR_EMPTY_THRESHOLD => G_NEAR_EMPTY_THRESHOLD
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
			o_nearly_empty  => s_bram_nearly_empty,
			o_empty         => s_bram_empty
		);

	axis_pipeline_step_inst : entity work.axis_pipeline_step
		generic map (
			G_BYTE_WIDTH => G_DATA_BYTE_WIDTH
		)
		port map (
			clk   => clk,
			reset => reset,
			-- AXIS INPUT
			i_s_axis_tdata  => s_bram_output_stream,
			i_s_axis_tkeep  => s_ps_axis_tkeep,
			i_s_axis_tlast  => s_ps_axis_tlast,
			o_s_axis_tready => s_ps_axis_tready,
			i_s_axis_tvalid => s_ps_axis_tvalid,
			-- AXIS OUTPUT
			o_m_axis_tdata  => o_px_m_axis_tdata,
			o_m_axis_tkeep  => o_px_m_axis_tkeep,
			o_m_axis_tlast  => s_px_m_axis_tlast,
			i_m_axis_tready => i_px_m_axis_tready,
			o_m_axis_tvalid => s_px_m_axis_tvalid
		);

	----------------------------------------
	-- Asynchronous signals
	----------------------------------------
	s_bram_rd_en <= (others => (i_kernel_complete or not (or s_bram_nearly_empty)) and s_ps_axis_tready);
	s_en         <= not (and s_bram_nearly_full);

	----------------------------------------
	-- Set outputs
	----------------------------------------
	o_px_m_axis_tvalid <= s_px_m_axis_tvalid;
	o_px_m_axis_tlast  <= s_px_m_axis_tlast;
	o_en               <= s_en;
	o_accel_finished   <= s_accel_finish;

end architecture rtl;
