library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.libmatrix.all;
use std.env.finish;

entity combine_unit_tb is
end entity combine_unit_tb;

architecture bench of combine_unit_tb is

	-- Clock period
	constant clk_period : time := 10 ns;
	-- Generics
	constant vector_length : integer := 8;
	constant kernel_size   : integer := 5;
    constant input_amount : integer := 6;
	-- Ports
	signal clk               : std_logic := '0';
	signal reset             : std_logic;
	signal activation_matrix : matrix_1d(0 to input_amount - 1)(vector_length - 1 downto 0);
	signal kernel_en         : std_logic;
	signal kernel_complete   : std_logic;
	signal new_pixel         : std_logic_vector(vector_length - 1 downto 0);
	signal valid_pixel       : std_logic;
	signal comp_complete     : std_logic;

begin

	KERNEL_COMPUTATION_UNIT_INST : entity work.kernel_computation_unit
		generic map (
			input_length               => vector_length,
			output_length              => vector_length,
			input_amount               => input_amount,
			pool_or_conv               => 1,
			enable_bias                => 0,
			enable_multiplication_line => 0,
			enable_shift               => 1,
			enable_relu                => 1,
            enable_clip_adder => 1
		)
		port map (
			clk               => clk,
			reset             => reset,
			activation_matrix => activation_matrix,
			weight_matrix     => (others => (others => '0') ) ,
			shamt             => x"01",
			bias              => (others => '0') ,
			kernel_en         => kernel_en,
			kernel_complete   => kernel_complete,
			new_pixel         => new_pixel,
			valid_pixel       => valid_pixel,
			comp_complete     => comp_complete
		);

	clk               <= not clk after clk_period / 2;
	reset             <= '1' after 0 ns, '0' after 10 ns;
	activation_matrix <=
	(
	  others => (others => '1')
	) after 0 ns,
	  (
	    x"01",
	    x"02",
	    x"03",
	    x"04",
	    x"05",
        x"06"
	  ) after 20 ns;

	kernel_en         <= '1' after 0 ns, '0' after 20 ns,  '1' after 30 ns;
	kernel_complete   <= '0' after 0 ns, '1' after 30 ns;

	TB : process is
	begin

		wait for 30 * clk_period;
		finish;

	end process TB;

end architecture bench;
