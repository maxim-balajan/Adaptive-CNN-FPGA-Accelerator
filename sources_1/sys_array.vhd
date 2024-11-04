library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.libmatrix.all;

entity sys_array is
	generic (
		weight_width  : integer := 4;
		weight_height : integer := 3;
		input_width   : integer := 1;
		vector_length : integer := 8
	);
	port (
		clk           : in std_logic;
		reset         : in std_logic;
		weights       : in matrix_2d(0 to weight_width - 1, 0 to weight_height - 1)(vector_length - 1 downto 0);
		inputs        : in matrix_2d(0 to input_width - 1, 0 to weight_width - 1)(vector_length - 1 downto 0);
		results       : out matrix_2d(0 to input_width - 1, 0 to weight_height - 1)(vector_length - 1 downto 0);
		comp_complete : out std_logic
	);
end entity sys_array;

architecture rtl of sys_array is

	signal s_results : matrix_2d(0 to input_width - 1, 0 to weight_height - 1)(vector_length - 1 downto 0);
-- signal s_control_register : unsigned();

begin

	COMB_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_results <= (others => (others => (others => '0')));
				-- s_step    <= (others => '0');
				comp_complete <= '0';
			else
			end if;
		end if;

	end process COMB_PROC;

end architecture rtl;
