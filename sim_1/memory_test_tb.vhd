library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity memory_test_tb is
end entity memory_test_tb;

architecture bench of memory_test_tb is

	-- Clock period
	constant clk_period : time := 5 ns;
	-- Generics
	constant vector_length  : natural := 8;
	constant channel_amount : natural := 16;
	constant iterations     : natural := 5;
	-- Ports
	signal clk               : std_logic := '0';
	signal reset             : std_logic;
	signal i_wt_s_axis_tdata : std_logic_vector(vector_length * channel_amount - 1 downto 0);
	signal i_wt_s_axis_tkeep : STD_LOGIC_VECTOR(channel_amount - 1 downto 0);

	signal i_px_s_axis_tdata_matrix : matrix_1d(0 to channel_amount - 1)(vector_length - 1 downto 0);
	signal i_wt_s_axis_tdata_matrix : matrix_1d(0 to channel_amount - 1)(vector_length - 1 downto 0);
	signal i_wt_cnt, i_px_cnt       : integer range 0 to iterations;

	signal i_wt_s_axis_tlast  : std_logic;
	signal o_wt_s_axis_tready : std_logic;
	signal i_wt_s_axis_tvalid : std_logic;
	signal i_px_s_axis_tdata  : std_logic_vector(vector_length * channel_amount - 1 downto 0);
	signal i_px_s_axis_tkeep  : std_logic_vector(channel_amount - 1 downto 0);
	signal i_px_s_axis_tlast  : std_logic;
	signal o_px_s_axis_tready : std_logic;
	signal i_px_s_axis_tvalid : std_logic;
	signal o_px_m_axis_tdata  : std_logic_vector(vector_length * channel_amount - 1 downto 0);
	signal o_px_m_axis_tkeep  : std_logic_vector(channel_amount - 1 downto 0);
	signal o_px_m_axis_tlast  : std_logic;
	signal i_px_m_axis_tready : std_logic := '0';
	signal o_px_m_axis_tvalid : std_logic;

	signal o_wt_rx_iterations : std_logic_vector(15 downto 0);
	signal o_wt_tx_iterations : std_logic_vector(15 downto 0);
	--
	signal o_px_rx_iterations : std_logic_vector(15 downto 0);
	signal o_px_tx_iterations : std_logic_vector(15 downto 0);
	--
	signal o_done_weight      : std_logic;
	signal o_done_activations : std_logic;

	constant c_wt_delay_max : natural := 3;
	constant c_px_delay_max : natural := 5;

	signal s_wt_delay : integer range 0 to c_wt_delay_max := 0;
	signal s_px_delay : integer range 0 to c_px_delay_max := 0;

begin

	memory_test_inst : entity work.memory_test_wrapper
		generic map (
			vector_length  => vector_length,
			channel_amount => channel_amount,
			iterations     => iterations
		)
		port map (
			clk   => clk,
			reset => reset,
			--
			-- Control Logic Outputs
			o_wt_rx_iterations => o_wt_rx_iterations,
			o_wt_tx_iterations => o_wt_tx_iterations,
			--
			o_px_rx_iterations => o_px_rx_iterations,
			o_px_tx_iterations => o_px_tx_iterations,
			--
			o_done_weight      => o_done_weight,
			o_done_activations => o_done_activations,
			wt_s_axis_tdata    => i_wt_s_axis_tdata,
			wt_s_axis_tkeep    => i_wt_s_axis_tkeep,
			wt_s_axis_tlast    => i_wt_s_axis_tlast,
			wt_s_axis_tready   => o_wt_s_axis_tready,
			wt_s_axis_tvalid   => i_wt_s_axis_tvalid,
			--
			px_s_axis_tdata  => i_px_s_axis_tdata,
			px_s_axis_tkeep  => i_px_s_axis_tkeep,
			px_s_axis_tlast  => i_px_s_axis_tlast,
			px_s_axis_tready => o_px_s_axis_tready,
			px_s_axis_tvalid => i_px_s_axis_tvalid,
			--
			px_m_axis_tdata  => o_px_m_axis_tdata,
			px_m_axis_tkeep  => o_px_m_axis_tkeep,
			px_m_axis_tlast  => o_px_m_axis_tlast,
			px_m_axis_tready => i_px_m_axis_tready,
			px_m_axis_tvalid => o_px_m_axis_tvalid
		);

	clk                <= not clk after clk_period / 2;
	i_px_m_axis_tready <= not i_px_m_axis_tready after clk_period;

	SET_WEIGHTS : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then

				for i in 0 to channel_amount - 1 loop

					i_wt_s_axis_tdata_matrix(i) <= std_logic_vector(to_unsigned(i, vector_length));

				end loop;

				i_wt_s_axis_tdata <= (others => '0');

				s_wt_delay         <= 0;
				i_wt_cnt           <= 0;
				i_wt_s_axis_tlast  <= '0';
				i_wt_s_axis_tkeep  <= (others => '1');
				i_wt_s_axis_tvalid <= '0';
			else
				if o_wt_s_axis_tready = '1' and i_wt_s_axis_tvalid = '1' then

					for i in 0 to channel_amount - 1 loop

						i_wt_s_axis_tdata_matrix(i) <= std_logic_vector(unsigned(i_wt_s_axis_tdata_matrix(i)) + 1);

					end loop;

				end if;

				if s_wt_delay = 0 then
					if i_wt_cnt = iterations then
						i_wt_s_axis_tlast  <= '0';
						i_wt_s_axis_tkeep  <= (others => '0');
						i_wt_s_axis_tvalid <= '0';
					else
						i_wt_cnt           <= i_wt_cnt + 1;
						i_wt_s_axis_tlast  <= '1' when TRUE else '0';
						i_wt_s_axis_tkeep  <= (others => '1');
						i_wt_s_axis_tvalid <= '1';
					end if;
					i_wt_s_axis_tdata <= f_flatten_matrix1d(i_wt_s_axis_tdata_matrix);
				else
					i_wt_s_axis_tvalid <= '0';
					i_wt_s_axis_tlast  <= '0';
				end if;
				if s_wt_delay = c_wt_delay_max then
					s_wt_delay <= 0;
				else
					s_wt_delay <= s_wt_delay + 1;
				end if;
			end if;
		end if;

	end process SET_WEIGHTS;

	SET_PIXEL : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then

				for i in 0 to channel_amount - 1 loop

					i_px_s_axis_tdata_matrix(i) <= std_logic_vector(to_unsigned(i, vector_length));

				end loop;

				i_px_s_axis_tdata <= (others => '0');

				s_px_delay         <= 0;
				i_px_cnt           <= 0;
				i_px_s_axis_tlast  <= '0';
				i_px_s_axis_tkeep  <= (others => '1');
				i_px_s_axis_tvalid <= '0';
			else
				if o_px_s_axis_tready = '1' and i_px_s_axis_tvalid = '1' then

					for i in 0 to channel_amount - 1 loop

						i_px_s_axis_tdata_matrix(i) <= std_logic_vector(unsigned(i_px_s_axis_tdata_matrix(i)) + 1);

					end loop;

				end if;
				if s_px_delay = 0 then
					if i_px_cnt = iterations then
						i_px_s_axis_tlast  <= '0';
						i_px_s_axis_tkeep  <= (others => '0');
						i_px_s_axis_tvalid <= '0';
					else
						i_px_cnt           <= i_px_cnt + 1;
						i_px_s_axis_tlast  <= '1' when i_px_cnt = (iterations - 1) else '0';
						i_px_s_axis_tkeep  <= (others => '1');
						i_px_s_axis_tvalid <= '1';
					end if;
					i_px_s_axis_tdata <= f_flatten_matrix1d(i_px_s_axis_tdata_matrix);
				else
					i_px_s_axis_tvalid <= '0';
					i_px_s_axis_tlast  <= '0';
				end if;
				if s_px_delay = c_px_delay_max then
					s_px_delay <= 0;
				else
					s_px_delay <= s_px_delay + 1;
				end if;
			end if;
		end if;

	end process SET_PIXEL;

	RESET_PROC : process is
	begin

		reset <= '1';
		wait for clk_period * 2;
		reset <= '0';
		wait;

	end process RESET_PROC;

	TB_PROC : process is
	begin

		wait until o_px_m_axis_tlast = '1';

		wait until o_px_m_axis_tlast = '0';

		std.env.finish;

	end process TB_PROC;

end architecture bench;
