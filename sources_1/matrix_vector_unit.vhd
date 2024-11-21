library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity matrix_vector_unit is
	generic (
		-- weight_width == input_height
		weight_width  : integer := 400;
		weight_height : integer := 120;
		vector_length : integer := 8
	);
	port (
		clk           : in std_logic;
		reset         : in std_logic;
		en            : in std_logic;
		weights       : in matrix_1d(0 to weight_height - 1)(vector_length - 1 downto 0);
		inputs        : in matrix_1d(0 to weight_width - 1)(vector_length - 1 downto 0);
		bias          : in matrix_1d(0 to weight_height - 1)(vector_length - 1 downto 0);
		results       : out matrix_1d(0 to weight_height - 1)(vector_length - 1 downto 0);
		comp_complete : out std_logic
	);
end entity matrix_vector_unit;

architecture rtl of matrix_vector_unit is

	signal s_inputs_finished : unsigned(integer(ceil(log2(real(weight_width)))) - 1 downto 0);
	signal s_results : matrix_1d(0 to weight_height - 1)(vector_length - 1 downto 0);

	signal s_enable_bits     : std_logic_vector(0 to weight_height);
	signal s_input_line      : matrix_1d(0 to weight_height)(vector_length - 1 downto 0);
	signal s_partial_results : matrix_1d(0 to weight_height - 1)(3 * vector_length - 1 downto 0);

begin

	process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_inputs_finished <= (others => '0');
				s_enable_bits(s_enable_bits'low) <= '0';
			else
				s_enable_bits(s_enable_bits'low) <= en;
				s_inputs_finished <= s_inputs_finished + (s_inputs_finished'high - 1 downto 1 => '0') & s_enable_bits(s_enable_bits'high);
			end if;
		end if;

	end process;

	MAC_GENERATION : for y_id in 0 to weight_height - 1 generate

		MACS : entity work.mac_unit
			generic map (
				vector_length => vector_length
			)
			port map (
				clk                                                       => clk,
				reset                                                     => reset,
				valid                                                     => s_enable_bits(y_id),
				input_vector                                              => s_input_line(y_id),
				weight_vector                                             => weights(y_id),
				initial_value(vector_length - 1 downto 0)                 => bias(y_id),
				initial_value(3 * vector_length - 1 downto vector_length) => (others => '0'),
				partial_sum                                               => s_partial_results(y_id),
				valid_delay                                               => s_enable_bits(y_id + 1),
				input_delay                                               => s_input_line(y_id + 1),
				partial_result                                            => s_partial_results(y_id)
			);

	end generate MAC_GENERATION;

	-- This process is necessary to get vector_length-long slices of s_patrial_results
	-- Maybe there is a smater way to do this but I dont know how
	MAPPING_PROC : process (s_partial_results) is
	begin

		for i in s_partial_results'range loop

			s_results(i) <= s_partial_results(i)(vector_length - 1 downto 0);

		end loop;

	end process MAPPING_PROC;

	results       <= s_results;
	comp_complete <= std_logic_vector(s_inputs_finished) ?= std_logic_vector(to_unsigned(weight_width, s_inputs_finished'length));

end architecture rtl;
