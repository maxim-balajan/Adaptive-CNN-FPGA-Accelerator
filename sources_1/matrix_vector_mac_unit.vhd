library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity matrix_vector_mac_unit is
	generic (
		vector_length     : natural              := 8;
		enable_clip_adder : integer range 0 to 1 := 1
	);
	port (
		clk            : in std_logic;
		reset          : in std_logic;
		mac_en         : in std_logic;
		input_vector   : in std_logic_vector(vector_length - 1 downto 0);
		weight_vector  : in std_logic_vector(vector_length - 1 downto 0);
		partial_sum    : in std_logic_vector(3 * vector_length - 1 downto 0);
		mac_en_delay   : out std_logic;
		input_delay    : out std_logic_vector(vector_length - 1 downto 0);
		partial_result : out std_logic_vector(3 * vector_length - 1 downto 0)
	);
end entity matrix_vector_mac_unit;

architecture rtl of matrix_vector_mac_unit is

	signal s_mac_en      : std_logic;
	signal s_input       : signed(vector_length - 1 downto 0);
	signal s_weight      : signed(vector_length - 1 downto 0);
	signal s_partial_sum : signed(3 * vector_length - 1 downto 0);

	signal s_mul_result : signed(3 * vector_length - 1 downto 0);
	signal s_add_result : signed(3 * vector_length - 1 downto 0);
	-- This signal is for the clip adder
	signal s_tmp_add_result : std_logic_vector(3 * vector_length - 1 downto 0);

begin

	DELAY_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_mac_en      <= '0';
				s_input       <= (others => '0');
				s_weight      <= (others => '0');
				s_partial_sum <= (others => '0');
			else
				s_mac_en      <= mac_en;
				s_input       <= signed(input_vector);
				s_weight      <= signed(weight_vector);
				s_partial_sum <= signed(partial_sum);
			end if;
		end if;

	end process DELAY_PROC;

	-- Calculations of inputs; delayed by one cycle through DELAY_PROC
	-- weight_vector also delayed => BRAM needs enable signals one cycle earlier
	s_mul_result <= resize(signed(s_input) * signed(s_weight), s_mul_result'length);

	CLIP_GEN : if enable_clip_adder = 1 generate

		CLIP_ADDER_INST : entity work.clip_adder
			generic map (
				vector_length => s_tmp_add_result'length
			)
			port map (
				din0 => std_logic_vector(s_mul_result),
				din1 => std_logic_vector(s_partial_sum),
				dout => s_tmp_add_result
			);

	else generate
		s_tmp_add_result <= std_logic_vector(s_mul_result + s_partial_sum);
	end generate CLIP_GEN;

	-- result is only taken iff. s_mac_en = '1'
	s_add_result <= signed(s_tmp_add_result) when s_mac_en = '1' else s_partial_sum;

	-- Setting of output signals
	mac_en_delay   <= s_mac_en;
	partial_result <= std_logic_vector(s_add_result);
	input_delay    <= std_logic_vector(s_input);

end architecture rtl;
