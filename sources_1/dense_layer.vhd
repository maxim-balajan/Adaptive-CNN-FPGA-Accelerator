library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;
use work.libutil.all;
use work.libmemory.all;

entity dense_layer is
	generic (
		input_length  : natural := 8;
		output_length : natural := 3 * input_length;
		-- weight_width == input_height
		max_weight_width  : natural := 400;
		max_weight_height : natural := 120;
		weight_widths  : int_list    := (400, 120, 84);
		weight_heights : int_list    := (120, 84, 10);
		weight_paths   : string_list := ("../data/layer_weight_2.data",
										 "../data/layer_weight_3.data",
										 "../data/layer_weight_4.data")
	);
	port (
		clk                  : in std_logic;
		reset                : in std_logic;
		en                   : in std_logic;
		actual_weight_width  : in std_logic_vector(integer(ceil(log2(real(max_weight_width)))) downto 0);
		actual_weight_height : in std_logic_vector(integer(ceil(log2(real(max_weight_height)))) downto 0);
		input                : in std_logic_vector(input_length - 1 downto 0);
		base_addr            : in std_logic_vector(integer(ceil(log2(real(sum_int_list(weight_widths))))) - 1 downto 0);
		results              : out matrix_1d(0 to max_weight_height - 1)(output_length - 1 downto 0);
		comp_complete        : out std_logic
	);
end entity dense_layer;

architecture rtl of dense_layer is

	signal s_weights      : matrix_1d(0 to max_weight_height - 1)(input_length - 1 downto 0);
	signal s_bram_en_line : std_logic_vector(0 to max_weight_height - 1);

begin

	MV_UNIT_INST : entity work.matrix_vector_unit
		generic map (
			max_weight_width  => max_weight_width,
			max_weight_height => max_weight_height,
			input_length      => input_length,
			output_length     => output_length
		)
		port map (
			clk                  => clk,
			reset                => reset,
			en                   => en,
			actual_weight_width  => actual_weight_width,
			actual_weight_height => actual_weight_height,
			weights              => s_weights,
			input                => input,
			bram_enable_line     => s_bram_en_line,
			results              => results,
			comp_complete        => comp_complete
		);

	MEM_INTER_CONNECT_INST : entity work.matrix_vector_mem_interconnect
		generic map (
			vector_length     => input_length,
			max_weight_width  => max_weight_width,
			max_weight_height => max_weight_height,
			weight_widths     => weight_widths,
			weight_heights    => weight_heights,
			weight_paths      => weight_paths
		)
		port map (
			clk              => clk,
			reset            => reset,
			bram_enable_line => s_bram_en_line,
			base_addr        => base_addr,
			weights          => s_weights
		);

end architecture rtl;
