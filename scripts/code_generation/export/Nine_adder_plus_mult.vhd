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


entity Nine_adder_plus_mult is
    port (
        clk   : in std_logic;
        reset : in std_logic;
        --
        i_activation_matrix_line  : in matrix_1d(0 to 20 * 9 - 1)(9 - 1 downto 0);
        i_weight_matrix_line      : in matrix_1d(0 to 20 * 9 - 1)(9 - 1 downto 0);
        i_shamt_line              : in matrix_1d(0 to 20 - 1)(9 - 1 downto 0);
        i_bias_line               : in matrix_1d(0 to 20 - 1)(9 - 1 downto 0);
        i_kernel_en_line          : in std_logic_vector(0 to 20 - 1);   
        i_kernel_complete_line    : in std_logic_vector(0 to 20 - 1);
        --
        o_pixel_line         : out matrix_1d(0 to 20 - 1)(9 - 1 downto 0);
        o_valid_pixel_line   : out std_logic_vector(0 to 20 - 1);
        o_comp_complete_line : out std_logic_vector(0 to 20 - 1)
    );
end entity Nine_adder_plus_mult;


architecture rtl of Nine_adder_plus_mult is
begin

    Nine_adder_plus_mult_GEN : for i in 0 to 20 - 1 generate
        
        Nine_adder_plus_mult_INST : entity work.kernel_computation_unit
            generic map (
                pool_or_conv                => 1,
                enable_clip_adder           => 1,
                enable_multiplication_line  => 1,
                enable_shift                => 0,
                enable_bias                 => 0,
                enable_relu                 => 1,
                input_length                => 9,
                output_length               => 24,
                input_amount                => 9
            )
            port map (
                clk                 => clk,
                reset               => reset,
                --
                activation_matrix   => i_activation_matrix_line(i * 9 to (i + 1) * 9 - 1),
                weight_matrix       => i_weight_matrix_line(i * 9 to (i + 1) * 9 - 1),
                shamt               => i_shamt_line(i),
                bias                => i_bias_line(i),
                kernel_en           => i_kernel_en_line(i),
                kernel_complete     => i_kernel_complete_line(i),
                --
                new_pixel           => o_pixel_line(i),
                valid_pixel         => o_valid_pixel_line(i),
                comp_complete       => o_comp_complete_line(i)
            );

    end generate Nine_adder_plus_mult_GEN;

end architecture rtl;
