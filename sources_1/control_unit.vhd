library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity control_unit is
	generic (
		G_WEIGHT_BIT_WIDTH : integer range 2 to 128 := 8;
		G_WEIGHT_AMOUNT    : natural                := 128
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		-- AXIS Interface
		i_wt_s_axis_tdata  : in std_logic_vector(127 downto 0);
		i_wt_s_axis_tkeep  : in std_logic_vector(15 downto 0);
		i_wt_s_axis_tlast  : in std_logic;
		o_wt_s_axis_tready : out std_logic;
		i_wt_s_axis_tvalid : in std_logic;
		-- CONFIG Outputs
		o_image_input_length          : out std_logic_vector(15 downto 0);
		o_image_output_length         : out std_logic_vector(15 downto 0);
		o_input_channel_size          : out std_logic_vector(15 downto 0);
		o_output_channel_size         : out std_logic_vector(15 downto 0);
		o_input_channel_per_iteration : out std_logic_vector(15 downto 0);
		o_kernel_size                 : out std_logic_vector(7 downto 0);
		o_padding_size                : out std_logic_vector(7 downto 0);
		o_stride_bit_mask             : out std_logic_vector(7 downto 0);
		o_shamt                       : out std_logic_vector(7 downto 0);
		o_pool_or_conv                : out std_logic;
		o_enable_relu                 : out std_logic;
		-- WEIGHT MODULE OUTPUTS
		o_kernel_weight_init   : out std_logic;
		o_kernel_weight_error  : out std_logic;
		o_kernel_weight_matrix : out matrix_1d(0 to G_WEIGHT_AMOUNT - 1)(G_WEIGHT_BIT_WIDTH - 1 downto 0);
		-- RESET OUTPUTS
		o_rst_config_slider : out std_logic;
		o_rst_kernel_cores  : out std_logic;
		o_rst_accumulator   : out std_logic;
		o_rst_bram_fifo     : out std_logic;
		-- Control Signals
		i_temp_comp_complete : in std_logic;
		o_group_id           : out std_logic_vector(7 downto 0);
		o_current_state      : out std_logic_vector(7 downto 0);
		o_overall_done       : out std_logic
	);
end entity control_unit;

architecture rtl of control_unit is

	type control_state_t is (
		e_CONFIG_RETR, e_1st_RST_SUBMODULE,
		e_WT_RETR, e_WT_INIT, e_2nd_RST_SUBMODULE, e_DONE, e_ERROR
	);

	signal s_current_state : control_state_t;

	-- AXIS Interfaces routed to Config Unit
	signal s_wt_2_cfg_s_axis_tdata  : std_logic_vector(127 downto 0);
	signal s_wt_2_cfg_s_axis_tkeep  : std_logic_vector(15 downto 0);
	signal s_wt_2_cfg_s_axis_tlast  : std_logic;
	signal s_wt_2_cfg_s_axis_tready : std_logic;
	signal s_wt_2_cfg_s_axis_tvalid : std_logic;

	-- AXIS Interfaces routed to Weight Unit
	signal s_wt_2_wt_s_axis_tdata  : std_logic_vector(127 downto 0);
	signal s_wt_2_wt_s_axis_tkeep  : std_logic_vector(15 downto 0);
	signal s_wt_2_wt_s_axis_tlast  : std_logic;
	signal s_wt_2_wt_s_axis_tready : std_logic;
	signal s_wt_2_wt_s_axis_tvalid : std_logic;

	-- Reset signals
	signal s_rst_cfg_unit      : std_logic;
	signal s_rst_wt_unit       : std_logic;
	signal s_rst_config_slider : std_logic;
	signal s_rst_kernel_cores  : std_logic;
	signal s_rst_accumulator   : std_logic;
	signal s_rst_bram_fifo     : std_logic;

	-------------------------
	-- Control signals
	-------------------------
	-- CL of Control Unit
	signal s_group_id   : unsigned(15 downto 0);
	signal s_current_oc : unsigned(15 downto 0);

	-- CL Weight Unit <-> Control Unit <-> Config Unit
	signal s_kernel_size                 : std_logic_vector(7 downto 0);
	signal s_input_channel_per_iteration : std_logic_vector(15 downto 0);
	signal s_pool_or_conv                : std_logic;

	-- CL Config Unit
	signal s_config_valid    : std_logic;
	signal s_config_valid_1c : std_logic;
	signal s_config_error    : std_logic;
	signal s_config_error_1c : std_logic;

	-- CL Weight Unit
	signal s_kernel_weight_init  : std_logic;
	signal s_kernel_weight_error : std_logic;

begin

	TRANSITION_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_current_state <= e_CONFIG_RETR;
			else
				case s_current_state is
					when e_CONFIG_RETR =>
						if s_config_valid = '1' then
							s_current_state <= e_1st_RST_SUBMODULE;
						elsif s_config_error = '1' then
							s_current_state <= e_ERROR;
						end if;
					when e_1st_RST_SUBMODULE =>
						if s_pool_or_conv = '1' then
							s_current_state <= e_WT_RETR;
						else
							s_current_state <= e_WT_INIT;
						end if;
					when e_WT_RETR =>
						if s_kernel_weight_init = '1' then
							s_current_state <= e_WT_INIT;
						elsif s_kernel_weight_error = '1' then
							s_current_state <= e_ERROR;
						end if;
					when e_WT_INIT =>
						null;
					when e_2nd_RST_SUBMODULE =>
						null;
					when e_DONE =>
						null;
					when e_ERROR =>
						null;
				end case;
			end if;
		end if;

	end process TRANSITION_PROC;

	OUTPUT_PROC : process (s_current_state, i_wt_s_axis_tdata, i_wt_s_axis_tkeep, i_wt_s_axis_tlast, i_wt_s_axis_tvalid) is
	begin

		case s_current_state is
			when e_CONFIG_RETR =>
				-- Start at fist iteration
				s_group_id   <= (others => '0');
				s_current_oc <= (others => '0');

				-- Reset all modules except config unit
				s_rst_cfg_unit      <= '0';
				s_rst_wt_unit       <= '1';
				s_rst_config_slider <= '1';
				s_rst_kernel_cores  <= '1';
				s_rst_accumulator   <= '1';
				s_rst_bram_fifo     <= '1';

				-- Route all AXIS Interfaces IN to Config Unit
				o_wt_s_axis_tready <= s_wt_2_cfg_s_axis_tready;

				s_wt_2_cfg_s_axis_tdata  <= i_wt_s_axis_tdata;
				s_wt_2_cfg_s_axis_tkeep  <= i_wt_s_axis_tkeep;
				s_wt_2_cfg_s_axis_tlast  <= i_wt_s_axis_tlast;
				s_wt_2_cfg_s_axis_tvalid <= i_wt_s_axis_tvalid;

				-- Set all Weight Unit AXIS Interfaces to Low
				s_wt_2_wt_s_axis_tdata  <= (others => '0');
				s_wt_2_wt_s_axis_tkeep  <= (others => '0');
				s_wt_2_wt_s_axis_tlast  <= '0';
				s_wt_2_wt_s_axis_tvalid <= '0';
			when e_1st_RST_SUBMODULE =>
				-- Reset all modules except Config Unit, BRAM FIFO and Weight Unit
				-- -> that way configuration values are stored
				s_rst_cfg_unit      <= '0';
				s_rst_wt_unit       <= '0';
				s_rst_config_slider <= '1';
				s_rst_kernel_cores  <= '1';
				s_rst_accumulator   <= '1';
				s_rst_bram_fifo     <= '0';

				-- In this cycle, no values should be read from the weight stream
				-- -> ready has to be on Low
				o_wt_s_axis_tready <= '0';
			when e_WT_RETR =>
				-- Now Configurable Slider can start receive values until its just before initialized
				s_rst_cfg_unit      <= '0';
				s_rst_wt_unit       <= '0';
				s_rst_config_slider <= '0';
				s_rst_kernel_cores  <= '1';
				s_rst_accumulator   <= '1';
				s_rst_bram_fifo     <= '0';

				-- Route all AXIS Interfaces IN to Weight Unit
				o_wt_s_axis_tready <= s_wt_2_wt_s_axis_tready;

				s_wt_2_wt_s_axis_tdata  <= i_wt_s_axis_tdata;
				s_wt_2_wt_s_axis_tkeep  <= i_wt_s_axis_tkeep;
				s_wt_2_wt_s_axis_tlast  <= i_wt_s_axis_tlast;
				s_wt_2_wt_s_axis_tvalid <= i_wt_s_axis_tvalid;

				-- Set all Configurable Unit AXIS Interfaces to Low
				s_wt_2_cfg_s_axis_tdata  <= (others => '0');
				s_wt_2_cfg_s_axis_tkeep  <= (others => '0');
				s_wt_2_cfg_s_axis_tlast  <= '0';
				s_wt_2_cfg_s_axis_tvalid <= '0';
			when e_WT_INIT =>
				null;
			when e_2nd_RST_SUBMODULE =>
				null;
			when e_DONE =>
				null;
			when e_ERROR =>
				null;
		end case;

	end process OUTPUT_PROC;

	weight_unit_inst : entity work.weight_unit
		generic map (
			g_weight_bit_width => G_WEIGHT_BIT_WIDTH,
			g_weight_amount    => G_WEIGHT_AMOUNT
		)
		port map (
			clk   => clk,
			reset => reset or s_rst_wt_unit,
			-- AXIS Interface
			i_wt_s_axis_tdata  => s_wt_2_wt_s_axis_tdata,
			i_wt_s_axis_tkeep  => s_wt_2_wt_s_axis_tkeep,
			i_wt_s_axis_tlast  => s_wt_2_wt_s_axis_tlast,
			o_wt_s_axis_tready => s_wt_2_wt_s_axis_tready,
			i_wt_s_axis_tvalid => s_wt_2_wt_s_axis_tvalid,
			-- CONFIG MODULE OUTPUTS
			i_input_channel_per_iteration => s_input_channel_per_iteration,
			i_kernel_size                 => s_kernel_size,
			-- WEIGHT MODULE OUTPUTS
			o_kernel_weight_init   => s_kernel_weight_init,
			o_kernel_weight_error  => s_kernel_weight_error,
			o_kernel_weight_matrix => o_kernel_weight_matrix
		);

	config_unit_inst : entity work.config_unit
		port map (
			clk   => clk,
			reset => reset or s_rst_cfg_unit,
			-- AXIS Interface
			i_wt_s_axis_tdata  => s_wt_2_cfg_s_axis_tdata,
			i_wt_s_axis_tkeep  => s_wt_2_cfg_s_axis_tkeep,
			i_wt_s_axis_tlast  => s_wt_2_cfg_s_axis_tlast,
			o_wt_s_axis_tready => s_wt_2_cfg_s_axis_tready,
			i_wt_s_axis_tvalid => s_wt_2_cfg_s_axis_tvalid,
			-- Control Outputs
			o_config_valid    => s_config_valid,
			o_config_valid_1c => s_config_valid_1c,
			o_config_error    => s_config_error,
			o_config_error_1c => s_config_error_1c,
			-- CONFIG Outputs
			o_image_input_length          => o_image_input_length,
			o_image_output_length         => o_image_output_length,
			o_input_channel_size          => o_input_channel_size,
			o_output_channel_size         => o_output_channel_size,
			o_input_channel_per_iteration => s_input_channel_per_iteration,
			o_kernel_size                 => s_kernel_size,
			o_padding_size                => o_padding_size,
			o_stride_bit_mask             => o_stride_bit_mask,
			o_shamt                       => o_shamt,
			o_pool_or_conv                => s_pool_or_conv,
			o_enable_relu                 => o_enable_relu
		);

end architecture rtl;
