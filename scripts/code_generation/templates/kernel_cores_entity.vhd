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
use %%CORE_COMPILE_LIB%%.libmatrix.all;

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
		i_activation_matrix_line : in matrix_1d(0 to %%INPUT_AMOUNT%% - 1)(%%CORE_MAX_INPUT_LENGTH%% - 1 downto 0);
		i_weight_matrix_line     : in matrix_1d(0 to %%INPUT_AMOUNT%% - 1)(%%CORE_MAX_INPUT_LENGTH%% - 1 downto 0);
		i_shamt_line             : in matrix_1d(0 to %%MAX_CORE_AMOUNT%% - 1)(G_SHAMT_AMOUNT - 1 downto 0);
		i_bias_line              : in matrix_1d(0 to %%MAX_CORE_AMOUNT%% - 1)(G_BIAS_AMOUNT - 1 downto 0);
		i_kernel_en_line         : in std_logic_vector(0 to %%MAX_CORE_AMOUNT%% - 1);
		i_kernel_complete_line   : in std_logic_vector(0 to %%MAX_CORE_AMOUNT%% - 1);
		-- KERNEL CORES OUTPUT PORTS
		o_pixel_line         : out matrix_1d(0 to %%MAX_CORE_AMOUNT%% - 1)(%%CORE_MAX_OUTPUT_LENGTH%% - 1 downto 0);
		o_valid_pixel_line   : out std_logic_vector(0 to %%MAX_CORE_AMOUNT%% - 1);
		o_comp_complete_line : out std_logic_vector(0 to %%MAX_CORE_AMOUNT%% - 1)
	);
end entity kernel_cores;
