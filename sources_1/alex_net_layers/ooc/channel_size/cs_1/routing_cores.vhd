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
        -- Global enable: If set to 0, stall entire unit and set outputs to low
        i_en  : IN std_logic;
        -- KERNEL CORES INPUT PORTS
        o_activation_matrix_line  : OUT matrix_1d(0 to 1000 - 1)(24 - 1 downto 0);
        o_weight_matrix_line      : OUT matrix_1d(0 to 1000 - 1)(24 - 1 downto 0);
        o_shamt_line              : OUT matrix_1d(0 to 100 - 1)(8 - 1 downto 0);
        o_bias_line               : OUT matrix_1d(0 to 100 - 1)(8 - 1 downto 0);
        o_kernel_en_line          : OUT std_logic_vector(0 to 100 - 1);   
        o_kernel_complete_line    : OUT std_logic_vector(0 to 100 - 1);
        -- KERNEL CORES OUTPUT PORTS
        i_pixel_line         : IN matrix_1d(0 to 100 - 1)(24 - 1 downto 0);
        i_valid_pixel_line   : IN std_logic_vector(0 to 100 - 1);
        i_comp_complete_line : IN std_logic_vector(0 to 100 - 1);
        -- CONFIGURABLE SLIDER OUTPUTS
        i_kernel_complete          : IN std_logic;
		i_kernel_en                : IN std_logic;
		i_kernel_activation_matrix : IN matrix_1d(0 to 12 * 80 - 1)(8 - 1 downto 0);
        -- WEIGHT MODULE OUTPUTS
        i_kernel_weight_en     : IN std_logic;
        i_kernel_weight_matrix : IN matrix_1d(0 to 12 * 80 - 1)(8 - 1 downto 0); 
        i_shamt_line           : IN matrix_1d(0 to 100 - 1)(8 - 1 downto 0);
        i_bias_line            : IN matrix_1d(0 to 100 - 1)(8 - 1 downto 0);
        -- ROUTING CORES OUTPUTS
        o_kernel_complete : OUT std_logic;
        o_kernel_valid    : OUT std_logic;
        o_pixel_line      : OUT matrix_1d(0 to 16 - 1)(24 - 1 downto 0)
    );
end entity routing_cores;

architecture route_a of routing_cores is

    -------------------------------------------
    -- CONSTANTs
    -------------------------------------------
    CONSTANT C_MAX_PIPELINE_STEPS : POSITIVE := 2;

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


    -- Output Channel 0 Routing...
    o_activation_matrix_line(0)     <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(0)), o_activation_matrix_line(0)'LENGTH));
    o_weight_matrix_line(0)         <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(0)), o_weight_matrix_line(0)'LENGTH));
    o_activation_matrix_line(1)     <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(1)), o_activation_matrix_line(1)'LENGTH));
    o_weight_matrix_line(1)         <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(1)), o_weight_matrix_line(1)'LENGTH));
    o_activation_matrix_line(2)     <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(2)), o_activation_matrix_line(2)'LENGTH));
    o_weight_matrix_line(2)         <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(2)), o_weight_matrix_line(2)'LENGTH));
    o_bias_line(0)                  <= s_wm_bias_line(0);
    o_shamt_line(0)                 <= s_wm_shamt_line(0);
    o_kernel_en_line(0)             <= s_cs_kernel_en;
    o_kernel_complete_line(0)       <= s_cs_kernel_complete;
    o_activation_matrix_line(3)     <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(3)), o_activation_matrix_line(3)'LENGTH));
    o_weight_matrix_line(3)         <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(3)), o_weight_matrix_line(3)'LENGTH));
    o_activation_matrix_line(4)     <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(4)), o_activation_matrix_line(4)'LENGTH));
    o_weight_matrix_line(4)         <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(4)), o_weight_matrix_line(4)'LENGTH));
    o_activation_matrix_line(5)     <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(5)), o_activation_matrix_line(5)'LENGTH));
    o_weight_matrix_line(5)         <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(5)), o_weight_matrix_line(5)'LENGTH));
    o_bias_line(1)                  <= s_wm_bias_line(1);
    o_shamt_line(1)                 <= s_wm_shamt_line(1);
    o_kernel_en_line(1)             <= s_cs_kernel_en;
    o_kernel_complete_line(1)       <= s_cs_kernel_complete;
    o_activation_matrix_line(6)     <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(6)), o_activation_matrix_line(6)'LENGTH));
    o_weight_matrix_line(6)         <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(6)), o_weight_matrix_line(6)'LENGTH));
    o_activation_matrix_line(7)     <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(7)), o_activation_matrix_line(7)'LENGTH));
    o_weight_matrix_line(7)         <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(7)), o_weight_matrix_line(7)'LENGTH));
    o_activation_matrix_line(8)     <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(8)), o_activation_matrix_line(8)'LENGTH));
    o_weight_matrix_line(8)         <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(8)), o_weight_matrix_line(8)'LENGTH));
    o_bias_line(2)                  <= s_wm_bias_line(2);
    o_shamt_line(2)                 <= s_wm_shamt_line(2);
    o_kernel_en_line(2)             <= s_cs_kernel_en;
    o_kernel_complete_line(2)       <= s_cs_kernel_complete;
    o_activation_matrix_line(400)   <= s_kc_pixel_line(1)(0);
    o_weight_matrix_line(400)       <= (others => '0');
    o_activation_matrix_line(401)   <= s_kc_pixel_line(1)(1);
    o_weight_matrix_line(401)       <= (others => '0');
    o_activation_matrix_line(402)   <= s_kc_pixel_line(1)(2);
    o_weight_matrix_line(402)       <= (others => '0');
    o_bias_line(40)                 <= s_wm_bias_line(40);
    o_shamt_line(40)                <= s_wm_shamt_line(40);
    o_kernel_en_line(40)            <= s_kc_valid_line(1)(0);
    o_kernel_complete_line(40)      <= s_kc_comp_line(1)(0);


    -------------------------------------------
    -- FINAL OUTPUTs
    -------------------------------------------

    o_kernel_complete <= s_kc_comp_line(1)(40);
    o_kernel_valid    <= s_kc_valid_line(1)(40);
    o_pixel_line(0)   <= std_logic_vector(resize(unsigned(s_kc_pixel_line(1)(40)), o_pixel_line(0)'LENGTH));


end architecture route_a;
