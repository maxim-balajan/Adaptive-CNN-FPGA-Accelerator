library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.libmatrix.all;

entity sys_array is
	generic (
		-- weight_width == input_height
		weight_width  : integer := 4;
		weight_height : integer := 3;
		input_width   : integer := 1;
		vector_length : integer := 8
	);
	port (
		clk           : in std_logic;
		reset         : in std_logic;
		weights       : in matrix_2d(0 to weight_width - 1)(0 to weight_height - 1)(vector_length - 1 downto 0);
		inputs        : in matrix_2d(0 to input_width - 1)(0 to weight_width - 1)(vector_length - 1 downto 0);
		results       : out matrix_2d(0 to input_width - 1)(0 to weight_height - 1)(vector_length - 1 downto 0);
		comp_complete : out std_logic
	);
end entity sys_array;

architecture rtl of sys_array is

	signal s_enable_matrix : matrix_1d(0 to weight_width)(maximum(weight_width, weight_height) - 1 downto 0);
	-- this is necessary to delay enable bits by one cyle, otherwise they will reach the result buffers one cycle early
	signal s_enable_result_buffer : std_logic_vector(weight_height - 1 downto 0);
	signal s_partial_sums         : matrix_2d(0 to weight_width)(0 to weight_height - 1)(3 * vector_length - 1 downto 0);
	-- activation_input is transposed => y,x,Vector Length
	signal s_activation_input : matrix_2d(0 to weight_height)(0 to weight_width - 1)(vector_length - 1 downto 0);
	signal s_buffer_full_vec  : std_logic_vector(weight_height - 1 downto 0);
	-- result and inputs need to be transposed in order to be connected to submodules
	signal s_results_transposed : matrix_2d(0 to weight_height - 1)(0 to input_width - 1)(vector_length - 1 downto 0);
	signal s_inputs_transposed  : matrix_2d(0 to weight_width - 1)(0 to input_width - 1)(vector_length - 1 downto 0);
	signal s_results            : matrix_2d(0 to input_width - 1)(0 to weight_height - 1)(vector_length - 1 downto 0);

begin

	RESET_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				-- reset first dimension of partial sums
				for i in 0 to weight_height - 1 loop

					s_partial_sums(s_partial_sums'low)(i) <= (others => '0');

				end loop;

				s_enable_result_buffer <= (others => '0');
			else
				s_enable_result_buffer <= s_enable_matrix(s_enable_matrix'high)(s_enable_result_buffer'range);
			end if;
		end if;

	end process RESET_PROC;

	-- Generation of control unit

	CONTROL_UNIT : entity work.sys_array_control_unit
		generic map (
			weight_width  => weight_width,
			weight_height => weight_height,
			input_width   => input_width
		)
		port map (
			clk         => clk,
			reset       => reset,
			enable_bits => s_enable_matrix(s_enable_matrix'low)
		);

	-- Generation of activation memory buffers

	GENERATE_ACT_BUFFER : for y_id in 0 to weight_width - 1 generate

		ACT_BUFFER : entity work.sys_array_activation_buffer
			generic map (
				input_width   => input_width,
				vector_length => vector_length
			)
			port map (
				clk               => clk,
				reset             => reset,
				en                => s_enable_matrix(s_enable_matrix'low)(y_id),
				din               => s_inputs_transposed(y_id),
				result_activation => s_activation_input(s_activation_input'low)(y_id)
			);

	end generate GENERATE_ACT_BUFFER;

	-- inputs need to be transposed in order to be connected to activation buffer
	s_inputs_transposed <= transpose_matrix2d(inputs);

	-- Generation of MACs

	X_GENERATE_MACS : for x_id in 0 to weight_width - 1 generate

		Y_GENERATE_MACS : for y_id in 0 to weight_height - 1 generate

			MACS : entity work.mac_unit
				generic map (
					vector_length => vector_length
				)
				port map (
					clk            => clk,
					reset          => reset,
					valid          => s_enable_matrix(x_id)(y_id),
					input_vector   => s_activation_input(y_id)(x_id),
					weight_vector  => weights(x_id)(y_id),
					partial_sum    => s_partial_sums(x_id)(y_id),
					valid_delay    => s_enable_matrix(x_id + 1)(y_id),
					input_delay    => s_activation_input(y_id + 1)(x_id),
					partial_result => s_partial_sums(x_id + 1)(y_id)
				);

		end generate Y_GENERATE_MACS;

	end generate X_GENERATE_MACS;

	-- Generation of result buffer

	GENERATE_RES_BUFFER : for y_id in 0 to weight_height - 1 generate

		RES_BUFFER : entity work.sys_array_result_buffer
			generic map (
				input_width   => input_width,
				vector_length => vector_length
			)
			port map (
				clk           => clk,
				reset         => reset,
				en            => s_enable_result_buffer(y_id),
				din           => s_partial_sums(s_partial_sums'high)(y_id),
				buffer_full   => s_buffer_full_vec(y_id),
				result_buffer => s_results_transposed(y_id)
			);

	end generate GENERATE_RES_BUFFER;

	-- if all result buffers are full then computation has to be finished
	comp_complete <= and s_buffer_full_vec;
	-- results are generated transposed by result buffer => need to be transposed back for further computation
	s_results <= transpose_matrix2d(s_results_transposed);
	results   <= s_results;

end architecture rtl;
