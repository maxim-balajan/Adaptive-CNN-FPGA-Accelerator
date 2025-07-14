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


entity %%CORE_NAME%% is
    port (
        clk   : in std_logic;
        reset : in std_logic;
        --
        i_activation_matrix_line  : in matrix_1d(0 to %%CORE_AMOUNT%% * %%CORE_INPUT_AMOUNT%% - 1)(%%CORE_INPUT_LENGTH%% - 1 downto 0);
        i_weight_matrix_line      : in matrix_1d(0 to %%CORE_AMOUNT%% * %%CORE_INPUT_AMOUNT%% - 1)(%%CORE_INPUT_LENGTH%% - 1 downto 0);
        i_shamt_line              : in matrix_1d(0 to %%CORE_AMOUNT%% - 1)(%%CORE_INPUT_LENGTH%% - 1 downto 0);
        i_bias_line               : in matrix_1d(0 to %%CORE_AMOUNT%% - 1)(%%CORE_INPUT_LENGTH%% - 1 downto 0);
        i_kernel_en_line          : in std_logic_vector(0 to %%CORE_AMOUNT%% - 1);   
        i_kernel_complete_line    : in std_logic_vector(0 to %%CORE_AMOUNT%% - 1);
        --
        o_pixel_line         : out matrix_1d(0 to %%CORE_AMOUNT%% - 1)(%%CORE_INPUT_LENGTH%% - 1 downto 0);
        o_valid_pixel_line   : out std_logic_vector(0 to %%CORE_AMOUNT%% - 1);
        o_comp_complete_line : out std_logic_vector(0 to %%CORE_AMOUNT%% - 1)
    );
end entity %%CORE_NAME%%;


architecture rtl of %%CORE_NAME%% is
begin

    %%CORE_NAME%%_GEN : for i in 0 to %%CORE_AMOUNT%% - 1 generate
        
        %%CORE_NAME%%_INST : entity %%CORE_COMPILE_LIB%%.kernel_computation_unit
            generic map (
                pool_or_conv                => %%CORE_TYPE%%,
                enable_clip_adder           => %%CORE_CLIP_ADDER%%,
                enable_multiplication_line  => %%CORE_MULTIPLICATION_LINE%%,
                enable_shift                => %%CORE_SHIFT%%,
                enable_bias                 => %%CORE_BIAS%%,
                enable_relu                 => %%CORE_RELU%%,
                input_length                => %%CORE_INPUT_LENGTH%%,
                output_length               => %%CORE_OUTPUT_LENGTH%%,
                input_amount                => %%CORE_INPUT_AMOUNT%%
            )
            port map (
                clk                 => clk,
                reset               => reset,
                --
                activation_matrix   => i_activation_matrix_line(i * %%CORE_INPUT_AMOUNT%% to (i + 1) * %%CORE_INPUT_AMOUNT%% - 1),
                weight_matrix       => i_weight_matrix_line(i * %%CORE_INPUT_AMOUNT%% to (i + 1) * %%CORE_INPUT_AMOUNT%% - 1),
                shamt               => i_shamt_line(i),
                bias                => i_bias_line(i),
                kernel_en           => i_kernel_en_line(i),
                kernel_complete     => i_kernel_complete_line(i),
                --
                new_pixel           => o_pixel_line(i),
                valid_pixel         => o_valid_pixel_line(i),
                comp_complete       => o_comp_complete_line(i)
            );

    end generate %%CORE_NAME%%_GEN;

end architecture rtl;
