library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;

entity sys_array_control_unit_tb is
end entity sys_array_control_unit_tb;

architecture bench of sys_array_control_unit_tb is

	-- Clock period
	constant clk_period : time := 5 ns;
	-- Generics
	constant weight_width  : integer := 4;
	constant weight_height : integer := 5;
	constant input_width   : integer := 6;
	-- Ports
	signal clk         : std_logic := '1';
	signal reset       : std_logic;
	signal enable_bits : std_logic_vector(maximum(weight_width, weight_height) - 1 downto 0);

begin

	sys_array_control_unit_inst : entity work.sys_array_control_unit
		generic map (
			weight_width  => weight_width,
			weight_height => weight_height,
			input_width   => input_width
		)
		port map (
			clk         => clk,
			reset       => reset,
			enable_bits => enable_bits
		);

	clk   <= not clk after clk_period / 2;
	reset <= '1' after 0 ns, '0' after 1.5 * clk_period;

	TB : process is
	begin

		wait for 13 * clk_period;
		finish;

	end process TB;

end architecture bench;
