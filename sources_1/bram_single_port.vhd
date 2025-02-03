library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use ieee.math_real.all;

use work.libmatrix.all;
use work.libmemory.all;

entity bram_single_port is
	generic (
		vector_length : natural := 8;
		depth         : natural;
		data          : matrix_1d
	);
	port (
		clk   : in std_logic;
		rd_en : in std_logic;
		wr_en : in std_logic;
		addr  : in std_logic_vector(integer(ceil(log2(real(depth)))) - 1 downto 0);
		din   : in std_logic_vector(vector_length - 1 downto 0);
		dout  : out std_logic_vector(vector_length - 1 downto 0)
	);
end entity bram_single_port;

architecture behavioral of bram_single_port is

	shared variable RAM : matrix_1d(0 to depth - 1)(vector_length - 1 downto 0) := data;

begin

	-- Definition r port
	PORT_R : process (clk) is
	begin

		if rising_edge(clk) then
			if rd_en = '1' then
				if wr_en = '1' then
					RAM(to_integer(unsigned(addr))) := din;
				end if;
				dout <= RAM(to_integer(unsigned(addr)));
			end if;
		end if;

	end process PORT_R;

end architecture behavioral;
