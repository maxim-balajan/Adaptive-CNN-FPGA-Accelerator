-- ============================================================================
--  *** AUTO-GENERATED FILE ***
--  This file was generated automatically by adder_tree_gen.py.
--  DO NOT MODIFY THIS FILE MANUALLY.
--  Any changes made to this file may be lost when the file is regenerated.
-- ============================================================================


LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.math_real.ALL;
USE work.libmatrix.ALL;


ENTITY routed_kernel_cores IS
	PORT (
		clk   : IN std_logic;
		reset : IN std_logic;
		-- CONFIGURABLE SLIDER OUTPUTS
		i_kernel_complete          : IN std_logic;
		i_kernel_en                : IN std_logic;
		i_kernel_activation_matrix : IN matrix_1d(0 to 11 * 180 - 1)(24 - 1 downto 0);
		-- WEIGHT MODULE OUTPUTS
		i_kernel_weight_en     : IN std_logic;
		i_kernel_weight_matrix : IN matrix_1d(0 to 11 * 180 - 1)(24 - 1 downto 0);
		i_shamt_line           : IN matrix_1d(0 to 300 - 1)(24 - 1 downto 0);
		i_bias_line            : IN matrix_1d(0 to 300 - 1)(24 - 1 downto 0);
		-- ROUTING CORES OUTPUTS
		o_kernel_complete : OUT std_logic;
		o_kernel_valid    : OUT std_logic;
		o_pixel_line      : OUT matrix_1d(0 to 5 - 1)(24 - 1 downto 0)
	);
END ENTITY routed_kernel_cores;


ARCHITECTURE route_a OF routed_kernel_cores IS

	-- KERNEL CORES INPUT PORTS
	SIGNAL s_activation_matrix_line : matrix_1d(0 to 6000 - 1)(24 - 1 downto 0);
	SIGNAL s_weight_matrix_line     : matrix_1d(0 to 6000 - 1)(24 - 1 downto 0);
	SIGNAL s_shamt_line             : matrix_1d(0 to 300 - 1)(24 - 1 downto 0);
	SIGNAL s_bias_line              : matrix_1d(0 to 300 - 1)(24 - 1 downto 0);
	SIGNAL s_kernel_en_line         : std_logic_vector(0 to 300 - 1);
	SIGNAL s_kernel_complete_line   : std_logic_vector(0 to 300 - 1);
	-- KERNEL CORES OUTPUT PORTS
	SIGNAL s_pixel_line         : matrix_1d(0 to 300 - 1)(24 - 1 downto 0);
	SIGNAL s_valid_pixel_line   : std_logic_vector(0 to 300 - 1);
	SIGNAL s_comp_complete_line : std_logic_vector(0 to 300 - 1);

BEGIN

	ROUTING_CORES_INST : ENTITY work.routing_cores
		PORT MAP (
			clk   => clk,
			reset => reset,
			-- KERNEL CORES INPUT PORTS
			o_activation_matrix_line => s_activation_matrix_line,
			o_weight_matrix_line     => s_weight_matrix_line,
			o_shamt_line             => s_shamt_line,
			o_bias_line              => s_bias_line,
			o_kernel_en_line         => s_kernel_en_line,
			o_kernel_complete_line   => s_kernel_complete_line,
			-- KERNEL CORES OUTPUT PORTS
			i_pixel_line         => s_pixel_line,
			i_valid_pixel_line   => s_valid_pixel_line,
			i_comp_complete_line => s_comp_complete_line,
			-- CONFIGURABLE SLIDER OUTPUTS
			i_kernel_complete          => i_kernel_complete,
			i_kernel_en                => i_kernel_en,
			i_kernel_activation_matrix => i_kernel_activation_matrix,
			-- WEIGHT MODULE OUTPUTS
			i_kernel_weight_en     => i_kernel_weight_en,
			i_kernel_weight_matrix => i_kernel_weight_matrix,
			i_shamt_line           => i_shamt_line,
			i_bias_line            => i_bias_line,
			-- ROUTING CORES OUTPUTS
			o_kernel_complete => o_kernel_complete,
			o_kernel_valid    => o_kernel_valid,
			o_pixel_line      => o_pixel_line
		);

	KERNEL_CORES_INST : ENTITY work.kernel_cores
		PORT MAP (
			clk                      => clk,
			reset                    => reset,
            -- KERNEL CORES INPUT PORTS
			i_activation_matrix_line => s_activation_matrix_line,
			i_weight_matrix_line     => s_weight_matrix_line,
			i_shamt_line             => s_shamt_line,
			i_bias_line              => s_bias_line,
			i_kernel_en_line         => s_kernel_en_line,
			i_kernel_complete_line   => s_kernel_complete_line,
			-- KERNEL CORES OUTPUT PORTS
            o_pixel_line             => s_pixel_line,
			o_valid_pixel_line       => s_valid_pixel_line,
			o_comp_complete_line     => s_comp_complete_line
		);

END ARCHITECTURE route_a;
