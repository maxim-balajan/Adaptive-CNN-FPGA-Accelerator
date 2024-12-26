library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.libmatrix.all;
use std.env.finish;

entity kernel_slider_tb is
end entity kernel_slider_tb;

architecture bench of kernel_slider_tb is

	-- Clock period
	constant clk_period : time := 10 ns;
	-- Generics
	constant vector_length : integer := 8;
	constant input_width   : integer := 10;
	constant input_height  : integer := 10;
	constant kernel_size   : integer := 5;
	-- Ports
	signal clk                      : std_logic := '0';
	signal reset                    : std_logic;
	signal input_matrix             : matrix_2d(0 to input_width - 1)(0 to input_height - 1)(vector_length - 1 downto 0);
	signal kernel_comp              : std_logic;
	signal kernel_en                : std_logic;
	signal kernel_activation_matrix : matrix_2d(0 to kernel_size - 1)(0 to kernel_size - 1)(vector_length - 1 downto 0);

begin

	kernel_slider_inst : entity work.kernel_slider
		generic map (
			vector_length => vector_length,
			input_width   => input_width,
			input_height  => input_height,
			kernel_size   => kernel_size
		)
		port map (
			clk                      => clk,
			reset                    => reset,
			input_matrix             => input_matrix,
			kernel_complete          => kernel_comp,
			kernel_en                => kernel_en,
			kernel_activation_matrix => kernel_activation_matrix
		);

	clk   <= not clk after clk_period / 2;
	reset <= '1' after 0 ns, '0' after 10 ns;

	x : for j in 0 to input_height - 1 generate

		y : for i in 0 to input_width - 1 generate
			input_matrix(i)(j) <= std_logic_vector(to_unsigned(i + input_width * j + 1, input_matrix(i)(j)'length));
		end generate y;

	end generate x;

	TB : process is
	begin

		wait for 300 * clk_period;
		finish;

	end process TB;

end architecture bench;
