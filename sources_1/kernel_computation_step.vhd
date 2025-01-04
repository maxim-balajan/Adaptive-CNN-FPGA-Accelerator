library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity kernel_computation_step is
	generic (
		vector_length : natural              := 8;
		input_width   : natural;
		pool_or_conv  : integer range 0 to 1 := 1
	);
	port (
		clk                 : in std_logic;
		reset               : in std_logic;
		input_matrix        : in matrix_1d(0 to input_width - 1)(vector_length - 1 downto 0);
		kernel_en           : in std_logic;
		kernel_complete     : in std_logic;
		output_matrix       : out matrix_1d(0 to integer(ceil(real(input_width) / 2.0)) - 1)(vector_length - 1 downto 0);
		kernel_en_del       : out std_logic;
		kernel_complete_del : out std_logic
	);
end entity kernel_computation_step;

architecture rtl of kernel_computation_step is

	-- increase s_input_matrix size by 1 in order to deal with uneven vector lengths correctly and to make HW more maintainable
	signal s_input_matrix    : matrix_1d(0 to input_width)(vector_length - 1 downto 0);
	signal s_output_matrix   : matrix_1d(0 to integer(ceil(real(input_width) / 2.0)) - 1)(vector_length - 1 downto 0);
	signal s_kernel_en_del   : std_logic;
	signal s_kernel_comp_del : std_logic;

begin

	DELAY_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_input_matrix    <= (others => (others => '0'));
				s_kernel_en_del   <= '0';
				s_kernel_comp_del <= '0';
			else
				s_input_matrix(input_matrix'range) <= input_matrix;
				s_kernel_en_del                    <= kernel_en;
				s_kernel_comp_del                  <= kernel_complete;
			end if;
		end if;

	end process DELAY_PROC;

	-- This generates an extra adder/comperator for all steps with uneven input sizes.
	-- This will result in extra HW but for our usecase this boils down to 3 adders per conv computation unit and no extra comperators for the pooling,
	-- whilst making the code much more easily maintainable. But remember that this could be solved more efficiently!
	-- This unit also does ReLU for uneven vector lengths when using comperation, but this won't happen in our usecase

	MAP_GEN : for i in s_output_matrix'range generate

		CONV_OR_POOL_GEN : if pool_or_conv = 1 generate
			s_output_matrix(i) <= std_logic_vector(signed(s_input_matrix(2 * i)) + signed(s_input_matrix(2 * i + 1)));
		else generate
			s_output_matrix(i) <= s_input_matrix(2 * i) when signed(s_input_matrix(2 * i)) > signed(s_input_matrix(2 * i + 1)) else
	                      s_input_matrix(2 * i + 1);
		end generate CONV_OR_POOL_GEN;

	end generate MAP_GEN;

	-- Set outputs
	output_matrix       <= s_output_matrix;
	kernel_en_del       <= s_kernel_en_del;
	kernel_complete_del <= s_kernel_comp_del;

end architecture rtl;
