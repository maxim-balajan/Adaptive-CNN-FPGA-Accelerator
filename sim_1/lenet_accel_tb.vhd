library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;
use work.libutil.all;
use work.libmemory.all;

entity lenet_accel_tb is
end entity lenet_accel_tb;

architecture bench of lenet_accel_tb is

	-- Clock period
	constant clk_period : time := 10 ns;
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
	constant scale_path                  : string               := "../data/scale_values.data";
	constant conv_shift_ids              : int_list             := (1, 2);
	constant dense_shift_ids             : int_list             := (3, 4, 5);
	constant dense_weight_widths         : int_list             := (400, 120, 84);
	constant dense_weight_heights        : int_list             := (120, 84, 10);
	constant conv_weight_paths           : string_list          :=
	(
	  "../data/layer_weight_0.data",
	  "../data/layer_weight_1.data"
	);
	constant dense_weight_paths          : string_list          :=
	(
	  "../data/layer_weight_2.data",
	  "../data/layer_weight_3.data",
	  "../data/layer_weight_4.data"
	);
	-- Ports
	signal clk           : std_logic := '0';
	signal reset         : std_logic;
	signal pixel_stream  : std_logic_vector(vector_length - 1 downto 0);
	signal valid_pixel   : std_logic;
	signal image_label   : std_logic_vector(integer(ceil(log2(real(dense_weight_heights(dense_weight_heights'high))))) - 1 downto 0);
	signal comp_complete : std_logic;

	-- write all input data to matrix_1d
	constant input_path_2     : string                                                                     := "../data/input_2.data";

	signal   s_input_stream_2 : matrix_1d(0 to input_width * input_height - 1)(vector_length - 1 downto 0) := init_from_file(input_path_2, vector_length, input_width * input_height);
	constant input_path_7 : string := "../data/input_7.data";
	signal s_input_stream_7 : matrix_1d(0 to input_width * input_height - 1)(vector_length - 1 downto 0) := init_from_file(input_path_7, vector_length, input_width * input_height);
	signal   s_read_pointer : integer range 0 to (input_width * input_height);

	signal s_actual_input_stream : matrix_1d(0 to input_width * input_height - 1)(vector_length - 1 downto 0);
	signal s_invalid_delay : integer range 0 to 3;
	signal s_iteration : integer := 0;

begin

	s_actual_input_stream <= s_input_stream_2 when s_iteration = 0 else s_input_stream_7;

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
						pixel_stream   <= s_actual_input_stream(s_read_pointer);
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

	lenet_accel_inst : entity work.lenet_accel
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
			scale_path                  => scale_path,
			conv_shift_ids              => conv_shift_ids,
			dense_shift_ids             => dense_shift_ids,
			dense_weight_widths         => dense_weight_widths,
			dense_weight_heights        => dense_weight_heights,
			conv_weight_paths           => conv_weight_paths,
			dense_weight_paths          => dense_weight_paths
		)
		port map (
			clk           => clk,
			reset         => reset,
			pixel_stream  => pixel_stream,
			valid_pixel   => valid_pixel,
			image_label   => image_label,
			comp_complete => comp_complete
		);

	clk   <= not clk after clk_period / 2;
	reset <= '1' after 0 ns, '0' after 2 * clk_period, '1' after 10000 * clk_period, '0' after 10002 * clk_period;

	TB : process (comp_complete)
	begin
		if rising_edge(comp_complete) then 
			s_iteration <= s_iteration + 1;
		end if;
	end process;

end architecture bench;
