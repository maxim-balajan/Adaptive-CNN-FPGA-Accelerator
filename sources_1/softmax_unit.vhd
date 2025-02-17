library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

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

	-- This constant stores the amount of convolution steps that are needed
	constant c_conv_step_count : integer := integer(ceil(log2(real(input_amount))));

	-- Amount of bits needed for the index representation
	constant c_index_length : integer := integer(ceil(log2(real(input_amount))));

	-- Amount of total inputs. This number is always a power of 2
	constant c_total_inputs : integer := integer(c_conv_step_count ** 2);

	-- Amount of inputs that are unused (and therefore set to 0)
	constant c_unused_inputs : integer := integer(c_total_inputs - input_amount);

	-- This signal is for all pipelined values that are used for the convolution computation
	-- It also contains double the amount of signals because it is easier to write that way and shouldn't result in more HW
	signal s_pipeline_values : matrix_2d(0 to c_conv_step_count)(0 to c_total_inputs - 1)(input_length - 1 downto 0);
	signal s_pipeline_indices : matrix_2d(0 to c_conv_step_count)(0 to c_total_inputs - 1)(c_index_length - 1 downto 0);

	signal s_pipeline_en : std_logic_vector(0 to c_conv_step_count);
begin
	-- EN_PROC : process (clk) is
	-- begin

	-- 	if rising_edge(clk) then
	-- 		if reset = '1' then
	-- 			s_pipeline_en(0) <= '0';
	-- 		else
	-- 			-- Only pipe the enable signal for one clock cycle
	-- 			-- This solves problems if the enable signal is set 
	-- 			if s_pipeline_en(0) = '1' then
	-- 				s_kernel_en       <= '0';
	-- 				s_kernel_complete <= '0';
	-- 				s_reset_del       <= '0';
	-- 			else
	-- 				s_kernel_en       <= kernel_en;
	-- 				s_kernel_complete <= kernel_complete;
	-- 			end if;
	-- 		end if;
	-- 	end if;

	-- end process EN_PROC;

	s_pipeline_en(0) <= en;
	comp_complete <= s_pipeline_en(c_conv_step_count);

	max_index <= s_pipeline_indices(c_conv_step_count)(0);

	-- Forward input values to first pipeline stage
	FORWARD_VALS: for i in 0 to input_amount - 1 generate
		s_pipeline_values(0)(i) <= input(i);
		s_pipeline_indices(0)(i) <= std_logic_vector(to_unsigned(i, c_index_length));
	end generate FORWARD_VALS;

	-- Set default values for unused inputs
	-- This makes it easy to handle inputs, although the amount of resulting hardware is not minimal
	SET_DEFAULTS: for i in 0 to c_unused_inputs - 1 generate
		s_pipeline_values(0)(input_amount + i) <= (others => '1'); -- Set unused inputs to MIN_INT
		s_pipeline_indices(0)(input_amount + i) <= (others => '0'); -- Set index of unused inputs to 0
	end generate SET_DEFAULTS;

	-- Generate all layers for softmax computation
	-- Basically works like the "Divide by 2"-Algorithm
	SOFTMAX_LAYER_GEN : for i in 0 to c_conv_step_count - 1 generate

		SOFTMAX_LAYER_INST : entity work.softmax_layer
			generic map (
				vector_length => input_length,
				input_amount   => integer(ceil(real(c_total_inputs) / real(2 ** i))),
				index_length => c_index_length
			)
			port map (
				clk => clk,
				reset => reset,
				en => s_pipeline_en(i),
				input_values => s_pipeline_values(i)(0 to integer(ceil(real(c_total_inputs) / real(2 ** i))) - 1),
				input_indices => s_pipeline_indices(i)(0 to integer(ceil(real(c_total_inputs) / real(2 ** i))) - 1),
				max_values => s_pipeline_values(i + 1)(0 to integer(ceil(real(c_total_inputs) / real(2 ** (i + 1)))) - 1),
				max_indices => s_pipeline_indices(i + 1)(0 to integer(ceil(real(c_total_inputs) / real(2 ** (i + 1)))) - 1),
				comp_complete => s_pipeline_en(i + 1)
			);
    end generate SOFTMAX_LAYER_GEN;
end architecture rtl;
