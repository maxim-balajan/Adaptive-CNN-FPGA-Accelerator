
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.env.finish;

entity bram_fifo_tb is
end;

architecture bench of bram_fifo_tb is
	-- Clock period
	constant clk_period : time := 10 ns;
	-- Generics
	constant vector_length : integer := 8;
	constant depth : integer := 10;
	-- Ports
	signal clk : std_logic := '0';
	signal reset : std_logic;
	signal set_full : std_logic;
	signal actual_depth 	 : std_logic_vector(integer(ceil(log2(real(depth)))) - 1 downto 0);
	signal wr_en : std_logic;
	signal rd_en : std_logic;
	signal full : std_logic;
	signal empty : std_logic;
	signal din : std_logic_vector(vector_length - 1 downto 0) := (others => '0');
	signal dout : std_logic_vector(vector_length - 1 downto 0);
begin

	bram_fifo_inst : entity work.bram_fifo
	generic map (
		vector_length => vector_length,
		G_MAX_DEPTH => depth
	)
	port map (
		clk => clk,
		reset => reset,
		set_full => set_full,
		depth => actual_depth,
		wr_en => wr_en,
		rd_en => rd_en,
		full => full,
		empty => empty,
		din => din,
		dout => dout
	);

	process is
	begin
		reset <= '1';
		set_full <= '0';
		actual_depth <= std_logic_vector(to_unsigned(3, actual_depth'length));
		wait for clk_period;
		reset <= '0';
		wait for 5 * clk_period;
		set_full <= '1';
		reset <= '1';
		actual_depth <= std_logic_vector(to_unsigned(5, actual_depth'length));
		wait for clk_period;
		reset <= '0';
		wait for 10 * clk_period;

	end process;

	clk   <= not clk after clk_period / 2;
	--reset <= '1' after 0 ns, '0' after 10 ns;
	wr_en <= '0' after 0 ns, '1' after 10 ns, '0' after 70 ns, '1' after 80 ns, '0' after 100 ns;
    rd_en <= '0' after 0 ns, '1' after 4 * clk_period, '0' after 6 * clk_period, '1' after 9 * clk_period;

    process is 
    begin
        wait for clk_period;
        din <= std_logic_vector(unsigned(din) + 1);
    end process;


	TB : process is
	begin

		wait for 200 ns;
		finish;

	end process TB;

end;