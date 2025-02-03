library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.libmatrix.all;
use work.libmemory.all;
use std.env.finish;


entity conv_par_tb is
end entity conv_par_tb;

architecture bench of conv_par_tb is

	-- Clock period
	constant clk_period : time := 10 ns;
	-- Generics
	constant vector_length        : natural              := 8;
	constant input_width          : natural              := 32;
	constant input_height         : natural              := 32;
	constant kernel_size          : natural              := 5;
	constant pooling_size         : integer range 2 to 2 := 2;
	constant enable_clip_adder    : integer range 0 to 1 := 1;
	constant total_input_channel  : natural              := 1;
	constant total_output_channel : natural              := 6;
	constant weight_path          : string               := "../data/layer_weight_0.data";
	constant current_scale        : natural              := 1;
	constant scale_path           : string               := "../data/scale_values.data";
	constant input_path           : string               := "../data/input_7.data";
	-- Ports
	signal clk               : std_logic := '0';
	signal reset             : std_logic;
	signal pixel_stream      : std_logic_vector(vector_length - 1 downto 0);
	signal valid_pixel       : std_logic;
	signal new_pixels_stream : matrix_1d(0 to total_output_channel - 1)(vector_length - 1 downto 0);

	-- write all input data to matrix_1d
	signal s_input_stream : matrix_1d(0 to input_width * input_height - 1)(vector_length - 1 downto 0) := init_from_file(input_path, vector_length, input_width * input_height);
	signal s_read_pointer : integer range 0 to (input_width * input_height)                            := 0;

	signal s_write_pointer : integer range 0 to (14 ** 2 - 1) := 0;
	signal s_output_values : matrix_2d(0 to total_output_channel - 1)(0 to 14 ** 2 - 1)(vector_length - 1 downto 0);

	signal s_new_pixel_complete, s_new_valid_pixel : std_logic;

	-- expected output of the first convolution
	constant expected_result_path : string                                                                         := "../data/expected_output_first_conv_pool_7.data";
	constant expected_output      : matrix_1d(0 to total_output_channel * 14 ** 2 - 1)(vector_length - 1 downto 0) := init_from_file(expected_result_path, vector_length,  total_output_channel * 14 ** 2);

	signal s_test : std_logic;
begin

	STREAM_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				pixel_stream <= (others => '0');
				valid_pixel  <= '0';
				s_test <= '0';
				s_read_pointer <= 0; 
			else
				if s_read_pointer < (input_width * input_height) then
					if s_test = '0' then
						pixel_stream   <= s_input_stream(s_read_pointer);
						s_read_pointer <= s_read_pointer + 1;
						valid_pixel    <= '1';
					else
						valid_pixel <= '0';
					end if;

					s_test <= not s_test;
				else
					pixel_stream <= (others => '0');
					valid_pixel  <= '0';
				end if;
			end if;
		end if;

	end process STREAM_PROC;

	conv_par_inst : entity work.conv_par
		generic map (
			vector_length        => vector_length,
			input_width          => input_width,
			input_height         => input_height,
			kernel_size          => kernel_size,
			pooling_size         => pooling_size,
			enable_clip_adder    => enable_clip_adder,
			total_input_channel  => total_input_channel,
			total_output_channel => total_output_channel,
			weight_path          => weight_path,
			current_scale        => current_scale,
			scale_path           => scale_path
		)
		port map (
			clk                => clk,
			reset              => reset,
			pixel_stream       => pixel_stream,
			valid_pixel        => valid_pixel,
			new_pixels_stream  => new_pixels_stream,
			new_valid_pixel    => s_new_valid_pixel,
			new_pixel_complete => s_new_pixel_complete
		);

	clk   <= not clk after clk_period / 2;
	reset <= '1' after 0 ns, '0' after 2 * clk_period, '1' after 4000 * clk_period, '0' after 4010 * clk_period;

	READ_AND_CHECK_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_write_pointer <=  0;
			elsif (s_new_valid_pixel and not s_new_pixel_complete) = '1' then
				-- Read and Write to output signal
				for i in s_output_values'range loop

					s_output_values(i)(s_write_pointer) <= new_pixels_stream(i);

				end loop;

				s_write_pointer <= s_write_pointer + 1;

				-- Compare with expected result
				for i in s_output_values'range loop

					assert new_pixels_stream(i) = expected_output(i * 14 ** 2 + s_write_pointer)
						report "Expected: " & integer'image(to_integer(signed(expected_output(i * 14 ** 2 + s_write_pointer)))) & " | Got: " & integer'image(to_integer(signed(new_pixels_stream(i))))
						severity FAILURE;

				end loop;

			end if;
		end if;

	end process READ_AND_CHECK_PROC;

	TB : process is
	begin

		wait for 3000 * clk_period;
		finish;

	end process TB;

end architecture bench;
