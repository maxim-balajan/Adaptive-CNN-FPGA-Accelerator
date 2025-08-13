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


entity Nine_pooling is
    port (
        clk   : in std_logic;
        reset : in std_logic;
        --
        i_activation_matrix_line  : in matrix_1d(0 to 2 * 10 - 1)(24 - 1 downto 0);
        i_weight_matrix_line      : in matrix_1d(0 to 2 * 10 - 1)(24 - 1 downto 0);
        i_shamt_line              : in matrix_1d(0 to 2 - 1)(24 - 1 downto 0);
        i_bias_line               : in matrix_1d(0 to 2 - 1)(24 - 1 downto 0);
        i_kernel_en_line          : in std_logic_vector(0 to 2 - 1);   
        i_kernel_complete_line    : in std_logic_vector(0 to 2 - 1);
        --
        o_pixel_line         : out matrix_1d(0 to 2 - 1)(24 - 1 downto 0);
        o_valid_pixel_line   : out std_logic_vector(0 to 2 - 1);
        o_comp_complete_line : out std_logic_vector(0 to 2 - 1)
    );
end entity Nine_pooling;

architecture Nine_pooling_rtl of Nine_pooling is
begin

    Nine_pooling_GEN : for i in 0 to 2 - 1 generate
        
        KERNEL_COMPUTATION_INST : entity work.kernel_computation_unit
            generic map (
                pool_or_conv                => 0,
                enable_clip_adder           => 1,
                enable_multiplication_line  => 0,
                enable_shift                => 0,
                enable_bias                 => 0,
                enable_relu                 => 1,
                input_length                => 24,
                output_length               => 24,
                input_amount                => 9
            )
            port map (
                clk                 => clk,
                reset               => reset,
                --
                activation_matrix(0)          => i_activation_matrix_line(i * 9 + 0)(23 downto 0),
                activation_matrix(1)          => i_activation_matrix_line(i * 9 + 1)(23 downto 0),
                activation_matrix(2)          => i_activation_matrix_line(i * 9 + 2)(23 downto 0),
                activation_matrix(3)          => i_activation_matrix_line(i * 9 + 3)(23 downto 0),
                activation_matrix(4)          => i_activation_matrix_line(i * 9 + 4)(23 downto 0),
                activation_matrix(5)          => i_activation_matrix_line(i * 9 + 5)(23 downto 0),
                activation_matrix(6)          => i_activation_matrix_line(i * 9 + 6)(23 downto 0),
                activation_matrix(7)          => i_activation_matrix_line(i * 9 + 7)(23 downto 0),
                activation_matrix(8)          => i_activation_matrix_line(i * 9 + 8)(23 downto 0),
                weight_matrix                 => (others => (others => '0')),
                --
                shamt               => i_shamt_line(i)(24 - 1 downto 0),
                bias                => i_bias_line(i)(24 - 1 downto 0),
                kernel_en           => i_kernel_en_line(i),
                kernel_complete     => i_kernel_complete_line(i),
                --
                new_pixel           => o_pixel_line(i)(24 - 1 downto 0),
                valid_pixel         => o_valid_pixel_line(i),
                comp_complete       => o_comp_complete_line(i)
            );

    end generate Nine_pooling_GEN;

end architecture Nine_pooling_rtl;
