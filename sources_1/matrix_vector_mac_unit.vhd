library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity matrix_vector_mac_unit is
	generic (
		vector_length : natural := 8
	);
	port (
		clk            : in std_logic;
		reset          : in std_logic;
		mac_en         : in std_logic;
		bias_en        : in std_logic;
		input_vector   : in std_logic_vector(vector_length - 1 downto 0);
		weight_vector  : in std_logic_vector(vector_length - 1 downto 0);
		bias_vector    : in std_logic_vector(3 * vector_length - 1 downto 0);
		partial_sum    : in std_logic_vector(3 * vector_length - 1 downto 0);
		mac_en_delay   : out std_logic;
		input_delay    : out std_logic_vector(vector_length - 1 downto 0);
		partial_result : out std_logic_vector(3 * vector_length - 1 downto 0)
	);
end entity matrix_vector_mac_unit;

architecture rtl of matrix_vector_mac_unit is

	signal s_mac_en      : std_logic;
	signal s_bias_en     : std_logic;
	signal s_input       : signed(vector_length - 1 downto 0);
	signal s_partial_sum : signed(3 * vector_length - 1 downto 0);

	signal s_mult_result      : signed(2 * vector_length - 1 downto 0);
	signal s_add_result       : signed(3 * vector_length - 1 downto 0);
	signal s_add_extra_result : signed(3 * vector_length - 1 downto 0);

begin

	DELAY_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_mac_en      <= '0';
				s_bias_en     <= '0';
				s_input       <= (others => '0');
				s_partial_sum <= (others => '0');
			else
				s_mac_en      <= mac_en;
				s_bias_en     <= bias_en;
				s_input       <= signed(input_vector);
				s_partial_sum <= signed(partial_sum);
			end if;
		end if;

	end process DELAY_PROC;

	-- Calculations of inputs; delayed by one cycle through DELAY_PROC
	-- weight_vector and bias_vector are implicitly delayed by the BRAM, so no extra delay is needed
	s_mult_result      <= s_input * signed(weight_vector);
	s_add_result       <= s_mult_result + signed(s_partial_sum) when s_mac_en = '1' else signed(s_partial_sum);
	s_add_extra_result <= s_add_result + signed(bias_vector) when s_bias_en = '1' else s_add_result;

	-- Setting of output signals
	mac_en_delay   <= s_mac_en;
	partial_result <= std_logic_vector(s_add_extra_result);
	input_delay    <= std_logic_vector(s_input);

end architecture rtl;
