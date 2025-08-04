
architecture %%CORE_ARCHITECTURE_NAME%% of %%CORE_ENTITY_NAME%% is
begin

    %%CORE_ENTITY_NAME%%_GEN : for i in 0 to %%CORE_AMOUNT%% - 1 generate
        
        KERNEL_COMPUTATION_INST : entity %%CORE_COMPILE_LIB%%.kernel_computation_unit
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
%%CORE_ACTIVATION_MATRIX%%
%%CORE_WEIGHT_MATRIX%%
                --
                shamt               => i_shamt_line(i)(%%CORE_INPUT_LENGTH%% - 1 downto 0),
                bias                => i_bias_line(i)(%%CORE_OUTPUT_LENGTH%% - 1 downto 0),
                kernel_en           => i_kernel_en_line(i),
                kernel_complete     => i_kernel_complete_line(i),
                --
                new_pixel           => o_pixel_line(i)(%%CORE_OUTPUT_LENGTH%% - 1 downto 0),
                valid_pixel         => o_valid_pixel_line(i),
                comp_complete       => o_comp_complete_line(i)
            );

    end generate %%CORE_ENTITY_NAME%%_GEN;

end architecture %%CORE_ARCHITECTURE_NAME%%;
