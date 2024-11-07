library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity sys_array_result_buffer is
	generic (
		input_width   : integer := 1;
		vector_length : integer := 8
	);
	port (
		clk           : in std_logic;
		reset         : in std_logic;
		en            : in std_logic;
		din           : in std_logic_vector(3 * vector_length - 1 downto 0);
		result_buffer : out matrix_1d(input_width)(vector_length - 1 downto 0)
	);
end entity sys_array_result_buffer;

architecture rtl of sys_array_result_buffer is

	signal s_buffer   : matrix_1d(0 to input_width - 1)(vector_length - 1 downto 0);
	signal s_write_id : unsigned(integer(ceil(log2(real(input_width)))) downto 0);

begin

	WRITE_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_buffer   <= (others => (others => '0'));
				s_write_id <= (others => '0');
			else
				if en = '1' then
					s_buffer(to_integer(s_write_id)) <= din(7 downto 0);
					-- this is necessary to prevent out of bounds indexing
					if to_integer(s_write_id) = input_width - 1 then
						s_write_id <= (others => '0');
					else
						s_write_id <= s_write_id + 1;
					end if;
				end if;
			end if;
		end if;

	end process WRITE_PROC;

	result_buffer <= s_buffer;

end architecture rtl;
