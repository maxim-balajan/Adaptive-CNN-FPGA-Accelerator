library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package libutil is

	--! List of integers

	type int_list is array(natural range <>) of integer;

	--! List of strings

	type string_list is array(natural range <>) of string;

	--! function that returns the reduction of a list

	function sum_int_list (
		input : int_list
	) return integer;

end package libutil;

package body libutil is

	function sum_int_list (
		input : int_list
	) return integer is

		variable tmp : integer := 0;

	begin

		for i in input'range loop

			tmp := tmp + input(i);

		end loop;

		return tmp;

	end function sum_int_list;

end package body libutil;
