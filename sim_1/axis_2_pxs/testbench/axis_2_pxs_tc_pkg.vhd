library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library tb_lib;
use tb_lib.axis_2_pxs_tb_pkg.all;

library vunit_lib;
	context vunit_lib.vunit_context;
	context vunit_lib.vc_context;

library osvvm;
	context osvvm.OsvvmContext;
use osvvm.RandomPkg.all;
use osvvm.AlertLogPkg.Log;

package axis_2_pxs_tc_pkg is

	----------------
	-- TEST CASES --
	----------------

	procedure TC_0000 (
		signal net      : inout network_t;
		constant stream : axi_stream_master_t;
		signal tb_o     : out t_tb_o;
		signal tb_i     : in t_tb_i;
		signal en       : std_logic
	);

end package axis_2_pxs_tc_pkg;

package body axis_2_pxs_tc_pkg is

	------------------------------------------------------------------
	-- test-case
	------------------------------------------------------------------

	procedure TC_0000 (
		signal net      : inout network_t;
		constant stream : axi_stream_master_t;
		signal tb_o     : out t_tb_o;
		signal tb_i     : in t_tb_i;
		signal en       : std_logic
	) is

		variable tdata : std_logic_vector(tb_i.G_INPUT_BYTE_WIDTH * 8 - 1 downto 0) := f_create_start_stream_id_indicator(tb_i);

	begin

		tb_o.i_image_input_length <= std_logic_vector(to_unsigned(10, tb_o.i_image_input_length'length));
		tb_o.i_padding_size       <= std_logic_vector(to_unsigned(2, tb_o.i_padding_size'length));

		tc_init(tb_o, tb_i);

		for i in 0 to 109 loop

			push_axi_stream(net, stream,
	                tdata => tdata,
	                tlast => '0',
	                tkeep => x"FFFF");

			tdata := f_create_data_stream(tb_i, tdata);

			-- Random wait cycle
			for j in 0 to sv_rnd.RandInt(0, 5) - 1 loop

				wait until rising_edge(tb_i.clk) and en = '1';

			end loop;

		end loop;

		tc_end(tb_o, tb_i);

	end procedure TC_0000;

end package body axis_2_pxs_tc_pkg;
