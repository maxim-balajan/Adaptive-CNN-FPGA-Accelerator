library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.env.finish;

entity line_buffer_tb is
end entity line_buffer_tb;

architecture bench of line_buffer_tb is

	-- Clock period
	constant clk_period : time := 10 ns;
	-- Generics
	constant vector_length : integer := 8;
	constant depth         : integer := 10;
	-- Ports
	signal clk   : std_logic := '0';
	signal reset : std_logic;
	signal set_full : std_logic;

	signal actual_depth : std_logic_vector(integer(ceil(log2(real(depth)))) - 1 downto 0);
	signal wr_en : std_logic;
	signal full, full_read_and_write  : std_logic;
	signal din   : std_logic_vector(vector_length - 1 downto 0) := (others => '0');
	signal dout  : std_logic_vector(vector_length - 1 downto 0);

begin

	line_buffer_inst : entity work.line_buffer
		generic map (
			vector_length => vector_length,
			G_MAX_DEPTH => depth
		)
		port map (
			clk   => clk,
			reset => reset,
			set_full => set_full,
			depth => actual_depth,
			en    => '1',
			wr_en => wr_en,
			full  => full,
			full_read_and_write => full_read_and_write,
			din   => din,
			dout  => dout
		);

	clk   <= not clk after clk_period / 2;

	process
	begin
		reset <= '1';
		set_full <= '0';
		actual_depth <= std_logic_vector(to_unsigned(3, actual_depth'length));
		wait for clk_period;
		reset <= '0';
		--din <= std_logic_vector(unsigned(din) + 1);
		wr_en <= '1';
		wait for 3 * clk_period;
		reset <= '1';
		set_full <= '1';
		actual_depth <= std_logic_vector(to_unsigned(5, actual_depth'length));
		wait for clk_period;
		reset <= '0';
		wait for 6 * clk_period;
	end process;

	process
	begin
		din <= std_logic_vector(unsigned(din) + 1);
		wait for clk_period;
	end process;

	TB : process is
	begin

		wait for 12 * clk_period;
		finish;

	end process TB;

end architecture bench;
