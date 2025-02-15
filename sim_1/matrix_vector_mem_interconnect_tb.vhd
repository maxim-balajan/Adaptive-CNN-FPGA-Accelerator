library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;
use work.libmemory.all;
use work.libutil.all;
use std.env.finish;

entity matrix_vector_mem_interconnect_tb is
end entity matrix_vector_mem_interconnect_tb;

architecture bench of matrix_vector_mem_interconnect_tb is

	-- Clock period
	constant clk_period : time := 10 ns;
	-- Generics
	constant vector_length     : natural     := 8;
	constant max_weight_width  : natural     := 400;
	constant max_weight_height : natural     := 120;
	constant weight_widths     : int_list    := (400, 120, 84);
	constant weight_heights    : int_list    := (120, 84, 10);
	constant weight_paths      : string_list :=
	(
	  "../data/layer_weight_2.data",
	  "../data/layer_weight_3.data",
	  "../data/layer_weight_4.data"
	);
	-- Ports
	signal clk              : std_logic := '0';
	signal reset            : std_logic;
	signal bram_enable_line : std_logic_vector(0 to max_weight_height - 1);
	signal base_addr        : std_logic_vector(integer(ceil(log2(real(sum_int_list(weight_widths))))) - 1 downto 0);
	signal weights          : matrix_1d(0 to max_weight_height - 1)(vector_length - 1 downto 0);

begin

	matrix_vector_mem_interconnect_inst : entity work.matrix_vector_mem_interconnect
		generic map (
			vector_length     => vector_length,
			max_weight_width  => max_weight_width,
			max_weight_height => max_weight_height,
			weight_widths     => weight_widths,
			weight_heights    => weight_heights,
			weight_paths      => weight_paths
		)
		port map (
			clk              => clk,
			reset            => reset,
			bram_enable_line => bram_enable_line,
			base_addr        => base_addr,
			weights          => weights
		);

	clk              <= not clk after clk_period / 2;
	reset            <= '1' after 0 ns, '0' after 2 * clk_period;
	base_addr        <= (others => '0');
	bram_enable_line <= (others => '0');

	TB : process is
	begin

		wait for 20 * clk_period;
		finish;

	end process TB;

end architecture bench;
