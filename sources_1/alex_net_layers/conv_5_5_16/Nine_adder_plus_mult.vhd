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
        -- Global enable: If set to 0, stall entire unit and set outputs to low 
        i_en  : in std_logic;
        --
        i_activation_matrix_line  : in matrix_1d(0 to 40 * 10 - 1)(24 - 1 downto 0);
        i_weight_matrix_line      : in matrix_1d(0 to 40 * 10 - 1)(24 - 1 downto 0);
        i_shamt_line              : in matrix_1d(0 to 40 - 1)(24 - 1 downto 0);
        i_bias_line               : in matrix_1d(0 to 40 - 1)(24 - 1 downto 0);
        i_kernel_en_line          : in std_logic_vector(0 to 40 - 1);   
        i_kernel_complete_line    : in std_logic_vector(0 to 40 - 1);
        --
        o_pixel_line         : out matrix_1d(0 to 40 - 1)(24 - 1 downto 0);
        o_valid_pixel_line   : out std_logic_vector(0 to 40 - 1);
        o_comp_complete_line : out std_logic_vector(0 to 40 - 1)
    );
end entity Nine_adder_plus_mult;

architecture Nine_adder_plus_mult_rlt of Nine_adder_plus_mult is
begin

    Nine_adder_plus_mult_GEN : for i in 0 to 45 - 1 generate
        
        KERNEL_COMPUTATION_INST : entity work.kernel_computation_unit
            generic map (
                pool_or_conv                => 1,
                enable_clip_adder           => 1,
                enable_multiplication_line  => 1,
                enable_shift                => 0,
                enable_bias                 => 0,
                enable_relu                 => 0,
                -- Dont sanitize outputs inside of unit, otherwise wont work as expected
                G_SANITIZE_OUTPUT           => 0,
                input_length                => 8,
                output_length               => 24,
                input_amount                => 9
            )
            port map (
                clk                 => clk,
                reset               => reset,
                --
                i_en                => i_en,
                --
                activation_matrix(0)          => i_activation_matrix_line(i * 9 + 0)(7 downto 0),
                activation_matrix(1)          => i_activation_matrix_line(i * 9 + 1)(7 downto 0),
                activation_matrix(2)          => i_activation_matrix_line(i * 9 + 2)(7 downto 0),
                activation_matrix(3)          => i_activation_matrix_line(i * 9 + 3)(7 downto 0),
                activation_matrix(4)          => i_activation_matrix_line(i * 9 + 4)(7 downto 0),
                activation_matrix(5)          => i_activation_matrix_line(i * 9 + 5)(7 downto 0),
                activation_matrix(6)          => i_activation_matrix_line(i * 9 + 6)(7 downto 0),
                activation_matrix(7)          => i_activation_matrix_line(i * 9 + 7)(7 downto 0),
                activation_matrix(8)          => i_activation_matrix_line(i * 9 + 8)(7 downto 0),
                weight_matrix(0)              => i_weight_matrix_line(i * 9 + 0)(7 downto 0),
                weight_matrix(1)              => i_weight_matrix_line(i * 9 + 1)(7 downto 0),
                weight_matrix(2)              => i_weight_matrix_line(i * 9 + 2)(7 downto 0),
                weight_matrix(3)              => i_weight_matrix_line(i * 9 + 3)(7 downto 0),
                weight_matrix(4)              => i_weight_matrix_line(i * 9 + 4)(7 downto 0),
                weight_matrix(5)              => i_weight_matrix_line(i * 9 + 5)(7 downto 0),
                weight_matrix(6)              => i_weight_matrix_line(i * 9 + 6)(7 downto 0),
                weight_matrix(7)              => i_weight_matrix_line(i * 9 + 7)(7 downto 0),
                weight_matrix(8)              => i_weight_matrix_line(i * 9 + 8)(7 downto 0),
                --
                shamt               => i_shamt_line(i)(8 - 1 downto 0),
                bias                => i_bias_line(i)(24 - 1 downto 0),
                kernel_en           => i_kernel_en_line(i),
                kernel_complete     => i_kernel_complete_line(i),
                --
                new_pixel           => o_pixel_line(i)(24 - 1 downto 0),
                valid_pixel         => o_valid_pixel_line(i),
                comp_complete       => o_comp_complete_line(i)
            );

    end generate Nine_adder_plus_mult_GEN;

end architecture Nine_adder_plus_mult_rlt;
