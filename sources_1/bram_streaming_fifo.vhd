library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

-- A streaming fifo that additionally blocks when reading data until valid data is available

entity bram_streaming_fifo is
	generic (
		vector_length : natural := 8;
		depth         : natural := 28
	);
	port (
		clk         : in std_logic;
		reset       : in std_logic;
		wr_en       : in std_logic;
		rd_en       : in std_logic;  -- note: as long as waiting is set, this signal is ignored
		full        : out std_logic;
		empty       : out std_logic;
		last_read   : out std_logic; -- is high for the last read before wrapping around
		waiting     : out std_logic; -- is true if we are waiting for data to be written
		dout_valid  : out std_logic; -- is only high when reading existing data or when writing data
		din         : in std_logic_vector(vector_length - 1 downto 0);
		dout        : out std_logic_vector(vector_length - 1 downto 0)
	);
end entity bram_streaming_fifo;

architecture rtl of bram_streaming_fifo is

	signal RAM : matrix_1d(0 to depth - 1)(vector_length - 1 downto 0);
	attribute ram_style : string;
	attribute ram_style of RAM : signal is "block";

	-- Read and write pointers to the memory
	signal s_read_pointer  : unsigned(integer(ceil(log2(real(depth)))) - 1 downto 0);     -- depth is enough for this pointer
	signal s_write_pointer : unsigned(integer(ceil(log2(real(depth + 1)))) - 1 downto 0); -- needs depth+1 because this will be equal to depth when fifo is full

	signal s_empty      : std_logic;
	signal s_full       : std_logic;
	signal s_waiting    : std_logic;
	signal s_dout_valid : std_logic;

	signal s_dout : std_logic_vector(vector_length - 1 downto 0);

begin

	s_empty   <= '1' when to_integer(s_write_pointer) = 0 else '0';
	s_full    <= '1' when to_integer(s_write_pointer) = depth else '0';

	empty       <= s_empty;
	full        <= s_full;
	waiting     <= s_waiting;
	dout_valid  <= s_dout_valid;

	dout <= s_dout;

	last_read   <= '1' when to_integer(s_read_pointer) = depth - 1 else '0';

	process (clk, reset) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_read_pointer  <= (others => '0');
				s_write_pointer <= (others => '0');
				s_dout          <= (others => '0');
				s_waiting       <= '0';
				s_dout_valid    <= '0';
			else
				s_dout_valid <= '0';
				if rd_en = '1' and s_waiting = '0' then -- we ignore any additional state changes if we are already waiting
					if std_logic_vector(s_read_pointer) ?= std_logic_vector(s_write_pointer) then
						if wr_en = '1' then
							-- okay we need to read data that is not available yet
							-- but as the data is currently written in this cycle we can just forward it
							s_dout <= din;
							s_dout_valid <= '1';
						else
							-- okay data is not available yet, we need to wait for it
							s_waiting <= '1';
						end if;
					else
						s_dout <= RAM(to_integer(s_read_pointer));
						s_dout_valid <= '1';
					end if;

					-- increment the read pointer even if we are waiting
					if s_read_pointer /= depth - 1 then
						s_read_pointer <= s_read_pointer + 1;
					else
						s_read_pointer <= (others => '0');
					end if;
				end if;
				if wr_en = '1' and (s_full = '0' or rd_en = '1') then
					if s_write_pointer /= depth then
						-- write to memory
						RAM(to_integer(s_write_pointer)) <= din;

						-- only increment write pointer if there is still space left
						s_write_pointer <= s_write_pointer + 1;
					
						if s_waiting = '1' then
							s_waiting <= '0';
							s_dout <= din;
							s_dout_valid <= '1';
						end if;
					end if;

					
				end if;
			end if;
		end if;

	end process;

end architecture rtl;
