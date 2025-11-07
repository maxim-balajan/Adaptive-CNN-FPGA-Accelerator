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
        o_activation_matrix_line  : OUT matrix_1d(0 to 6000 - 1)(24 - 1 downto 0);
        o_weight_matrix_line      : OUT matrix_1d(0 to 6000 - 1)(24 - 1 downto 0);
        o_shamt_line              : OUT matrix_1d(0 to 300 - 1)(8 - 1 downto 0);
        o_bias_line               : OUT matrix_1d(0 to 300 - 1)(8 - 1 downto 0);
        o_kernel_en_line          : OUT std_logic_vector(0 to 300 - 1);   
        o_kernel_complete_line    : OUT std_logic_vector(0 to 300 - 1);
        -- KERNEL CORES OUTPUT PORTS
        i_pixel_line         : IN matrix_1d(0 to 300 - 1)(24 - 1 downto 0);
        i_valid_pixel_line   : IN std_logic_vector(0 to 300 - 1);
        i_comp_complete_line : IN std_logic_vector(0 to 300 - 1);
        -- CONFIGURABLE SLIDER OUTPUTS
        i_kernel_complete          : IN std_logic;
		i_kernel_en                : IN std_logic;
		i_kernel_activation_matrix : IN matrix_1d(0 to 12 * 80 - 1)(8 - 1 downto 0);
        -- WEIGHT MODULE OUTPUTS
        i_kernel_weight_en     : IN std_logic;
        i_kernel_weight_matrix : IN matrix_1d(0 to 12 * 80 - 1)(8 - 1 downto 0); 
        i_shamt_line           : IN matrix_1d(0 to 300 - 1)(8 - 1 downto 0);
        i_bias_line            : IN matrix_1d(0 to 300 - 1)(8 - 1 downto 0);
        -- ROUTING CORES OUTPUTS
        o_kernel_complete : OUT std_logic;
        o_kernel_valid    : OUT std_logic;
        o_pixel_line      : OUT matrix_1d(0 to 16 - 1)(8 - 1 downto 0)
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
    o_bias_line(0)                  <= s_wm_bias_line(0);
    o_shamt_line(0)                 <= s_wm_shamt_line(0);
    o_kernel_en_line(0)             <= s_cs_kernel_en;
    o_kernel_complete_line(0)       <= s_cs_kernel_complete;
    o_activation_matrix_line(4)     <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(4)), o_activation_matrix_line(4)'LENGTH));
    o_weight_matrix_line(4)         <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(4)), o_weight_matrix_line(4)'LENGTH));
    o_activation_matrix_line(5)     <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(5)), o_activation_matrix_line(5)'LENGTH));
    o_weight_matrix_line(5)         <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(5)), o_weight_matrix_line(5)'LENGTH));
    o_activation_matrix_line(6)     <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(6)), o_activation_matrix_line(6)'LENGTH));
    o_weight_matrix_line(6)         <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(6)), o_weight_matrix_line(6)'LENGTH));
    o_activation_matrix_line(7)     <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(7)), o_activation_matrix_line(7)'LENGTH));
    o_weight_matrix_line(7)         <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(7)), o_weight_matrix_line(7)'LENGTH));
    o_bias_line(1)                  <= s_wm_bias_line(1);
    o_shamt_line(1)                 <= s_wm_shamt_line(1);
    o_kernel_en_line(1)             <= s_cs_kernel_en;
    o_kernel_complete_line(1)       <= s_cs_kernel_complete;
    o_activation_matrix_line(8)     <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(8)), o_activation_matrix_line(8)'LENGTH));
    o_weight_matrix_line(8)         <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(8)), o_weight_matrix_line(8)'LENGTH));
    o_activation_matrix_line(9)     <= (others => '0');
    o_weight_matrix_line(9)         <= (others => '0');
    o_activation_matrix_line(10)    <= (others => '0');
    o_weight_matrix_line(10)        <= (others => '0');
    o_activation_matrix_line(11)    <= (others => '0');
    o_weight_matrix_line(11)        <= (others => '0');
    o_bias_line(2)                  <= s_wm_bias_line(2);
    o_shamt_line(2)                 <= s_wm_shamt_line(2);
    o_kernel_en_line(2)             <= s_cs_kernel_en;
    o_kernel_complete_line(2)       <= s_cs_kernel_complete;
    o_activation_matrix_line(12)    <= s_kc_pixel_line(1)(0);
    o_weight_matrix_line(12)        <= (others => '0');
    o_activation_matrix_line(13)    <= s_kc_pixel_line(1)(1);
    o_weight_matrix_line(13)        <= (others => '0');
    o_activation_matrix_line(14)    <= s_kc_pixel_line(1)(2);
    o_weight_matrix_line(14)        <= (others => '0');
    o_activation_matrix_line(15)    <= (others => '0');
    o_weight_matrix_line(15)        <= (others => '0');
    o_bias_line(3)                  <= s_wm_bias_line(3);
    o_shamt_line(3)                 <= s_wm_shamt_line(3);
    o_kernel_en_line(3)             <= s_kc_valid_line(1)(0);
    o_kernel_complete_line(3)       <= s_kc_comp_line(1)(0);

    -- Output Channel 1 Routing...
    o_activation_matrix_line(16)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(9)), o_activation_matrix_line(16)'LENGTH));
    o_weight_matrix_line(16)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(9)), o_weight_matrix_line(16)'LENGTH));
    o_activation_matrix_line(17)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(10)), o_activation_matrix_line(17)'LENGTH));
    o_weight_matrix_line(17)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(10)), o_weight_matrix_line(17)'LENGTH));
    o_activation_matrix_line(18)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(11)), o_activation_matrix_line(18)'LENGTH));
    o_weight_matrix_line(18)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(11)), o_weight_matrix_line(18)'LENGTH));
    o_activation_matrix_line(19)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(12)), o_activation_matrix_line(19)'LENGTH));
    o_weight_matrix_line(19)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(12)), o_weight_matrix_line(19)'LENGTH));
    o_bias_line(4)                  <= s_wm_bias_line(4);
    o_shamt_line(4)                 <= s_wm_shamt_line(4);
    o_kernel_en_line(4)             <= s_cs_kernel_en;
    o_kernel_complete_line(4)       <= s_cs_kernel_complete;
    o_activation_matrix_line(20)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(13)), o_activation_matrix_line(20)'LENGTH));
    o_weight_matrix_line(20)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(13)), o_weight_matrix_line(20)'LENGTH));
    o_activation_matrix_line(21)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(14)), o_activation_matrix_line(21)'LENGTH));
    o_weight_matrix_line(21)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(14)), o_weight_matrix_line(21)'LENGTH));
    o_activation_matrix_line(22)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(15)), o_activation_matrix_line(22)'LENGTH));
    o_weight_matrix_line(22)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(15)), o_weight_matrix_line(22)'LENGTH));
    o_activation_matrix_line(23)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(16)), o_activation_matrix_line(23)'LENGTH));
    o_weight_matrix_line(23)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(16)), o_weight_matrix_line(23)'LENGTH));
    o_bias_line(5)                  <= s_wm_bias_line(5);
    o_shamt_line(5)                 <= s_wm_shamt_line(5);
    o_kernel_en_line(5)             <= s_cs_kernel_en;
    o_kernel_complete_line(5)       <= s_cs_kernel_complete;
    o_activation_matrix_line(24)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(17)), o_activation_matrix_line(24)'LENGTH));
    o_weight_matrix_line(24)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(17)), o_weight_matrix_line(24)'LENGTH));
    o_activation_matrix_line(25)    <= (others => '0');
    o_weight_matrix_line(25)        <= (others => '0');
    o_activation_matrix_line(26)    <= (others => '0');
    o_weight_matrix_line(26)        <= (others => '0');
    o_activation_matrix_line(27)    <= (others => '0');
    o_weight_matrix_line(27)        <= (others => '0');
    o_bias_line(6)                  <= s_wm_bias_line(6);
    o_shamt_line(6)                 <= s_wm_shamt_line(6);
    o_kernel_en_line(6)             <= s_cs_kernel_en;
    o_kernel_complete_line(6)       <= s_cs_kernel_complete;
    o_activation_matrix_line(28)    <= s_kc_pixel_line(1)(4);
    o_weight_matrix_line(28)        <= (others => '0');
    o_activation_matrix_line(29)    <= s_kc_pixel_line(1)(5);
    o_weight_matrix_line(29)        <= (others => '0');
    o_activation_matrix_line(30)    <= s_kc_pixel_line(1)(6);
    o_weight_matrix_line(30)        <= (others => '0');
    o_activation_matrix_line(31)    <= (others => '0');
    o_weight_matrix_line(31)        <= (others => '0');
    o_bias_line(7)                  <= s_wm_bias_line(7);
    o_shamt_line(7)                 <= s_wm_shamt_line(7);
    o_kernel_en_line(7)             <= s_kc_valid_line(1)(4);
    o_kernel_complete_line(7)       <= s_kc_comp_line(1)(4);

    -- Output Channel 2 Routing...
    o_activation_matrix_line(32)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(18)), o_activation_matrix_line(32)'LENGTH));
    o_weight_matrix_line(32)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(18)), o_weight_matrix_line(32)'LENGTH));
    o_activation_matrix_line(33)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(19)), o_activation_matrix_line(33)'LENGTH));
    o_weight_matrix_line(33)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(19)), o_weight_matrix_line(33)'LENGTH));
    o_activation_matrix_line(34)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(20)), o_activation_matrix_line(34)'LENGTH));
    o_weight_matrix_line(34)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(20)), o_weight_matrix_line(34)'LENGTH));
    o_activation_matrix_line(35)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(21)), o_activation_matrix_line(35)'LENGTH));
    o_weight_matrix_line(35)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(21)), o_weight_matrix_line(35)'LENGTH));
    o_bias_line(8)                  <= s_wm_bias_line(8);
    o_shamt_line(8)                 <= s_wm_shamt_line(8);
    o_kernel_en_line(8)             <= s_cs_kernel_en;
    o_kernel_complete_line(8)       <= s_cs_kernel_complete;
    o_activation_matrix_line(36)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(22)), o_activation_matrix_line(36)'LENGTH));
    o_weight_matrix_line(36)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(22)), o_weight_matrix_line(36)'LENGTH));
    o_activation_matrix_line(37)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(23)), o_activation_matrix_line(37)'LENGTH));
    o_weight_matrix_line(37)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(23)), o_weight_matrix_line(37)'LENGTH));
    o_activation_matrix_line(38)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(24)), o_activation_matrix_line(38)'LENGTH));
    o_weight_matrix_line(38)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(24)), o_weight_matrix_line(38)'LENGTH));
    o_activation_matrix_line(39)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(25)), o_activation_matrix_line(39)'LENGTH));
    o_weight_matrix_line(39)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(25)), o_weight_matrix_line(39)'LENGTH));
    o_bias_line(9)                  <= s_wm_bias_line(9);
    o_shamt_line(9)                 <= s_wm_shamt_line(9);
    o_kernel_en_line(9)             <= s_cs_kernel_en;
    o_kernel_complete_line(9)       <= s_cs_kernel_complete;
    o_activation_matrix_line(40)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(26)), o_activation_matrix_line(40)'LENGTH));
    o_weight_matrix_line(40)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(26)), o_weight_matrix_line(40)'LENGTH));
    o_activation_matrix_line(41)    <= (others => '0');
    o_weight_matrix_line(41)        <= (others => '0');
    o_activation_matrix_line(42)    <= (others => '0');
    o_weight_matrix_line(42)        <= (others => '0');
    o_activation_matrix_line(43)    <= (others => '0');
    o_weight_matrix_line(43)        <= (others => '0');
    o_bias_line(10)                 <= s_wm_bias_line(10);
    o_shamt_line(10)                <= s_wm_shamt_line(10);
    o_kernel_en_line(10)            <= s_cs_kernel_en;
    o_kernel_complete_line(10)      <= s_cs_kernel_complete;
    o_activation_matrix_line(44)    <= s_kc_pixel_line(1)(8);
    o_weight_matrix_line(44)        <= (others => '0');
    o_activation_matrix_line(45)    <= s_kc_pixel_line(1)(9);
    o_weight_matrix_line(45)        <= (others => '0');
    o_activation_matrix_line(46)    <= s_kc_pixel_line(1)(10);
    o_weight_matrix_line(46)        <= (others => '0');
    o_activation_matrix_line(47)    <= (others => '0');
    o_weight_matrix_line(47)        <= (others => '0');
    o_bias_line(11)                 <= s_wm_bias_line(11);
    o_shamt_line(11)                <= s_wm_shamt_line(11);
    o_kernel_en_line(11)            <= s_kc_valid_line(1)(8);
    o_kernel_complete_line(11)      <= s_kc_comp_line(1)(8);

    -- Output Channel 3 Routing...
    o_activation_matrix_line(48)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(27)), o_activation_matrix_line(48)'LENGTH));
    o_weight_matrix_line(48)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(27)), o_weight_matrix_line(48)'LENGTH));
    o_activation_matrix_line(49)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(28)), o_activation_matrix_line(49)'LENGTH));
    o_weight_matrix_line(49)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(28)), o_weight_matrix_line(49)'LENGTH));
    o_activation_matrix_line(50)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(29)), o_activation_matrix_line(50)'LENGTH));
    o_weight_matrix_line(50)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(29)), o_weight_matrix_line(50)'LENGTH));
    o_activation_matrix_line(51)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(30)), o_activation_matrix_line(51)'LENGTH));
    o_weight_matrix_line(51)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(30)), o_weight_matrix_line(51)'LENGTH));
    o_bias_line(12)                 <= s_wm_bias_line(12);
    o_shamt_line(12)                <= s_wm_shamt_line(12);
    o_kernel_en_line(12)            <= s_cs_kernel_en;
    o_kernel_complete_line(12)      <= s_cs_kernel_complete;
    o_activation_matrix_line(52)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(31)), o_activation_matrix_line(52)'LENGTH));
    o_weight_matrix_line(52)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(31)), o_weight_matrix_line(52)'LENGTH));
    o_activation_matrix_line(53)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(32)), o_activation_matrix_line(53)'LENGTH));
    o_weight_matrix_line(53)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(32)), o_weight_matrix_line(53)'LENGTH));
    o_activation_matrix_line(54)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(33)), o_activation_matrix_line(54)'LENGTH));
    o_weight_matrix_line(54)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(33)), o_weight_matrix_line(54)'LENGTH));
    o_activation_matrix_line(55)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(34)), o_activation_matrix_line(55)'LENGTH));
    o_weight_matrix_line(55)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(34)), o_weight_matrix_line(55)'LENGTH));
    o_bias_line(13)                 <= s_wm_bias_line(13);
    o_shamt_line(13)                <= s_wm_shamt_line(13);
    o_kernel_en_line(13)            <= s_cs_kernel_en;
    o_kernel_complete_line(13)      <= s_cs_kernel_complete;
    o_activation_matrix_line(56)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(35)), o_activation_matrix_line(56)'LENGTH));
    o_weight_matrix_line(56)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(35)), o_weight_matrix_line(56)'LENGTH));
    o_activation_matrix_line(57)    <= (others => '0');
    o_weight_matrix_line(57)        <= (others => '0');
    o_activation_matrix_line(58)    <= (others => '0');
    o_weight_matrix_line(58)        <= (others => '0');
    o_activation_matrix_line(59)    <= (others => '0');
    o_weight_matrix_line(59)        <= (others => '0');
    o_bias_line(14)                 <= s_wm_bias_line(14);
    o_shamt_line(14)                <= s_wm_shamt_line(14);
    o_kernel_en_line(14)            <= s_cs_kernel_en;
    o_kernel_complete_line(14)      <= s_cs_kernel_complete;
    o_activation_matrix_line(60)    <= s_kc_pixel_line(1)(12);
    o_weight_matrix_line(60)        <= (others => '0');
    o_activation_matrix_line(61)    <= s_kc_pixel_line(1)(13);
    o_weight_matrix_line(61)        <= (others => '0');
    o_activation_matrix_line(62)    <= s_kc_pixel_line(1)(14);
    o_weight_matrix_line(62)        <= (others => '0');
    o_activation_matrix_line(63)    <= (others => '0');
    o_weight_matrix_line(63)        <= (others => '0');
    o_bias_line(15)                 <= s_wm_bias_line(15);
    o_shamt_line(15)                <= s_wm_shamt_line(15);
    o_kernel_en_line(15)            <= s_kc_valid_line(1)(12);
    o_kernel_complete_line(15)      <= s_kc_comp_line(1)(12);

    -- Output Channel 4 Routing...
    o_activation_matrix_line(64)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(36)), o_activation_matrix_line(64)'LENGTH));
    o_weight_matrix_line(64)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(36)), o_weight_matrix_line(64)'LENGTH));
    o_activation_matrix_line(65)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(37)), o_activation_matrix_line(65)'LENGTH));
    o_weight_matrix_line(65)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(37)), o_weight_matrix_line(65)'LENGTH));
    o_activation_matrix_line(66)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(38)), o_activation_matrix_line(66)'LENGTH));
    o_weight_matrix_line(66)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(38)), o_weight_matrix_line(66)'LENGTH));
    o_activation_matrix_line(67)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(39)), o_activation_matrix_line(67)'LENGTH));
    o_weight_matrix_line(67)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(39)), o_weight_matrix_line(67)'LENGTH));
    o_bias_line(16)                 <= s_wm_bias_line(16);
    o_shamt_line(16)                <= s_wm_shamt_line(16);
    o_kernel_en_line(16)            <= s_cs_kernel_en;
    o_kernel_complete_line(16)      <= s_cs_kernel_complete;
    o_activation_matrix_line(68)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(40)), o_activation_matrix_line(68)'LENGTH));
    o_weight_matrix_line(68)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(40)), o_weight_matrix_line(68)'LENGTH));
    o_activation_matrix_line(69)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(41)), o_activation_matrix_line(69)'LENGTH));
    o_weight_matrix_line(69)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(41)), o_weight_matrix_line(69)'LENGTH));
    o_activation_matrix_line(70)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(42)), o_activation_matrix_line(70)'LENGTH));
    o_weight_matrix_line(70)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(42)), o_weight_matrix_line(70)'LENGTH));
    o_activation_matrix_line(71)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(43)), o_activation_matrix_line(71)'LENGTH));
    o_weight_matrix_line(71)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(43)), o_weight_matrix_line(71)'LENGTH));
    o_bias_line(17)                 <= s_wm_bias_line(17);
    o_shamt_line(17)                <= s_wm_shamt_line(17);
    o_kernel_en_line(17)            <= s_cs_kernel_en;
    o_kernel_complete_line(17)      <= s_cs_kernel_complete;
    o_activation_matrix_line(72)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(44)), o_activation_matrix_line(72)'LENGTH));
    o_weight_matrix_line(72)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(44)), o_weight_matrix_line(72)'LENGTH));
    o_activation_matrix_line(73)    <= (others => '0');
    o_weight_matrix_line(73)        <= (others => '0');
    o_activation_matrix_line(74)    <= (others => '0');
    o_weight_matrix_line(74)        <= (others => '0');
    o_activation_matrix_line(75)    <= (others => '0');
    o_weight_matrix_line(75)        <= (others => '0');
    o_bias_line(18)                 <= s_wm_bias_line(18);
    o_shamt_line(18)                <= s_wm_shamt_line(18);
    o_kernel_en_line(18)            <= s_cs_kernel_en;
    o_kernel_complete_line(18)      <= s_cs_kernel_complete;
    o_activation_matrix_line(76)    <= s_kc_pixel_line(1)(16);
    o_weight_matrix_line(76)        <= (others => '0');
    o_activation_matrix_line(77)    <= s_kc_pixel_line(1)(17);
    o_weight_matrix_line(77)        <= (others => '0');
    o_activation_matrix_line(78)    <= s_kc_pixel_line(1)(18);
    o_weight_matrix_line(78)        <= (others => '0');
    o_activation_matrix_line(79)    <= (others => '0');
    o_weight_matrix_line(79)        <= (others => '0');
    o_bias_line(19)                 <= s_wm_bias_line(19);
    o_shamt_line(19)                <= s_wm_shamt_line(19);
    o_kernel_en_line(19)            <= s_kc_valid_line(1)(16);
    o_kernel_complete_line(19)      <= s_kc_comp_line(1)(16);

    -- Output Channel 5 Routing...
    o_activation_matrix_line(80)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(45)), o_activation_matrix_line(80)'LENGTH));
    o_weight_matrix_line(80)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(45)), o_weight_matrix_line(80)'LENGTH));
    o_activation_matrix_line(81)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(46)), o_activation_matrix_line(81)'LENGTH));
    o_weight_matrix_line(81)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(46)), o_weight_matrix_line(81)'LENGTH));
    o_activation_matrix_line(82)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(47)), o_activation_matrix_line(82)'LENGTH));
    o_weight_matrix_line(82)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(47)), o_weight_matrix_line(82)'LENGTH));
    o_activation_matrix_line(83)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(48)), o_activation_matrix_line(83)'LENGTH));
    o_weight_matrix_line(83)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(48)), o_weight_matrix_line(83)'LENGTH));
    o_bias_line(20)                 <= s_wm_bias_line(20);
    o_shamt_line(20)                <= s_wm_shamt_line(20);
    o_kernel_en_line(20)            <= s_cs_kernel_en;
    o_kernel_complete_line(20)      <= s_cs_kernel_complete;
    o_activation_matrix_line(84)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(49)), o_activation_matrix_line(84)'LENGTH));
    o_weight_matrix_line(84)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(49)), o_weight_matrix_line(84)'LENGTH));
    o_activation_matrix_line(85)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(50)), o_activation_matrix_line(85)'LENGTH));
    o_weight_matrix_line(85)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(50)), o_weight_matrix_line(85)'LENGTH));
    o_activation_matrix_line(86)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(51)), o_activation_matrix_line(86)'LENGTH));
    o_weight_matrix_line(86)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(51)), o_weight_matrix_line(86)'LENGTH));
    o_activation_matrix_line(87)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(52)), o_activation_matrix_line(87)'LENGTH));
    o_weight_matrix_line(87)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(52)), o_weight_matrix_line(87)'LENGTH));
    o_bias_line(21)                 <= s_wm_bias_line(21);
    o_shamt_line(21)                <= s_wm_shamt_line(21);
    o_kernel_en_line(21)            <= s_cs_kernel_en;
    o_kernel_complete_line(21)      <= s_cs_kernel_complete;
    o_activation_matrix_line(88)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(53)), o_activation_matrix_line(88)'LENGTH));
    o_weight_matrix_line(88)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(53)), o_weight_matrix_line(88)'LENGTH));
    o_activation_matrix_line(89)    <= (others => '0');
    o_weight_matrix_line(89)        <= (others => '0');
    o_activation_matrix_line(90)    <= (others => '0');
    o_weight_matrix_line(90)        <= (others => '0');
    o_activation_matrix_line(91)    <= (others => '0');
    o_weight_matrix_line(91)        <= (others => '0');
    o_bias_line(22)                 <= s_wm_bias_line(22);
    o_shamt_line(22)                <= s_wm_shamt_line(22);
    o_kernel_en_line(22)            <= s_cs_kernel_en;
    o_kernel_complete_line(22)      <= s_cs_kernel_complete;
    o_activation_matrix_line(92)    <= s_kc_pixel_line(1)(20);
    o_weight_matrix_line(92)        <= (others => '0');
    o_activation_matrix_line(93)    <= s_kc_pixel_line(1)(21);
    o_weight_matrix_line(93)        <= (others => '0');
    o_activation_matrix_line(94)    <= s_kc_pixel_line(1)(22);
    o_weight_matrix_line(94)        <= (others => '0');
    o_activation_matrix_line(95)    <= (others => '0');
    o_weight_matrix_line(95)        <= (others => '0');
    o_bias_line(23)                 <= s_wm_bias_line(23);
    o_shamt_line(23)                <= s_wm_shamt_line(23);
    o_kernel_en_line(23)            <= s_kc_valid_line(1)(20);
    o_kernel_complete_line(23)      <= s_kc_comp_line(1)(20);

    -- Output Channel 6 Routing...
    o_activation_matrix_line(96)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(54)), o_activation_matrix_line(96)'LENGTH));
    o_weight_matrix_line(96)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(54)), o_weight_matrix_line(96)'LENGTH));
    o_activation_matrix_line(97)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(55)), o_activation_matrix_line(97)'LENGTH));
    o_weight_matrix_line(97)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(55)), o_weight_matrix_line(97)'LENGTH));
    o_activation_matrix_line(98)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(56)), o_activation_matrix_line(98)'LENGTH));
    o_weight_matrix_line(98)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(56)), o_weight_matrix_line(98)'LENGTH));
    o_activation_matrix_line(99)    <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(57)), o_activation_matrix_line(99)'LENGTH));
    o_weight_matrix_line(99)        <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(57)), o_weight_matrix_line(99)'LENGTH));
    o_bias_line(24)                 <= s_wm_bias_line(24);
    o_shamt_line(24)                <= s_wm_shamt_line(24);
    o_kernel_en_line(24)            <= s_cs_kernel_en;
    o_kernel_complete_line(24)      <= s_cs_kernel_complete;
    o_activation_matrix_line(100)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(58)), o_activation_matrix_line(100)'LENGTH));
    o_weight_matrix_line(100)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(58)), o_weight_matrix_line(100)'LENGTH));
    o_activation_matrix_line(101)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(59)), o_activation_matrix_line(101)'LENGTH));
    o_weight_matrix_line(101)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(59)), o_weight_matrix_line(101)'LENGTH));
    o_activation_matrix_line(102)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(60)), o_activation_matrix_line(102)'LENGTH));
    o_weight_matrix_line(102)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(60)), o_weight_matrix_line(102)'LENGTH));
    o_activation_matrix_line(103)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(61)), o_activation_matrix_line(103)'LENGTH));
    o_weight_matrix_line(103)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(61)), o_weight_matrix_line(103)'LENGTH));
    o_bias_line(25)                 <= s_wm_bias_line(25);
    o_shamt_line(25)                <= s_wm_shamt_line(25);
    o_kernel_en_line(25)            <= s_cs_kernel_en;
    o_kernel_complete_line(25)      <= s_cs_kernel_complete;
    o_activation_matrix_line(104)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(62)), o_activation_matrix_line(104)'LENGTH));
    o_weight_matrix_line(104)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(62)), o_weight_matrix_line(104)'LENGTH));
    o_activation_matrix_line(105)   <= (others => '0');
    o_weight_matrix_line(105)       <= (others => '0');
    o_activation_matrix_line(106)   <= (others => '0');
    o_weight_matrix_line(106)       <= (others => '0');
    o_activation_matrix_line(107)   <= (others => '0');
    o_weight_matrix_line(107)       <= (others => '0');
    o_bias_line(26)                 <= s_wm_bias_line(26);
    o_shamt_line(26)                <= s_wm_shamt_line(26);
    o_kernel_en_line(26)            <= s_cs_kernel_en;
    o_kernel_complete_line(26)      <= s_cs_kernel_complete;
    o_activation_matrix_line(108)   <= s_kc_pixel_line(1)(24);
    o_weight_matrix_line(108)       <= (others => '0');
    o_activation_matrix_line(109)   <= s_kc_pixel_line(1)(25);
    o_weight_matrix_line(109)       <= (others => '0');
    o_activation_matrix_line(110)   <= s_kc_pixel_line(1)(26);
    o_weight_matrix_line(110)       <= (others => '0');
    o_activation_matrix_line(111)   <= (others => '0');
    o_weight_matrix_line(111)       <= (others => '0');
    o_bias_line(27)                 <= s_wm_bias_line(27);
    o_shamt_line(27)                <= s_wm_shamt_line(27);
    o_kernel_en_line(27)            <= s_kc_valid_line(1)(24);
    o_kernel_complete_line(27)      <= s_kc_comp_line(1)(24);

    -- Output Channel 7 Routing...
    o_activation_matrix_line(112)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(63)), o_activation_matrix_line(112)'LENGTH));
    o_weight_matrix_line(112)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(63)), o_weight_matrix_line(112)'LENGTH));
    o_activation_matrix_line(113)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(64)), o_activation_matrix_line(113)'LENGTH));
    o_weight_matrix_line(113)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(64)), o_weight_matrix_line(113)'LENGTH));
    o_activation_matrix_line(114)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(65)), o_activation_matrix_line(114)'LENGTH));
    o_weight_matrix_line(114)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(65)), o_weight_matrix_line(114)'LENGTH));
    o_activation_matrix_line(115)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(66)), o_activation_matrix_line(115)'LENGTH));
    o_weight_matrix_line(115)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(66)), o_weight_matrix_line(115)'LENGTH));
    o_bias_line(28)                 <= s_wm_bias_line(28);
    o_shamt_line(28)                <= s_wm_shamt_line(28);
    o_kernel_en_line(28)            <= s_cs_kernel_en;
    o_kernel_complete_line(28)      <= s_cs_kernel_complete;
    o_activation_matrix_line(116)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(67)), o_activation_matrix_line(116)'LENGTH));
    o_weight_matrix_line(116)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(67)), o_weight_matrix_line(116)'LENGTH));
    o_activation_matrix_line(117)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(68)), o_activation_matrix_line(117)'LENGTH));
    o_weight_matrix_line(117)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(68)), o_weight_matrix_line(117)'LENGTH));
    o_activation_matrix_line(118)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(69)), o_activation_matrix_line(118)'LENGTH));
    o_weight_matrix_line(118)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(69)), o_weight_matrix_line(118)'LENGTH));
    o_activation_matrix_line(119)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(70)), o_activation_matrix_line(119)'LENGTH));
    o_weight_matrix_line(119)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(70)), o_weight_matrix_line(119)'LENGTH));
    o_bias_line(29)                 <= s_wm_bias_line(29);
    o_shamt_line(29)                <= s_wm_shamt_line(29);
    o_kernel_en_line(29)            <= s_cs_kernel_en;
    o_kernel_complete_line(29)      <= s_cs_kernel_complete;
    o_activation_matrix_line(120)   <= std_logic_vector(resize(unsigned(s_cs_kernel_matrix(71)), o_activation_matrix_line(120)'LENGTH));
    o_weight_matrix_line(120)       <= std_logic_vector(resize(unsigned(s_wm_weight_matrix(71)), o_weight_matrix_line(120)'LENGTH));
    o_activation_matrix_line(121)   <= (others => '0');
    o_weight_matrix_line(121)       <= (others => '0');
    o_activation_matrix_line(122)   <= (others => '0');
    o_weight_matrix_line(122)       <= (others => '0');
    o_activation_matrix_line(123)   <= (others => '0');
    o_weight_matrix_line(123)       <= (others => '0');
    o_bias_line(30)                 <= s_wm_bias_line(30);
    o_shamt_line(30)                <= s_wm_shamt_line(30);
    o_kernel_en_line(30)            <= s_cs_kernel_en;
    o_kernel_complete_line(30)      <= s_cs_kernel_complete;
    o_activation_matrix_line(124)   <= s_kc_pixel_line(1)(28);
    o_weight_matrix_line(124)       <= (others => '0');
    o_activation_matrix_line(125)   <= s_kc_pixel_line(1)(29);
    o_weight_matrix_line(125)       <= (others => '0');
    o_activation_matrix_line(126)   <= s_kc_pixel_line(1)(30);
    o_weight_matrix_line(126)       <= (others => '0');
    o_activation_matrix_line(127)   <= (others => '0');
    o_weight_matrix_line(127)       <= (others => '0');
    o_bias_line(31)                 <= s_wm_bias_line(31);
    o_shamt_line(31)                <= s_wm_shamt_line(31);
    o_kernel_en_line(31)            <= s_kc_valid_line(1)(28);
    o_kernel_complete_line(31)      <= s_kc_comp_line(1)(28);


    -------------------------------------------
    -- FINAL OUTPUTs
    -------------------------------------------

    o_kernel_complete <= s_kc_comp_line(1)(3);
    o_kernel_valid    <= s_kc_valid_line(1)(3);
    o_pixel_line(0)   <= std_logic_vector(resize(unsigned(s_kc_pixel_line(1)(3)), o_pixel_line(0)'LENGTH));
    o_pixel_line(1)   <= std_logic_vector(resize(unsigned(s_kc_pixel_line(1)(7)), o_pixel_line(1)'LENGTH));
    o_pixel_line(2)   <= std_logic_vector(resize(unsigned(s_kc_pixel_line(1)(11)), o_pixel_line(2)'LENGTH));
    o_pixel_line(3)   <= std_logic_vector(resize(unsigned(s_kc_pixel_line(1)(15)), o_pixel_line(3)'LENGTH));
    o_pixel_line(4)   <= std_logic_vector(resize(unsigned(s_kc_pixel_line(1)(19)), o_pixel_line(4)'LENGTH));
    o_pixel_line(5)   <= std_logic_vector(resize(unsigned(s_kc_pixel_line(1)(23)), o_pixel_line(5)'LENGTH));
    o_pixel_line(6)   <= std_logic_vector(resize(unsigned(s_kc_pixel_line(1)(27)), o_pixel_line(6)'LENGTH));
    o_pixel_line(7)   <= std_logic_vector(resize(unsigned(s_kc_pixel_line(1)(31)), o_pixel_line(7)'LENGTH));


end architecture route_a;
