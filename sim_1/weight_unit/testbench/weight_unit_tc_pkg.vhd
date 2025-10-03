library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library tb_lib;
use tb_lib.weight_unit_tb_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;


LIBRARY osvvm;
context osvvm.OsvvmContext;
use osvvm.RandomPkg.all;


package weight_unit_tc_pkg is
    
    ----------------
    -- TEST CASES --
    ----------------
    PROCEDURE TC_0000(signal tb_o : out t_tb_o; signal tb_i : t_tb_i);
    PROCEDURE TC_0001(signal tb_o : out t_tb_o; signal tb_i : t_tb_i);

end package;


package body weight_unit_tc_pkg is

    ------------------------------------------------------------------
    -- test-case
    ------------------------------------------------------------------
    procedure TC_0000 (signal tb_o : out t_tb_o; signal tb_i : t_tb_i) is
    begin
        tc_init(tb_o, tb_i);

        

        tc_end(tb_o, tb_i);
    end procedure;


    ------------------------------------------------------------------
    -- test-case
    ------------------------------------------------------------------
    procedure TC_0001 (signal tb_o : out t_tb_o; signal tb_i : t_tb_i) is
    begin
        tc_init(tb_o, tb_i);


        tc_end(tb_o, tb_i);
    end procedure;

end package body;