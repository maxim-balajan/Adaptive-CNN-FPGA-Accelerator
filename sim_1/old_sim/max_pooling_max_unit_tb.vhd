
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;

entity max_pooling_max_unit_tb is
end entity max_pooling_max_unit_tb;

architecture bench of max_pooling_max_unit_tb is

	-- Clock period
	constant clk_period : time := 5 ns;
	-- Generics
	constant number_width : natural := 8;
	-- Ports
	signal clk       : std_logic := '1';
	signal reset     : std_logic;
	signal input1_en : std_logic;
	signal input2_en : std_logic;
	signal input1    : std_logic_vector(number_width - 1 downto 0);
	signal input2    : std_logic_vector(number_width - 1 downto 0);
	signal output    : std_logic_vector(number_width - 1 downto 0);
	signal finished  : std_logic;

begin

	max_pooling_max_unit_inst : entity work.max_pooling_max_unit
		generic map (
			number_width => number_width
		)
		port map (
			clk       => clk,
			reset     => reset,
			input1_en => input1_en,
			input2_en => input2_en,
			input1    => input1,
			input2    => input2,
			output    => output,
			finished  => finished
		);

	clk       <= not clk after clk_period / 2;
	reset     <= '1' after 0 ns, '0' after  1.5 * clk_period;
	input1_en <= '0' after 0 ns, '1' after 2 * clk_period;
	input2_en <= '0' after 0 ns, '1' after 2.5 * clk_period, '0' after 6 * clk_period;
	input1    <= "01101001" after 0 ns, "00001111" after 4 * clk_period, "10010110" after 5 * clk_period;
	input2    <= "00111111" after 0 ns, "00000000" after 4 * clk_period, "00101010" after 5 * clk_period;

	WAITFORRES : process is
	begin

		wait for 10 * clk_period;
		finish;

	end process WAITFORRES;

end architecture bench;
