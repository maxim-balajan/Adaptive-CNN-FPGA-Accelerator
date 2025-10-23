library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library tb_lib;
use tb_lib.axis_2_configurable_slider_tb_pkg.all;
use tb_lib.axis_2_configurable_slider_tc_pkg.all;

library vunit_lib;
	context vunit_lib.vunit_context;
	context vunit_lib.vc_context;

library osvvm;
	context osvvm.OsvvmContext;
use osvvm.RandomPkg;

entity axis_2_configurable_slider_tb is
	generic (
		runner_cfg : string      := runner_cfg_default;
		stop_level : log_level_t := error;
		-- TB
		G_RND_SEED  : STRING               := "xxx";
		G_LOG_LEVEL : INTEGER range 0 to 2 := 1;
		-- DUT
		G_INPUT_BYTE_WIDTH            : INTEGER range 1 to 128 := 16;
		G_OUTPUT_BYTE_WIDTH           : INTEGER range 1 to 128 := 15;
		G_INPUT_CHANNEL_PER_ITERATION : natural                := 3;
		G_IMG_MAX_LENGTH              : natural                := 300;
		G_MAX_FIFO_DEPTH              : natural                := 512;
		G_NEAR_FULL_THRESHOLD         : natural                := 0
	);
end entity axis_2_configurable_slider_tb;

architecture bench of axis_2_configurable_slider_tb is

	-- Clock period
	signal clk       : std_logic := '0';
	signal s_tb_i    : t_tb_i;
	signal s_tb_o    : t_tb_o;
	signal s_en      : std_logic := '1';
	signal s_wt_init : std_logic := '0';
	signal s_cs_init : std_logic := '0';

	constant stream_master : axi_stream_master_t := new_axi_stream_master(data_length => G_INPUT_BYTE_WIDTH * 8);

	signal tvalid : std_logic;
	signal tready : std_logic;
	signal tdata  : std_logic_vector(G_INPUT_BYTE_WIDTH * 8 - 1 downto 0);
	signal tlast  : std_logic;
	signal tkeep  : std_logic_vector(G_INPUT_BYTE_WIDTH - 1 downto 0);

	signal s_count_valid : integer := 0;

begin

	axis_2_configurable_slider_wrapper_inst : entity work.axis_2_configurable_slider_wrapper
		generic map (
			G_VECTOR_BYTE_LENGTH          => 1,
			G_IMG_MAX_LENGTH              => 300,
			G_KERNEL_SIZE                 => 5,
			G_PADDING_SIZE                => 2,
			G_INPUT_BYTE_WIDTH            => 16,
			G_OUTPUT_BYTE_WIDTH           => 15,
			G_INPUT_CHANNEL_PER_ITERATION => 3,
			G_MAX_FIFO_DEPTH              => 512,
			G_NEAR_FULL_THRESHOLD         => 0,
			G_MAX_KERNEL_SIZE             => 11,
			G_LINE_BUFFER_AMOUNT          => 16 * 5,
			G_PIPELINE_STEPS              => 1
		)
		port map (
			clk                        => clk,
			reset                      => s_tb_o.reset,
			--
			i_rst_axis_2_pxs => s_tb_o.reset,
			i_rst_configurable_slider => s_tb_o.reset,
			--
			i_pool_or_conv => '1',
			i_en                       => '1',
			i_s_axis_tdata             => tdata,
			i_s_axis_tkeep             => tkeep,
			i_s_axis_tlast             => tlast,
			o_s_axis_tready            => tready,
			i_s_axis_tvalid            => tvalid,
			i_image_input_length       => (others => '0') ,
			i_image_output_length      => (others => '0') ,
			i_kernel_size              => (others => '0') ,
			i_padding_size             => (others => '0') ,
			i_stride_bit_mask          => (others => '0') ,
			i_wt_init                  => '0',
			o_kernel_complete          => open,
			o_kernel_en                => open,
			o_kernel_activation_matrix => open
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

	EN_PROC : process is
	begin

		for i in 0 to sv_rnd.RandInt(0, 4) loop

			wait until rising_edge(s_tb_i.clk);

		end loop;

		s_en <= '1';

		for i in 0 to sv_rnd.RandInt(0, 2) loop

			wait until rising_edge(s_tb_i.clk);

		end loop;

		s_en <= '0';

	end process EN_PROC;

	WT_INIT_PROC : process is
	begin

		s_wt_init <= '0';

		for i in 0 to sv_rnd.RandInt(43, 188) loop

			wait until rising_edge(s_tb_i.clk) and s_en = '1';

		end loop;

		s_wt_init <= '1';

		wait;

	end process WT_INIT_PROC;

	CS_INIT_PROC : process is
	begin

		s_cs_init <= '0';

		for i in 0 to sv_rnd.RandInt(23, 57) loop

			wait until rising_edge(s_tb_i.clk) and s_en = '1';

		end loop;

		s_cs_init <= '1';

		wait;

	end process CS_INIT_PROC;

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
				TC_0000(net, stream_master, s_tb_o, s_tb_i, s_en);
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

	b_valid_count : block is
	begin

		process (clk) is
		begin

			if rising_edge(clk) then
				if s_tb_o.reset = '1' then
					s_count_valid <= 0;
				elsif s_tb_i.o_valid_pixel_streams = '1' then
					s_count_valid <= s_count_valid + 1;
				end if;
			end if;

		end process;

	end block b_valid_count;

	-------------------------------------------
	-- misc.
	-------------------------------------------

	clk <= not clk after C_CLK_PERIOD / 2;

	b_misc : block is
	begin

		p_clk : process (clk, s_en, s_wt_init, s_cs_init) is
		begin

			s_tb_i.clk       <= clk;
			s_tb_i.i_en      <= s_en;
			s_tb_i.i_wt_init <= s_wt_init;
			s_tb_i.i_cs_init <= s_cs_init;

		end process p_clk;

		p_one_time : process is
		begin

			s_tb_i.G_LOG_LEVEL                   <= G_LOG_LEVEL;
			s_tb_i.G_INPUT_BYTE_WIDTH            <= G_INPUT_BYTE_WIDTH;
			s_tb_i.G_OUTPUT_BYTE_WIDTH           <= G_OUTPUT_BYTE_WIDTH;
			s_tb_i.G_BRAM_BYTE_WIDTH             <= 1;
			s_tb_i.G_INPUT_CHANNEL_PER_ITERATION <= G_INPUT_CHANNEL_PER_ITERATION;
			s_tb_i.G_IMG_MAX_LENGTH              <= G_IMG_MAX_LENGTH;
			s_tb_i.G_MAX_FIFO_DEPTH              <= G_MAX_FIFO_DEPTH;
			s_tb_i.G_NEAR_FULL_THRESHOLD         <= G_NEAR_FULL_THRESHOLD;

			wait;

		end process p_one_time;

	end block b_misc;

end architecture bench;
