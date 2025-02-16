
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

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
    input <= (others => (others => '0')) after 0 ns, 
             (0 => "10101101", 1 => "00101010", 2 => "01101010", 3 => "00000000", 4 => "11011010", 5 => "00001010", 6 => "00010000", 7 => "10101010", 8 => "0100000", 9 => "00101010") after 2 * clk_period;
    en <= '0' after ns, '1' after 3 * clk_period;

end architecture bench;
