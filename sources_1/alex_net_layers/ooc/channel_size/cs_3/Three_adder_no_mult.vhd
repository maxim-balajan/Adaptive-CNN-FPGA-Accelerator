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


entity Three_adder_no_mult is
    port (
        clk   : in std_logic;
        reset : in std_logic;
        -- Global enable: If set to 0, stall entire unit and set outputs to low 
        i_en  : in std_logic;
        --
        i_activation_matrix_line  : in matrix_1d(0 to 20 * 5 - 1)(24 - 1 downto 0);
        i_weight_matrix_line      : in matrix_1d(0 to 20 * 5 - 1)(24 - 1 downto 0);
        i_shamt_line              : in matrix_1d(0 to 20 - 1)(24 - 1 downto 0);
        i_bias_line               : in matrix_1d(0 to 20 - 1)(24 - 1 downto 0);
        i_kernel_en_line          : in std_logic_vector(0 to 20 - 1);   
        i_kernel_complete_line    : in std_logic_vector(0 to 20 - 1);
        --
        o_pixel_line         : out matrix_1d(0 to 20 - 1)(24 - 1 downto 0);
        o_valid_pixel_line   : out std_logic_vector(0 to 20 - 1);
        o_comp_complete_line : out std_logic_vector(0 to 20 - 1)
    );
end entity Three_adder_no_mult;

architecture Three_adder_no_mult_rlt of Three_adder_no_mult is
begin

    Three_adder_no_mult_GEN : for i in 0 to 4 - 1 generate
        
        KERNEL_COMPUTATION_INST : entity work.kernel_computation_unit
            generic map (
                pool_or_conv                => 1,
                enable_clip_adder           => 1,
                enable_multiplication_line  => 0,
                enable_shift                => 0,
                enable_bias                 => 0,
                enable_relu                 => 0,
                -- Dont sanitize outputs inside of unit, otherwise wont work as expected
                G_SANITIZE_OUTPUT           => 0,
                input_length                => 24,
                output_length               => 24,
                input_amount                => 3
            )
            port map (
                clk                 => clk,
                reset               => reset,
                --
                i_en                => i_en,
                --
                activation_matrix(0)          => i_activation_matrix_line(i * 3 + 0)(23 downto 0),
                activation_matrix(1)          => i_activation_matrix_line(i * 3 + 1)(23 downto 0),
                activation_matrix(2)          => i_activation_matrix_line(i * 3 + 2)(23 downto 0),
                weight_matrix(0)              => i_weight_matrix_line(i * 3 + 0)(23 downto 0),
                weight_matrix(1)              => i_weight_matrix_line(i * 3 + 1)(23 downto 0),
                weight_matrix(2)              => i_weight_matrix_line(i * 3 + 2)(23 downto 0),
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

    end generate Three_adder_no_mult_GEN;

end architecture Three_adder_no_mult_rlt;
