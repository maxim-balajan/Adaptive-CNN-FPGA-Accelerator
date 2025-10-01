library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity temp_layer_accumulator_tb is
end entity temp_layer_accumulator_tb;

architecture bench of temp_layer_accumulator_tb is

	-- Clock period
	constant clk_period : time := 5 ns;
	-- Generics
	constant g_vector_length         : natural := 24;
	constant g_clipped_vector_length : natural := 8;
	constant g_max_fifo_depth        : natural := 27 ** 2;
	constant g_oc_amount             : natural := 5;
	-- Ports
	signal clk               : std_logic := '1';
	signal reset             : std_logic;
	signal i_en              : std_logic := '0';
	signal i_kernel_complete : std_logic;
	signal i_kernel_valid    : std_logic;
	signal i_pixel_line, s_pixel_line      : matrix_1d(0 to g_oc_amount - 1)(g_vector_length - 1 downto 0);
	signal i_pixel_amount    : std_logic_vector(integer(ceil(log2(real(g_max_fifo_depth)))) - 1 downto 0);
	signal i_oc_size         : std_logic_vector(15 downto 0);
	signal i_enable_relu     : std_logic;
	signal i_shamt           : std_logic_vector(g_vector_length - 1 downto 0);
	signal o_kernel_complete : std_logic;
	signal o_kernel_valid    : std_logic;
	signal o_pixel_line      : matrix_1d(0 to g_oc_amount - 1)(g_clipped_vector_length - 1 downto 0);

begin

	temp_layer_accumulator_inst : entity work.temp_layer_accumulator
		generic map (
			g_vector_length         => g_vector_length,
			g_clipped_vector_length => g_clipped_vector_length,
			g_max_fifo_depth        => g_max_fifo_depth,
			g_oc_amount             => g_oc_amount
		)
		port map (
			clk   => clk,
			reset => reset,
			--
			i_en => i_en,
			--
			i_kernel_complete => i_kernel_complete,
			i_kernel_valid    => i_kernel_valid,
			i_pixel_line      => i_pixel_line,
			--
			i_pixel_amount => i_pixel_amount,
			i_oc_size      => i_oc_size,
			i_enable_relu  => i_enable_relu,
			i_shamt        => i_shamt,
			--
			o_kernel_complete => o_kernel_complete,
			o_kernel_valid    => o_kernel_valid,
			o_pixel_line      => o_pixel_line
		);

	clk <= not clk after clk_period / 2;

	RESET_PROC : process is
	begin

		reset <= '1';
		-- half end-result
		i_shamt(1 downto 0)                   <= "01";
		i_shamt(g_vector_length - 1 downto 2) <= (others => '0');
		i_enable_relu                         <= '1';
		-- 4 pixel per iteration
		i_pixel_amount(2 downto 0)                   <= "100";
		i_pixel_amount(i_pixel_amount'high downto 3) <= (others => '0');
		-- 4 output channels, meaning 4 iterations
		i_oc_size <= x"0004";
		wait for 2 * clk_period;
		reset     <= '0';
		wait;

	end process RESET_PROC;

	i_en <= not i_en after clk_period;

	PIXEL_PROC : process is
	begin

		i_kernel_complete <= '0';
		i_kernel_valid    <= '0';

		for i in s_pixel_line'range loop

			s_pixel_line(i) <= std_logic_vector(to_signed(i + 1, s_pixel_line(i)'length));

		end loop;

		wait for 0 ns;

		i_pixel_line <= s_pixel_line;

		wait for 2 * clk_period;

		for l in 0 to 3 loop

			--for en_count in 0 to 2 loop

			--	i_en <= '1' when en_count = 1 else '0';

				for k in 0 to 3 loop

					wait until rising_edge(i_en);
					i_kernel_complete <= '0';
					i_kernel_valid    <= '1';
					wait until rising_edge(i_en);
					wait for clk_period;

					i_kernel_complete <= '1' when k = 3 and l = 3 else '0';
					i_kernel_valid    <= '0';
					i_pixel_line      <= (others => (others => '1'));
					wait for clk_period;

					for i in s_pixel_line'range loop

						s_pixel_line(i) <= std_logic_vector(signed(s_pixel_line(i)) + 1);

					end loop;

					wait for 0 ns;

					i_pixel_line <= s_pixel_line;

				end loop;

			--end loop;

			--wait for clk_period;

		end loop;

		--i_en <= '1';

		-- i_kernel_complete <= '1';

		wait;

	end process PIXEL_PROC;

	TB_PROC : process is
	begin

		wait until rising_edge(o_kernel_complete);
		wait until rising_edge(clk);
		wait until rising_edge(clk);

		std.env.finish;

	end process TB_PROC;

end architecture bench;
