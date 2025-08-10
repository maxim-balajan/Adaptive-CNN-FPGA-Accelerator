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


entity routing_cores is
    port (
        clk   : IN std_logic;
        reset : IN std_logic;
        -- KERNEL_CORES_INPUT PORTS
        o_activation_matrix_line  : OUT matrix_1d(0 to 6000 - 1)(24 - 1 downto 0);
        o_weight_matrix_line      : OUT matrix_1d(0 to 6000 - 1)(24 - 1 downto 0);
        o_shamt_line              : OUT matrix_1d(0 to 300 - 1)(24 - 1 downto 0);
        o_bias_line               : OUT matrix_1d(0 to 300 - 1)(24 - 1 downto 0);
        o_kernel_en_line          : OUT std_logic_vector(0 to 300 - 1);   
        o_kernel_complete_line    : OUT std_logic_vector(0 to 300 - 1);
        -- KERNEL CORES OUTPUT PORTS
        i_pixel_line         : IN matrix_1d(0 to 300 - 1)(24 - 1 downto 0);
        i_valid_pixel_line   : IN std_logic_vector(0 to 300 - 1);
        i_comp_complete_line : IN std_logic_vector(0 to 300 - 1);
        -- CONFIGURABLE SLIDER OUTPUTS
        i_kernel_complete          : IN std_logic;
		i_kernel_en                : IN std_logic;
		i_kernel_activation_matrix : IN matrix_1d(0 to 11 * 180 - 1)(24 - 1 downto 0);
        -- ROUTING CORES OUTPUTS
        o_kernel_complete : OUT std_logic;
        o_kernel_valid    : OUT std_logic;
        o_pixel_line      : OUT matrix_1d(0 to 5 - 1)(24 - 1 downto 0)
    );
end entity routing_cores;

architecture route_a of routing_cores is

    -------------------------------------------
    -- CONSTANTs
    -------------------------------------------
    CONSTANT C_MAX_PIPELINE_STEPS : POSITIVE := 5;

    -------------------------------------------
    -- SIGNALs
    -------------------------------------------

    -- CONFIGURABLE SLIDER OUTPUT REGISTERS (1 cycle)
    SIGNAL s_cs_kernel_matrix   : matrix_1d(i_kernel_activation_matrix'RANGE)(i_kernel_activation_matrix(i_kernel_activation_matrix'LOW)'RANGE);
    SIGNAL s_cs_kernel_en       : std_logic;
    SIGNAL s_cs_kernel_complete : std_logic;

    -- KERNEL CORES OUTPUT SHIFT REGISTERS (delay bounded by C_MAX_PIPELINE_STEPS)
    SIGNAL s_kc_pixel_line : matrix_2d(0 to C_MAX_PIPELINE_STEPS - 1)(i_pixel_line'RANGE)(i_pixel_line(i_pixel_line'LOW)'RANGE);
    SIGNAL s_kc_valid_line : matrix_1d(0 to C_MAX_PIPELINE_STEPS - 1)(i_valid_pixel_line'RANGE);
    SIGNAL s_kc_comp_line  : matrix_1d(0 to C_MAX_PIPELINE_STEPS - 1)(i_comp_complete_line'RANGE);

begin

    DELAY_PROC : process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then

                -- Reset of CONFIGURABLE SLIDER OUTPUT REGISTERS
                s_cs_kernel_matrix   <= (others => (others => '0'));
                s_cs_kernel_en       <= '0';
                s_cs_kernel_complete <= '0';

                -- Reset of KERNEL CORES OUTPUT SHIFT REGISTERS
                s_kc_pixel_line(1 to C_MAX_PIPELINE_STEPS - 1) <= (others => (others => (others => '0')));
                s_kc_valid_line(1 to C_MAX_PIPELINE_STEPS - 1) <= (others => (others => '0'));
                s_kc_comp_line(1 to C_MAX_PIPELINE_STEPS - 1)  <= (others => (others => '0'));

            else

                -- 1 cycle delay for CONFIGURABLE SLIDER OUTPUT
                s_cs_kernel_matrix   <= i_kernel_activation_matrix;
                s_cs_kernel_en       <= i_kernel_en;
                s_cs_kernel_complete <= i_kernel_complete;

                -- SHIFT REGISTERS for KERNEL CORES OUTPUT
                s_kc_pixel_line(1 to C_MAX_PIPELINE_STEPS - 1) <= s_kc_pixel_line(0 to C_MAX_PIPELINE_STEPS - 2);
                s_kc_valid_line(1 to C_MAX_PIPELINE_STEPS - 1) <= s_kc_valid_line(0 to C_MAX_PIPELINE_STEPS - 2);
                s_kc_comp_line(1 to C_MAX_PIPELINE_STEPS - 1)  <= s_kc_comp_line(0 to C_MAX_PIPELINE_STEPS - 2);

            end if;
        end if;
    end process DELAY_PROC;

    -------------------------------------------
    -- Pipeline start
    -------------------------------------------
    s_kc_pixel_line(s_kc_pixel_line'LOW) <= i_pixel_line;
    s_kc_valid_line(s_kc_valid_line'LOW) <= i_valid_pixel_line;
    s_kc_comp_line(s_kc_comp_line'LOW)   <= i_comp_complete_line; 

    -------------------------------------------
    -- OUTPUTs
    -------------------------------------------

%%ROUTE_SIGNAL_OUTPUT%%

end architecture route_a;
