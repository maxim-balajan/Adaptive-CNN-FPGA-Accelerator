library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity line_buffer is
	generic (
		vector_length : integer := 8;
		depth         : integer := 32
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		wr_en : in std_logic;
		full  : out std_logic; -- this signal is necessary in order to start writing to next line_bufers
		din   : in std_logic_vector(vector_length - 1 downto 0);
		dout  : out std_logic_vector(vector_length - 1 downto 0)
	);
end entity line_buffer;

architecture rtl of line_buffer is

	signal s_rd_en : std_logic;

begin

    full <= s_rd_en;

	FIFO_INST : entity work.bram_fifo
		generic map (
			vector_length => vector_length,
			depth         => depth
		)
		port map (
			clk   => clk,
			reset => reset,
			wr_en => wr_en,
			rd_en => s_rd_en,
			full  => s_rd_en,
			empty => open,
			din   => din,
			dout  => dout
		);

end architecture rtl;
