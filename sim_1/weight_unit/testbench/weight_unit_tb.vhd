library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.libmatrix.all;

library tb_lib;
use tb_lib.weight_unit_tb_pkg.all;
use tb_lib.weight_unit_tc_pkg.all;

library vunit_lib;
	context vunit_lib.vunit_context;

library osvvm;
	context osvvm.OsvvmContext;
use osvvm.RandomPkg;

entity weight_unit_tb is
	generic (
		runner_cfg : string      := runner_cfg_default;
		stop_level : log_level_t := error;
		-- TB
		G_RND_SEED  : STRING               := "123";
		G_LOG_LEVEL : INTEGER range 0 to 2 := 1;
		-- DUT
		G_WEIGHT_BIT_WIDTH : INTEGER range 2 to 128 := 8;
		G_WEIGHT_AMOUNT    : NATURAL                := 128
	);
end entity weight_unit_tb;

architecture bench of weight_unit_tb is

	-- Clock period
	signal clk    : std_logic := '0';
	signal s_tb_i : t_tb_i;
	signal s_tb_o : t_tb_o;

begin

	weight_unit_inst : entity work.weight_unit
		generic map (
			g_weight_bit_width => G_WEIGHT_BIT_WIDTH,
			g_weight_amount    => G_WEIGHT_AMOUNT
		)
		port map (
			clk                           => s_tb_i.clk,
			reset                         => s_tb_o.reset,
			i_wt_s_axis_tdata             => s_tb_o.i_wt_s_axis_tdata,
			i_wt_s_axis_tkeep             => s_tb_o.i_wt_s_axis_tkeep,
			i_wt_s_axis_tlast             => s_tb_o.i_wt_s_axis_tlast,
			o_wt_s_axis_tready            => s_tb_i.o_wt_s_axis_tready,
			i_wt_s_axis_tvalid            => s_tb_o.i_wt_s_axis_tvalid,
			i_input_channel_per_iteration => s_tb_o.i_input_channel_per_iteration,
			i_kernel_size                 => s_tb_o.i_kernel_size,
			o_kernel_weight_init          => s_tb_i.o_kernel_weight_init,
			o_kernel_weight_error         => s_tb_i.o_kernel_weight_error,
			o_kernel_weight_matrix        => open
		);

	main : process is
	begin

		test_runner_setup(runner, runner_cfg);
		set_stop_level(stop_level);

		if G_LOG_LEVEL > 1 then
			enable_pass_msg;
		end if;

		-- User information
		info("Testbench directory..: " & tb_path(runner_cfg));
		info("Output    directory..: " & output_path(runner_cfg));
		info("Active test case.....: " & enabled_test_cases(runner_cfg));

		sv_rnd.initseed(G_RND_SEED);

		wait for 0 ns;

		while test_suite loop

			if run("TC_0000") then
				TC_0000(s_tb_o, s_tb_i);
			elsif run("TC_0001") then
				TC_0001(s_tb_o, s_tb_i);
			else
				report "main: invalid test case assigned: " & enabled_test_cases(runner_cfg)
					severity failure;
			end if;

		end loop;

		test_runner_cleanup(runner);

	end process main;

	-------------------------------------------
	-- misc.
	-------------------------------------------

	clk <= not clk after C_CLK_PERIOD / 2;

	b_misc : block is
	begin

		p_clk : process (clk) is
		begin

			s_tb_i.clk <= clk;

		end process p_clk;

		p_one_time : process is
		begin

			s_tb_i.G_LOG_LEVEL        <= G_LOG_LEVEL;
			s_tb_i.G_WEIGHT_BIT_WIDTH <= G_WEIGHT_BIT_WIDTH;
			s_tb_i.G_WEIGHT_AMOUNT    <= G_WEIGHT_AMOUNT;

            wait;

		end process p_one_time;

	end block b_misc;

end architecture bench;
