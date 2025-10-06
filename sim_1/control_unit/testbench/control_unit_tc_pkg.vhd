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

		variable iteration_amount : natural;
		variable tkeep            : std_logic_vector(15 downto 0);
		variable tlast            : std_logic;
		variable tdata            : std_logic_vector(127 downto 0) := (others => '0');
		variable left_over        : natural;

	begin

		tc_init(tb_o, tb_i);

		osvvm.AlertLogPkg.Log("Simple push of Config data");

		push_axi_stream(net, stream,
		-- important values (kernel_size=0x0B, input_channel_simul=0x03, input_channel_size=0x03, output_channel_size=0x03)
	                tdata => x"01010301020B00030003000300e30037",
	                tkeep => x"FFFF",
	                tlast => '1');

		-- Random wait cycle
		for j in 0 to sv_rnd.RandInt(0, 10) - 1 loop

			wait until rising_edge(tb_i.clk);

		end loop;

		osvvm.AlertLogPkg.Log("Simple push of Weight data over three iterations");

		for n in 0 to 2 loop

			tb_o.i_temp_comp_complete <= '0';

			iteration_amount := integer(ceil(real(11 * 11 * 3) / real(128 / tb_i.g_weight_bit_width)));

			for i in 1 to iteration_amount - 1 loop

				push_axi_stream(net, stream,
	                tdata => x"000102030405060708090A0B0C0D0E0F",
	                tlast => '0',
	                tkeep => x"FFFF"
	              );

				-- Random wait cycle
				for j in 0 to sv_rnd.RandInt(0, 10) - 1 loop

					wait until rising_edge(tb_i.clk);

				end loop;

			end loop;

			left_over := ((128 / tb_i.g_weight_bit_width)) - (iteration_amount * (128 / tb_i.g_weight_bit_width) - (11 * 11 * 3));
			osvvm.AlertLogPkg.Log("Left_over: " & Integer'image(left_over));

			tdata(8 * left_over - 1 downto 0)      := (others => '1');
			tdata(tdata'high downto 8 * left_over) := (others => 'U');
			tkeep(left_over - 1 downto 0)          := (others => '1');
			tkeep(tkeep'high downto left_over)     := (others => '0');
			push_axi_stream(net, stream,
	                tdata => tdata,
	                tlast => '1',
	                tkeep => tkeep
	              );

			osvvm.AlertLogPkg.Log("Left_over: " & Integer'image(left_over));

			-- Random wait cycle
			for j in 0 to sv_rnd.RandInt(0, 10) - 1 loop

				wait until rising_edge(tb_i.clk);

			end loop;

			wait on tb_i.clk until tb_i.o_kernel_weight_init = '1' or tb_i.o_kernel_weight_error = '1' for 150 * C_CLK_PERIOD;

			check_true(tb_i.o_kernel_weight_init = '1', "Check Kernel Weight was initialized");

			check_true(tb_i.o_kernel_weight_error = '0', "Check Kernel Error not triggered");

			-- Random wait cycle
			for j in 0 to sv_rnd.RandInt(2, 15) - 1 loop

				wait until rising_edge(tb_i.clk);

			end loop;

			tb_o.i_temp_comp_complete <= '1';

			-- Random wait cycle
			for j in 0 to sv_rnd.RandInt(2, 15) - 1 loop

				wait until rising_edge(tb_i.clk);

			end loop;

		end loop;

		wait on tb_i.clk until tb_i.o_overall_done = '1' or tb_i.o_overall_error = '1' for 15 * C_CLK_PERIOD;

		check_true(tb_i.o_kernel_weight_error = '0', "Check if Control Unit has no errors");

		check_true(tb_i.o_overall_done = '1', "Check if Control Unit has finished");

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
