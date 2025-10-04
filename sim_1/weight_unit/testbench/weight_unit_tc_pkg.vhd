library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library tb_lib;
use tb_lib.weight_unit_tb_pkg.all;

library vunit_lib;
	context vunit_lib.vunit_context;
	context vunit_lib.vc_context;

library osvvm;
	context osvvm.OsvvmContext;
use osvvm.RandomPkg.all;
use osvvm.AlertLogPkg.Log;

package weight_unit_tc_pkg is

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

end package weight_unit_tc_pkg;

package body weight_unit_tc_pkg is

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

		tb_o.i_kernel_size                 <= x"0B";
		tb_o.i_input_channel_per_iteration <= x"0003";
		tc_init(tb_o, tb_i);

		osvvm.AlertLogPkg.Log("Simple push of weight data");

		iteration_amount := integer(ceil(real(11 * 11 * 3) / real(128 / tb_i.g_weight_bit_width)));

		-- Note: The weight unit takes in values in reversed order. Because of that, the first left_over
		-- bytes need to be filled with garbled data to keep the alignment because the unit needs a stream
		-- that ends with tlast=1 and tkeep=0xFFFF ! Otherwise the unit will break...
		
		left_over                              := iteration_amount * (128 / tb_i.g_weight_bit_width) - (11 * 11 * 3);
		tdata(8 * left_over - 1 downto 0)      := (others => 'U');
		tdata(tdata'high downto 8 * left_over) := (others => '1');
		push_axi_stream(net, stream,
	                tdata => tdata,
	                tlast => '1',
	                tkeep => x"FFFF"
	              );

		osvvm.AlertLogPkg.Log("Left_over: " & Integer'image(left_over));

		for i in 1 to iteration_amount - 1 loop

			tlast := '1' when i = (iteration_amount - 1) else '0';

			push_axi_stream(net, stream,
	                tdata => x"000102030405060708090A0B0C0D0E0F",
	                tlast => tlast,
	                tkeep => x"FFFF"
	              );

			-- Random wait cycle
			for j in 0 to sv_rnd.RandInt(0, 10) - 1 loop

				wait until rising_edge(tb_i.clk);

			end loop;

		end loop;

		wait on tb_i.clk until tb_i.o_kernel_weight_init = '1' or tb_i.o_kernel_weight_error = '1' for 150 * C_CLK_PERIOD;

		check_true(tb_i.o_kernel_weight_init = '1', "Check Kernel Weight was initialized");

		check_true(tb_i.o_kernel_weight_error = '0', "Check Kernel Error not triggered");

		wait for 3 * C_CLK_PERIOD;

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

end package body weight_unit_tc_pkg;
