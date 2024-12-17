
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;

entity bram_fifo_tb is
end;

architecture bench of bram_fifo_tb is
	-- Clock period
	constant clk_period : time := 10 ns;
	-- Generics
	constant vector_length : integer := 8;
	constant depth : integer := 5;
	-- Ports
	signal clk : std_logic := '0';
	signal reset : std_logic;
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
		depth => depth
	)
	port map (
		clk => clk,
		reset => reset,
		wr_en => wr_en,
		rd_en => rd_en,
		full => full,
		empty => empty,
		din => din,
		dout => dout
	);

	clk   <= not clk after clk_period / 2;
	reset <= '1' after 0 ns, '0' after 10 ns;
	wr_en <= '0' after 0 ns, '1' after 10 ns, '0' after 70 ns, '1' after 80 ns, '0' after 100 ns;
    rd_en <= '0' after 0 ns, '1' after 90 ns;

    process is 
    begin
        wait for 10 ns;
        din <= std_logic_vector(unsigned(din) + 1);
    end process;


	TB : process is
	begin

		wait for 200 ns;
		finish;

	end process TB;

end;