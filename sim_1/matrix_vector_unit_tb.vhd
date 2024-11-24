library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;
use std.env.finish;

entity matrix_vector_unit_tb is
end entity matrix_vector_unit_tb;

architecture bench of matrix_vector_unit_tb is

	-- Clock period
	constant clk_period : time := 5 ns;
	-- Generics
	constant weight_width  : integer := 1024;
	constant weight_height : integer := 800;
	constant vector_length : integer := 8;
	-- Ports
	signal clk              : std_logic := '1';
	signal reset            : std_logic;
	signal en               : std_logic;
	signal weights          : matrix_1d(0 to weight_height - 1)(vector_length - 1 downto 0);
	signal inputs           : matrix_1d(0 to weight_width - 1)(vector_length - 1 downto 0);
	signal bias             : std_logic_vector(vector_length - 1 downto 0);
	signal bram_enable_line : std_logic_vector(0 to weight_height);
	signal results          : matrix_1d(0 to weight_height - 1)(vector_length - 1 downto 0);
	signal comp_complete    : std_logic;

begin

	matrix_vector_unit_inst : entity work.matrix_vector_unit
		generic map (
			weight_width  => weight_width,
			weight_height => weight_height,
			vector_length => vector_length
		)
		port map (
			clk              => clk,
			reset            => reset,
			en               => en,
			weights          => weights,
			actual_weight_width => std_logic_vector(to_unsigned(4, integer(ceil(log2(real(weight_width)))) + 1)),
			actual_weight_heigth => std_logic_vector(to_unsigned(3, integer(ceil(log2(real(weight_height)))) + 1)),
			inputs           => inputs,
			bias             => bias,
			bram_enable_line => bram_enable_line,
			results          => results,
			comp_complete    => comp_complete
		);

	clk   <= not clk after clk_period / 2;
	reset <= '1' after 0 ns, '0' after 1.5 * clk_period;
	en    <= '1' after 0 ns, '0' after 3 * clk_period, '1' after 6 * clk_period;

	-- (5x3)
	-- weights <= (x"01", x"02", x"03", x"04", x"05") after 0 ns;
	-- inputs  <= (x"01", x"00", x"FE");
	-- bias    <= x"00" after 0 ns, x"02" after 3 * clk_period, x"03" after 4 * clk_period, x"04" after 5 * clk_period,
	--           x"05" after 6 * clk_period, x"06" after  7 * clk_period;

	-- (3x4)
	weights(0 to 2) <= (x"01", x"02", x"03") after 0 ns;
	weights(3 to weights'high) <= (others => (others => '0')) after 0 ns;
	inputs(0 to 3)  <= (x"01", x"00", x"FE", x"03") after 0 ns;
	inputs(4 to inputs'high) <= (others => (others => '0')) after 0 ns;
	bias    <= x"00" after 0 ns, x"02" after 3 * clk_period, x"03" after 4 * clk_period, x"04" after 5 * clk_period;

	TB : process is
	begin

		wait for 15 * clk_period;
		finish;

	end process TB;

end architecture bench;
