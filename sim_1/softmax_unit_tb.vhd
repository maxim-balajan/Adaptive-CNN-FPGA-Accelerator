library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;
use std.env.finish;

entity softmax_unit_tb is
end entity softmax_unit_tb;

architecture bench of softmax_unit_tb is

	-- Clock period
	constant clk_period : time := 5 ns;
	-- Generics
	constant input_length : natural := 8;
	constant input_amount : natural := 10;
	-- Ports
	signal clk           : std_logic := '0';
	signal reset         : std_logic;
	signal en            : std_logic;
	signal input         : matrix_1d(0 to input_amount - 1)(input_length - 1 downto 0);
	signal max_index     : std_logic_vector(integer(ceil(log2(real(input_amount)))) - 1 downto 0);
	signal comp_complete : std_logic;

begin

	softmax_unit_inst : entity work.softmax_unit
		generic map (
			input_length => input_length,
			input_amount => input_amount
		)
		port map (
			clk           => clk,
			reset         => reset,
			en            => en,
			input         => input,
			max_index     => max_index,
			comp_complete => comp_complete
		);

	clk   <= not clk after clk_period / 2;
	reset <= '1' after 0 ns, '0' after 2 * clk_period;
	input <= ("10101101", "10101010", "11101010", "10000000", "11011010", "10001010", "10010000", "10101010", "11000000", "10110101");
	en    <= '1';

	TB : process is
	begin

		wait for 10 * clk_period;
		finish;

	end process TB;

end architecture bench;
