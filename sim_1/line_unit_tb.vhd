
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;
use std.env.finish;

entity line_unit_tb is
end entity line_unit_tb;

architecture bench of line_unit_tb is

	-- Clock period
	constant clk_period : time := 5 ns;
	-- Generics
	constant vector_length     : natural := 16;
	constant G_IMG_MAX_LENGTH  : natural := 10;
	constant G_KERNEL_MAX_SIZE : natural := 6;
	-- Ports
	signal clk                  : std_logic                                    := '0';
	signal reset                : std_logic;
	signal set_line_buffer_full : std_logic;
	signal line_buffer_depth    : std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
	signal din, s_din           : std_logic_vector(vector_length - 1 downto 0) := (others => '0');
	signal en                   : std_logic;
	signal wr_en                : std_logic;
	signal pixel_window_line    : matrix_1d(0 to G_KERNEL_MAX_SIZE - 1)(vector_length - 1 downto 0);
	signal enable_window_line   : std_logic_vector(0 to G_KERNEL_MAX_SIZE - 1);

begin

	line_unit_inst : entity work.line_unit
		generic map (
			vector_length     => vector_length,
			G_IMG_MAX_LENGTH  => G_IMG_MAX_LENGTH,
			G_KERNEL_MAX_SIZE => G_KERNEL_MAX_SIZE
		)
		port map (
			clk                  => clk,
			reset                => reset,
			set_line_buffer_full => set_line_buffer_full,
			line_buffer_depth    => line_buffer_depth,
			din                  => din,
			en                   => en,
			wr_en                => wr_en,
			pixel_window_line    => pixel_window_line,
			enable_window_line   => enable_window_line
		);

	clk <= not clk after clk_period / 2;

	RST_PROC : process is
	begin

		reset                <= '1';
		set_line_buffer_full <= '0';
		line_buffer_depth    <= STD_LOGIC_VECTOR(to_unsigned(3, line_buffer_depth'length));
		wait for 2 * clk_period;
		reset                <= '0';
		wr_en                <= '1';
		wait for 50 * clk_period;
		reset                <= '1';
		set_line_buffer_full <= '1';
		line_buffer_depth    <= STD_LOGIC_VECTOR(to_unsigned(3, line_buffer_depth'length));
		wait for 1 * clk_period;
		reset                <= '0';
		wr_en                <= '1';
		wait for 50 * clk_period;

	end process RST_PROC;

	DIN_PROC : process is
	begin

		din   <= (others => '1');
		en    <= '0';
		wait for 2 * clk_period;
		s_din <= STD_LOGIC_VECTOR(unsigned(s_din) + 1);
		en    <= '1';
		din   <= STD_LOGIC_VECTOR(unsigned(s_din) + 1);
		wait for clk_period;

	end process DIN_PROC;

	TB : process is
	begin

		wait for 220 * clk_period;
		finish;

	end process TB;

end architecture bench;
