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


entity routing_cores_entity is
    port (
        clk   : in std_logic;
        reset : in std_logic;
        -- KERNEL_CORES_INPUT PORTS
        o_activation_matrix_line  : OUT matrix_1d(0 to %%INPUT_AMOUNT%% - 1)(%%CORE_MAX_INPUT_LENGTH%% - 1 downto 0);
        o_weight_matrix_line      : OUT matrix_1d(0 to %%INPUT_AMOUNT%% - 1)(%%CORE_MAX_INPUT_LENGTH%% - 1 downto 0);
        o_shamt_line              : OUT matrix_1d(0 to %%MAX_CORE_AMOUNT%% - 1)(%%CORE_MAX_INPUT_LENGTH%% - 1 downto 0);
        o_bias_line               : OUT matrix_1d(0 to %%MAX_CORE_AMOUNT%% - 1)(%%CORE_MAX_INPUT_LENGTH%% - 1 downto 0);
        o_kernel_en_line          : OUT std_logic_vector(0 to %%MAX_CORE_AMOUNT%% - 1);   
        o_kernel_complete_line    : OUT std_logic_vector(0 to %%MAX_CORE_AMOUNT%% - 1);
        -- KERNEL CORES OUTPUT PORTS
        i_pixel_line         : IN matrix_1d(0 to %%MAX_CORE_AMOUNT%% - 1)(%%CORE_MAX_OUTPUT_LENGTH%% - 1 downto 0);
        i_valid_pixel_line   : IN std_logic_vector(0 to %%MAX_CORE_AMOUNT%% - 1);
        i_comp_complete_line : IN std_logic_vector(0 to %%MAX_CORE_AMOUNT%% - 1);
        -- CONFIGURABLE SLIDER OUTPUTS
        i_kernel_complete          : IN std_logic;
		i_kernel_en                : IN std_logic;
		i_kernel_activation_matrix : IN matrix_1d(0 to %%MAX_KERNEL_SIZE%% * %%LINE_BUFFER_AMOUNT%% - 1)(%%CORE_MAX_INPUT_LENGTH%% - 1 downto 0);
        -- ROUTING CORES OUTPUTS
        o_kernel_complete : OUT std_logic;
        o_kernel_valid    : OUT std_logic;
        o_pixel_line      : OUT matrix_1d(0 to %%MAX_OUTPUT_CHANNELS%% - 1)(%%CORE_MAX_OUTPUT_LENGTH%% - 1 downto 0)
    );
end entity routing_cores_entity;
