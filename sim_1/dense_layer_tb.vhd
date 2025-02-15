library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;
use work.libutil.all;
use work.libmemory.all;
use std.env.finish;

entity dense_layer_tb is
end entity dense_layer_tb;

architecture bench of dense_layer_tb is

	-- Constants
	constant clk_period      : time    := 10 ns;
	constant scale_file_name : string  := "../data/scale_values.data";
	constant scale_row       : natural := 3;
	-- Generics
	constant vector_length     : natural              := 8;
	constant max_weight_width  : natural              := 400;
	constant max_weight_height : natural              := 120;
	constant enable_shift      : integer range 0 to 1 := 1;
	constant weight_widths     : int_list             := (400, 120, 84);
	constant weight_heights    : int_list             := (120, 84, 10);
	constant weight_paths      : string_list          :=
	(
	  "../data/layer_weight_2.data",
	  "../data/layer_weight_3.data",
	  "../data/layer_weight_4.data"
	);
	-- Ports
	signal   clk                  : std_logic                                    := '0';
	signal   reset                : std_logic;
	signal   en                   : std_logic;
	signal   actual_weight_width  : std_logic_vector(integer(ceil(log2(real(max_weight_width)))) downto 0);
	signal   actual_weight_height : std_logic_vector(integer(ceil(log2(real(max_weight_height)))) downto 0);
	signal   input                : std_logic_vector(vector_length - 1 downto 0);
	constant shamt                : std_logic_vector(vector_length - 1 downto 0) := read_scale_value(scale_file_name, vector_length, vector_length, scale_row);
	signal   base_addr            : std_logic_vector(integer(ceil(log2(real(sum_int_list(weight_widths))))) - 1 downto 0);
	signal   results              : matrix_1d(0 to max_weight_height - 1)(vector_length - 1 downto 0);
	signal   comp_complete        : std_logic;

	constant c_input_data_file_name : string                                                           := "../data/example_layer_data/5_flatten.data";
	signal   input_stream           : matrix_1d(0 to max_weight_width - 1)(vector_length - 1 downto 0) := init_from_file(c_input_data_file_name, vector_length, max_weight_width);
	signal   read_pointer           : integer;
	signal   invalid_delay          : integer range 0 to 3;

begin

	dense_layer_inst : entity work.dense_layer
		generic map (
			vector_length     => vector_length,
			max_weight_width  => max_weight_width,
			max_weight_height => max_weight_height,
			enable_shift      => enable_shift,
			weight_widths     => weight_widths,
			weight_heights    => weight_heights,
			weight_paths      => weight_paths
		)
		port map (
			clk                  => clk,
			reset                => reset,
			en                   => en,
			input                => input,
			actual_weight_width  => actual_weight_width,
			actual_weight_height => actual_weight_height,
			shamt                => shamt,
			base_addr            => base_addr,
			results              => results,
			comp_complete        => comp_complete
		);

	clk                  <= not clk after clk_period / 2;
	reset                <= '1' after 0 ns, '0' after 2 * clk_period;
	actual_weight_width  <= std_logic_vector(to_unsigned(max_weight_width, actual_weight_width'length));
	actual_weight_height <= std_logic_vector(to_unsigned(max_weight_height, actual_weight_height'length));
	base_addr            <= (others => '0');

	INPUT_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				input         <= (others => '0');
				read_pointer  <= 0;
				en            <= '0';
				invalid_delay <= 0;
			else
				if invalid_delay = 0 then
					input <= input_stream(read_pointer);
					en    <= '1';
					if read_pointer >= max_weight_width - 1 then
						read_pointer <= 0;
					else
						read_pointer <= read_pointer + 1;
					end if;
				else
					input <= (others => '1');
					en    <= '0';
				end if;
				if invalid_delay >= 3 then
					invalid_delay <= 0;
				else
					invalid_delay <= invalid_delay + 1;
				end if;
			end if;
		end if;

	end process INPUT_PROC;

	TB : process is
	begin

		wait for 1000 * clk_period;
		finish;

	end process TB;

end architecture bench;
