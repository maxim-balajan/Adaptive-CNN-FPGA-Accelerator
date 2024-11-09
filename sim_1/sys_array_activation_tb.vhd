library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.libmatrix.all;
use std.env.finish;

entity sys_array_activation_buffer_tb is
end entity sys_array_activation_buffer_tb;

architecture bench of sys_array_activation_buffer_tb is

	-- Clock period
	constant clk_period : time := 5 ns;
	-- Generics
	constant input_width   : integer := 6;
	constant vector_length : integer := 8;
	-- Ports
	signal clk               : std_logic := '1';
	signal reset             : std_logic;
	signal en                : std_logic;
	signal din               : matrix_1d(0 to input_width - 1)(vector_length - 1 downto 0);
	signal result_activation : std_logic_vector(vector_length - 1 downto 0);

begin

	sys_array_activation_buffer_inst : entity work.sys_array_activation_buffer
		generic map (
			input_width   => input_width,
			vector_length => vector_length
		)
		port map (
			clk               => clk,
			reset             => reset,
			en                => en,
			din               => din,
			result_activation => result_activation
		);

	clk   <= not clk after clk_period / 2;
	reset <= '1' after 0 ns, '0' after  1.5 * clk_period;
	en    <= '1' after 0 ns, '0' after 4 * clk_period, '1' after 5 * clk_period;
	din   <= (x"01", x"02", x"03", x"04", x"05", x"06") after 0 ns;

	TB : process is
	begin

		wait for 10 * clk_period;
		finish;

	end process TB;

end architecture bench;
