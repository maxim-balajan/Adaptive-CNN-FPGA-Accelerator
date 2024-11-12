
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.libmatrix.all;

entity max_pooling_max_unit is
	generic (
		number_width : natural := 8
	);
	port (
		clk       : in std_logic;
		reset     : in std_logic;
		input1_en : in std_logic;
		input2_en : in std_logic;
		input1    : in std_logic_vector(number_width - 1 downto 0);
		input2    : in std_logic_vector(number_width - 1 downto 0);
		output    : out std_logic_vector(number_width - 1 downto 0);
		finished  : out std_logic
	);
end entity max_pooling_max_unit;

architecture Behavioral of max_pooling_max_unit is

	signal s_finished : std_logic;
	signal s_output   : std_logic_vector(number_width - 1 downto 0);

begin

	MAIN_PROCESS : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_finished <= '0';
				s_output   <= (others => '0');
			else
				-- Shift valid bits via shift register for input_width amount of cycles
				if (input1_en and input2_en) = '1' then
					if signed(input1) > signed(input2) then
						s_output <= input1;
					else
						s_output <= input2;
					end if;
					s_finished <= '1';-- after 1 ns;
				else
					s_finished <= '0';
				end if;
			end if;
		end if;

	end process MAIN_PROCESS;
	
	finished <= s_finished;
	output <= s_output;
end architecture Behavioral;
