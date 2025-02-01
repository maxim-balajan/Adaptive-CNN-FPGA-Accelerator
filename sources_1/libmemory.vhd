library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.TEXTIO.all;
use work.libmatrix.all;

package libmemory is

	impure function init_from_file (
		file_name     : in string;
		vector_length : in natural;
		depth         : in natural
	) return matrix_1d;

	impure function read_output_channel (
		file_name            : in string;
		vector_length        : in natural;
		input_amount          : in natural;
		total_input_channel  : in natural;
		total_output_channel : in natural;
		curr_output_channel  : in natural
	) return matrix_1d;

	impure function read_input_channel (
		file_name            : in string;
		vector_length        : in natural;
		input_amount          : in natural;
		total_input_channel  : in natural;
		total_output_channel : in natural;
		curr_input_channel   : in natural
	) return matrix_1d;

	impure function read_scale_value (
		file_name : in string;
		vector_length : in natural;
		current_scale : in natural
	) return std_logic_vector;

	impure function read_weight_row (
		file_name            : in string;
		vector_length        : in natural;
		total_rows       : in natural;
		row_length           : in natural;
		curr_row          : in natural
	) return matrix_1d;

end package libmemory;

package body libmemory is

	impure function init_from_file (
		file_name     : in string;
		vector_length : in natural;
		depth         : in natural
	) return matrix_1d is

		file     mem_file  : text open read_mode is file_name;
		variable file_line : line;
		variable tmp_ram   : matrix_1d(0 to depth - 1)(vector_length - 1 downto 0);

	begin

		for i in tmp_ram'range loop

			readline(mem_file, file_line);
			hread(file_line, tmp_ram(i));

		end loop;

		return tmp_ram;

	end function init_from_file;

	impure function read_output_channel (
		file_name            : in string;
		vector_length        : in natural;
		input_amount          : in natural;
		total_input_channel  : in natural;
		total_output_channel : in natural;
		curr_output_channel  : in natural
	) return matrix_1d is

		file     mem_file  : text open read_mode is file_name;
		variable file_line : line;
		variable tmp_ram   : matrix_1d(0 to input_amount * total_input_channel - 1)(vector_length - 1 downto 0);

		variable actual_curr_output_channel : natural;

	begin

		-- Deal with wrong set current output channel
		if curr_output_channel > total_output_channel then
			actual_curr_output_channel := total_output_channel;
		elsif curr_output_channel <= 0 then
			actual_curr_output_channel := 1;
		else
			actual_curr_output_channel := curr_output_channel;
		end if;

		-- Skip lines that are not necessary

		for i in 1 to actual_curr_output_channel - 1 loop

			for j in tmp_ram'range loop

				readline(mem_file, file_line);

			end loop;

		end loop;

		-- Read important data and Write them to BRAM

		for i in tmp_ram'range loop

			readline(mem_file, file_line);
			hread(file_line, tmp_ram(i));

		end loop;

		return tmp_ram;

	end function read_output_channel;

	impure function read_input_channel (
		file_name            : in string;
		vector_length        : in natural;
		input_amount          : in natural;
		total_input_channel  : in natural;
		total_output_channel : in natural;
		curr_input_channel   : in natural
	) return matrix_1d is

		file     mem_file  : text open read_mode is file_name;
		variable file_line : line;
		variable tmp_ram   : matrix_1d(0 to input_amount * total_output_channel - 1)(vector_length - 1 downto 0);

		variable actual_curr_input_channel : natural;

	begin

		-- Deal with wrong set current input channel
		if curr_input_channel > total_input_channel then
			actual_curr_input_channel := total_input_channel;
		elsif curr_input_channel <= 0 then
			actual_curr_input_channel := 1;
		else
			actual_curr_input_channel := curr_input_channel;
		end if;

		-- Offset reading process to get current input channel of interest

		for i in 1 to actual_curr_input_channel - 1 loop

			for j in 0 to input_amount - 1 loop

				readline(mem_file, file_line);

			end loop;

		end loop;

		-- Do reading for every output channel
		for i in 0 to total_output_channel - 1 loop

			-- Read legal input channel and write them to BRAM
			for j in 0 to input_amount - 1 loop

				readline(mem_file, file_line);
				hread(file_line, tmp_ram(i * input_amount + j));

			end loop;

			-- Offset to get input channel of interest of next output channel
			-- extra minus 1 because we also have the upper reading for-loop
			for j in 0 to total_input_channel - 2 loop

				for k in 0 to input_amount - 1 loop

					readline(mem_file, file_line);

				end loop;

			end loop;

		end loop;

		return tmp_ram;

	end function read_input_channel;

	impure function read_scale_value (
		file_name : in string;
		vector_length : in natural;
		current_scale : in natural
	) return std_logic_vector is

		file     mem_file  : text open read_mode is file_name;
		variable file_line : line;
		variable tmp_ram   : std_logic_vector(vector_length - 1 downto 0);

	begin

		-- Read until desired line
		for i in 0 to current_scale - 1 loop

			readline(mem_file, file_line);

		end loop;

		-- Write line to RAM variable and return
		hread(file_line, tmp_ram);

		return tmp_ram;

	end function read_scale_value;

	impure function read_weight_row (
		file_name            : in string;
		vector_length        : in natural;
		total_rows       : in natural;
		row_length           : in natural;
		curr_row          : in natural
	) return matrix_1d is

		file     mem_file  : text open read_mode is file_name;
		variable file_line : line;
		variable tmp_ram   : matrix_1d(0 to row_length - 1)(vector_length - 1 downto 0);

		variable actual_curr_row : natural;

	begin

		-- Deal with wrong set current row
		if actual_curr_row > total_rows then
			actual_curr_row := total_rows;
		elsif actual_curr_row <= 0 then
			actual_curr_row := 1;
		else
			actual_curr_row := curr_row;
		end if;

		-- Skip lines that are not necessary

		for i in 1 to curr_row - 1 loop

			for j in tmp_ram'range loop

				readline(mem_file, file_line);

			end loop;

		end loop;

		-- Read important data and Write them to Output

		for i in tmp_ram'range loop

			readline(mem_file, file_line);
			hread(file_line, tmp_ram(i));

		end loop;

		return tmp_ram;

	end function read_weight_row;

end package body libmemory;
