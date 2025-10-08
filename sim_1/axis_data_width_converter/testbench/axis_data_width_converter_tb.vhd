library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library tb_lib;
use tb_lib.axis_data_width_converter_tb_pkg.all;
use tb_lib.axis_data_width_converter_tc_pkg.all;

library vunit_lib;
	context vunit_lib.vunit_context;
	context vunit_lib.vc_context;

library osvvm;
	context osvvm.OsvvmContext;
use osvvm.RandomPkg;

entity axis_data_width_converter_tb is
	generic (
		runner_cfg : string      := runner_cfg_default;
		stop_level : log_level_t := error;
		-- TB
		G_RND_SEED  : STRING               := "xxx";
		G_LOG_LEVEL : INTEGER range 0 to 2 := 1;
		-- DUT
		G_INPUT_BYTE_WIDTH  : INTEGER range 1 to 128 := 16;
		G_OUTPUT_BYTE_WIDTH : INTEGER range 1 to 128 := 15
	);
end entity axis_data_width_converter_tb;

architecture bench of axis_data_width_converter_tb is

	-- Clock period
	signal clk    : std_logic := '0';
	signal s_tb_i : t_tb_i;
	signal s_tb_o : t_tb_o;

	constant stream_master : axi_stream_master_t := new_axi_stream_master(data_length => G_INPUT_BYTE_WIDTH * 8);

	signal tvalid : std_logic;
	signal tready : std_logic;
	signal tdata  : std_logic_vector(G_INPUT_BYTE_WIDTH * 8 - 1 downto 0);
	signal tlast  : std_logic;
	signal tkeep  : std_logic_vector(G_INPUT_BYTE_WIDTH - 1 downto 0);

	signal m_axis_tready : std_logic;
	signal const_m_tready : std_logic := '1';
	signal rnd_m_tready   : std_logic := '0';

begin

	axis_data_width_converter_inst : entity tb_lib.axis_data_width_converter
		generic map (
			G_INPUT_BYTE_WIDTH  => G_INPUT_BYTE_WIDTH,
			G_OUTPUT_BYTE_WIDTH => G_OUTPUT_BYTE_WIDTH
		)
		port map (
			clk   => s_tb_i.clk,
			reset => s_tb_o.reset,
			-- AXIS INPUT
			i_s_axis_tdata  => tdata,
			i_s_axis_tkeep  => tkeep,
			i_s_axis_tlast  => tlast,
			o_s_axis_tready => tready,
			i_s_axis_tvalid => tvalid,
			-- AXIS OUTPUT
			o_m_axis_tdata  => s_tb_i.o_m_axis_tdata(G_OUTPUT_BYTE_WIDTH * 8 - 1 downto 0),
			o_m_axis_tkeep  => s_tb_i.o_m_axis_tkeep(G_OUTPUT_BYTE_WIDTH - 1 downto 0),
			o_m_axis_tlast  => s_tb_i.o_m_axis_tlast,
			i_m_axis_tready => m_axis_tready,
			o_m_axis_tvalid => s_tb_i.o_m_axis_tvalid
		);

	axi_stream_master_inst : entity vunit_lib.axi_stream_master
		generic map (
			master => stream_master,
			drive_invalid_val => '0'
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

	RND_TREADY : process is
	begin

		for i in 0 to sv_rnd.RandInt(0, 4) loop

			wait until rising_edge(s_tb_i.clk);

		end loop;

		rnd_m_tready <= '1';

		for i in 0 to sv_rnd.RandInt(0, 2) loop

			wait until rising_edge(s_tb_i.clk);

		end loop;

		rnd_m_tready <= '0';

	end process RND_TREADY;

	m_axis_tready <= const_m_tready when running_test_case = "TC_0000" else rnd_m_tready;

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
				TC_0000(net, stream_master, s_tb_o, s_tb_i);
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

			s_tb_i.G_LOG_LEVEL         <= G_LOG_LEVEL;
			s_tb_i.G_INPUT_BYTE_WIDTH  <= G_INPUT_BYTE_WIDTH;
			s_tb_i.G_OUTPUT_BYTE_WIDTH <= G_OUTPUT_BYTE_WIDTH;

			wait;

		end process p_one_time;

	end block b_misc;

end architecture bench;
