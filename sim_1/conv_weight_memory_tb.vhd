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
	constant init_type            : integer range 0 to 1 := 0;
	constant data_path            : string               := "../data/layer_weight_0.data";
	-- Ports
	signal clk           : std_logic := '0';
	signal reset         : std_logic;
	signal base_addr     : std_logic_vector(kernel_size ** 2 * total_input_channel ** (1 - init_type) * total_output_channel ** (init_type) - 1 downto 0);
	signal weight_matrix : matrix_2d(0 to kernel_size - 1)(0 to kernel_size - 1)(vector_length - 1 downto 0);

begin

	conv_weight_memory_inst : entity work.conv_weight_memory
		generic map (
			vector_length        => vector_length,
			kernel_size          => kernel_size,
			total_input_channel  => total_input_channel,
			total_output_channel => total_output_channel,
			current_channel      => current_channel,
			init_type            => init_type,
			data_path            => data_path
		)
		port map (
			clk           => clk,
			reset         => reset,
			base_addr     => base_addr,
			weight_matrix => weight_matrix
		);

    clk <= not clk after clk_period/2;
    reset <= '1' after 0 ns, '0' after clk_period;
    base_addr <= (others => '0'); 

    TB : process
    begin
        wait for 30 * clk_period;
        finish;
    end process;

end architecture bench;
