library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity line_buffer is
	generic (
		vector_length : natural := 8;
		G_MAX_DEPTH   : natural := 227
	);
	port (
		clk                 : in std_logic;
		reset               : in std_logic;
		set_full			: in std_logic;
		depth 	 			: in std_logic_vector(integer(ceil(log2(real(G_MAX_DEPTH)))) - 1 downto 0);
		--
		din                 : in std_logic_vector(vector_length - 1 downto 0);
		en                  : in std_logic;
		wr_en               : in std_logic;
		--
		dout                : out std_logic_vector(vector_length - 1 downto 0);
		full                : out std_logic; -- this signal can be omitted but is here for legacy purposes
		full_read_and_write : out std_logic  -- this signal is necessary in order to start writing to next line_bufers
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
			elsif en = '1' then
				full_read_and_write <= full and wr_en;
			end if;
		end if;

	end process;

	FIFO_INST : entity work.bram_fifo
		generic map (
			vector_length => vector_length,
			G_MAX_DEPTH => G_MAX_DEPTH
		)
		port map (
			clk   => clk,
			reset => reset,
			set_full => set_full,
			depth => depth,
			wr_en => wr_en and en,
			rd_en => s_rd_en and en,
			full  => s_rd_en,
			empty => open,
			din   => din,
			dout  => dout
		);

end architecture rtl;
