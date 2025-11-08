-- ============================================================================
--  *** AUTO-GENERATED FILE ***
--  This file was generated automatically by adder_tree_gen.py.
--  DO NOT MODIFY THIS FILE MANUALLY.
--  Any changes made to this file may be lost when the file is regenerated.
-- ============================================================================

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
use work.libmatrix.all;

entity routed_kernel_cores is
	generic (
		G_VECTOR_IN_LENGTH          : natural := 8;
		G_VECTOR_OUT_LENGTH         : natural := 24;
		G_MAX_KERNEL_SIZE           : natural := 12;
		G_LINE_BUFFER_AMOUNT        : natural := 80;
		G_MAX_CORE_AMOUNT           : natural := 100;
		G_MAX_OUTPUT_CHANNEL_AMOUNT : natural := 16
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		-- Global enable: If set to 0, stall entire unit and set outputs to low
		i_en : in std_logic;
		-- CONFIGURABLE SLIDER OUTPUTS
		i_kernel_complete          : in std_logic;
		i_kernel_en                : in std_logic;
		i_kernel_activation_matrix : in matrix_1d(0 to G_MAX_KERNEL_SIZE * G_LINE_BUFFER_AMOUNT - 1)(G_VECTOR_IN_LENGTH - 1 downto 0);
		-- WEIGHT MODULE OUTPUTS
		i_kernel_weight_en     : in std_logic;
		i_kernel_weight_matrix : in matrix_1d(0 to G_MAX_KERNEL_SIZE * G_LINE_BUFFER_AMOUNT - 1)(G_VECTOR_IN_LENGTH - 1 downto 0);
		i_shamt_line           : in matrix_1d(0 to G_MAX_CORE_AMOUNT - 1)(G_VECTOR_IN_LENGTH - 1 downto 0);
		i_bias_line            : in matrix_1d(0 to G_MAX_CORE_AMOUNT - 1)(G_VECTOR_IN_LENGTH - 1 downto 0);
		-- ROUTING CORES OUTPUTS
		o_kernel_complete : out std_logic;
		o_kernel_valid    : out std_logic;
		o_pixel_line      : out matrix_1d(0 to G_MAX_OUTPUT_CHANNEL_AMOUNT - 1)(G_VECTOR_OUT_LENGTH - 1 downto 0)
	);
end entity routed_kernel_cores;

architecture route_a of routed_kernel_cores is

	-- KERNEL CORES INPUT PORTS
	signal s_activation_matrix_line : matrix_1d(0 to 700 - 1)(24 - 1 downto 0);
	signal s_weight_matrix_line     : matrix_1d(0 to 700 - 1)(24 - 1 downto 0);
	signal s_shamt_line             : matrix_1d(0 to 100 - 1)(8 - 1 downto 0);
	signal s_bias_line              : matrix_1d(0 to 100 - 1)(8 - 1 downto 0);
	signal s_kernel_en_line         : std_logic_vector(0 to 100 - 1);
	signal s_kernel_complete_line   : std_logic_vector(0 to 100 - 1);
	-- KERNEL CORES OUTPUT PORTS
	signal s_pixel_line         : matrix_1d(0 to 100 - 1)(24 - 1 downto 0);
	signal s_valid_pixel_line   : std_logic_vector(0 to 100 - 1);
	signal s_comp_complete_line : std_logic_vector(0 to 100 - 1);

begin

	ROUTING_CORES_INST : entity work.routing_cores
		port map (
			clk   => clk,
			reset => reset,
			--
			i_en => i_en,
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

	KERNEL_CORES_INST : entity work.kernel_cores
		generic map (
			G_SHAMT_AMOUNT => G_VECTOR_IN_LENGTH,
			G_BIAS_AMOUNT  => G_VECTOR_IN_LENGTH
		)
		port map (
			clk   => clk,
			reset => reset,
			--
			i_en => i_en,
			-- KERNEL CORES INPUT PORTS
			i_activation_matrix_line => s_activation_matrix_line,
			i_weight_matrix_line     => s_weight_matrix_line,
			i_shamt_line             => s_shamt_line,
			i_bias_line              => s_bias_line,
			i_kernel_en_line         => s_kernel_en_line,
			i_kernel_complete_line   => s_kernel_complete_line,
			-- KERNEL CORES OUTPUT PORTS
			o_pixel_line         => s_pixel_line,
			o_valid_pixel_line   => s_valid_pixel_line,
			o_comp_complete_line => s_comp_complete_line
		);

end architecture route_a;
