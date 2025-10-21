
architecture %%ROUTE_ARCHITECTURE_NAME%% of routing_cores is

    -------------------------------------------
    -- CONSTANTs
    -------------------------------------------
    CONSTANT C_MAX_PIPELINE_STEPS : POSITIVE := %%MAX_PIPELINE_STEPS%%;

    -------------------------------------------
    -- SIGNALs
    -------------------------------------------

    -- CONFIGURABLE SLIDER OUTPUT REGISTERS (1 cycle)
    SIGNAL s_cs_kernel_matrix   : matrix_1d(i_kernel_activation_matrix'RANGE)(i_kernel_activation_matrix(i_kernel_activation_matrix'LOW)'RANGE);
    SIGNAL s_cs_kernel_en       : std_logic;
    SIGNAL s_cs_kernel_complete : std_logic;

    -- WEIGHT MODULE OUTPUT REGISTERS (1 cycle)
    SIGNAL s_wm_weight_en     : std_logic;
    SIGNAL s_wm_weight_matrix : matrix_1d(i_kernel_weight_matrix'RANGE)(i_kernel_weight_matrix(i_kernel_weight_matrix'LOW)'RANGE);
    SIGNAL s_wm_shamt_line    : matrix_1d(i_shamt_line'RANGE)(i_shamt_line(i_shamt_line'LOW)'RANGE);
    SIGNAL s_wm_bias_line     : matrix_1d(i_bias_line'RANGE)(i_bias_line(i_bias_line'LOW)'RANGE);

    -- KERNEL CORES OUTPUT SHIFT REGISTERS (delay bounded by C_MAX_PIPELINE_STEPS)
    SIGNAL s_kc_pixel_line : matrix_2d(0 to C_MAX_PIPELINE_STEPS)(i_pixel_line'RANGE)(i_pixel_line(i_pixel_line'LOW)'RANGE);
    SIGNAL s_kc_valid_line : matrix_1d(0 to C_MAX_PIPELINE_STEPS)(i_valid_pixel_line'RANGE);
    SIGNAL s_kc_comp_line  : matrix_1d(0 to C_MAX_PIPELINE_STEPS)(i_comp_complete_line'RANGE);

begin

    DELAY_PROC : process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then

                -- Reset of CONFIGURABLE SLIDER OUTPUT REGISTERS
                s_cs_kernel_matrix   <= (others => (others => '0'));
                s_cs_kernel_en       <= '0';
                s_cs_kernel_complete <= '0';

                -- Reset of WEIGHT MODULE OUTPUT REGISTERS
                s_wm_weight_en     <= '0';
                s_wm_weight_matrix <= (others => (others => '0'));
                s_wm_shamt_line    <= (others => (others => '0'));
                s_wm_bias_line     <= (others => (others => '0'));

                s_kc_pixel_line(s_kc_pixel_line'LOW) <= (others => (others => '0') ) ;
                s_kc_valid_line(s_kc_valid_line'LOW) <= (others => '0') ;
                s_kc_comp_line(s_kc_comp_line'LOW)   <= (others => '0') ; 

                -- Reset of KERNEL CORES OUTPUT SHIFT REGISTERS
                s_kc_pixel_line(1 to C_MAX_PIPELINE_STEPS - 1) <= (others => (others => (others => '0')));
                s_kc_valid_line(1 to C_MAX_PIPELINE_STEPS - 1) <= (others => (others => '0'));
                s_kc_comp_line(1 to C_MAX_PIPELINE_STEPS - 1)  <= (others => (others => '0'));

            elsif i_en = '1' then

                -------------------------------------------
                -- Pipeline start
                -------------------------------------------
                s_kc_pixel_line(s_kc_pixel_line'LOW) <= i_pixel_line;
                s_kc_valid_line(s_kc_valid_line'LOW) <= i_valid_pixel_line;
                s_kc_comp_line(s_kc_comp_line'LOW)   <= i_comp_complete_line; 

                -- 1 cycle delay for CONFIGURABLE SLIDER OUTPUT
                s_cs_kernel_matrix   <= i_kernel_activation_matrix;
                s_cs_kernel_en       <= i_kernel_en;
                s_cs_kernel_complete <= i_kernel_complete;

                -- 1 cycle delay for WEIGHT MODULE OUTPUT
                s_wm_weight_en     <= i_kernel_weight_en;
                s_wm_weight_matrix <= i_kernel_weight_matrix;
                s_wm_shamt_line    <= i_shamt_line;
                s_wm_bias_line     <= i_bias_line;

                -- SHIFT REGISTERS for KERNEL CORES OUTPUT
                s_kc_pixel_line(1 to C_MAX_PIPELINE_STEPS) <= s_kc_pixel_line(0 to C_MAX_PIPELINE_STEPS - 1);
                s_kc_valid_line(1 to C_MAX_PIPELINE_STEPS) <= s_kc_valid_line(0 to C_MAX_PIPELINE_STEPS - 1);
                s_kc_comp_line(1 to C_MAX_PIPELINE_STEPS)  <= s_kc_comp_line(0 to C_MAX_PIPELINE_STEPS - 1);

            end if;
        end if;
    end process DELAY_PROC;

    -------------------------------------------
    -- INTERMEDIATE OUTPUTs
    -------------------------------------------

%%ROUTE_SIGNAL_OUTPUT%%

    -------------------------------------------
    -- FINAL OUTPUTs
    -------------------------------------------

%%ROUTE_SIGNAL_FINAL_OUTPUT%%

end architecture %%ROUTE_ARCHITECTURE_NAME%%;
