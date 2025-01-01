library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.libmatrix.all;
use std.env.finish;

entity sys_array_result_buffer_tb is
end entity sys_array_result_buffer_tb;

architecture bench of sys_array_result_buffer_tb is

	-- Clock period
	constant clk_period : time := 5 ns;
	-- Generics
	constant input_width   : integer := 6;
	constant vector_length : integer := 8;
	-- Ports
	signal clk           : std_logic := '1';
	signal reset         : std_logic;
	signal en            : std_logic;
	signal din           : std_logic_vector(3 * vector_length - 1 downto 0);
	signal buffer_full   : std_logic;
	signal result_buffer : matrix_1d(0 to input_width - 1)(vector_length - 1 downto 0);

begin

	sys_array_result_buffer_inst : entity work.sys_array_result_buffer
		generic map (
			input_width   => input_width,
			vector_length => vector_length
		)
		port map (
			clk           => clk,
			reset         => reset,
			en            => en,
			din           => din,
			buffer_full   => buffer_full,
			result_buffer => result_buffer
		);

	clk   <= not clk after clk_period / 2;
	reset <= '1' after 0 ns, '0' after  1.5 * clk_period;
	en    <= '1' after 0 ns, '0' after 4 * clk_period, '1' after 5 * clk_period;
	din   <= x"000001" after 0 ns, x"000002" after 3 * clk_period, x"000003" after 4 * clk_period,
	         x"000004" after 5 * clk_period, x"000005" after 6 * clk_period, x"000006" after 7 * clk_period,
	         x"000007" after 8 * clk_period, x"000008" after 9 * clk_period, x"000009" after 10 * clk_period;

	TB : process is
	begin

		wait for 10 * clk_period;
		finish;

	end process TB;

end architecture bench;
