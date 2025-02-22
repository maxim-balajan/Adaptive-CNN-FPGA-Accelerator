library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libutil.all;
use work.libmatrix.all;
use work.libmemory.all;

entity dense_layer_combined is
	generic (
		vector_length : natural := 8;
		-- weight_width == input_height
		max_weight_width  : natural     := 400;
		max_weight_height : natural     := 120;
		shift_path        : string      := "../data/scale_values.data";
		shift_ids         : int_list    := (3, 4, 5);
		weight_widths     : int_list    := (400, 120, 84);
		weight_heights    : int_list    := (120, 84, 10);
		weight_paths      : string_list := ("../data/layer_weight_2.data",
										 "../data/layer_weight_3.data",
										 "../data/layer_weight_4.data")
	);
	port (
		clk           : in std_logic;
		reset         : in std_logic;
		en            : in std_logic;
		input         : in std_logic_vector(vector_length - 1 downto 0);
		results       : out matrix_1d(0 to weight_heights(weight_heights'high) - 1)(vector_length - 1 downto 0);
		comp_complete : out std_logic
	);
end entity dense_layer_combined;

architecture rtl of dense_layer_combined is

	-- This function retrieves all base_addresses necessary for computation

	impure function get_base_addr return matrix_1d is

		variable tmp : matrix_1d(weight_widths'range)(integer(ceil(log2(real(sum_int_list(weight_widths))))) - 1 downto 0);

	begin

		tmp(tmp'low) := (others => '0');

		for i in tmp'low + 1 to tmp'high loop

			tmp(i) := std_logic_vector(to_unsigned(sum_int_list(weight_widths(weight_widths'low to i - 1)), tmp(i)'length));

		end loop;

		return tmp;

	end function get_base_addr;

	-- This function retrieves all necessary scale values

	impure function get_scale_values return matrix_1d is

		variable tmp : matrix_1d(shift_ids'range)(vector_length - 1 downto 0);

	begin

		for i in tmp'range loop

			tmp(i) := read_scale_value(shift_path, vector_length, vector_length, shift_ids(i));

		end loop;

		return tmp;

	end function get_scale_values;

	-- Constants for scales and base_addresses
	constant c_scale_values : matrix_1d(shift_ids'range)(vector_length - 1 downto 0)                                              := get_scale_values;
	constant c_base_addr    : matrix_1d(weight_widths'range)(integer(ceil(log2(real(sum_int_list(weight_widths))))) - 1 downto 0) := get_base_addr;

	-- Counter to check which dense iteration we are on
	signal s_iteration_count : unsigned(integer(ceil(log2(real(weight_paths'length)))) downto 0);
	-- This signal is for the temporary reset of the dense layer unit
	signal s_iteration_reset : std_logic;
	-- This signal indicates if a dense_layer has finished
	signal s_tmp_complete : std_logic;
	-- This signal stores the temporary results in order to stream it back to the  input of the dense layer
	signal s_tmp_results              : matrix_1d(0 to max_weight_height - 1)(3 * vector_length - 1 downto 0);
	signal s_tmp_results_read_pointer : unsigned(integer(ceil(log2(real(s_tmp_results'length)))) downto 0);

	signal s_en : std_logic;

	signal s_comp_complete : std_logic;
	signal s_results       : matrix_1d(0 to max_weight_height - 1)(3 * vector_length - 1 downto 0);

	-- Signals for pipelining input
	signal s_shifted_input_en : std_logic;
	signal s_sliced_input_en  : std_logic;
	signal s_sliced_input     : std_logic_vector(3 * vector_length - 1 downto 0);
	-- This signal stores all possible shifts of s_input
	signal s_shifted_input : matrix_1d(shift_ids'range)(3 * vector_length - 1 downto 0);
	-- This signal is feed into the dense layer
	signal s_input : std_logic_vector(vector_length - 1 downto 0);
	-- Signals for pipelining output
	signal s_shifted_en : std_logic;
	signal s_clipped_en : std_logic;
	-- This signal always computes the last shift of the first 10 values
	signal s_shifted_solutions : matrix_1d(0 to weight_heights(weight_heights'high) - 1)(3 * vector_length - 1 downto 0);
	-- This signal contains the clipped version of s_shifted_solutions
	signal s_clipped_solutions : matrix_1d(0 to weight_heights(weight_heights'high) - 1)(vector_length - 1 downto 0);

begin

	CONTROL_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_iteration_count          <= (others => '0');
				s_iteration_reset          <= '1';
				s_input                    <= (others => '0');
				s_en                       <= '0';
				s_tmp_results_read_pointer <= (others => '0');
				s_comp_complete            <= '0';
			else
				-- always set iteration reset to 0 for safety
				s_iteration_reset <= '0';
				-- Only do something while the iteration is not resetting
				if s_iteration_reset /= '1' then
					-- if iteration is finished, then increase count and reset the dense layer unit
					if s_tmp_complete = '1' then
						-- If all layers have been computed, finish calculation
						if s_iteration_count >= weight_paths'length - 1 then
							s_comp_complete <= '1';
						else
							s_iteration_count          <= s_iteration_count + 1;
							s_iteration_reset          <= '1';
							s_en                       <= '0';
							s_tmp_results_read_pointer <= (others => '0');
						end if;
					elsif s_iteration_count = 0 then
						s_input <= input;
						s_en    <= en;
					else
						-- Clip values that are streamed into mv_unit
						if signed(s_shifted_input(to_integer(s_iteration_count) - 1)) > 2 ** (vector_length - 1) - 1 then
							s_input <= std_logic_vector(to_signed(2 ** (vector_length - 1) - 1, s_input'length));
						elsif signed(s_shifted_input(to_integer(s_iteration_count) - 1)) < - 2 ** (vector_length - 1) then
							s_input <= std_logic_vector(to_signed(- 2 ** (vector_length - 1), s_input'length));
						else
							s_input <= s_shifted_input(to_integer(s_iteration_count) - 1)(vector_length - 1 downto 0);
						end if;
						s_en <= s_shifted_input_en;
						-- Increament_read_pointer
						if s_tmp_results_read_pointer >= s_tmp_results'length - 1 then
							s_tmp_results_read_pointer <= (others => '0');
						else
							s_tmp_results_read_pointer <= s_tmp_results_read_pointer + 1;
						end if;
					end if;
				end if;
			end if;
		end if;

	end process CONTROL_PROC;

	-- This process only stores the result, when the iteration has concluded
	-- It is necessary so that we can read the old result in order to use it as an input in the next iteration
	RESULT_REG_PROC : process (s_tmp_complete) is
	begin

		if rising_edge(s_tmp_complete) then
			s_tmp_results <= s_results;
		end if;

	end process RESULT_REG_PROC;

	-- This process does the current indexing and shift_ids'length many static shifts of the output
	-- and also pipelines these through

	INPUT_PIPELINE_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then

				for i in s_shifted_input'range loop

					s_shifted_input(i) <= (others => '0');

				end loop;

				s_sliced_input     <= (others => '0');
				s_shifted_input_en <= '0';
			else
				-- Slice input
				s_sliced_input <= s_tmp_results(to_integer(s_tmp_results_read_pointer));
				-- And then shift them
				for i in s_shifted_input'range loop

					-- Calculate all static shifts because they cost next to nothing
					s_shifted_input(i) <= std_logic_vector(shift_right(signed(s_sliced_input),
	                                                   to_integer(unsigned(c_scale_values(i)))));

				end loop;

				-- only set it to '1' if this is not a reset and not a comlete cycle
				-- If you just set it to '1' this will break the dense layer
				s_sliced_input_en  <= not s_iteration_reset and not s_tmp_complete;
				s_shifted_input_en <= s_sliced_input_en;
			end if;
		end if;

	end process INPUT_PIPELINE_PROC;

	DENSE_LAYER_INST : entity work.dense_layer
		generic map (
			input_length     => vector_length,
			output_length    => 3 * vector_length,
			max_weight_width => max_weight_width,
			weight_widths    => weight_widths,
			weight_heights   => weight_heights,
			weight_paths     => weight_paths
		)
		port map (
			clk                  => clk,
			reset                => s_iteration_reset,
			en                   => s_en,
			actual_weight_height => std_logic_vector(to_unsigned(weight_heights(to_integer(s_iteration_count)),
				integer(ceil(log2(real(max_weight_height)))) + 1)),
			actual_weight_width  => std_logic_vector(to_unsigned(weight_widths(to_integer(s_iteration_count)),
				integer(ceil(log2(real(max_weight_width)))) + 1)),
			input                => s_input,
			base_addr            => std_logic_vector(c_base_addr(to_integer(s_iteration_count))),
			results              => s_results,
			comp_complete        => s_tmp_complete
		);

	-- This process shifts and clips the first weight_heights(weight'high) values 
	-- so that it can be passed to the output port.
	-- It also pipelines the output so decrease critical path
	OUTPUT_PIPELINE_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then

				for i in s_shifted_solutions'range loop

					s_shifted_solutions(i) <= (others => '0');
					s_clipped_solutions(i) <= (others => '0');

				end loop;

				s_shifted_en <= '0';
				s_clipped_en <= '0';
			else

				for i in s_shifted_solutions'range loop

					-- Shift the first weight_heights(weight'high) values with the last scale value
					s_shifted_solutions(i) <= std_logic_vector(shift_right(signed(s_tmp_results(i)),
	                                                       to_integer(unsigned(c_scale_values(c_scale_values'high)))));
					-- And then clip them accordingly for use in softmax unit

					if signed(s_shifted_solutions(i)) > 2 ** (vector_length - 1) - 1 then
						s_clipped_solutions(i) <= std_logic_vector(to_signed(2 ** (vector_length - 1) - 1, s_clipped_solutions(i)'length));
					elsif signed(s_shifted_solutions(i)) < - 2 ** (vector_length - 1) then
						s_clipped_solutions(i) <= std_logic_vector(to_signed(- 2 ** (vector_length - 1), s_clipped_solutions(i)'length));
					else
						s_clipped_solutions(i) <= s_shifted_solutions(i)(vector_length - 1 downto 0);
					end if;

				end loop;

				s_shifted_en <= s_comp_complete;
				s_clipped_en <= s_shifted_en;
			end if;
		end if;

	end process OUTPUT_PIPELINE_PROC;

	-- Set output for the results
	comp_complete <= s_clipped_en;
	results       <= s_clipped_solutions;

end architecture rtl;
