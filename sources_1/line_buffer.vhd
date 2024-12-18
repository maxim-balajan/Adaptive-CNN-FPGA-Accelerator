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
		clk                 : in std_logic;
		reset               : in std_logic;
		wr_en               : in std_logic;
		full                : out std_logic; -- this signal can be omitted but is here for legacy purposes
		full_read_and_write : out std_logic; -- this signal is necessary in order to start writing to next line_bufers
		din                 : in std_logic_vector(vector_length - 1 downto 0);
		dout                : out std_logic_vector(vector_length - 1 downto 0)
	);
end entity line_buffer;

architecture rtl of line_buffer is

	signal s_rd_en : std_logic;

begin

	full <= s_rd_en;

	-- this process is neccessary to delay next write signal for upcoming line_buffer
	process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				full_read_and_write <= '0';
			else
				full_read_and_write <= full and wr_en;
			end if;
		end if;

	end process;

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
