library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity bram_fifo is
	generic (
		vector_length : natural := 8;
		depth         : natural := 28
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		wr_en : in std_logic;
		rd_en : in std_logic;
		full  : out std_logic;
		empty : out std_logic;
		din   : in std_logic_vector(vector_length - 1 downto 0);
		dout  : out std_logic_vector(vector_length - 1 downto 0)
	);
end entity bram_fifo;

architecture rtl of bram_fifo is

	signal RAM : matrix_1d(0 to depth - 1)(vector_length - 1 downto 0);
	attribute ram_style : string;
	attribute ram_style of RAM : signal is "block";

	-- Read and write pointers to the memory
	signal s_read_pointer  : unsigned(integer(ceil(log2(real(depth)))) - 1 downto 0);
	signal s_write_pointer : unsigned(integer(ceil(log2(real(depth)))) - 1 downto 0);

	signal s_empty : std_logic;
	signal s_full  : std_logic;

	signal s_last_write : std_logic;
	signal s_dout       : std_logic_vector(vector_length - 1 downto 0);

begin

	s_empty <= std_logic_vector(s_read_pointer) ?= std_logic_vector(s_write_pointer) and not s_last_write;
	s_full  <= std_logic_vector(s_read_pointer) ?= std_logic_vector(s_write_pointer) and s_last_write;

	empty <= s_empty;
	full  <= s_full;

	dout <= s_dout;

	process (clk, reset) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_read_pointer  <= (others => '0');
				s_write_pointer <= (others => '0');
				s_last_write    <= '0';
				s_dout          <= (others => '0');
			else
				-- Reset of last write value and put on it 0 for now
				s_last_write <= '0';
				if rd_en = '1' and s_empty = '0' then
					-- Read from memory
					s_dout <= RAM(to_integer(s_read_pointer));

					if s_read_pointer /= depth - 1 then
						s_read_pointer <= s_read_pointer + 1;
					else
						s_read_pointer <= (others => '0');
					end if;
				end if;
				if wr_en = '1' and (s_full = '0' or rd_en = '1') then
					s_last_write <= '1';
					-- Write to memory
					RAM(to_integer(s_write_pointer)) <= din;

					if s_write_pointer /= depth - 1 then
						s_write_pointer <= s_write_pointer + 1;
					else
						s_write_pointer <= (others => '0');
					end if;
				end if;
				-- If neither read nor wright was performed, hold old state and overwrite initial reset statement
				if not (rd_en = '1' and s_empty = '0') and not (wr_en = '1' and (s_full = '0' or rd_en = '1')) then
					s_last_write <= s_last_write;
				end if;
			end if;
		end if;

	end process;

end architecture rtl;
