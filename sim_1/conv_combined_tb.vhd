library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.libmatrix.all;
use work.libutil.all;
use work.libmemory.all;
use std.env.finish;

entity conv_combined_tb is
end entity conv_combined_tb;

architecture bench of conv_combined_tb is

	-- Clock period
	constant clk_period : time := 5 ns;
	-- Generics
	constant vector_length               : natural              := 8;
	constant accumulator_length          : natural              := 24;
	constant input_width                 : natural              := 32;
	constant input_height                : natural              := 32;
	constant kernel_size                 : natural              := 5;
	constant pooling_size                : integer range 2 to 2 := 2;
	constant enable_clip_adder           : integer range 0 to 1 := 1;
	constant total_input_channel_conv_1  : natural              := 1;
	constant total_input_channel_conv_2  : natural              := 6;
	constant total_output_channel_conv_2 : natural              := 16;
	constant weight_path_conv_1          : string               := "../data/layer_weight_0.data";
	constant weight_path_conv_2          : string               := "../data/layer_weight_1.data";
	constant scales                      : int_list             := (1, 2);
	constant scale_path                  : string               := "../data/scale_values.data";
	-- Ports
	signal clk                : std_logic := '0';
	signal reset              : std_logic;
	signal pixel_stream       : std_logic_vector(vector_length - 1 downto 0);
	signal valid_pixel        : std_logic;
	signal new_pixel_stream   : std_logic_vector(vector_length - 1 downto 0);
	signal new_valid_pixel    : std_logic;
	signal new_pixel_complete : std_logic;

	-- write all input data to matrix_1d
	constant input_path     : string                                                                     := "../data/example_layer_data/0_input.data";
	signal   s_input_stream : matrix_1d(0 to input_width * input_height - 1)(vector_length - 1 downto 0) := init_from_file(input_path, vector_length, input_width * input_height);
	signal   s_read_pointer : integer range 0 to (input_width * input_height);

	signal s_write_pointer : integer;

	-- expected output of the first convolution
	constant expected_result_path : string                                                                                         := "../data/example_layer_data/5_flatten.data";
	signal   actual_output        : matrix_1d(0 to total_output_channel_conv_2 * kernel_size ** 2 - 1)(vector_length - 1 downto 0);
	constant expected_output      : matrix_1d(0 to total_output_channel_conv_2 * kernel_size ** 2 - 1)(vector_length - 1 downto 0) := init_from_file(expected_result_path, vector_length,  16 * (5 ** 2));

	signal s_invalid_delay : integer range 0 to 3;
    signal s_comp_counter : integer range 0 to 2 := 0;

begin

	STREAM_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				pixel_stream    <= (others => '0');
				valid_pixel     <= '0';
				s_invalid_delay <= 0;
				s_read_pointer  <= 0;
			else
				if s_read_pointer < (input_width * input_height) then
					if s_invalid_delay = 0 then
						pixel_stream   <= s_input_stream(s_read_pointer);
						s_read_pointer <= s_read_pointer + 1;
						valid_pixel    <= '1';
					else
						valid_pixel <= '0';
					end if;

					if s_invalid_delay /= 3 then
						s_invalid_delay <= s_invalid_delay + 1;
					else
						s_invalid_delay <= 0;
					end if;
				else
					pixel_stream <= (others => '0');
					valid_pixel  <= '0';
				end if;
			end if;
		end if;

	end process STREAM_PROC;

	conv_combined_inst : entity work.conv_combined
		generic map (
			vector_length               => vector_length,
			accumulator_length          => accumulator_length,
			input_width                 => input_width,
			input_height                => input_height,
			kernel_size                 => kernel_size,
			pooling_size                => pooling_size,
			enable_clip_adder           => enable_clip_adder,
			total_input_channel_conv_1  => total_input_channel_conv_1,
			total_input_channel_conv_2  => total_input_channel_conv_2,
			total_output_channel_conv_2 => total_output_channel_conv_2,
			weight_path_conv_1          => weight_path_conv_1,
			weight_path_conv_2          => weight_path_conv_2,
			scales                      => scales,
			scale_path                  => scale_path
		)
		port map (
			clk                => clk,
			reset              => reset,
			pixel_stream       => pixel_stream,
			valid_pixel        => valid_pixel,
			new_pixel_stream   => new_pixel_stream,
			new_valid_pixel    => new_valid_pixel,
			new_pixel_complete => new_pixel_complete
		);

	clk   <= not clk after clk_period / 2;
	reset <= '1' after 0 ns, '0' after 2 * clk_period, '1' after 7500 * clk_period, '0' after 7510 * clk_period;

	READ_AND_CHECK_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_write_pointer <= 0;
			elsif (new_valid_pixel and not new_pixel_complete) = '1' then
				-- Read and Write to output signal
				actual_output(s_write_pointer) <= new_pixel_stream;

				if s_write_pointer >= total_output_channel_conv_2 * kernel_size ** 2 - 1 then
					s_write_pointer <= 0;
				else
					s_write_pointer <= s_write_pointer + 1;
				end if;

				-- Compare with expected result

				assert new_pixel_stream = expected_output(s_write_pointer)
					report "Expected: " & integer'image(to_integer(unsigned(expected_output(s_write_pointer)))) &
					       " | Got: " & integer'image(to_integer(signed(actual_output(s_write_pointer))))
					severity FAILURE;
			end if;
		end if;

	end process READ_AND_CHECK_PROC;

	TB : process (new_pixel_complete) is
	begin
		if rising_edge(new_pixel_complete) then
            if s_comp_counter = 1 then
			    finish;
            else
                s_comp_counter <= s_comp_counter + 1;
            end if;
		end if;

	end process TB;

end architecture bench;
