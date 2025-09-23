library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity memory_test is
	generic (
		vector_length  : natural := 8;
		channel_amount : natural := 16;
		iterations     : natural := 40
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		-- Weight Inputs
		i_wt_s_axis_tdata  : in std_logic_vector(vector_length * channel_amount - 1 downto 0);
		i_wt_s_axis_tkeep  : in std_logic_vector(channel_amount - 1 downto 0);
		i_wt_s_axis_tlast  : in std_logic;
		o_wt_s_axis_tready : out std_logic;
		i_wt_s_axis_tvalid : in std_logic;
		-- Activation Pixel Input
		i_px_s_axis_tdata  : in std_logic_vector(vector_length * channel_amount - 1 downto 0);
		i_px_s_axis_tkeep  : in std_logic_vector(channel_amount - 1 downto 0);
		i_px_s_axis_tlast  : in std_logic;
		o_px_s_axis_tready : out std_logic;
		i_px_s_axis_tvalid : in std_logic;
		-- Result Pixel Output
		o_px_m_axis_tdata  : out std_logic_vector(vector_length * channel_amount - 1 downto 0);
		o_px_m_axis_tkeep  : out std_logic_vector(channel_amount - 1 downto 0);
		o_px_m_axis_tlast  : out std_logic;
		i_px_m_axis_tready : in std_logic;
		o_px_m_axis_tvalid : out std_logic
	);
end entity memory_test;

architecture rtl of memory_test is

	signal s_sa_wt_tdata      : matrix_1d(0 to channel_amount - 1)(vector_length - 1 downto 0);
	signal s_wt_s_axis_tready : std_logic;
	signal s_wt_rx_iterations : integer range 0 to iterations;
	signal s_sa_px_tdata      : matrix_1d(0 to channel_amount - 1)(vector_length - 1 downto 0);
	signal s_px_s_axis_tready : std_logic;
	signal s_px_rx_iterations : integer range 0 to iterations;

	signal   s_weight_mem       : matrix_1d(0 to channel_amount * iterations - 1)(vector_length - 1 downto 0);
	constant C_EMPTY_BURST      : matrix_1d(0 to channel_amount - 1)(vector_length - 1 downto 0) := (others => (others => '0'));
	signal   s_wt_tx_iterations : integer range 0 to iterations;
	signal   s_pixel_mem        : matrix_1d(0 to channel_amount * iterations - 1)(vector_length - 1 downto 0);
	signal   s_px_tx_iterations : integer range 0 to iterations;

	signal s_done_weight      : std_logic;
	signal s_done_activations : std_logic;

begin

	SANATIZE_GEN : for i in 0 to channel_amount - 1 generate
		s_sa_wt_tdata(channel_amount - i - 1) <= i_wt_s_axis_tdata((i + 1) * vector_length - 1 downto i * vector_length)
	                                         when i_wt_s_axis_tkeep(i) = '1' else
	                                         (others => '0');
		s_sa_px_tdata(channel_amount - i - 1) <= i_px_s_axis_tdata((i + 1) * vector_length - 1 downto i * vector_length)
	                                         when i_px_s_axis_tkeep(i) = '1' else
	                                         (others => '0');
	end generate SANATIZE_GEN;

	WEIGHT_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				-- weight reset
				s_weight_mem       <= (others => (others => '0'));
				s_done_weight      <= '0';
				s_wt_s_axis_tready <= '0';
				-- pixel reset
				s_pixel_mem        <= (others => (others => '0'));
				s_done_activations <= '0';
				s_px_s_axis_tready <= '0';
				-- output reset
				o_px_m_axis_tdata  <= (others => '0');
				o_px_m_axis_tkeep  <= (others => '1');
				o_px_m_axis_tlast  <= '0';
				o_px_m_axis_tvalid <= '0';
				--
				s_px_rx_iterations <= 0;
				s_wt_rx_iterations <= 0;
				--
				s_px_tx_iterations <= 0;
				s_wt_tx_iterations <= 0;
			else
				----------------------------------------
				-- Weight Retrieval
				----------------------------------------
				s_wt_s_axis_tready <= '1';

				-- if last burst has been reached, then quit weight retrieval
				if s_wt_rx_iterations >= iterations - 1 and (i_wt_s_axis_tlast = '1' or s_wt_s_axis_tready = '0') then
					s_done_weight      <= '1';
					s_wt_s_axis_tready <= '0';
				end if;

				-- save data if not all iterations have concluded and increment iteration variable
				if i_wt_s_axis_tvalid = '1' and s_done_weight = '0' then
					s_weight_mem       <= s_weight_mem(channel_amount to s_weight_mem'high) & s_sa_wt_tdata;
					s_wt_rx_iterations <= s_wt_rx_iterations + 1;
				end if;

				----------------------------------------
				-- Pixel Retrieval
				----------------------------------------

				-- if last burst has been reached, then quit pixel retrieval
				s_px_s_axis_tready <= '1';
				if s_px_rx_iterations >= iterations - 1 and (i_px_s_axis_tlast = '1' or s_px_s_axis_tready = '0') then
					s_done_activations <= '1';
					s_px_s_axis_tready <= '0';
				end if;

				-- save data if not all iterations have concluded and increment iteration variable
				if i_px_s_axis_tvalid = '1' and s_done_activations = '0' then
					s_pixel_mem        <= s_pixel_mem(channel_amount to s_pixel_mem'high) & s_sa_px_tdata;
					s_px_rx_iterations <= s_px_rx_iterations + 1;
				end if;

				----------------------------------------
				-- TX write process
				----------------------------------------

				if s_done_activations = '1' and s_done_weight = '1' then
					o_px_m_axis_tvalid <= '1';
					o_px_m_axis_tlast  <= '0';
					-- Set data depending on the state
					if s_wt_tx_iterations < iterations then
						o_px_m_axis_tdata <= f_flatten_matrix1d(s_weight_mem(0 to channel_amount - 1));
					elsif s_px_tx_iterations < iterations then
						o_px_m_axis_tdata <= f_flatten_matrix1d(s_pixel_mem(0 to channel_amount - 1));
					else
						-- all data has been send, nothing can be sent anymore, so just send -1
						o_px_m_axis_tdata <= (others => '1');
					end if;

					-- Progress state if data can be read
					if i_px_m_axis_tready = '1' then
						-- sending of result is finished
						if s_wt_tx_iterations < iterations then
							s_wt_tx_iterations <= s_wt_tx_iterations + 1;
							s_weight_mem       <= s_weight_mem(channel_amount to s_weight_mem'high) & C_EMPTY_BURST;
						elsif s_px_tx_iterations < iterations then
							s_px_tx_iterations <= s_px_tx_iterations + 1;
							if s_px_tx_iterations = iterations - 1 then
								o_px_m_axis_tlast <= '1';
							else
								o_px_m_axis_tlast <= '0';
							end if;
							s_pixel_mem <= s_pixel_mem(channel_amount to s_pixel_mem'high) & C_EMPTY_BURST;
						end if;
					end if;
				end if;
			end if;
		end if;

	end process WEIGHT_PROC;

	----------------------------------------
	-- Set Outputs
	----------------------------------------
	o_wt_s_axis_tready <= s_wt_s_axis_tready;
	o_px_s_axis_tready <= s_px_s_axis_tready;

end architecture rtl;
