

%%CORE_NAME%%_GEN : for i in %%CORE_AMOUNT%% generate
    
    entity work.kernel_computation_unit
        generic map (
            pool_or_conv                => %%CORE_TYPE%%,
            enable_clip_adder           => %%CORE_TYPE%%,
            enable_multiplication_line  => %%CORE_TYPE%%,
            enable_shift                => %%CORE_TYPE%%,
            enable_bias                 => %%CORE_TYPE%%,
            enable_relu                 => %%CORE_TYPE%%,
            input_length                => %%CORE_TYPE%%,
            output_length               => %%CORE_TYPE%%,
            input_amount                => %%CORE_TYPE%%
        )
        port map (
            clk                 => clk,
            reset               => reset,
            --
            %%CORE_ACTIVATION_MATRIX%%
            %%CORE_WEIGHT_MATRIX%%
            shamt               => shamt,
            bias                => bias,
            kernel_en           => kernel_en,
            kernel_complete     => kernel_complete,
            --
            new_pixel           => new_pixel,
            valid_pixel         => valid_pixel,
            comp_complete       => comp_complete
        );

end generate %%CORE_NAME%%_GEN;

