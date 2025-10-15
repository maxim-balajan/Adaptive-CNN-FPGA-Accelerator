library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library tb_lib;
use tb_lib.pxs_2_axis_tb_pkg.all;

library vunit_lib;
	context vunit_lib.vunit_context;
	context vunit_lib.vc_context;

library osvvm;
	context osvvm.OsvvmContext;
use osvvm.RandomPkg.all;
use osvvm.AlertLogPkg.Log;

package pxs_2_axis_tc_pkg is

	----------------
	-- TEST CASES --
	----------------

	procedure TC_0000 (
		signal net      : inout network_t;
		constant stream : axi_stream_slave_t;
		signal tb_o     : out t_tb_o;
		signal tb_i     : in t_tb_i
	);

end package pxs_2_axis_tc_pkg;

package body pxs_2_axis_tc_pkg is

	------------------------------------------------------------------
	-- test-case
	------------------------------------------------------------------

	procedure TC_0000 (
		signal net      : inout network_t;
		constant stream : axi_stream_slave_t;
		signal tb_o     : out t_tb_o;
		signal tb_i     : in t_tb_i
	) is

		variable data : unsigned(7 downto 0) := (others => '0');

	begin

		tc_init(tb_o, tb_i);

		wait for 3 ps; -- wait some time

		for i in 0 to 99 loop

			tb_o.i_kernel_complete <= '0' when i /= 99 else '1';
			tb_o.i_kernel_valid <= '1';
			tb_o.i_pixel_line   <= (others => std_logic_vector(data));

			wait until rising_edge(tb_i.clk) and tb_i.o_en = '1';
			tb_o.i_kernel_valid <= '0';

			-- Invalid delay cycles
			for i in 0 to sv_rnd.RandInt(0, 3) - 1 loop
				
				wait until rising_edge(tb_i.clk) and tb_i.o_en = '1';

			end loop;

			if data = 127 then
				data := (others => '0') ;
			else
				data := data + 1;
			end if;

		end loop;

			wait until rising_edge(tb_i.o_accel_finished) for 5 * C_CLK_PERIOD;
			wait for 5 * C_CLK_PERIOD;

		tc_end(tb_o, tb_i);

	end procedure TC_0000;

end package body pxs_2_axis_tc_pkg;
