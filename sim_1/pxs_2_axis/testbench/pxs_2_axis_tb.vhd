library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library tb_lib;
use tb_lib.pxs_2_axis_tb_pkg.all;
use tb_lib.pxs_2_axis_tc_pkg.all;

library vunit_lib;
	context vunit_lib.vunit_context;
	context vunit_lib.vc_context;

library osvvm;
	context osvvm.OsvvmContext;
use osvvm.RandomPkg;

entity pxs_2_axis_tb is
	generic (
		runner_cfg : string      := runner_cfg_default;
		stop_level : log_level_t := error;
		-- TB
		G_RND_SEED  : STRING               := "xxx";
		G_LOG_LEVEL : INTEGER range 0 to 2 := 1;
		-- DUT
		G_OUTPUT_CHANNELS     : natural                := 2;
		G_DATA_BYTE_WIDTH     : integer range 1 to 128 := 16;
		G_BRAM_MAX_DEPTH      : natural                := 16;
		G_NEAR_FULL_THRESHOLD : natural                := 3
	);
end entity pxs_2_axis_tb;

architecture bench of pxs_2_axis_tb is

	-- Clock period
	signal clk    : std_logic := '0';
	signal s_tb_i : t_tb_i;
	signal s_tb_o : t_tb_o;

	constant stream_slave : axi_stream_slave_t := new_axi_stream_slave(data_length => G_DATA_BYTE_WIDTH * 8);

	signal tready : std_logic := '0';

begin

	pxs_2_axis_inst : entity work.pxs_2_axis
		generic map (
			G_OUTPUT_CHANNELS     => G_OUTPUT_CHANNELS,
			G_DATA_BYTE_WIDTH     => G_DATA_BYTE_WIDTH,
			G_BRAM_BYTE_WIDTH     => 1,
			G_BRAM_MAX_DEPTH      => G_BRAM_MAX_DEPTH,
			G_NEAR_FULL_THRESHOLD => G_NEAR_FULL_THRESHOLD
		)
		port map (
			clk               => s_tb_i.clk,
			reset             => s_tb_o.reset,
			o_en              => s_tb_i.o_en,
			i_kernel_complete => s_tb_o.i_kernel_complete,
			i_kernel_valid    => s_tb_o.i_kernel_valid,
			i_pixel_line      => s_tb_o.i_pixel_line,
			--
			o_accel_finished => s_tb_i.o_accel_finished,
			-- AXIS INTERFACE
			o_px_m_axis_tdata  => s_tb_i.o_px_m_axis_tdata,
			o_px_m_axis_tkeep  => s_tb_i.o_px_m_axis_tkeep,
			o_px_m_axis_tlast  => s_tb_i.o_px_m_axis_tlast,
			i_px_m_axis_tready => tready,
			o_px_m_axis_tvalid => s_tb_i.o_px_m_axis_tvalid
		);

	ready_proc : process is
	begin

		for i in 0 to sv_rnd.RandInt(0, 4) loop

			wait until rising_edge(s_tb_i.clk);

		end loop;

		tready <= '1';

		for i in 0 to sv_rnd.RandInt(0, 2) loop

			wait until rising_edge(s_tb_i.clk);

		end loop;

		tready <= '0';

	end process ready_proc;

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
				TC_0000(net, stream_slave, s_tb_o, s_tb_i);
			-- elsif run("TC_0001") then
			--  TC_0000(net, stream_master, s_tb_o, s_tb_i);
			else
				report "main: invalid test case assigned: " & enabled_test_cases(runner_cfg)
					severity failure;
			end if;

		end loop;

		test_runner_cleanup(runner);

	end process main;

	-------------------------------------------
	-- Monitors
	-------------------------------------------

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

			s_tb_i.G_LOG_LEVEL           <= G_LOG_LEVEL;
			s_tb_i.G_DATA_BYTE_WIDTH     <= G_DATA_BYTE_WIDTH;
			s_tb_i.G_OUTPUT_CHANNELS     <= G_OUTPUT_CHANNELS;
			s_tb_i.G_BRAM_BYTE_WIDTH     <= 1;
			s_tb_i.G_BRAM_MAX_DEPTH      <= G_BRAM_MAX_DEPTH;
			s_tb_i.G_NEAR_FULL_THRESHOLD <= G_NEAR_FULL_THRESHOLD;

			wait;

		end process p_one_time;

	end block b_misc;

end architecture bench;
