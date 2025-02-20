library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.libmatrix.all;

package libutil is

	--! List of integers

	type int_list is array(natural range <>) of integer;

	--! List of strings

	type string_list is array(natural range <>) of string;

	--! function that returns the reduction of a list

	function sum_int_list (
		input : int_list
	) return integer;

	function f_append (
		list : int_list;
		element : integer
	) return int_list;

	function f_range(
		start_id : integer := 0;
		end_id : integer
	) return int_list;

	function f_max(
		list : int_list
	) return integer;

	function f_min(
		list : int_list
	) return integer;

	function f_int_list_to_matrix_1d(
		vector_length : integer;
		list : int_list
	) return matrix_1d;

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

	function f_append (
		list 	: int_list;
		element : integer
	) return int_list is
		variable tmp : int_list(0 to list'length);
	begin
		tmp(list'range) := list;
		tmp(tmp'high) := element;

		return tmp;
	end function;

	function f_range(
		start_id : integer := 0;
		end_id 	 : integer
	) return int_list is
		variable tmp : int_list(0 to end_id - start_id - 1) := (others => 0);
	begin

		for i in start_id to end_id - 1 loop
			tmp(i - start_id) := i;
		end loop;

		return tmp;
	end function f_range;

	function f_max(
		list : int_list
	) return integer is
		variable tmp : integer := - 2147483647;
	begin
		for i in list'range loop
			tmp := maximum(tmp, list(i));
		end loop;

		return tmp;
	end function;

	function f_min(
		list : int_list
	) return integer is
		variable tmp : integer := 2147483647;
	begin
		for i in list'range loop
			tmp := minimum(tmp, list(i));
		end loop;

		return tmp;
	end function;

	function f_int_list_to_matrix_1d(
		vector_length : integer;
		list : int_list
	) return matrix_1d is
		variable tmp : matrix_1d(list'range)(vector_length - 1 downto 0) := (others => (others => '0') ) ;
	begin
		for i in list'range loop
			tmp(i) := std_logic_vector(to_unsigned(list(i), vector_length));
		end loop;

		return tmp;
	end function;

end package body libutil;
