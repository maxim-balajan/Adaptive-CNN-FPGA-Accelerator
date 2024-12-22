library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use STD.TEXTIO.all;
use work.libmatrix.all;

entity bram_single_port is
	generic (
		vector_length : integer := 8;
		depth         : integer := 25;
		data_path     : string  := "../data/test.data"
	);
	port (
		clk   : in std_logic;
		rd_en : in std_logic;
		wr_en : in std_logic;
		addr  : in std_logic_vector(depth - 1 downto 0);
		din   : in std_logic_vector(vector_length - 1 downto 0);
		dout  : out std_logic_vector(vector_length - 1 downto 0)
	);
end entity bram_single_port;

architecture behavioral of bram_single_port is

	impure function init_from_file (
		file_name: in string
	) return matrix_1d is

		file     mem_file  : text open read_mode is file_name;
		variable file_line : line;
		variable tmp_ram   : matrix_1d(0 to depth - 1)(vector_length - 1 downto 0);

	begin

		for i in tmp_ram'range loop

			readline(mem_file, file_line);
			hread(file_line, tmp_ram(i));

		end loop;

		return tmp_ram;

	end function init_from_file;

	shared variable RAM : matrix_1d(0 to depth - 1)(vector_length - 1 downto 0) := init_from_file(data_path);

begin

	-- Definition r port
	PORT_R : process (clk) is
	begin

		if rising_edge(clk) then
			if rd_en = '1' then
				if wr_en = '1' then
					RAM(to_integer(unsigned(addr))) := din;
				else
					dout <= RAM(to_integer(unsigned(addr)));
				end if;
			end if;
		end if;

	end process PORT_R;

end architecture behavioral;
