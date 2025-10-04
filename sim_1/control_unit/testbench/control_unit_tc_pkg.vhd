library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library tb_lib;
use tb_lib.control_unit_tb_pkg.all;

library vunit_lib;
	context vunit_lib.vunit_context;
	context vunit_lib.vc_context;

library osvvm;
	context osvvm.OsvvmContext;
use osvvm.RandomPkg.all;
use osvvm.AlertLogPkg.Log;

package control_unit_tc_pkg is

	----------------
	-- TEST CASES --
	----------------

	procedure TC_0000 (
		signal net      : inout network_t;
		constant stream : axi_stream_master_t;
		signal tb_o     : out t_tb_o;
		signal tb_i     : in t_tb_i
	);

	procedure TC_0001 (
		signal net      : inout network_t;
		constant stream : axi_stream_master_t;
		signal tb_o     : out t_tb_o;
		signal tb_i     : in t_tb_i
	);

end package control_unit_tc_pkg;

package body control_unit_tc_pkg is

	------------------------------------------------------------------
	-- test-case
	------------------------------------------------------------------

	procedure TC_0000 (
		signal net      : inout network_t;
		constant stream : axi_stream_master_t;
		signal tb_o     : out t_tb_o;
		signal tb_i     : in t_tb_i
	) is

	begin

		tc_init(tb_o, tb_i);

		check_failed(" # Not implemented yes!");

		tc_end(tb_o, tb_i);

	end procedure TC_0000;

	------------------------------------------------------------------
	-- test-case
	------------------------------------------------------------------

	procedure TC_0001 (
		signal net      : inout network_t;
		constant stream : axi_stream_master_t;
		signal tb_o     : out t_tb_o;
		signal tb_i     : in t_tb_i
	) is
	begin

		tc_init(tb_o, tb_i);

		check_failed(" # Not implemented yet!");

		tc_end(tb_o, tb_i);

	end procedure TC_0001;

end package body control_unit_tc_pkg;
