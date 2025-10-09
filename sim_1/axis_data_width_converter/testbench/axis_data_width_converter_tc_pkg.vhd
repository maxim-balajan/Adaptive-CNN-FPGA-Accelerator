library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library tb_lib;
use tb_lib.axis_data_width_converter_tb_pkg.all;

library vunit_lib;
	context vunit_lib.vunit_context;
	context vunit_lib.vc_context;

library osvvm;
	context osvvm.OsvvmContext;
use osvvm.RandomPkg.all;
use osvvm.AlertLogPkg.Log;

package axis_data_width_converter_tc_pkg is

	----------------
	-- TEST CASES --
	----------------

	procedure TC_0000 (
		signal net      : inout network_t;
		constant stream : axi_stream_master_t;
		signal tb_o     : out t_tb_o;
		signal tb_i     : in t_tb_i
	);

end package axis_data_width_converter_tc_pkg;

package body axis_data_width_converter_tc_pkg is

	------------------------------------------------------------------
	-- test-case
	------------------------------------------------------------------

	procedure TC_0000 (
		signal net      : inout network_t;
		constant stream : axi_stream_master_t;
		signal tb_o     : out t_tb_o;
		signal tb_i     : in t_tb_i
	) is

		variable v_tlast : std_logic;

	begin

		tc_init(tb_o, tb_i);

		osvvm.AlertLogPkg.Log("Simple push of 2 * tb_i.G_OUTPUT_BYTE_WIDTH valid signals (aligned with G_OUTPUT_BYTE_WIDTH) with random invalid in between");

		for i in 0 to 2 * tb_i.G_OUTPUT_BYTE_WIDTH loop

			if i = 5 then
				tb_o.reset <= '1';
				wait until rising_edge(tb_i.clk);
				wait until rising_edge(tb_i.clk);
				tb_o.reset <= '0';
				wait until rising_edge(tb_i.clk);
			end if;

			v_tlast := '0' when i /= 2 * tb_i.G_OUTPUT_BYTE_WIDTH - 1 else '1';

			push_axi_stream(net, stream,
	                tdata => x"0F0E0D0C0B0A09080706050403020100",
	                tlast => v_tlast,
	                tkeep => x"FFFF"
	              );

			-- Random wait cycle
			for j in 0 to sv_rnd.RandInt(0, 10) - 1 loop

				wait until rising_edge(tb_i.clk);

			end loop;

		end loop;

		wait for 30 * C_CLK_PERIOD;

		tc_end(tb_o, tb_i);

	end procedure TC_0000;


end package body axis_data_width_converter_tc_pkg;
