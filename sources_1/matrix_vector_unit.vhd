library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity matrix_vector_unit is
	generic (
		-- weight_width == input_height
		weight_width  : natural := 400;
		weight_height : natural := 120;
		vector_length : natural := 8
	);
	port (
		clk                  : in std_logic;
		reset                : in std_logic;
		en                   : in std_logic;
		actual_weight_width  : in std_logic_vector(integer(ceil(log2(real(weight_width)))) downto 0);
		actual_weight_heigth : in std_logic_vector(integer(ceil(log2(real(weight_height)))) downto 0);
		weights              : in matrix_1d(0 to weight_height - 1)(vector_length - 1 downto 0);
		inputs               : in matrix_1d(0 to weight_width - 1)(vector_length - 1 downto 0);
		bias                 : in std_logic_vector(vector_length - 1 downto 0);
		bram_enable_line     : out std_logic_vector(0 to weight_height);
		results              : out matrix_1d(0 to weight_height - 1)(vector_length - 1 downto 0);
		comp_complete        : out std_logic
	);
end entity matrix_vector_unit;

architecture rtl of matrix_vector_unit is

	signal s_en : std_logic;

	signal s_inputs_pipelined : unsigned(integer(ceil(log2(real(weight_width)))) downto 0);
	signal s_inputs_finished  : unsigned(integer(ceil(log2(real(weight_width)))) downto 0);
	signal s_current_bias_id  : unsigned(integer(ceil(log2(real(weight_height)))) downto 0);

	signal s_results        : matrix_1d(0 to weight_height - 1)(vector_length - 1 downto 0);
	signal s_output_results : matrix_1d(0 to weight_height - 1)(vector_length - 1 downto 0);

	signal s_bias_en          : std_logic;
	signal s_bias_enable_line : std_logic_vector(0 to weight_height);
	signal s_enable_bits      : std_logic_vector(0 to weight_height);
	signal s_input_line       : matrix_1d(0 to weight_height)(vector_length - 1 downto 0);
	signal s_partial_results  : matrix_1d(0 to weight_height - 1)(3 * vector_length - 1 downto 0);

	signal s_actual_weight_width  : unsigned(integer(ceil(log2(real(weight_width)))) downto 0);
	signal s_actual_weight_height : unsigned(integer(ceil(log2(real(weight_height)))) downto 0);

begin

	process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_inputs_pipelined               <= (others => '0');
				s_inputs_finished                <= (others => '0');
				s_current_bias_id                <= (others => '0');
				s_enable_bits(s_enable_bits'low) <= '0';
				s_bias_en                        <= '0';
				s_input_line(s_input_line'low)   <= (others => '0');
				s_bias_enable_line               <= (others => '0');
				-- when resetting the unit set the actual weight_width and weight_height for further computation
				s_actual_weight_width  <= unsigned(actual_weight_width);
				s_actual_weight_height <= unsigned(actual_weight_heigth);
			else
				s_enable_bits(s_enable_bits'low) <= s_en;
				s_bias_enable_line               <= (others => '0');
				if s_en = '1' then
					-- Store amount of inputs pipelined and write current input to first MAC
					s_inputs_pipelined             <= s_inputs_pipelined + 1;
					s_input_line(s_input_line'low) <= inputs(to_integer(s_inputs_pipelined));
				end if;
				-- Demultiplex bias to correct MAC
				if s_current_bias_id /= s_actual_weight_height then
					s_current_bias_id                                 <= s_current_bias_id + 1;
					s_bias_enable_line(to_integer(s_current_bias_id)) <= '1';
					s_bias_en                                         <= '1';
				else
					s_bias_en <= '0';
				end if;
				-- If enable bit is bufferd through all MACs then a input value is finished with it's computation
				if s_enable_bits(to_integer(s_actual_weight_height)) = '1' then
					s_inputs_finished <= s_inputs_finished + 1;
				end if;
			end if;
		end if;

	end process;

	MAC_GENERATION : for y_id in 0 to weight_height - 1 generate

		MACS : entity work.matrix_vector_mac_unit
			generic map (
				vector_length => vector_length
			)
			port map (
				clk                                                     => clk,
				reset                                                   => reset,
				mac_en                                                  => s_enable_bits(y_id),
				bias_en                                                 => s_bias_enable_line(y_id),
				input_vector                                            => s_input_line(y_id),
				weight_vector                                           => weights(y_id),
				bias_vector(vector_length - 1 downto 0)                 => bias,
				bias_vector(3 * vector_length - 1 downto vector_length) => (others => '0'),
				partial_sum                                             => s_partial_results(y_id),
				mac_en_delay                                            => s_enable_bits(y_id + 1),
				input_delay                                             => s_input_line(y_id + 1),
				partial_result                                          => s_partial_results(y_id)
			);

	end generate MAC_GENERATION;

	-- This process is necessary to get vector_length-long slices of s_patrial_results
	-- It also clips the value in order to correctly deal with overflows
	-- Maybe there is a smarter way to do this but I dont know how
	MAPPING_PROC : process (s_partial_results) is

		variable tmp : signed(vector_length - 1 downto 0);

	begin

		for i in s_partial_results'range loop

			if signed(s_partial_results(i)(vector_length - 1 downto 0)) > 127 then
				tmp := to_signed(127, tmp'length);
			elsif signed(s_partial_results(i)(vector_length - 1 downto 0)) < -128 then
				tmp := to_signed(-128, tmp'length);
			else
				tmp := signed(s_partial_results(i)(vector_length - 1 downto 0));
			end if;

			s_results(i) <= std_logic_vector(tmp);

		end loop;

	end process MAPPING_PROC;

	-- s_output_results is a seperate buffer for the result that is only written to if comp_complete has been set from 0 to 1
	-- reason for this beeing so that the matrix vector unit can be used multiple times
	WRITE_RESULT_PROC : process (comp_complete) is
	begin

		if rising_edge(comp_complete) then
			s_output_results <= s_results;
		end if;

	end process WRITE_RESULT_PROC;

	-- This is necessary so that no illegal values are pipelined into the unit
	s_en <= en when s_inputs_pipelined /= s_actual_weight_width else '0';

	results          <= s_output_results;
	comp_complete    <= std_logic_vector(s_inputs_finished) ?= std_logic_vector(s_actual_weight_width);
	bram_enable_line <= s_enable_bits(0 to weight_height - 1) & s_bias_en;

end architecture rtl;
