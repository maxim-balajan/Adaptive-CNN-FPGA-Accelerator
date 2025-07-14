
-- %%CORE_TYPE%% Core Bundle with %%CORE_AMOUNT%% Cores

%%CORE_NAME%%_inst : entity %%CORE_COMPILE_LIB%%.%%CORE_NAME%%
	port map (
		clk   => clk,
		reset => reset,
        --
		%%CORE_ACTIVATION_MATRIX_LINE%%
		%%CORE_WEIGHT_MATRIX_LINE%%
		%%CORE_SHAMT_LINE%%
		%%CORE_BIAS_LINE%%
		%%CORE_KERNEL_EN_LINE%%
		%%CORE_KERNEL_COMPLETE_LINE%%
        --
		%%CORE_PIXEL_LINE%%
		%%CORE_VALID_PIXEL_LINE%%
		%%CORE_COMP_COMPLETE_LINE%%
	);
