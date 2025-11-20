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
        o_activation_matrix_line  : OUT matrix_1d(0 to 2000 - 1)(24 - 1 downto 0);
        o_weight_matrix_line      : OUT matrix_1d(0 to 2000 - 1)(24 - 1 downto 0);
        o_shamt_line              : OUT matrix_1d(0 to 200 - 1)(8 - 1 downto 0);
        o_bias_line               : OUT matrix_1d(0 to 200 - 1)(8 - 1 downto 0);
        o_kernel_en_line          : OUT std_logic_vector(0 to 200 - 1);   
        o_kernel_complete_line    : OUT std_logic_vector(0 to 200 - 1);
        -- KERNEL CORES OUTPUT PORTS
        i_pixel_line         : IN matrix_1d(0 to 200 - 1)(24 - 1 downto 0);
        i_valid_pixel_line   : IN std_logic_vector(0 to 200 - 1);
        i_comp_complete_line : IN std_logic_vector(0 to 200 - 1);
        -- CONFIGURABLE SLIDER OUTPUTS
        i_kernel_complete          : IN std_logic;
		i_kernel_en                : IN std_logic;
		i_kernel_activation_matrix : IN matrix_1d(0 to 12 * 80 - 1)(8 - 1 downto 0);
        -- WEIGHT MODULE OUTPUTS
        i_kernel_weight_en     : IN std_logic;
        i_kernel_weight_matrix : IN matrix_1d(0 to 12 * 80 - 1)(8 - 1 downto 0); 
        i_shamt_line           : IN matrix_1d(0 to 200 - 1)(8 - 1 downto 0);
        i_bias_line            : IN matrix_1d(0 to 200 - 1)(8 - 1 downto 0);
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
    o_activation_matrix_line(3)     <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(3)), o_activation_matrix_line(3)'LENGTH));
    o_weight_matrix_line(3)         <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(3)), o_weight_matrix_line(3)'LENGTH));
    o_activation_matrix_line(4)     <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(4)), o_activation_matrix_line(4)'LENGTH));
    o_weight_matrix_line(4)         <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(4)), o_weight_matrix_line(4)'LENGTH));
    o_activation_matrix_line(5)     <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(5)), o_activation_matrix_line(5)'LENGTH));
    o_weight_matrix_line(5)         <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(5)), o_weight_matrix_line(5)'LENGTH));
    o_activation_matrix_line(6)     <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(6)), o_activation_matrix_line(6)'LENGTH));
    o_weight_matrix_line(6)         <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(6)), o_weight_matrix_line(6)'LENGTH));
    o_activation_matrix_line(7)     <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(7)), o_activation_matrix_line(7)'LENGTH));
    o_weight_matrix_line(7)         <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(7)), o_weight_matrix_line(7)'LENGTH));
    o_activation_matrix_line(8)     <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(8)), o_activation_matrix_line(8)'LENGTH));
    o_weight_matrix_line(8)         <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(8)), o_weight_matrix_line(8)'LENGTH));
    o_bias_line(0)                  <= s_wm_bias_line(0);
    o_shamt_line(0)                 <= s_wm_shamt_line(0);
    o_kernel_en_line(0)             <= s_cs_kernel_en;
    o_kernel_complete_line(0)       <= s_cs_kernel_complete;
    o_activation_matrix_line(9)     <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(9)), o_activation_matrix_line(9)'LENGTH));
    o_weight_matrix_line(9)         <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(9)), o_weight_matrix_line(9)'LENGTH));
    o_activation_matrix_line(10)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(10)), o_activation_matrix_line(10)'LENGTH));
    o_weight_matrix_line(10)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(10)), o_weight_matrix_line(10)'LENGTH));
    o_activation_matrix_line(11)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(11)), o_activation_matrix_line(11)'LENGTH));
    o_weight_matrix_line(11)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(11)), o_weight_matrix_line(11)'LENGTH));
    o_activation_matrix_line(12)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(12)), o_activation_matrix_line(12)'LENGTH));
    o_weight_matrix_line(12)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(12)), o_weight_matrix_line(12)'LENGTH));
    o_activation_matrix_line(13)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(13)), o_activation_matrix_line(13)'LENGTH));
    o_weight_matrix_line(13)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(13)), o_weight_matrix_line(13)'LENGTH));
    o_activation_matrix_line(14)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(14)), o_activation_matrix_line(14)'LENGTH));
    o_weight_matrix_line(14)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(14)), o_weight_matrix_line(14)'LENGTH));
    o_activation_matrix_line(15)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(15)), o_activation_matrix_line(15)'LENGTH));
    o_weight_matrix_line(15)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(15)), o_weight_matrix_line(15)'LENGTH));
    o_activation_matrix_line(16)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(16)), o_activation_matrix_line(16)'LENGTH));
    o_weight_matrix_line(16)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(16)), o_weight_matrix_line(16)'LENGTH));
    o_activation_matrix_line(17)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(17)), o_activation_matrix_line(17)'LENGTH));
    o_weight_matrix_line(17)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(17)), o_weight_matrix_line(17)'LENGTH));
    o_bias_line(1)                  <= s_wm_bias_line(1);
    o_shamt_line(1)                 <= s_wm_shamt_line(1);
    o_kernel_en_line(1)             <= s_cs_kernel_en;
    o_kernel_complete_line(1)       <= s_cs_kernel_complete;
    o_activation_matrix_line(18)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(18)), o_activation_matrix_line(18)'LENGTH));
    o_weight_matrix_line(18)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(18)), o_weight_matrix_line(18)'LENGTH));
    o_activation_matrix_line(19)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(19)), o_activation_matrix_line(19)'LENGTH));
    o_weight_matrix_line(19)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(19)), o_weight_matrix_line(19)'LENGTH));
    o_activation_matrix_line(20)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(20)), o_activation_matrix_line(20)'LENGTH));
    o_weight_matrix_line(20)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(20)), o_weight_matrix_line(20)'LENGTH));
    o_activation_matrix_line(21)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(21)), o_activation_matrix_line(21)'LENGTH));
    o_weight_matrix_line(21)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(21)), o_weight_matrix_line(21)'LENGTH));
    o_activation_matrix_line(22)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(22)), o_activation_matrix_line(22)'LENGTH));
    o_weight_matrix_line(22)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(22)), o_weight_matrix_line(22)'LENGTH));
    o_activation_matrix_line(23)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(23)), o_activation_matrix_line(23)'LENGTH));
    o_weight_matrix_line(23)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(23)), o_weight_matrix_line(23)'LENGTH));
    o_activation_matrix_line(24)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(24)), o_activation_matrix_line(24)'LENGTH));
    o_weight_matrix_line(24)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(24)), o_weight_matrix_line(24)'LENGTH));
    o_activation_matrix_line(25)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(25)), o_activation_matrix_line(25)'LENGTH));
    o_weight_matrix_line(25)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(25)), o_weight_matrix_line(25)'LENGTH));
    o_activation_matrix_line(26)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(26)), o_activation_matrix_line(26)'LENGTH));
    o_weight_matrix_line(26)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(26)), o_weight_matrix_line(26)'LENGTH));
    o_bias_line(2)                  <= s_wm_bias_line(2);
    o_shamt_line(2)                 <= s_wm_shamt_line(2);
    o_kernel_en_line(2)             <= s_cs_kernel_en;
    o_kernel_complete_line(2)       <= s_cs_kernel_complete;
    o_activation_matrix_line(27)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(27)), o_activation_matrix_line(27)'LENGTH));
    o_weight_matrix_line(27)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(27)), o_weight_matrix_line(27)'LENGTH));
    o_activation_matrix_line(28)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(28)), o_activation_matrix_line(28)'LENGTH));
    o_weight_matrix_line(28)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(28)), o_weight_matrix_line(28)'LENGTH));
    o_activation_matrix_line(29)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(29)), o_activation_matrix_line(29)'LENGTH));
    o_weight_matrix_line(29)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(29)), o_weight_matrix_line(29)'LENGTH));
    o_activation_matrix_line(30)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(30)), o_activation_matrix_line(30)'LENGTH));
    o_weight_matrix_line(30)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(30)), o_weight_matrix_line(30)'LENGTH));
    o_activation_matrix_line(31)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(31)), o_activation_matrix_line(31)'LENGTH));
    o_weight_matrix_line(31)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(31)), o_weight_matrix_line(31)'LENGTH));
    o_activation_matrix_line(32)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(32)), o_activation_matrix_line(32)'LENGTH));
    o_weight_matrix_line(32)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(32)), o_weight_matrix_line(32)'LENGTH));
    o_activation_matrix_line(33)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(33)), o_activation_matrix_line(33)'LENGTH));
    o_weight_matrix_line(33)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(33)), o_weight_matrix_line(33)'LENGTH));
    o_activation_matrix_line(34)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(34)), o_activation_matrix_line(34)'LENGTH));
    o_weight_matrix_line(34)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(34)), o_weight_matrix_line(34)'LENGTH));
    o_activation_matrix_line(35)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(35)), o_activation_matrix_line(35)'LENGTH));
    o_weight_matrix_line(35)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(35)), o_weight_matrix_line(35)'LENGTH));
    o_bias_line(3)                  <= s_wm_bias_line(3);
    o_shamt_line(3)                 <= s_wm_shamt_line(3);
    o_kernel_en_line(3)             <= s_cs_kernel_en;
    o_kernel_complete_line(3)       <= s_cs_kernel_complete;
    o_activation_matrix_line(36)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(36)), o_activation_matrix_line(36)'LENGTH));
    o_weight_matrix_line(36)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(36)), o_weight_matrix_line(36)'LENGTH));
    o_activation_matrix_line(37)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(37)), o_activation_matrix_line(37)'LENGTH));
    o_weight_matrix_line(37)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(37)), o_weight_matrix_line(37)'LENGTH));
    o_activation_matrix_line(38)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(38)), o_activation_matrix_line(38)'LENGTH));
    o_weight_matrix_line(38)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(38)), o_weight_matrix_line(38)'LENGTH));
    o_activation_matrix_line(39)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(39)), o_activation_matrix_line(39)'LENGTH));
    o_weight_matrix_line(39)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(39)), o_weight_matrix_line(39)'LENGTH));
    o_activation_matrix_line(40)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(40)), o_activation_matrix_line(40)'LENGTH));
    o_weight_matrix_line(40)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(40)), o_weight_matrix_line(40)'LENGTH));
    o_activation_matrix_line(41)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(41)), o_activation_matrix_line(41)'LENGTH));
    o_weight_matrix_line(41)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(41)), o_weight_matrix_line(41)'LENGTH));
    o_activation_matrix_line(42)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(42)), o_activation_matrix_line(42)'LENGTH));
    o_weight_matrix_line(42)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(42)), o_weight_matrix_line(42)'LENGTH));
    o_activation_matrix_line(43)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(43)), o_activation_matrix_line(43)'LENGTH));
    o_weight_matrix_line(43)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(43)), o_weight_matrix_line(43)'LENGTH));
    o_activation_matrix_line(44)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(44)), o_activation_matrix_line(44)'LENGTH));
    o_weight_matrix_line(44)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(44)), o_weight_matrix_line(44)'LENGTH));
    o_bias_line(4)                  <= s_wm_bias_line(4);
    o_shamt_line(4)                 <= s_wm_shamt_line(4);
    o_kernel_en_line(4)             <= s_cs_kernel_en;
    o_kernel_complete_line(4)       <= s_cs_kernel_complete;
    o_activation_matrix_line(45)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(45)), o_activation_matrix_line(45)'LENGTH));
    o_weight_matrix_line(45)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(45)), o_weight_matrix_line(45)'LENGTH));
    o_activation_matrix_line(46)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(46)), o_activation_matrix_line(46)'LENGTH));
    o_weight_matrix_line(46)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(46)), o_weight_matrix_line(46)'LENGTH));
    o_activation_matrix_line(47)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(47)), o_activation_matrix_line(47)'LENGTH));
    o_weight_matrix_line(47)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(47)), o_weight_matrix_line(47)'LENGTH));
    o_activation_matrix_line(48)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(48)), o_activation_matrix_line(48)'LENGTH));
    o_weight_matrix_line(48)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(48)), o_weight_matrix_line(48)'LENGTH));
    o_activation_matrix_line(49)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(49)), o_activation_matrix_line(49)'LENGTH));
    o_weight_matrix_line(49)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(49)), o_weight_matrix_line(49)'LENGTH));
    o_activation_matrix_line(50)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(50)), o_activation_matrix_line(50)'LENGTH));
    o_weight_matrix_line(50)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(50)), o_weight_matrix_line(50)'LENGTH));
    o_activation_matrix_line(51)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(51)), o_activation_matrix_line(51)'LENGTH));
    o_weight_matrix_line(51)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(51)), o_weight_matrix_line(51)'LENGTH));
    o_activation_matrix_line(52)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(52)), o_activation_matrix_line(52)'LENGTH));
    o_weight_matrix_line(52)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(52)), o_weight_matrix_line(52)'LENGTH));
    o_activation_matrix_line(53)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(53)), o_activation_matrix_line(53)'LENGTH));
    o_weight_matrix_line(53)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(53)), o_weight_matrix_line(53)'LENGTH));
    o_bias_line(5)                  <= s_wm_bias_line(5);
    o_shamt_line(5)                 <= s_wm_shamt_line(5);
    o_kernel_en_line(5)             <= s_cs_kernel_en;
    o_kernel_complete_line(5)       <= s_cs_kernel_complete;
    o_activation_matrix_line(54)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(54)), o_activation_matrix_line(54)'LENGTH));
    o_weight_matrix_line(54)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(54)), o_weight_matrix_line(54)'LENGTH));
    o_activation_matrix_line(55)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(55)), o_activation_matrix_line(55)'LENGTH));
    o_weight_matrix_line(55)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(55)), o_weight_matrix_line(55)'LENGTH));
    o_activation_matrix_line(56)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(56)), o_activation_matrix_line(56)'LENGTH));
    o_weight_matrix_line(56)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(56)), o_weight_matrix_line(56)'LENGTH));
    o_activation_matrix_line(57)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(57)), o_activation_matrix_line(57)'LENGTH));
    o_weight_matrix_line(57)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(57)), o_weight_matrix_line(57)'LENGTH));
    o_activation_matrix_line(58)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(58)), o_activation_matrix_line(58)'LENGTH));
    o_weight_matrix_line(58)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(58)), o_weight_matrix_line(58)'LENGTH));
    o_activation_matrix_line(59)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(59)), o_activation_matrix_line(59)'LENGTH));
    o_weight_matrix_line(59)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(59)), o_weight_matrix_line(59)'LENGTH));
    o_activation_matrix_line(60)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(60)), o_activation_matrix_line(60)'LENGTH));
    o_weight_matrix_line(60)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(60)), o_weight_matrix_line(60)'LENGTH));
    o_activation_matrix_line(61)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(61)), o_activation_matrix_line(61)'LENGTH));
    o_weight_matrix_line(61)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(61)), o_weight_matrix_line(61)'LENGTH));
    o_activation_matrix_line(62)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(62)), o_activation_matrix_line(62)'LENGTH));
    o_weight_matrix_line(62)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(62)), o_weight_matrix_line(62)'LENGTH));
    o_bias_line(6)                  <= s_wm_bias_line(6);
    o_shamt_line(6)                 <= s_wm_shamt_line(6);
    o_kernel_en_line(6)             <= s_cs_kernel_en;
    o_kernel_complete_line(6)       <= s_cs_kernel_complete;
    o_activation_matrix_line(63)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(63)), o_activation_matrix_line(63)'LENGTH));
    o_weight_matrix_line(63)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(63)), o_weight_matrix_line(63)'LENGTH));
    o_activation_matrix_line(64)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(64)), o_activation_matrix_line(64)'LENGTH));
    o_weight_matrix_line(64)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(64)), o_weight_matrix_line(64)'LENGTH));
    o_activation_matrix_line(65)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(65)), o_activation_matrix_line(65)'LENGTH));
    o_weight_matrix_line(65)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(65)), o_weight_matrix_line(65)'LENGTH));
    o_activation_matrix_line(66)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(66)), o_activation_matrix_line(66)'LENGTH));
    o_weight_matrix_line(66)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(66)), o_weight_matrix_line(66)'LENGTH));
    o_activation_matrix_line(67)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(67)), o_activation_matrix_line(67)'LENGTH));
    o_weight_matrix_line(67)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(67)), o_weight_matrix_line(67)'LENGTH));
    o_activation_matrix_line(68)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(68)), o_activation_matrix_line(68)'LENGTH));
    o_weight_matrix_line(68)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(68)), o_weight_matrix_line(68)'LENGTH));
    o_activation_matrix_line(69)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(69)), o_activation_matrix_line(69)'LENGTH));
    o_weight_matrix_line(69)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(69)), o_weight_matrix_line(69)'LENGTH));
    o_activation_matrix_line(70)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(70)), o_activation_matrix_line(70)'LENGTH));
    o_weight_matrix_line(70)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(70)), o_weight_matrix_line(70)'LENGTH));
    o_activation_matrix_line(71)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(71)), o_activation_matrix_line(71)'LENGTH));
    o_weight_matrix_line(71)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(71)), o_weight_matrix_line(71)'LENGTH));
    o_bias_line(7)                  <= s_wm_bias_line(7);
    o_shamt_line(7)                 <= s_wm_shamt_line(7);
    o_kernel_en_line(7)             <= s_cs_kernel_en;
    o_kernel_complete_line(7)       <= s_cs_kernel_complete;
    o_activation_matrix_line(72)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(72)), o_activation_matrix_line(72)'LENGTH));
    o_weight_matrix_line(72)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(72)), o_weight_matrix_line(72)'LENGTH));
    o_activation_matrix_line(73)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(73)), o_activation_matrix_line(73)'LENGTH));
    o_weight_matrix_line(73)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(73)), o_weight_matrix_line(73)'LENGTH));
    o_activation_matrix_line(74)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(74)), o_activation_matrix_line(74)'LENGTH));
    o_weight_matrix_line(74)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(74)), o_weight_matrix_line(74)'LENGTH));
    o_activation_matrix_line(75)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(75)), o_activation_matrix_line(75)'LENGTH));
    o_weight_matrix_line(75)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(75)), o_weight_matrix_line(75)'LENGTH));
    o_activation_matrix_line(76)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(76)), o_activation_matrix_line(76)'LENGTH));
    o_weight_matrix_line(76)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(76)), o_weight_matrix_line(76)'LENGTH));
    o_activation_matrix_line(77)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(77)), o_activation_matrix_line(77)'LENGTH));
    o_weight_matrix_line(77)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(77)), o_weight_matrix_line(77)'LENGTH));
    o_activation_matrix_line(78)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(78)), o_activation_matrix_line(78)'LENGTH));
    o_weight_matrix_line(78)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(78)), o_weight_matrix_line(78)'LENGTH));
    o_activation_matrix_line(79)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(79)), o_activation_matrix_line(79)'LENGTH));
    o_weight_matrix_line(79)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(79)), o_weight_matrix_line(79)'LENGTH));
    o_activation_matrix_line(80)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(80)), o_activation_matrix_line(80)'LENGTH));
    o_weight_matrix_line(80)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(80)), o_weight_matrix_line(80)'LENGTH));
    o_bias_line(8)                  <= s_wm_bias_line(8);
    o_shamt_line(8)                 <= s_wm_shamt_line(8);
    o_kernel_en_line(8)             <= s_cs_kernel_en;
    o_kernel_complete_line(8)       <= s_cs_kernel_complete;
    o_activation_matrix_line(81)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(81)), o_activation_matrix_line(81)'LENGTH));
    o_weight_matrix_line(81)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(81)), o_weight_matrix_line(81)'LENGTH));
    o_activation_matrix_line(82)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(82)), o_activation_matrix_line(82)'LENGTH));
    o_weight_matrix_line(82)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(82)), o_weight_matrix_line(82)'LENGTH));
    o_activation_matrix_line(83)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(83)), o_activation_matrix_line(83)'LENGTH));
    o_weight_matrix_line(83)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(83)), o_weight_matrix_line(83)'LENGTH));
    o_activation_matrix_line(84)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(84)), o_activation_matrix_line(84)'LENGTH));
    o_weight_matrix_line(84)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(84)), o_weight_matrix_line(84)'LENGTH));
    o_activation_matrix_line(85)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(85)), o_activation_matrix_line(85)'LENGTH));
    o_weight_matrix_line(85)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(85)), o_weight_matrix_line(85)'LENGTH));
    o_activation_matrix_line(86)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(86)), o_activation_matrix_line(86)'LENGTH));
    o_weight_matrix_line(86)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(86)), o_weight_matrix_line(86)'LENGTH));
    o_activation_matrix_line(87)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(87)), o_activation_matrix_line(87)'LENGTH));
    o_weight_matrix_line(87)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(87)), o_weight_matrix_line(87)'LENGTH));
    o_activation_matrix_line(88)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(88)), o_activation_matrix_line(88)'LENGTH));
    o_weight_matrix_line(88)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(88)), o_weight_matrix_line(88)'LENGTH));
    o_activation_matrix_line(89)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(89)), o_activation_matrix_line(89)'LENGTH));
    o_weight_matrix_line(89)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(89)), o_weight_matrix_line(89)'LENGTH));
    o_bias_line(9)                  <= s_wm_bias_line(9);
    o_shamt_line(9)                 <= s_wm_shamt_line(9);
    o_kernel_en_line(9)             <= s_cs_kernel_en;
    o_kernel_complete_line(9)       <= s_cs_kernel_complete;
    o_activation_matrix_line(90)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(90)), o_activation_matrix_line(90)'LENGTH));
    o_weight_matrix_line(90)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(90)), o_weight_matrix_line(90)'LENGTH));
    o_activation_matrix_line(91)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(91)), o_activation_matrix_line(91)'LENGTH));
    o_weight_matrix_line(91)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(91)), o_weight_matrix_line(91)'LENGTH));
    o_activation_matrix_line(92)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(92)), o_activation_matrix_line(92)'LENGTH));
    o_weight_matrix_line(92)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(92)), o_weight_matrix_line(92)'LENGTH));
    o_activation_matrix_line(93)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(93)), o_activation_matrix_line(93)'LENGTH));
    o_weight_matrix_line(93)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(93)), o_weight_matrix_line(93)'LENGTH));
    o_activation_matrix_line(94)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(94)), o_activation_matrix_line(94)'LENGTH));
    o_weight_matrix_line(94)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(94)), o_weight_matrix_line(94)'LENGTH));
    o_activation_matrix_line(95)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(95)), o_activation_matrix_line(95)'LENGTH));
    o_weight_matrix_line(95)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(95)), o_weight_matrix_line(95)'LENGTH));
    o_activation_matrix_line(96)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(96)), o_activation_matrix_line(96)'LENGTH));
    o_weight_matrix_line(96)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(96)), o_weight_matrix_line(96)'LENGTH));
    o_activation_matrix_line(97)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(97)), o_activation_matrix_line(97)'LENGTH));
    o_weight_matrix_line(97)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(97)), o_weight_matrix_line(97)'LENGTH));
    o_activation_matrix_line(98)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(98)), o_activation_matrix_line(98)'LENGTH));
    o_weight_matrix_line(98)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(98)), o_weight_matrix_line(98)'LENGTH));
    o_bias_line(10)                 <= s_wm_bias_line(10);
    o_shamt_line(10)                <= s_wm_shamt_line(10);
    o_kernel_en_line(10)            <= s_cs_kernel_en;
    o_kernel_complete_line(10)      <= s_cs_kernel_complete;
    o_activation_matrix_line(99)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(99)), o_activation_matrix_line(99)'LENGTH));
    o_weight_matrix_line(99)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(99)), o_weight_matrix_line(99)'LENGTH));
    o_activation_matrix_line(100)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(100)), o_activation_matrix_line(100)'LENGTH));
    o_weight_matrix_line(100)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(100)), o_weight_matrix_line(100)'LENGTH));
    o_activation_matrix_line(101)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(101)), o_activation_matrix_line(101)'LENGTH));
    o_weight_matrix_line(101)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(101)), o_weight_matrix_line(101)'LENGTH));
    o_activation_matrix_line(102)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(102)), o_activation_matrix_line(102)'LENGTH));
    o_weight_matrix_line(102)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(102)), o_weight_matrix_line(102)'LENGTH));
    o_activation_matrix_line(103)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(103)), o_activation_matrix_line(103)'LENGTH));
    o_weight_matrix_line(103)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(103)), o_weight_matrix_line(103)'LENGTH));
    o_activation_matrix_line(104)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(104)), o_activation_matrix_line(104)'LENGTH));
    o_weight_matrix_line(104)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(104)), o_weight_matrix_line(104)'LENGTH));
    o_activation_matrix_line(105)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(105)), o_activation_matrix_line(105)'LENGTH));
    o_weight_matrix_line(105)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(105)), o_weight_matrix_line(105)'LENGTH));
    o_activation_matrix_line(106)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(106)), o_activation_matrix_line(106)'LENGTH));
    o_weight_matrix_line(106)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(106)), o_weight_matrix_line(106)'LENGTH));
    o_activation_matrix_line(107)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(107)), o_activation_matrix_line(107)'LENGTH));
    o_weight_matrix_line(107)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(107)), o_weight_matrix_line(107)'LENGTH));
    o_bias_line(11)                 <= s_wm_bias_line(11);
    o_shamt_line(11)                <= s_wm_shamt_line(11);
    o_kernel_en_line(11)            <= s_cs_kernel_en;
    o_kernel_complete_line(11)      <= s_cs_kernel_complete;
    o_activation_matrix_line(108)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(108)), o_activation_matrix_line(108)'LENGTH));
    o_weight_matrix_line(108)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(108)), o_weight_matrix_line(108)'LENGTH));
    o_activation_matrix_line(109)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(109)), o_activation_matrix_line(109)'LENGTH));
    o_weight_matrix_line(109)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(109)), o_weight_matrix_line(109)'LENGTH));
    o_activation_matrix_line(110)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(110)), o_activation_matrix_line(110)'LENGTH));
    o_weight_matrix_line(110)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(110)), o_weight_matrix_line(110)'LENGTH));
    o_activation_matrix_line(111)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(111)), o_activation_matrix_line(111)'LENGTH));
    o_weight_matrix_line(111)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(111)), o_weight_matrix_line(111)'LENGTH));
    o_activation_matrix_line(112)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(112)), o_activation_matrix_line(112)'LENGTH));
    o_weight_matrix_line(112)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(112)), o_weight_matrix_line(112)'LENGTH));
    o_activation_matrix_line(113)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(113)), o_activation_matrix_line(113)'LENGTH));
    o_weight_matrix_line(113)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(113)), o_weight_matrix_line(113)'LENGTH));
    o_activation_matrix_line(114)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(114)), o_activation_matrix_line(114)'LENGTH));
    o_weight_matrix_line(114)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(114)), o_weight_matrix_line(114)'LENGTH));
    o_activation_matrix_line(115)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(115)), o_activation_matrix_line(115)'LENGTH));
    o_weight_matrix_line(115)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(115)), o_weight_matrix_line(115)'LENGTH));
    o_activation_matrix_line(116)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(116)), o_activation_matrix_line(116)'LENGTH));
    o_weight_matrix_line(116)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(116)), o_weight_matrix_line(116)'LENGTH));
    o_bias_line(12)                 <= s_wm_bias_line(12);
    o_shamt_line(12)                <= s_wm_shamt_line(12);
    o_kernel_en_line(12)            <= s_cs_kernel_en;
    o_kernel_complete_line(12)      <= s_cs_kernel_complete;
    o_activation_matrix_line(117)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(117)), o_activation_matrix_line(117)'LENGTH));
    o_weight_matrix_line(117)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(117)), o_weight_matrix_line(117)'LENGTH));
    o_activation_matrix_line(118)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(118)), o_activation_matrix_line(118)'LENGTH));
    o_weight_matrix_line(118)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(118)), o_weight_matrix_line(118)'LENGTH));
    o_activation_matrix_line(119)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(119)), o_activation_matrix_line(119)'LENGTH));
    o_weight_matrix_line(119)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(119)), o_weight_matrix_line(119)'LENGTH));
    o_activation_matrix_line(120)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(120)), o_activation_matrix_line(120)'LENGTH));
    o_weight_matrix_line(120)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(120)), o_weight_matrix_line(120)'LENGTH));
    o_activation_matrix_line(121)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(121)), o_activation_matrix_line(121)'LENGTH));
    o_weight_matrix_line(121)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(121)), o_weight_matrix_line(121)'LENGTH));
    o_activation_matrix_line(122)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(122)), o_activation_matrix_line(122)'LENGTH));
    o_weight_matrix_line(122)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(122)), o_weight_matrix_line(122)'LENGTH));
    o_activation_matrix_line(123)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(123)), o_activation_matrix_line(123)'LENGTH));
    o_weight_matrix_line(123)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(123)), o_weight_matrix_line(123)'LENGTH));
    o_activation_matrix_line(124)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(124)), o_activation_matrix_line(124)'LENGTH));
    o_weight_matrix_line(124)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(124)), o_weight_matrix_line(124)'LENGTH));
    o_activation_matrix_line(125)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(125)), o_activation_matrix_line(125)'LENGTH));
    o_weight_matrix_line(125)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(125)), o_weight_matrix_line(125)'LENGTH));
    o_bias_line(13)                 <= s_wm_bias_line(13);
    o_shamt_line(13)                <= s_wm_shamt_line(13);
    o_kernel_en_line(13)            <= s_cs_kernel_en;
    o_kernel_complete_line(13)      <= s_cs_kernel_complete;
    o_activation_matrix_line(126)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(126)), o_activation_matrix_line(126)'LENGTH));
    o_weight_matrix_line(126)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(126)), o_weight_matrix_line(126)'LENGTH));
    o_activation_matrix_line(127)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(127)), o_activation_matrix_line(127)'LENGTH));
    o_weight_matrix_line(127)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(127)), o_weight_matrix_line(127)'LENGTH));
    o_activation_matrix_line(128)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(128)), o_activation_matrix_line(128)'LENGTH));
    o_weight_matrix_line(128)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(128)), o_weight_matrix_line(128)'LENGTH));
    o_activation_matrix_line(129)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(129)), o_activation_matrix_line(129)'LENGTH));
    o_weight_matrix_line(129)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(129)), o_weight_matrix_line(129)'LENGTH));
    o_activation_matrix_line(130)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(130)), o_activation_matrix_line(130)'LENGTH));
    o_weight_matrix_line(130)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(130)), o_weight_matrix_line(130)'LENGTH));
    o_activation_matrix_line(131)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(131)), o_activation_matrix_line(131)'LENGTH));
    o_weight_matrix_line(131)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(131)), o_weight_matrix_line(131)'LENGTH));
    o_activation_matrix_line(132)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(132)), o_activation_matrix_line(132)'LENGTH));
    o_weight_matrix_line(132)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(132)), o_weight_matrix_line(132)'LENGTH));
    o_activation_matrix_line(133)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(133)), o_activation_matrix_line(133)'LENGTH));
    o_weight_matrix_line(133)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(133)), o_weight_matrix_line(133)'LENGTH));
    o_activation_matrix_line(134)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(134)), o_activation_matrix_line(134)'LENGTH));
    o_weight_matrix_line(134)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(134)), o_weight_matrix_line(134)'LENGTH));
    o_bias_line(14)                 <= s_wm_bias_line(14);
    o_shamt_line(14)                <= s_wm_shamt_line(14);
    o_kernel_en_line(14)            <= s_cs_kernel_en;
    o_kernel_complete_line(14)      <= s_cs_kernel_complete;
    o_activation_matrix_line(135)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(135)), o_activation_matrix_line(135)'LENGTH));
    o_weight_matrix_line(135)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(135)), o_weight_matrix_line(135)'LENGTH));
    o_activation_matrix_line(136)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(136)), o_activation_matrix_line(136)'LENGTH));
    o_weight_matrix_line(136)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(136)), o_weight_matrix_line(136)'LENGTH));
    o_activation_matrix_line(137)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(137)), o_activation_matrix_line(137)'LENGTH));
    o_weight_matrix_line(137)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(137)), o_weight_matrix_line(137)'LENGTH));
    o_activation_matrix_line(138)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(138)), o_activation_matrix_line(138)'LENGTH));
    o_weight_matrix_line(138)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(138)), o_weight_matrix_line(138)'LENGTH));
    o_activation_matrix_line(139)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(139)), o_activation_matrix_line(139)'LENGTH));
    o_weight_matrix_line(139)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(139)), o_weight_matrix_line(139)'LENGTH));
    o_activation_matrix_line(140)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(140)), o_activation_matrix_line(140)'LENGTH));
    o_weight_matrix_line(140)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(140)), o_weight_matrix_line(140)'LENGTH));
    o_activation_matrix_line(141)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(141)), o_activation_matrix_line(141)'LENGTH));
    o_weight_matrix_line(141)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(141)), o_weight_matrix_line(141)'LENGTH));
    o_activation_matrix_line(142)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(142)), o_activation_matrix_line(142)'LENGTH));
    o_weight_matrix_line(142)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(142)), o_weight_matrix_line(142)'LENGTH));
    o_activation_matrix_line(143)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(143)), o_activation_matrix_line(143)'LENGTH));
    o_weight_matrix_line(143)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(143)), o_weight_matrix_line(143)'LENGTH));
    o_bias_line(15)                 <= s_wm_bias_line(15);
    o_shamt_line(15)                <= s_wm_shamt_line(15);
    o_kernel_en_line(15)            <= s_cs_kernel_en;
    o_kernel_complete_line(15)      <= s_cs_kernel_complete;
    o_activation_matrix_line(144)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(144)), o_activation_matrix_line(144)'LENGTH));
    o_weight_matrix_line(144)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(144)), o_weight_matrix_line(144)'LENGTH));
    o_activation_matrix_line(145)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(145)), o_activation_matrix_line(145)'LENGTH));
    o_weight_matrix_line(145)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(145)), o_weight_matrix_line(145)'LENGTH));
    o_activation_matrix_line(146)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(146)), o_activation_matrix_line(146)'LENGTH));
    o_weight_matrix_line(146)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(146)), o_weight_matrix_line(146)'LENGTH));
    o_activation_matrix_line(147)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(147)), o_activation_matrix_line(147)'LENGTH));
    o_weight_matrix_line(147)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(147)), o_weight_matrix_line(147)'LENGTH));
    o_activation_matrix_line(148)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(148)), o_activation_matrix_line(148)'LENGTH));
    o_weight_matrix_line(148)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(148)), o_weight_matrix_line(148)'LENGTH));
    o_activation_matrix_line(149)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(149)), o_activation_matrix_line(149)'LENGTH));
    o_weight_matrix_line(149)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(149)), o_weight_matrix_line(149)'LENGTH));
    o_activation_matrix_line(150)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(150)), o_activation_matrix_line(150)'LENGTH));
    o_weight_matrix_line(150)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(150)), o_weight_matrix_line(150)'LENGTH));
    o_activation_matrix_line(151)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(151)), o_activation_matrix_line(151)'LENGTH));
    o_weight_matrix_line(151)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(151)), o_weight_matrix_line(151)'LENGTH));
    o_activation_matrix_line(152)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(152)), o_activation_matrix_line(152)'LENGTH));
    o_weight_matrix_line(152)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(152)), o_weight_matrix_line(152)'LENGTH));
    o_bias_line(16)                 <= s_wm_bias_line(16);
    o_shamt_line(16)                <= s_wm_shamt_line(16);
    o_kernel_en_line(16)            <= s_cs_kernel_en;
    o_kernel_complete_line(16)      <= s_cs_kernel_complete;
    o_activation_matrix_line(153)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(153)), o_activation_matrix_line(153)'LENGTH));
    o_weight_matrix_line(153)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(153)), o_weight_matrix_line(153)'LENGTH));
    o_activation_matrix_line(154)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(154)), o_activation_matrix_line(154)'LENGTH));
    o_weight_matrix_line(154)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(154)), o_weight_matrix_line(154)'LENGTH));
    o_activation_matrix_line(155)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(155)), o_activation_matrix_line(155)'LENGTH));
    o_weight_matrix_line(155)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(155)), o_weight_matrix_line(155)'LENGTH));
    o_activation_matrix_line(156)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(156)), o_activation_matrix_line(156)'LENGTH));
    o_weight_matrix_line(156)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(156)), o_weight_matrix_line(156)'LENGTH));
    o_activation_matrix_line(157)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(157)), o_activation_matrix_line(157)'LENGTH));
    o_weight_matrix_line(157)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(157)), o_weight_matrix_line(157)'LENGTH));
    o_activation_matrix_line(158)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(158)), o_activation_matrix_line(158)'LENGTH));
    o_weight_matrix_line(158)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(158)), o_weight_matrix_line(158)'LENGTH));
    o_activation_matrix_line(159)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(159)), o_activation_matrix_line(159)'LENGTH));
    o_weight_matrix_line(159)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(159)), o_weight_matrix_line(159)'LENGTH));
    o_activation_matrix_line(160)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(160)), o_activation_matrix_line(160)'LENGTH));
    o_weight_matrix_line(160)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(160)), o_weight_matrix_line(160)'LENGTH));
    o_activation_matrix_line(161)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(161)), o_activation_matrix_line(161)'LENGTH));
    o_weight_matrix_line(161)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(161)), o_weight_matrix_line(161)'LENGTH));
    o_bias_line(17)                 <= s_wm_bias_line(17);
    o_shamt_line(17)                <= s_wm_shamt_line(17);
    o_kernel_en_line(17)            <= s_cs_kernel_en;
    o_kernel_complete_line(17)      <= s_cs_kernel_complete;
    o_activation_matrix_line(800)   <= s_kc_pixel_line(1)(0);
    o_weight_matrix_line(800)       <= (others => '0');
    o_activation_matrix_line(801)   <= s_kc_pixel_line(1)(1);
    o_weight_matrix_line(801)       <= (others => '0');
    o_activation_matrix_line(802)   <= s_kc_pixel_line(1)(2);
    o_weight_matrix_line(802)       <= (others => '0');
    o_activation_matrix_line(803)   <= s_kc_pixel_line(1)(3);
    o_weight_matrix_line(803)       <= (others => '0');
    o_bias_line(80)                 <= s_wm_bias_line(80);
    o_shamt_line(80)                <= s_wm_shamt_line(80);
    o_kernel_en_line(80)            <= s_kc_valid_line(1)(0);
    o_kernel_complete_line(80)      <= s_kc_comp_line(1)(0);
    o_activation_matrix_line(804)   <= s_kc_pixel_line(1)(4);
    o_weight_matrix_line(804)       <= (others => '0');
    o_activation_matrix_line(805)   <= s_kc_pixel_line(1)(5);
    o_weight_matrix_line(805)       <= (others => '0');
    o_activation_matrix_line(806)   <= s_kc_pixel_line(1)(6);
    o_weight_matrix_line(806)       <= (others => '0');
    o_activation_matrix_line(807)   <= s_kc_pixel_line(1)(7);
    o_weight_matrix_line(807)       <= (others => '0');
    o_bias_line(81)                 <= s_wm_bias_line(81);
    o_shamt_line(81)                <= s_wm_shamt_line(81);
    o_kernel_en_line(81)            <= s_kc_valid_line(1)(4);
    o_kernel_complete_line(81)      <= s_kc_comp_line(1)(4);
    o_activation_matrix_line(808)   <= s_kc_pixel_line(1)(8);
    o_weight_matrix_line(808)       <= (others => '0');
    o_activation_matrix_line(809)   <= s_kc_pixel_line(1)(9);
    o_weight_matrix_line(809)       <= (others => '0');
    o_activation_matrix_line(810)   <= s_kc_pixel_line(1)(10);
    o_weight_matrix_line(810)       <= (others => '0');
    o_activation_matrix_line(811)   <= s_kc_pixel_line(1)(11);
    o_weight_matrix_line(811)       <= (others => '0');
    o_bias_line(82)                 <= s_wm_bias_line(82);
    o_shamt_line(82)                <= s_wm_shamt_line(82);
    o_kernel_en_line(82)            <= s_kc_valid_line(1)(8);
    o_kernel_complete_line(82)      <= s_kc_comp_line(1)(8);
    o_activation_matrix_line(812)   <= s_kc_pixel_line(1)(12);
    o_weight_matrix_line(812)       <= (others => '0');
    o_activation_matrix_line(813)   <= s_kc_pixel_line(1)(13);
    o_weight_matrix_line(813)       <= (others => '0');
    o_activation_matrix_line(814)   <= s_kc_pixel_line(1)(14);
    o_weight_matrix_line(814)       <= (others => '0');
    o_activation_matrix_line(815)   <= s_kc_pixel_line(1)(15);
    o_weight_matrix_line(815)       <= (others => '0');
    o_bias_line(83)                 <= s_wm_bias_line(83);
    o_shamt_line(83)                <= s_wm_shamt_line(83);
    o_kernel_en_line(83)            <= s_kc_valid_line(1)(12);
    o_kernel_complete_line(83)      <= s_kc_comp_line(1)(12);
    o_activation_matrix_line(816)   <= s_kc_pixel_line(1)(16);
    o_weight_matrix_line(816)       <= (others => '0');
    o_activation_matrix_line(817)   <= s_kc_pixel_line(1)(17);
    o_weight_matrix_line(817)       <= (others => '0');
    o_activation_matrix_line(818)   <= (others => '0');
    o_weight_matrix_line(818)       <= (others => '0');
    o_activation_matrix_line(819)   <= (others => '0');
    o_weight_matrix_line(819)       <= (others => '0');
    o_bias_line(84)                 <= s_wm_bias_line(84);
    o_shamt_line(84)                <= s_wm_shamt_line(84);
    o_kernel_en_line(84)            <= s_kc_valid_line(1)(16);
    o_kernel_complete_line(84)      <= s_kc_comp_line(1)(16);
    o_activation_matrix_line(820)   <= s_kc_pixel_line(1)(80);
    o_weight_matrix_line(820)       <= (others => '0');
    o_activation_matrix_line(821)   <= s_kc_pixel_line(1)(81);
    o_weight_matrix_line(821)       <= (others => '0');
    o_activation_matrix_line(822)   <= s_kc_pixel_line(1)(82);
    o_weight_matrix_line(822)       <= (others => '0');
    o_activation_matrix_line(823)   <= s_kc_pixel_line(1)(83);
    o_weight_matrix_line(823)       <= (others => '0');
    o_bias_line(85)                 <= s_wm_bias_line(85);
    o_shamt_line(85)                <= s_wm_shamt_line(85);
    o_kernel_en_line(85)            <= s_kc_valid_line(1)(80);
    o_kernel_complete_line(85)      <= s_kc_comp_line(1)(80);
    o_activation_matrix_line(824)   <= s_kc_pixel_line(1)(84);
    o_weight_matrix_line(824)       <= (others => '0');
    o_activation_matrix_line(825)   <= (others => '0');
    o_weight_matrix_line(825)       <= (others => '0');
    o_activation_matrix_line(826)   <= (others => '0');
    o_weight_matrix_line(826)       <= (others => '0');
    o_activation_matrix_line(827)   <= (others => '0');
    o_weight_matrix_line(827)       <= (others => '0');
    o_bias_line(86)                 <= s_wm_bias_line(86);
    o_shamt_line(86)                <= s_wm_shamt_line(86);
    o_kernel_en_line(86)            <= s_kc_valid_line(1)(84);
    o_kernel_complete_line(86)      <= s_kc_comp_line(1)(84);
    o_activation_matrix_line(828)   <= s_kc_pixel_line(1)(85);
    o_weight_matrix_line(828)       <= (others => '0');
    o_activation_matrix_line(829)   <= s_kc_pixel_line(1)(86);
    o_weight_matrix_line(829)       <= (others => '0');
    o_activation_matrix_line(830)   <= (others => '0');
    o_weight_matrix_line(830)       <= (others => '0');
    o_activation_matrix_line(831)   <= (others => '0');
    o_weight_matrix_line(831)       <= (others => '0');
    o_bias_line(87)                 <= s_wm_bias_line(87);
    o_shamt_line(87)                <= s_wm_shamt_line(87);
    o_kernel_en_line(87)            <= s_kc_valid_line(1)(85);
    o_kernel_complete_line(87)      <= s_kc_comp_line(1)(85);


    -------------------------------------------
    -- FINAL OUTPUTs
    -------------------------------------------

    o_kernel_complete <= s_kc_comp_line(1)(87);
    o_kernel_valid    <= s_kc_valid_line(1)(87);
    o_pixel_line(0)   <= std_logic_vector(resize(unsigned(s_kc_pixel_line(1)(87)), o_pixel_line(0)'LENGTH));


end architecture route_a;
