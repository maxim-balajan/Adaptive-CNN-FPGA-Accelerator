library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity convolution_computation_unit is
	generic (
		vector_length : integer := 8;
		kernel_size   : integer := 5
	);
	port (
		clk               : in std_logic;
		reset             : in std_logic;
		activation_matrix : in matrix_2d(0 to kernel_size - 1)(0 to kernel_size - 1)(vector_length - 1 downto 0);
		weight_matrix     : in matrix_2d(0 to kernel_size - 1)(0 to kernel_size - 1)(vector_length - 1 downto 0);
		kernel_en         : in std_logic;
		kernel_complete   : in std_logic;
		new_pixel         : out std_logic_vector(vector_length - 1 downto 0);
		valid_pixel       : out std_logic;
		comp_complete     : out std_logic
	);
end entity convolution_computation_unit;

architecture rtl of convolution_computation_unit is

begin

    

end architecture;
