library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity bram_streaming_fifo is
	generic (
		vector_length : natural := 8;
		depth         : natural := 28
	);
	port (
		clk         : in std_logic;
		reset       : in std_logic;
		wr_en       : in std_logic;
		rd_en       : in std_logic;
		full        : out std_logic;
		empty       : out std_logic;
		wrap_around : out std_logic;  -- is high for the last read before wrapping around
		din         : in std_logic_vector(vector_length - 1 downto 0);
		dout        : out std_logic_vector(vector_length - 1 downto 0)
	);
end entity bram_streaming_fifo;

architecture rtl of bram_streaming_fifo is

	signal RAM : matrix_1d(0 to depth - 1)(vector_length - 1 downto 0);
	attribute ram_style : string;
	attribute ram_style of RAM : signal is "block";

	-- Read and write pointers to the memory
	signal s_read_pointer  : unsigned(integer(ceil(log2(real(depth)))) - 1 downto 0);   -- depth is enough for this pointer
	signal s_write_pointer : unsigned(integer(ceil(log2(real(depth+1)))) - 1 downto 0); -- needs depth+1 because this will be equal to depth when fifo is full

	signal s_empty     : std_logic;
	signal s_full      : std_logic;
	signal s_last_read : std_logic;

	signal s_dout : std_logic_vector(vector_length - 1 downto 0);

begin

	s_empty <= '1' when to_integer(s_write_pointer) = 0 else '0';
	s_full  <= '1' when to_integer(s_write_pointer) = depth else '0';

	empty       <= s_empty;
	full        <= s_full;
	wrap_around <= s_last_read;

	dout <= s_dout;

	process (clk, reset) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_read_pointer  <= (others => '0');
				s_write_pointer <= (others => '0');
				s_dout          <= (others => '0');
			else
				if rd_en = '1' then
					-- Read from memory
					assert to_integer(s_read_pointer) <= to_integer(s_write_pointer)
						report "Tried to read more data than available."
						severity FAILURE;

					if std_logic_vector(s_read_pointer) ?= std_logic_vector(s_write_pointer) then
						-- okay we need to read data that is not available yet
						-- but if data is written in this cycle we can just forward it
						assert wr_en = '1'
							report "Tried to read more data than available. (Write read_addr=write_addr but wr_en='0')"
							severity FAILURE;

						s_dout <= din;
					else
						s_dout <= RAM(to_integer(s_read_pointer));
					end if;

					if s_read_pointer /= depth - 1 then
						s_read_pointer <= s_read_pointer + 1;
						s_last_read    <= '0';
					else
						s_read_pointer <= (others => '0');
						s_last_read    <= '1';
					end if;
				end if;
				if wr_en = '1' and (s_full = '0' or rd_en = '1') then
					if s_write_pointer /= depth then
						-- write to memory
						RAM(to_integer(s_write_pointer)) <= din;

						-- only increment write pointer if there is still space left
						s_write_pointer <= s_write_pointer + 1;
					else
						-- no space left, ignore write signal
						assert FALSE
							report "Tried to write to a full streaming fifo. Please reset this component instead."
							severity FAILURE;
					end if;
				end if;
			end if;
		end if;

	end process;

end architecture rtl;
