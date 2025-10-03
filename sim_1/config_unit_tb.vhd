library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity config_unit_tb is
end entity config_unit_tb;

architecture bench of config_unit_tb is

	-- Clock period
	constant clk_period : time := 5 ns;
	-- Generics
	-- Ports
	signal clk                        : std_logic := '1';
	signal reset                      : std_logic;
	signal i_wt_s_axis_tdata          : std_logic_vector(127 downto 0);
	signal i_wt_s_axis_tkeep          : std_logic_vector(15 downto 0);
	signal i_wt_s_axis_tlast          : std_logic;
	signal o_wt_s_axis_tready         : std_logic;
	signal i_wt_s_axis_tvalid         : std_logic;
	signal o_config_valid             : std_logic;
	signal o_config_valid_1c          : std_logic;
	signal o_config_error             : std_logic;
	signal o_config_error_1c          : std_logic;
	signal o_image_input_length       : std_logic_vector(15 downto 0);
	signal o_image_output_length      : std_logic_vector(15 downto 0);
	signal o_input_channel_size       : std_logic_vector(15 downto 0);
	signal o_output_channel_size      : std_logic_vector(15 downto 0);
	signal o_input_channel_iterations : std_logic_vector(15 downto 0);
	signal o_kernel_size              : std_logic_vector(7 downto 0);
	signal o_padding_size             : std_logic_vector(7 downto 0);
	signal o_stride_bit_mask          : std_logic_vector(7 downto 0);
	signal o_shamt                    : std_logic_vector(7 downto 0);
	signal o_pool_or_conv             : std_logic;
	signal o_enable_relu              : std_logic;

begin

	config_unit_inst : entity work.config_unit
		port map (
			clk                        => clk,
			reset                      => reset,
			i_wt_s_axis_tdata          => i_wt_s_axis_tdata,
			i_wt_s_axis_tkeep          => i_wt_s_axis_tkeep,
			i_wt_s_axis_tlast          => i_wt_s_axis_tlast,
			o_wt_s_axis_tready         => o_wt_s_axis_tready,
			i_wt_s_axis_tvalid         => i_wt_s_axis_tvalid,
			o_config_valid             => o_config_valid,
			o_config_valid_1c          => o_config_valid_1c,
			o_config_error             => o_config_error,
			o_config_error_1c          => o_config_error_1c,
			o_image_input_length       => o_image_input_length,
			o_image_output_length      => o_image_output_length,
			o_input_channel_size       => o_input_channel_size,
			o_output_channel_size      => o_output_channel_size,
			o_input_channel_iterations => o_input_channel_iterations,
			o_kernel_size              => o_kernel_size,
			o_padding_size             => o_padding_size,
			o_stride_bit_mask          => o_stride_bit_mask,
			o_shamt                    => o_shamt,
			o_pool_or_conv             => o_pool_or_conv,
			o_enable_relu              => o_enable_relu
		);

	clk <= not clk after clk_period / 2;

	RESET_PROC : process is
	begin

		reset <= '1';
		wait for 2 * clk_period;
		reset <= '0';
		wait for 4 * clk_period;
		reset <= '1';
		wait for 2 * clk_period;
		reset <= '0';
		wait;

	end process RESET_PROC;

	INPUT_PROC : process is
	begin

		i_wt_s_axis_tdata  <= (others => '0');
		i_wt_s_axis_tkeep  <= (others => '1');
		i_wt_s_axis_tlast  <= '0';
		i_wt_s_axis_tvalid <= '0';

		wait for 2 * clk_period;

		-- Ignored config
		i_wt_s_axis_tdata <= x"55555555555555555555555555555555";

		wait for clk_period;

		-- Ignored config
		i_wt_s_axis_tdata <= x"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

		wait for clk_period;

		-- Valid Config
		i_wt_s_axis_tvalid <= '1';
		i_wt_s_axis_tlast  <= '1';
		i_wt_s_axis_tdata  <= x"AAAAAAAAAAAAAAAA" & x"5555555555555555";

		wait for 2 * clk_period;

		-- Reset config
		i_wt_s_axis_tdata  <= (others => '0');
		i_wt_s_axis_tkeep  <= (others => '0');
		i_wt_s_axis_tlast  <= '0';
		i_wt_s_axis_tvalid <= '0';

		wait for 2 * clk_period;

		-- Ignored config
		i_wt_s_axis_tdata <= x"55555555555555555555555555555555";

		wait for clk_period;

		-- Valid Config
		i_wt_s_axis_tvalid <= '1';
		i_wt_s_axis_tlast  <= '0';
		i_wt_s_axis_tdata  <= x"AAAAAAAAAAAAAAAA" & x"5555555555555555";

		wait;

	end process INPUT_PROC;

	TB_PROC : process is
	begin

		wait for 15 * clk_period;

		std.env.finish;

	end process TB_PROC;

end architecture bench;
