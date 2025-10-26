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
		G_RND_SEED   : STRING               := "xxx";
		G_LOG_LEVEL  : integer range 0 to 2 := 1;
		G_CONFIG_STR : string
	);
end entity top_level_cnn_tb;

architecture bench of top_level_cnn_tb is

	-- Clock period
	signal clk    : std_logic := '0';
	signal s_tb_i : t_tb_i;
	signal s_tb_o : t_tb_o;

	signal s_tready : std_logic := '0';

	signal s_actual_tready : std_logic;

	constant stream_master_wt : axi_stream_master_t := new_axi_stream_master(data_length => 128);
	constant stream_master_px : axi_stream_master_t := new_axi_stream_master(data_length => 128);

	-- constant c_config_slv : std_logic_vector(127 downto 0) := HEX_READ()

	signal wt_tvalid, px_tvalid : std_logic;
	signal wt_tready, px_tready : std_logic;
	signal wt_tdata,  px_tdata  : std_logic_vector(127 downto 0);
	signal wt_tlast,  px_tlast  : std_logic;
	signal wt_tkeep,  px_tkeep  : std_logic_vector(15 downto 0);

begin

	s_actual_tready <= s_tready when s_tb_o.i_use_rnd else s_tb_o.i_px_m_axis_tready;

	top_level_cnn_wrapper_inst : entity work.top_level_cnn_wrapper
		port map (
			clk                 => s_tb_i.clk,
			reset               => s_tb_o.reset,
			wt_s_axis_tdata     => wt_tdata,
			wt_s_axis_tkeep     => wt_tkeep,
			wt_s_axis_tlast     => wt_tlast,
			wt_s_axis_tready    => wt_tready,
			wt_s_axis_tvalid    => wt_tvalid,
			px_s_axis_tdata     => px_tdata,
			px_s_axis_tkeep     => px_tkeep,
			px_s_axis_tlast     => px_tlast,
			px_s_axis_tready    => px_tready,
			px_s_axis_tvalid    => px_tvalid,
			px_m_axis_tdata     => s_tb_i.o_px_m_axis_tdata,
			px_m_axis_tkeep     => s_tb_i.o_px_m_axis_tkeep,
			px_m_axis_tlast     => s_tb_i.o_px_m_axis_tlast,
			px_m_axis_tready    => s_actual_tready,
			px_m_axis_tvalid    => s_tb_i.o_px_m_axis_tvalid,
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

	ready_proc : process is
	begin

		for i in 0 to sv_rnd.RandInt(0, 4) loop

			wait until rising_edge(s_tb_i.clk);

		end loop;

		s_tready <= '1';

		for i in 0 to sv_rnd.RandInt(0, 2) loop

			wait until rising_edge(s_tb_i.clk);

		end loop;

		s_tready <= '0';

	end process ready_proc;

	WEIGHT_PROC : process is

		variable weight_index : natural := 0;
		variable v_tlast      : std_logic;

	begin

		wait until falling_edge(s_tb_o.reset);

		push_axi_stream(net, stream_master_wt,
	                tdata => hexstr_to_slv(G_CONFIG_STR)(127 downto 0),
	                tlast => '1',
	                tkeep => x"FFFF");

		for i in 0 to sv_rnd.RandInt(0, 3) loop

			wait until rising_edge(clk);

		end loop;

		report " # Weight amount per iteration: " & INTEGER'image(get_weight_per_iteration(G_CONFIG_STR));

		while True loop

			if weight_index + 16 >= get_weight_per_iteration(G_CONFIG_STR) then
				v_tlast := '1';
				weight_index := 0;
			else
				v_tlast := '0';
				weight_index := weight_index + 16;
			end if;

			push_axi_stream(net, stream_master_wt,
	                tdata => x"01010101010101010101010101010101",
	                tlast => v_tlast,
	                tkeep => x"FFFF");


			for i in 0 to sv_rnd.RandInt(0, 3) loop

				wait until rising_edge(clk);

			end loop;

		end loop;

		wait;

	end process WEIGHT_PROC;

	PIXEL_PROC : process is
	begin

		wait until falling_edge(s_tb_o.reset);

		while True loop

			push_axi_stream(net, stream_master_px,
	                tdata => x"01010101010101010101010101010101",
	                tlast => '0',
	                tkeep => x"FFFF");

			-- wait until rising_edge(s_tb_i.clk) and px_tready = '1';

			for i in 0 to sv_rnd.RandInt(0, 3) loop

				wait until rising_edge(clk);

			end loop;

		end loop;

		wait;

	end process PIXEL_PROC;

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
			elsif run("TC_0010") then
				TC_0010(s_tb_o, s_tb_i);
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
