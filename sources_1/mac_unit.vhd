library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity mac_unit is
	generic (
		vector_length : integer := 8
	);
	port (
		clk            : in std_logic;
		reset          : in std_logic;
		input_vector   : in std_logic_vector(vector_length - 1 downto 0);
		weight_vector  : in std_logic_vector(vector_length - 1 downto 0);
		partial_sum    : in std_logic_vector(3 * vector_length - 1 downto 0);
		input_delay    : out std_logic_vector(vector_length - 1 downto 0);
		partial_result : out std_logic_vector(3 * vector_length - 1 downto 0)
	);
end entity mac_unit;

architecture rtl of mac_unit is

	signal s_input       : signed(vector_length - 1 downto 0);
	signal s_weight      : signed(vector_length - 1 downto 0);
	signal s_partial_sum : signed(3 * vector_length - 1 downto 0);

	signal s_mult_result : signed(2 * vector_length - 1 downto 0);
	signal s_add_result  : signed(3 * vector_length - 1 downto 0);

begin

	DELAY_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_input       <= (others => '0');
				s_weight      <= (others => '0');
				s_partial_sum <= (others => '0');
			else
				s_input       <= signed(input_vector);
				s_weight      <= signed(weight_vector);
				s_partial_sum <= signed(partial_sum);
			end if;
		end if;

	end process DELAY_PROC;

	-- Calculations of inputs; delayed by one cycle through DELAY_PROC
	s_mult_result <= s_input * s_weight;
	s_add_result  <= s_mult_result + signed(s_partial_sum);

	-- Setting of output signals
	partial_result <= std_logic_vector(s_add_result);
	input_delay    <= std_logic_vector(s_input);

end architecture rtl;
