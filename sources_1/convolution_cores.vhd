library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity convolution_cores is
	generic (
		vector_length           : natural := 8;
		G_MAX_KERNEL_SIZE       : natural := 12;
		G_LINE_BUFFER_AMOUNT    : natural := 12 * 3 * 5;
		G_CORE_AMOUNT           : natural := 20;
		G_MAX_PIXEL_OUT_STREAMS : natural := 4
	);
	port (
	    clk   : in std_logic;
		reset : in std_logic;
		--
		i_kernel_en                : in std_logic;
		i_kernel_complete          : in std_logic;
		i_kernel_activation_matrix : in matrix_1d(0 to G_MAX_KERNEL_SIZE * G_LINE_BUFFER_AMOUNT - 1)(vector_length - 1 downto 0);
		--
		o_valid_pixel   : out std_logic;
		o_pixel_streams : out matrix_1d(0 to G_MAX_PIXEL_OUT_STREAMS - 1)(vector_length - 1 downto 0)
	);
end entity convolution_cores;

architecture rtl of convolution_cores is

begin

	G_CORE_INST_GEN : for i in 0 to G_CORE_AMOUNT - 1 generate

		G_CORE_INST : entity work.kernel_computation_unit
			generic map (
				pool_or_conv               => 1,
				enable_clip_adder          => 1,
				enable_multiplication_line => 1,
				enable_shift               => 0,
				enable_bias                => 0,
				enable_relu                => 0,
				input_length               => vector_length,
				output_length              => 3 * vector_length,
				input_amount               => 9
			)
			port map (
				clk               => clk,
				reset             => reset,
				activation_matrix => open,
				weight_matrix     => open,
				shamt             => open,
				bias              => (others => '0'),
				kernel_en         => i_kernel_en,
				kernel_complete   => i_kernel_complete,
				new_pixel         => open,
				valid_pixel       => open,
				comp_complete     => open
			);

	end generate G_CORE_INST_GEN;

end architecture rtl;
