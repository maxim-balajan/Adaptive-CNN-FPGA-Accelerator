library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;
use work.libutil.all;
use work.libmemory.all;

entity matrix_vector_unit is
	generic (
		-- weight_width == input_height
		max_weight_width  : natural := 400;
		max_weight_height : natural := 120;
		shift_path        : string  := "../data/scale_values.data";
		-- If you want no shifts give (0, 0, 0, ...) as an input (shift_ids same length as every other list)
		shift_ids         : int_list             := (3, 4, 5);
		vector_length     : natural              := 8;
		enable_clip_adder : integer range 0 to 1 := 1
	);
	port (
		clk                  : in std_logic;
		reset                : in std_logic;
		en                   : in std_logic;
		actual_weight_width  : in std_logic_vector(integer(ceil(log2(real(max_weight_width)))) downto 0);
		actual_weight_height : in std_logic_vector(integer(ceil(log2(real(max_weight_height)))) downto 0);
		weights              : in matrix_1d(0 to max_weight_height - 1)(vector_length - 1 downto 0);
		input                : in std_logic_vector(vector_length - 1 downto 0);
		shift_id             : in std_logic_vector(integer(ceil(log2(real(shift_ids'length)))) downto 0);
		bram_enable_line     : out std_logic_vector(0 to max_weight_height - 1);
		results              : out matrix_1d(0 to max_weight_height - 1)(vector_length - 1 downto 0);
		comp_complete        : out std_logic
	);
end entity matrix_vector_unit;

architecture rtl of matrix_vector_unit is

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
	constant c_scale_values : matrix_1d(shift_ids'range)(vector_length - 1 downto 0) := get_scale_values;

	signal s_input : std_logic_vector(vector_length - 1 downto 0);
	signal s_en    : std_logic;

	signal s_inputs_pipelined : unsigned(integer(ceil(log2(real(max_weight_width)))) downto 0);
	signal s_inputs_finished  : unsigned(integer(ceil(log2(real(max_weight_width)))) downto 0);

	signal s_shift_id        : std_logic_vector(integer(ceil(log2(real(shift_ids'length)))) downto 0);
	signal s_shifted_results : matrix_2d(c_scale_values'range)(0 to max_weight_height - 1)(3 * vector_length - 1 downto 0);

	signal s_results        : matrix_1d(0 to max_weight_height - 1)(vector_length - 1 downto 0);
	signal s_output_results : matrix_1d(0 to max_weight_height - 1)(vector_length - 1 downto 0);

	signal s_enable_bits     : std_logic_vector(0 to max_weight_height);
	signal s_input_line      : matrix_1d(0 to max_weight_height)(vector_length - 1 downto 0);
	signal s_partial_results : matrix_1d(0 to max_weight_height - 1)(3 * vector_length - 1 downto 0);

	signal s_actual_weight_width  : unsigned(integer(ceil(log2(real(max_weight_width)))) downto 0);
	signal s_actual_weight_height : unsigned(integer(ceil(log2(real(max_weight_height)))) downto 0);

begin

	-- This process delays the inputs by one cycle
	-- This could also probably be omitted but is here to make sure everything is clocked
	DELAY_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_input <= (others => '0');
				s_en    <= '0';
			else
				s_input <= input;
				s_en    <= en;
			end if;
		end if;

	end process DELAY_PROC;

	-- This process starts the actual pipelining process and also makes sure no illegal values are pipelined
	-- It also keeps track on how many inputs successfully finished computation to later correctly determine
	-- when the computation should end

	PIPELINE_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_inputs_pipelined               <= (others => '0');
				s_inputs_finished                <= (others => '0');
				s_enable_bits(s_enable_bits'low) <= '0';
				s_input_line(s_input_line'low)   <= (others => '0');
				-- when resetting the unit set the actual weight_width and weight_height for further computation
				s_actual_weight_width  <= unsigned(actual_weight_width);
				s_actual_weight_height <= unsigned(actual_weight_height);

				s_shift_id <= shift_id;
			else
				-- only pipeline values when not all inputs were received
				if s_inputs_pipelined /= s_actual_weight_width then
					s_enable_bits(s_enable_bits'low) <= s_en;
					if s_en = '1' then
						-- Store amount of inputs pipelined and write current input to first MAC
						s_inputs_pipelined             <= s_inputs_pipelined + 1;
						s_input_line(s_input_line'low) <= s_input;
					end if;
				else
					s_enable_bits(s_enable_bits'low) <= '0';
				end if;

				-- If enable bit is buffered through all MACs then a input value is finished with it's computation
				if s_enable_bits(to_integer(s_actual_weight_height)) = '1' then
					s_inputs_finished <= s_inputs_finished + 1;
				end if;
			end if;
		end if;

	end process PIPELINE_PROC;

	MAC_GENERATION : for y_id in 0 to max_weight_height - 1 generate

		MACS : entity work.matrix_vector_mac_unit
			generic map (
				vector_length     => vector_length,
				enable_clip_adder => enable_clip_adder
			)
			port map (
				clk            => clk,
				reset          => reset,
				mac_en         => s_enable_bits(y_id),
				input_vector   => s_input_line(y_id),
				weight_vector  => weights(y_id),
				partial_sum    => s_partial_results(y_id),
				mac_en_delay   => s_enable_bits(y_id + 1),
				input_delay    => s_input_line(y_id + 1),
				partial_result => s_partial_results(y_id)
			);

	end generate MAC_GENERATION;

	-- This process creates all static shifts that are necessary for the dense layer

	SHIFT_GEN : for i in s_shifted_results'range generate

		RESULT_SHIFT_GEN : for j in s_partial_results'range generate
			s_shifted_results(i)(j) <= std_logic_vector(shift_right(signed(s_partial_results(j)), to_integer(unsigned(c_scale_values(i)))));
		end generate RESULT_SHIFT_GEN;

	end generate SHIFT_GEN;

	-- This generate is necessary to get vector_length-long slices of s_partial_results
	-- It also shifts (if set) and clips the value in order to correctly deal with overflows

	MAP_GEN : for i in s_partial_results'range generate

		s_results(i) <= std_logic_vector(to_signed(2 ** (vector_length - 1) - 1, s_results(i)'length))
	                when signed(s_shifted_results(to_integer(unsigned(shift_id)))(i)) > 2 ** (vector_length - 1) - 1 else
	                std_logic_vector(to_signed(- 2 ** (vector_length - 1), s_results(i)'length))
	                when signed(s_shifted_results(to_integer(unsigned(shift_id)))(i)) < - 2 ** (vector_length - 1) else
	                s_shifted_results(to_integer(unsigned(shift_id)))(i)(vector_length - 1 downto 0);

	end generate MAP_GEN;

	results <= s_results;
	-- This signal is set one cycle to late, but this is not a problem because no illegal values are ever pipelined
	comp_complete <= std_logic_vector(s_inputs_finished) ?= std_logic_vector(s_actual_weight_width);
	-- BRAM enable line always needs enable signals one cycle earlier because BRAM access has a cycle delay
	bram_enable_line <= s_en & s_enable_bits(0 to max_weight_height - 2);

end architecture rtl;
