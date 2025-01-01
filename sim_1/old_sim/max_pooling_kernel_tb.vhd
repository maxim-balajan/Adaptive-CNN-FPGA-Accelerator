
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;
use work.libmatrix.all;

entity max_pooling_kernel_tb is
end entity max_pooling_kernel_tb;

architecture bench of max_pooling_kernel_tb is

	-- Clock period
	constant clk_period : time := 5 ns;
	-- Generics
	constant number_width : natural := 8;
	constant width        : natural := 2;
	constant height       : natural := 2;
	constant kernel_size  : natural := 2;
	constant x            : natural := 0;
	constant y            : natural := 0;
	-- Ports
	signal clk      : std_logic := '1';
	signal reset    : std_logic;
	signal en       : std_logic;
	signal input    : matrix_2d(0 to width - 1)(0 to height - 1)(number_width - 1 downto 0);
	signal output   : std_logic_vector(number_width - 1 downto 0);
	signal finished : std_logic;

begin

	max_pooling_kernel_inst : entity work.max_pooling_kernel
		generic map (
			number_width => number_width,
			width        => width,
			height       => height,
			kernel_size  => kernel_size,
			x            => x,
			y            => y
		)
		port map (
			clk      => clk,
			reset    => reset,
			en       => en,
			input    => input,
			output   => output,
			finished => finished
		);

	clk   <= not clk after clk_period / 2;
	reset <= '1' after 0 ns, '0' after  1.5 * clk_period;
	en    <= '0' after 0 ns, '1' after 2 * clk_period;
	input <= (("00101011", "01101011"), ("11111111", "00001001")) after 0 ns;

	WAITFORRES : process is
	begin

		wait for 10 * clk_period;
		finish;

	end process WAITFORRES;

end architecture bench;
