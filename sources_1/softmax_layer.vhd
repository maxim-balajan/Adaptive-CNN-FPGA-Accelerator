library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity softmax_layer is
	generic (
		vector_length : natural := 8;
		input_amount  : natural;
		index_length  : natural
	);
	port (
		clk           : in std_logic;
		reset         : in std_logic;
		en            : in std_logic;
		input_values  : in matrix_1d(0 to input_amount - 1)(vector_length - 1 downto 0);
		input_indices : in matrix_1d(0 to input_amount - 1)(index_length - 1 downto 0);
		max_values    : out matrix_1d(0 to integer(ceil(real(input_amount) / 2.0)) - 1)(vector_length - 1 downto 0);
		max_indices   : out matrix_1d(0 to integer(ceil(real(input_amount) / 2.0)) - 1)(index_length - 1 downto 0);
		comp_complete : out std_logic
	);
end entity softmax_layer;

architecture rtl of softmax_layer is

	-- Increase s_input_{values | indices} size by 1 in order to deal with uneven vector lengths correctly and to make HW more maintainable
	signal s_input_values  : matrix_1d(0 to input_amount)(vector_length - 1 downto 0);
	signal s_input_indices : matrix_1d(0 to input_amount)(index_length - 1 downto 0);
	signal s_max_values    : matrix_1d(0 to integer(ceil(real(input_amount) / 2.0)) - 1)(vector_length - 1 downto 0);
	signal s_max_indices   : matrix_1d(0 to integer(ceil(real(input_amount) / 2.0)) - 1)(index_length - 1 downto 0);
	signal s_comp_complete : std_logic;

begin

	DELAY_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then

				for i in s_input_values'range loop

					s_input_values(i)                         <= (others => '0');
					s_input_values(i)(s_input_values(i)'high) <= '1'; -- store INT_MIN as default value

				end loop;

				s_input_indices <= (others => (others => '0'));
				s_comp_complete <= '0';
			else
				s_input_values(input_values'range)   <= input_values;
				s_input_indices(input_indices'range) <= input_indices;

				s_comp_complete <= en;
			end if;
		end if;

	end process DELAY_PROC;

	MAP_GEN : for i in s_max_values'range generate

		s_max_values(i) <= s_input_values(2 * i) when signed(s_input_values(2 * i)) >= signed(s_input_values(2 * i + 1)) else
	                   s_input_values(2 * i + 1);

		s_max_indices(i) <= s_input_indices(2 * i) when signed(s_input_values(2 * i)) >= signed(s_input_values(2 * i + 1)) else
	                    s_input_indices(2 * i + 1);

	end generate MAP_GEN;

	-- Set outputs
	max_values    <= s_max_values;
	max_indices   <= s_max_indices;
	comp_complete <= s_comp_complete;

end architecture rtl;
