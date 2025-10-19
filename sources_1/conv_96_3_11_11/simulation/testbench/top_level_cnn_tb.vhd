library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.libmatrix.all;

library tb_lib;
use tb_lib.top_level_cnn_tb_pkg.all;
use tb_lib.top_level_cnn_tc_pkg.all;

library vunit_lib;
	context vunit_lib.vunit_context;
	context vunit_lib.vc_context;

library osvvm;
	context osvvm.OsvvmContext;
use osvvm.RandomPkg;

entity top_level_cnn_tb is
	generic (
		runner_cfg : string      := runner_cfg_default;
		stop_level : log_level_t := error;
		-- TB
		G_RND_SEED  : STRING               := "xxx";
		G_LOG_LEVEL : integer range 0 to 2 := 1
	);
end entity top_level_cnn_tb;

architecture bench of top_level_cnn_tb is

	-- Clock period
	signal clk    : std_logic := '0';
	signal s_tb_i : t_tb_i;
	signal s_tb_o : t_tb_o;

	constant stream_master_wt : axi_stream_master_t := new_axi_stream_master(data_length => 128);
	constant stream_master_px : axi_stream_master_t := new_axi_stream_master(data_length => 128);

	signal wt_tvalid, px_tvalid : std_logic;
	signal wt_tready, px_tready : std_logic;
	signal wt_tdata,  px_tdata  : std_logic_vector(127 downto 0);
	signal wt_tlast,  px_tlast  : std_logic;
	signal wt_tkeep,  px_tkeep  : std_logic_vector(15 downto 0);

begin

	top_level_cnn_wrapper_inst : entity work.top_level_cnn_wrapper
		port map (
			clk                 => s_tb_i.clk,
			reset               => s_tb_o.reset,
			i_wt_s_axis_tdata   => wt_tdata,
			i_wt_s_axis_tkeep   => wt_tkeep,
			i_wt_s_axis_tlast   => wt_tlast,
			o_wt_s_axis_tready  => wt_tready,
			i_wt_s_axis_tvalid  => wt_tvalid,
			i_px_s_axis_tdata   => px_tdata,
			i_px_s_axis_tkeep   => px_tkeep,
			i_px_s_axis_tlast   => px_tlast,
			o_px_s_axis_tready  => px_tready,
			i_px_s_axis_tvalid  => px_tvalid,
			o_px_m_axis_tdata   => s_tb_i.o_px_m_axis_tdata,
			o_px_m_axis_tkeep   => s_tb_i.o_px_m_axis_tkeep,
			o_px_m_axis_tlast   => s_tb_i.o_px_m_axis_tlast,
			i_px_m_axis_tready  => s_tb_o.i_px_m_axis_tready,
			o_px_m_axis_tvalid  => s_tb_i.o_px_m_axis_tvalid,
			o_current_ic_amount => s_tb_i.o_current_ic_amount,
			o_current_state     => s_tb_i.o_current_state,
			o_overall_done      => s_tb_i.o_overall_done,
			o_overall_error     => s_tb_i.o_overall_error
		);

	axi_stream_master_weights : entity vunit_lib.axi_stream_master
		generic map (
			master => stream_master_wt
		)
		port map (
			aclk     => s_tb_i.clk,
			areset_n => not s_tb_o.reset,
			tvalid   => wt_tvalid,
			tready   => wt_tready,
			tdata    => wt_tdata,
			tlast    => wt_tlast,
			tkeep    => wt_tkeep,
			tstrb    => open,
			tid      => open,
			tdest    => open,
			tuser    => open
		);

	axi_stream_master_pixel : entity vunit_lib.axi_stream_master
		generic map (
			master => stream_master_px
		)
		port map (
			aclk     => s_tb_i.clk,
			areset_n => not s_tb_o.reset,
			tvalid   => px_tvalid,
			tready   => px_tready,
			tdata    => px_tdata,
			tlast    => px_tlast,
			tkeep    => px_tkeep,
			tstrb    => open,
			tid      => open,
			tdest    => open,
			tuser    => open
		);

	WEIGHT_PROC: process
	begin
		-- TODO
		wait;
	end process;

	PIXEL_PROC: process
	begin
		-- TODO
		wait;
	end process;

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

			s_tb_i.G_LOG_LEVEL <= G_LOG_LEVEL;

			wait;

		end process p_one_time;

	end block b_misc;

end architecture bench;
