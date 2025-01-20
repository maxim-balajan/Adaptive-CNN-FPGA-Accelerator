library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.libmatrix.all;
use std.env.finish;

entity conv_weight_memory_tb is
end entity conv_weight_memory_tb;

architecture bench of conv_weight_memory_tb is

	-- Clock period
	constant clk_period : time := 10 ns;
	-- Generics
	constant vector_length        : natural              := 8;
	constant kernel_size          : natural              := 5;
	constant total_input_channel  : natural              := 1;
	constant total_output_channel : natural              := 6;
	constant current_channel      : natural              := 3;
	constant init_type_1          : integer range 0 to 1 := 0;
	constant init_type_2          : integer range 0 to 1 := 1;
	constant data_path_1          : string               := "../data/layer_weight_0.data";
	constant data_path_2          : string               := "../data/layer_weight_1.data";
	-- Ports
	signal clk                         : std_logic := '0';
	signal reset                       : std_logic;
	signal base_addr                   : std_logic_vector(kernel_size ** 2 * 6 ** (1 - init_type_2) * 16 ** (init_type_2) - 1 downto 0);
	signal weight_matrices_first_conv  : matrix_3d(0 to 5)(0 to kernel_size - 1)(0 to kernel_size - 1)(vector_length - 1 downto 0);
	signal weight_matrices_second_conv : matrix_3d(0 to 5)(0 to kernel_size - 1)(0 to kernel_size - 1)(vector_length - 1 downto 0);
    signal mem_valid_1 : std_logic_vector(1 to 6);
    signal mem_valid_2 : std_logic_vector(1 to 6);

begin

	FIRST_CONV_MEMORYS : for i in 1 to 6 generate

		conv_weight_memory_inst : entity work.conv_weight_memory
			generic map (
				vector_length        => vector_length,
				kernel_size          => kernel_size,
				total_input_channel  => 1,
				total_output_channel => 6,
				current_channel      => i,
				init_type            => init_type_1,
				data_path            => data_path_1
			)
			port map (
				clk           => clk,
				reset         => reset,
				base_addr     => (others => '0'),
                mem_valid => mem_valid_1(i),
				weight_matrix => weight_matrices_first_conv(i - 1)
			);

	end generate FIRST_CONV_MEMORYS;

	SECOND_CONV_MEMORYS : for i in 1 to 6 generate

		conv_weight_memory_inst : entity work.conv_weight_memory
			generic map (
				vector_length        => vector_length,
				kernel_size          => kernel_size,
				total_input_channel  => 6,
				total_output_channel => 16,
				current_channel      => i,
				init_type            => init_type_2,
				data_path            => data_path_2
			)
			port map (
				clk                                => clk,
				reset                              => reset,
				base_addr(7 downto 0)              => x"19",
				base_addr(base_addr'high downto 8) => (others => '0'),
                mem_valid => mem_valid_2(i),
				weight_matrix                      => weight_matrices_second_conv(i - 1)
			);

	end generate SECOND_CONV_MEMORYS;

	clk       <= not clk after clk_period / 2;
	reset     <= '1' after 0 ns, '0' after clk_period;
	base_addr <= (others => '0');

	TB : process is
	begin

		wait for 30 * clk_period;
		finish;

	end process TB;

end architecture bench;
