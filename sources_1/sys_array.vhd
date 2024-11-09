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
		results       : out matrix_2d(0 to input_width - 1)( 0 to weight_height - 1)(3 * vector_length - 1 downto 0);
		comp_complete : out std_logic
	);
end entity sys_array;

architecture rtl of sys_array is

	signal s_results : matrix_2d(0 to input_width - 1)(0 to weight_height - 1)(3 * vector_length - 1 downto 0);
	-- we need one more input_vector signal in y-direction in order to meet bounds
	signal s_input_vectors : matrix_2d(0 to weight_width - 1)(0 to weight_height)(vector_length - 1 downto 0);
	-- we need one more partial_sum signal in x-direction in order to meet bounds
	signal s_partial_sum  : matrix_2d(0 to weight_width)(0 to weight_height - 1)(3 * vector_length - 1 downto 0);
	signal s_input_buffer : matrix_2d(0 to weight_width + input_width - 1)(0 to weight_width - 1)(vector_length - 1 downto 0);

begin

	CALC_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_results      <= (others => (others => (others => '0')));
				comp_complete  <= '0';
				s_input_buffer <= (others => (others => (others => '0')));
				-- fill input buffer at specific locations for shiffting to work
				for x_id in 0 to input_width - 1 loop

					for y_id in 0 to weight_width - 1 loop

						s_input_buffer(x_id + y_id)(y_id) <= inputs(x_id)(y_id);

					end loop;

				end loop;

			else
				-- shift every buffer by one value
				for input_buffer_y_id in 0 to weight_width - 1 loop

					s_input_vectors(input_buffer_y_id)(0) <= s_input_buffer(0)(input_buffer_y_id);

					for input_buffer_x_id in 1 to weight_width + input_width - 1 loop

						s_input_buffer(input_buffer_x_id - 1)(input_buffer_y_id) <= s_input_buffer(input_buffer_x_id)(input_buffer_y_id);

					end loop;

					s_input_buffer(weight_width + input_width - 1)(input_buffer_y_id) <= (others => '0');

				end loop;

			end if;
		end if;

	end process CALC_PROC;

	-- Generation of MACs

	x_generate_block : for x_id in 0 to weight_width - 1 generate

		y_generate_block : for y_id in 0 to weight_height - 1 generate

			MACS : entity work.mac_unit
				generic map (
					vector_length => vector_length
				)
				port map (
					clk            => clk,
					reset          => reset,
					valid          => open,
					input_vector   => s_input_vectors(x_id)(y_id),
					weight_vector  => weights(x_id)(y_id),
					partial_sum    => s_partial_sum(x_id)(y_id),
					valid_delay    => open,
					input_delay    => s_input_vectors(x_id)(y_id + 1),
					partial_result => s_partial_sum(x_id + 1)(y_id)
				);

		end generate y_generate_block;

	end generate x_generate_block;

	WRITE_BACK_PROC : process (clk) is
	begin

		if rising_edge(clk) and reset = '0' then
			-- TODO: write back and add s_partial_sum(high, y_id) to s_results
			for y_id in 0 to weight_height - 1 loop

			end loop;

		end if;

	end process WRITE_BACK_PROC;

	results <= s_results;

end architecture rtl;
