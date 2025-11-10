library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library tb_lib;
use tb_lib.top_level_cnn_tb_pkg.all;

library vunit_lib;
	context vunit_lib.vunit_context;
	context vunit_lib.vc_context;

library osvvm;
	context osvvm.OsvvmContext;
use osvvm.RandomPkg.all;
use osvvm.AlertLogPkg.Log;

package top_level_cnn_tc_pkg is

	----------------
	-- TEST CASES --
	----------------

	procedure TC_0000 (
		signal tb_o : out t_tb_o;
		signal tb_i : in t_tb_i
	);

	procedure TC_0010 (
		signal tb_o : out t_tb_o;
		signal tb_i : in t_tb_i
	);

	procedure TC_0020 (
		signal tb_o : out t_tb_o;
		signal tb_i : in t_tb_i
	);

end package top_level_cnn_tc_pkg;

package body top_level_cnn_tc_pkg is

	------------------------------------------------------------------
	-- test-case
	------------------------------------------------------------------

	procedure TC_0000 (
		signal tb_o : out t_tb_o;
		signal tb_i : in t_tb_i
	) is

	begin

		tc_init(tb_o, tb_i);

		tb_o.i_px_m_axis_tready <= '1';
		tb_o.i_use_rnd          <= FALSE;

		wait until rising_edge(tb_i.o_overall_done) or rising_edge(tb_i.o_overall_error) for 200000 * C_CLK_PERIOD;

		wait for 10 * C_CLK_PERIOD;

		tc_end(tb_o, tb_i);

	end procedure TC_0000;

	------------------------------------------------------------------
	-- test-case
	------------------------------------------------------------------

	procedure TC_0010 (
		signal tb_o : out t_tb_o;
		signal tb_i : in t_tb_i
	) is

	begin

		tc_init(tb_o, tb_i);

		tb_o.i_use_rnd <= TRUE;

		wait until rising_edge(tb_i.o_overall_done) or rising_edge(tb_i.o_overall_error) for 200000 * C_CLK_PERIOD;

		wait for 10 * C_CLK_PERIOD;
		
		--wait until rising_edge(tb_i.o_overall_done) or rising_edge(tb_i.o_overall_error) for 200000 * C_CLK_PERIOD;
		
		--wait for 10 * C_CLK_PERIOD;

		tc_end(tb_o, tb_i);

	end procedure TC_0010;

		------------------------------------------------------------------
	-- test-case
	------------------------------------------------------------------

	procedure TC_0020 (
		signal tb_o : out t_tb_o;
		signal tb_i : in t_tb_i
	) is

	begin

		tc_init(tb_o, tb_i);

		tb_o.i_use_rnd <= TRUE;

		wait until rising_edge(tb_i.o_overall_done) or rising_edge(tb_i.o_overall_error) for 200000 * C_CLK_PERIOD;

		wait for 10 * C_CLK_PERIOD;
		
		wait until rising_edge(tb_i.o_overall_done) or rising_edge(tb_i.o_overall_error) for 200000 * C_CLK_PERIOD;
		
		wait for 10 * C_CLK_PERIOD;

		tc_end(tb_o, tb_i);

	end procedure TC_0020;

end package body top_level_cnn_tc_pkg;
