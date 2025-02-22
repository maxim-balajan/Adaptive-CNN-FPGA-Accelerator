library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- This unit is purely combinatorial!!! It is not pipelined because, although it would be easy to implement 
-- it for the convolutions, it would be hard to implement this into the MACs of the MV-Unit.
-- Also two multiplexers (in series) shouldn't increase the critical path by too much compared to a single adder

entity clip_adder is
	generic (
		vector_length : natural := 8
	);
	port (
		din0 : in std_logic_vector(vector_length - 1 downto 0);
		din1 : in std_logic_vector(vector_length - 1 downto 0);
		dout : out std_logic_vector(vector_length - 1 downto 0)
	);
end entity clip_adder;

architecture rtl of clip_adder is

	signal s_tmp_result : std_logic_vector(vector_length - 1 downto 0);
	signal s_result     : signed(vector_length - 1 downto 0);

	signal s_overflow  : std_logic;
	signal s_underflow : std_logic;

begin

	-- Do addition
	s_tmp_result <= std_logic_vector(signed(din0) + signed(din1));
	-- Set control signals
	s_overflow  <= '1' when din0(din0'high) = '0' and din1(din1'high) = '0' and s_tmp_result(s_tmp_result'high) = '1' else '0';
	s_underflow <= '1' when din0(din0'high) = '1' and din1(din1'high) = '1' and s_tmp_result(s_tmp_result'high) = '0' else '0';
	-- Output result via two multiplexers
	s_result <= to_signed(2 ** (vector_length - 1) - 1, s_result'length) when s_overflow = '1' else
	            to_signed(- 2 ** (vector_length - 1), s_result'length) when s_underflow = '1' else
	            signed(s_tmp_result);
	-- Write output to dout port
	dout <= std_logic_vector(s_result);

end architecture rtl;
