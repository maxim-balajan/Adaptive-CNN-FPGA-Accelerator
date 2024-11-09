library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity sys_array_control_unit is
	generic (
		weight_width  : integer := 4;
		weight_height : integer := 3;
		input_width   : integer := 1
	);
	port (
		clk         : in std_logic;
		reset       : in std_logic;
		enable_bits : out std_logic_vector(maximum(weight_width, weight_height) - 1 downto 0)
	);
end entity sys_array_control_unit;

architecture rtl of sys_array_control_unit is

	signal s_rem_en_bits : unsigned(integer(ceil(log2(real(input_width)))) downto 0);
	signal s_enable_bits : std_logic_vector(maximum(weight_width, weight_height) - 1 downto 0);

begin

	SHIFT_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_rem_en_bits <= to_unsigned(input_width, s_rem_en_bits'length);
				s_enable_bits <= (others => '0');
			else
				-- Shift valid bits via shift register for input_width amount of cycles
				if s_rem_en_bits /= 0 then
					s_rem_en_bits <= s_rem_en_bits - 1;
					s_enable_bits <= s_enable_bits(s_enable_bits'high - 1 downto s_enable_bits'low) & '1';
				else
					s_enable_bits <= s_enable_bits(s_enable_bits'high - 1 downto s_enable_bits'low) & '0';
				end if;
			end if;
		end if;

	end process SHIFT_PROC;

	enable_bits <= s_enable_bits;

end architecture rtl;
