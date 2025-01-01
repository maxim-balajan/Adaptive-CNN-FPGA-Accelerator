library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.libmatrix.all;
use std.env.finish;

entity sys_array_tb is
end entity sys_array_tb;

architecture bench of sys_array_tb is

	-- Clock period
	constant clk_period : time := 5 ns;
	-- Generics
	constant weight_width  : integer := 4;
	constant weight_height : integer := 3;
	constant input_width   : integer := 3;
	constant vector_length : integer := 8;
	-- Ports
	signal clk           : std_logic := '1';
	signal reset         : std_logic;
	signal weights       : matrix_2d(0 to weight_width - 1)(0 to weight_height - 1)(vector_length - 1 downto 0);
	signal inputs        : matrix_2d(0 to input_width - 1)(0 to weight_width - 1)(vector_length - 1 downto 0);
	signal results       : matrix_2d(0 to input_width - 1)(0 to weight_height - 1)(vector_length - 1 downto 0);
	signal comp_complete : std_logic;

begin

	sys_array_inst : entity work.sys_array
		generic map (
			weight_width  => weight_width,
			weight_height => weight_height,
			input_width   => input_width,
			vector_length => vector_length
		)
		port map (
			clk           => clk,
			reset         => reset,
			weights       => weights,
			inputs        => inputs,
			results       => results,
			comp_complete => comp_complete
		);

	clk   <= not clk after clk_period / 2;
	reset <= '1' after 0 ns, '0' after 1.5 * clk_period;

	weights <= ((x"01", x"00", x"01"), (x"02", x"FF", x"00"), (x"03", x"00", x"01"), (x"04", x"FE", x"01")) after 0 ns;
	inputs  <= ((x"01", x"FF", x"00", x"01"), (x"00", x"02", x"00", x"04"), (x"01", x"01", x"01", x"01")) after 0 ns;

	TB : process is
	begin

		wait for 15 * clk_period;
		finish;

	end process TB;

end architecture bench;
