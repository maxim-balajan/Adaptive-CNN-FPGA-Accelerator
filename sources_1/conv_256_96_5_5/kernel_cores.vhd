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
	generic (
		G_SHAMT_AMOUNT : natural;
		G_BIAS_AMOUNT  : natural
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		-- Global enable: If set to 0, stall entire unit and set outputs to low
		i_en : in std_logic;
		-- KERNEL_CORES_INPUT PORTS
		i_activation_matrix_line : in matrix_1d(0 to 500 - 1)(24 - 1 downto 0);
		i_weight_matrix_line     : in matrix_1d(0 to 500 - 1)(24 - 1 downto 0);
		i_shamt_line             : in matrix_1d(0 to 100 - 1)(G_SHAMT_AMOUNT - 1 downto 0);
		i_bias_line              : in matrix_1d(0 to 100 - 1)(G_BIAS_AMOUNT - 1 downto 0);
		i_kernel_en_line         : in std_logic_vector(0 to 100 - 1);
		i_kernel_complete_line   : in std_logic_vector(0 to 100 - 1);
		-- KERNEL CORES OUTPUT PORTS
		o_pixel_line         : out matrix_1d(0 to 100 - 1)(24 - 1 downto 0);
		o_valid_pixel_line   : out std_logic_vector(0 to 100 - 1);
		o_comp_complete_line : out std_logic_vector(0 to 100 - 1)
	);
end entity kernel_cores;

architecture rtl of kernel_cores is
begin


	-- Adder Core Bundle with 30 Cores

	Nine_adder_plus_mult_inst : entity work.Nine_adder_plus_mult(Nine_adder_plus_mult_rlt)
		port map (
			clk   => clk,
			reset => reset,
			--
			i_en  => i_en,
			--
            i_activation_matrix_line          => i_activation_matrix_line(0 TO 399),
            i_weight_matrix_line              => i_weight_matrix_line(0 TO 399),
            i_shamt_line                      => (others => (others => '0')),
            i_bias_line                       => (others => (others => '0')),
            i_kernel_en_line                  => i_kernel_en_line(0 TO 39),
            i_kernel_complete_line            => i_kernel_complete_line(0 TO 39),
			--
            o_pixel_line                      => o_pixel_line(0 TO 39),
            o_valid_pixel_line                => o_valid_pixel_line(0 TO 39),
            o_comp_complete_line              => o_comp_complete_line(0 TO 39)
		);

	-- Adder Core Bundle with 10 Cores

	Four_adder_no_mult_inst : entity work.Four_adder_no_mult(Four_adder_no_mult_rtl)
		port map (
			clk   => clk,
			reset => reset,
			--
			i_en  => i_en,
			--
            i_activation_matrix_line          => i_activation_matrix_line(400 TO 474),
            i_weight_matrix_line              => i_weight_matrix_line(400 TO 474),
            i_shamt_line                      => (others => (others => '0')),
            i_bias_line                       => (others => (others => '0')),
            i_kernel_en_line                  => i_kernel_en_line(40 TO 54),
            i_kernel_complete_line            => i_kernel_complete_line(40 TO 54),
			--
            o_pixel_line                      => o_pixel_line(40 TO 54),
            o_valid_pixel_line                => o_valid_pixel_line(40 TO 54),
            o_comp_complete_line              => o_comp_complete_line(40 TO 54)
		);


end architecture rtl;
