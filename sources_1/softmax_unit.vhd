library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;
use work.libutil.all;

entity softmax_unit is
	generic (
		input_length : natural := 8;
		input_amount : natural := 10
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		en    : in std_logic;
		input : in matrix_1d(0 to input_amount - 1)(input_length - 1 downto 0);
		-- The index (starting from 0) of the maximum value in the input vector
		max_index     : out std_logic_vector(integer(ceil(log2(real(input_amount)))) - 1 downto 0);
		comp_complete : out std_logic
	);
end entity softmax_unit;

architecture rtl of softmax_unit is

	-- Amount of bits needed for the index representation
	constant c_index_length : integer := integer(ceil(log2(real(input_amount))));

	-- It also contains double the amount of signals because it is easier to write that way and shouldn't result in more HW
	signal s_pipeline_values  : matrix_2d(0 to c_index_length)(0 to input_amount - 1)(input_length - 1 downto 0);
	signal s_pipeline_indices : matrix_2d(0 to c_index_length)(0 to input_amount - 1)(c_index_length - 1 downto 0);

	signal s_pipeline_en : std_logic_vector(0 to c_index_length);

	signal s_en    : std_logic;
	signal s_input : matrix_1d(0 to input_amount - 1)(input_length - 1 downto 0);

	signal s_reset_del : std_logic;

begin

	DELAY_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_en        <= '0';
				s_input     <= (others => (others => '0'));
				s_reset_del <= '1';
			else
				-- Big hack that solves pipelining of illegal value; don't know how to solve this differently
				if s_reset_del = '1' then
					s_en        <= '0';
					s_input     <= (others => (others => '0'));
					s_reset_del <= '0';
				else
					s_en    <= en;
					s_input <= input;
				end if;
			end if;
		end if;

	end process DELAY_PROC;

	-- Set start values for pipeline
	s_pipeline_en(s_pipeline_en'low)           <= s_en;
	s_pipeline_values(s_pipeline_values'low)   <= s_input;
	s_pipeline_indices(s_pipeline_indices'low) <= f_int_list_to_matrix_1d(c_index_length, f_range(0, input_amount));

	-- Set output values of unit
	max_index     <= s_pipeline_indices(c_index_length)(s_pipeline_indices(c_index_length)'low);
	comp_complete <= s_pipeline_en(s_pipeline_en'high);

	-- Generate all layers for softmax computation
	-- Basically works like the "Divide by 2"-Algorithm

	SOFTMAX_LAYER_GEN : for i in 0 to c_index_length - 1 generate

		SOFTMAX_LAYER_INST : entity work.softmax_layer
			generic map (
				vector_length => input_length,
				input_amount  => integer(ceil(real(input_amount) / real(2 ** i))),
				index_length  => c_index_length
			)
			port map (
				clk           => clk,
				reset         => reset,
				en            => s_pipeline_en(i),
				input_values  => s_pipeline_values(i)(0 to integer(ceil(real(input_amount) / real(2 ** i))) - 1),
				input_indices => s_pipeline_indices(i)(0 to integer(ceil(real(input_amount) / real(2 ** i))) - 1),
				max_values    => s_pipeline_values(i + 1)(0 to integer(ceil(real(input_amount) / real(2 ** (i + 1)))) - 1),
				max_indices   => s_pipeline_indices(i + 1)(0 to integer(ceil(real(input_amount) / real(2 ** (i + 1)))) - 1),
				comp_complete => s_pipeline_en(i + 1)
			);

	end generate SOFTMAX_LAYER_GEN;

end architecture rtl;
