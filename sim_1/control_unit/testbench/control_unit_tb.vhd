library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.libmatrix.all;

library tb_lib;
use tb_lib.control_unit_tb_pkg.all;
use tb_lib.control_unit_tc_pkg.all;

library vunit_lib;
	context vunit_lib.vunit_context;
	context vunit_lib.vc_context;

library osvvm;
	context osvvm.OsvvmContext;
use osvvm.RandomPkg;

entity control_unit_tb is
	generic (
		runner_cfg : string      := runner_cfg_default;
		stop_level : log_level_t := error;
		-- TB
		G_RND_SEED  : STRING               := "xxx";
		G_LOG_LEVEL : INTEGER range 0 to 2 := 1;
		-- DUT
		G_WEIGHT_BIT_WIDTH : INTEGER range 2 to 128 := 8;
		G_WEIGHT_AMOUNT    : NATURAL                := 512
	);
end entity control_unit_tb;

architecture bench of control_unit_tb is

	-- Clock period
	signal clk    : std_logic := '0';
	signal s_tb_i : t_tb_i;
	signal s_tb_o : t_tb_o;

	constant stream_master : axi_stream_master_t := new_axi_stream_master(data_length => 128);

    signal tvalid : std_logic;
    signal tready : std_logic;
    signal tdata : std_logic_vector(127 downto 0);
    signal tlast : std_logic;
    signal tkeep : std_logic_vector(15 downto 0);

begin

	weight_unit_inst : entity work.weight_unit
		generic map (
			g_weight_bit_width => G_WEIGHT_BIT_WIDTH,
			g_weight_amount    => G_WEIGHT_AMOUNT
		)
		port map (
			clk                           => s_tb_i.clk,
			reset                         => s_tb_o.reset,
			i_wt_s_axis_tdata             => tdata,
			i_wt_s_axis_tkeep             => tkeep,
			i_wt_s_axis_tlast             => tlast,
			o_wt_s_axis_tready            => tready,
			i_wt_s_axis_tvalid            => tvalid,
			i_input_channel_per_iteration => s_tb_o.i_input_channel_per_iteration,
			i_kernel_size                 => s_tb_o.i_kernel_size,
			o_kernel_weight_init          => s_tb_i.o_kernel_weight_init,
			o_kernel_weight_error         => s_tb_i.o_kernel_weight_error,
			o_kernel_weight_matrix        => s_tb_i.o_kernel_weight_matrix
		);

	axi_stream_master_inst : entity vunit_lib.axi_stream_master
		generic map (
			master => stream_master
		)
		port map (
			aclk     => s_tb_i.clk,
			areset_n => not s_tb_o.reset,
			tvalid   => tvalid,
			tready   => tready,
			tdata    => tdata,
			tlast    => tlast,
			tkeep    => tkeep,
			tstrb    => open,
			tid      => open,
			tdest    => open,
			tuser    => open
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
				TC_0000(net, stream_master, s_tb_o, s_tb_i);
			elsif run("TC_0001") then
				TC_0001(net, stream_master, s_tb_o, s_tb_i);
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
