-- ============================================================================
--  *** AUTO-GENERATED FILE ***
--  This file was generated automatically by adder_tree_gen.py.
--  DO NOT MODIFY THIS FILE MANUALLY.
--  Any changes made to this file may be lost when the file is regenerated.
-- ============================================================================


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;


entity kernel_cores is
    port (
        clk   : in std_logic;
        reset : in std_logic;
        --
        i_activation_matrix_line  : in matrix_1d(0 to 100 - 1)(24 - 1 downto 0);
        i_weight_matrix_line      : in matrix_1d(0 to 100 - 1)(24 - 1 downto 0);
        i_shamt_line              : in matrix_1d(0 to 10 - 1)(24 - 1 downto 0);
        i_bias_line               : in matrix_1d(0 to 10 - 1)(24 - 1 downto 0);
        i_kernel_en_line          : in std_logic_vector(0 to 10 - 1);   
        i_kernel_complete_line    : in std_logic_vector(0 to 10 - 1);
        --
        o_pixel_line         : out matrix_1d(0 to 10 - 1)(24 - 1 downto 0);
        o_valid_pixel_line   : out std_logic_vector(0 to 10 - 1);
        o_comp_complete_line : out std_logic_vector(0 to 10 - 1)
    );
end entity kernel_cores;

architecture rtl of kernel_cores is
begin


	-- Adder Core Bundle with 2 Cores

	Five_adder_plus_mult_inst : entity work.Five_adder_plus_mult(Five_adder_plus_mult_rlt)
		port map (
			clk   => clk,
			reset => reset,
			--
            i_activation_matrix_line          => i_activation_matrix_line(0 TO 39),
            i_weight_matrix_line              => i_weight_matrix_line(0 TO 39),
            i_shamt_line                      => (others => (others => '0')),
            i_bias_line                       => (others => (others => '0')),
            i_kernel_en_line                  => i_kernel_en_line(0 TO 4),
            i_kernel_complete_line            => i_kernel_complete_line(0 TO 4),
			--
            o_pixel_line                      => o_pixel_line(0 TO 4),
            o_valid_pixel_line                => o_valid_pixel_line(0 TO 4),
            o_comp_complete_line              => o_comp_complete_line(0 TO 4)
		);

	-- Adder Core Bundle with 2 Cores

	Three_adder_no_mult_inst : entity work.Three_adder_no_mult(Three_adder_no_mult_rtl)
		port map (
			clk   => clk,
			reset => reset,
			--
            i_activation_matrix_line          => i_activation_matrix_line(40 TO 54),
            i_weight_matrix_line              => i_weight_matrix_line(40 TO 54),
            i_shamt_line                      => (others => (others => '0')),
            i_bias_line                       => (others => (others => '0')),
            i_kernel_en_line                  => i_kernel_en_line(5 TO 7),
            i_kernel_complete_line            => i_kernel_complete_line(5 TO 7),
			--
            o_pixel_line                      => o_pixel_line(5 TO 7),
            o_valid_pixel_line                => o_valid_pixel_line(5 TO 7),
            o_comp_complete_line              => o_comp_complete_line(5 TO 7)
		);

	-- Comparator Core Bundle with 2 Cores

	Nine_pooling_inst : entity work.Nine_pooling(Nine_pooling_rtl)
		port map (
			clk   => clk,
			reset => reset,
			--
            i_activation_matrix_line          => i_activation_matrix_line(55 TO 74),
            i_weight_matrix_line              => (others => (others => '0')),
            i_shamt_line                      => (others => (others => '0')),
            i_bias_line                       => (others => (others => '0')),
            i_kernel_en_line                  => i_kernel_en_line(8 TO 9),
            i_kernel_complete_line            => i_kernel_complete_line(8 TO 9),
			--
            o_pixel_line                      => o_pixel_line(8 TO 9),
            o_valid_pixel_line                => o_valid_pixel_line(8 TO 9),
            o_comp_complete_line              => o_comp_complete_line(8 TO 9)
		);


end architecture rtl;
