library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;
use work.libutil.all;

entity top_level_cnn is
	generic (
		---------------------------
		-- Configurable Generics
		---------------------------
		G_VECTOR_IN_LENGTH          : natural := 8;
		G_WEIGHT_BIT_WIDTH          : natural := 8;
		G_VECTOR_OUT_LENGTH         : natural := 24;
		G_LINE_BUFFER_AMOUNT        : natural := 180;
		G_MAX_CORE_AMOUNT           : natural := 300;
		G_OUTPUT_CHANNEL            : natural := 1;
		G_MAX_OUTPUT_CHANNEL_AMOUNT : natural := 16;
		-- AXIS Inputs
		G_INPUT_DATA_BYTE_WIDTH       : natural                := 16;
		G_OUTPUT_BYTE_WIDTH           : integer range 1 to 128 := 15;
		G_INPUT_CHANNEL_PER_ITERATION : natural                := 3;
		-- IMG Generics
		G_MAX_KERNEL_SIZE : natural := 11;
		G_KERNEL_SIZE     : natural := 5;
		G_PADDING_SIZE    : natural := 2;
		-- Configurable Slider
		G_PIPELINE_STEPS : natural := 1;
		---------------------------
		-- Hard-Coded Generics
		---------------------------
		-- Control
		G_CONTROL_DELAY_CYCLES : natural := 2;
		-- IMG Generics
		G_IMG_MAX_LENGTH : natural := 300;
		-- AXIS INPUTS
		G_MAX_AXIS_2_PXS_FIFO_DEPTH : natural := 512;
		-- TEMP LAYER ACC FIFO
		G_MAX_TMP_LAYER_ACCUMULATOR_FIFO : natural := 55 ** 2;
		-- AXIS OUTPUT
		G_NEAR_FULL_THRESHOLD : natural range 3 to 10 := 5;
		G_MAX_PXS_2_AXIS      : natural               := 512 
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		-- AXIS WEIGHT INPUTS
		i_wt_s_axis_tdata  : in std_logic_vector(G_INPUT_DATA_BYTE_WIDTH * 8 - 1 downto 0);
		i_wt_s_axis_tkeep  : in std_logic_vector(G_INPUT_DATA_BYTE_WIDTH - 1 downto 0);
		i_wt_s_axis_tlast  : in std_logic;
		o_wt_s_axis_tready : out std_logic;
		i_wt_s_axis_tvalid : in std_logic;
		-- AXIS PIXEL INPUTS
		i_px_s_axis_tdata  : in std_logic_vector(G_INPUT_DATA_BYTE_WIDTH * 8 - 1 downto 0);
		i_px_s_axis_tkeep  : in std_logic_vector(G_INPUT_DATA_BYTE_WIDTH - 1 downto 0);
		i_px_s_axis_tlast  : in std_logic;
		o_px_s_axis_tready : out std_logic;
		i_px_s_axis_tvalid : in std_logic;
		-- AXIS PIXEL OUTPUTS
		o_px_m_axis_tdata  : out std_logic_vector(G_INPUT_DATA_BYTE_WIDTH * 8 - 1 downto 0);
		o_px_m_axis_tkeep  : out std_logic_vector(G_INPUT_DATA_BYTE_WIDTH - 1 downto 0);
		o_px_m_axis_tlast  : out std_logic;
		i_px_m_axis_tready : in std_logic;
		o_px_m_axis_tvalid : out std_logic;
		-- Control OUTPUT PORTS
		o_image_input_length          : out std_logic_vector(15 downto 0);
		o_image_output_length         : out std_logic_vector(15 downto 0);
		o_input_channel_size          : out std_logic_vector(15 downto 0);
		o_pixel_amount                : out std_logic_vector(15 downto 0);
		o_input_channel_per_iteration : out std_logic_vector(15 downto 0);
		o_kernel_size                 : out std_logic_vector(7 downto 0);
		o_padding_size                : out std_logic_vector(7 downto 0);
		o_stride_bit_mask             : out std_logic_vector(7 downto 0);
		o_shamt                       : out std_logic_vector(7 downto 0);
		o_pool_or_conv                : out std_logic;
		o_enable_relu                 : out std_logic;
		--
		o_current_oc_amount : out std_logic_vector(15 downto 0);
		o_current_ic_amount : out std_logic_vector(15 downto 0);
		o_current_state     : out std_logic_vector(2 downto 0);
		o_overall_done      : out std_logic;
		o_overall_error     : out std_logic
	);
end entity top_level_cnn;

architecture rtl of top_level_cnn is

	-- CONFIG REGISTERS
	signal s_image_input_length          : std_logic_vector(15 downto 0);
	signal s_image_output_length         : std_logic_vector(15 downto 0);
	signal s_input_channel_size          : std_logic_vector(15 downto 0);
	signal s_pixel_amount                : std_logic_vector(15 downto 0);
	signal s_input_channel_per_iteration : std_logic_vector(15 downto 0);
	signal s_kernel_size                 : std_logic_vector(7 downto 0);
	signal s_padding_size                : std_logic_vector(7 downto 0);
	signal s_stride_bit_mask             : std_logic_vector(7 downto 0);
	signal s_shamt                       : std_logic_vector(7 downto 0);
	signal s_pool_or_conv                : std_logic;
	signal s_enable_relu                 : std_logic;

	-- WEIGHT OUTPUT SIGNALS
	signal s_kernel_weight_init   : std_logic;
	signal s_kernel_weight_error  : std_logic;
	signal s_kernel_weight_matrix : matrix_1d(0 to G_LINE_BUFFER_AMOUNT * G_MAX_KERNEL_SIZE - 1)(G_WEIGHT_BIT_WIDTH - 1 downto 0);

	-- RESET SIGNALS
	signal s_rst_axis_2_pxs    : std_logic;
	signal s_rst_config_slider : std_logic;
	signal s_rst_kernel_cores  : std_logic;
	signal s_rst_accumulator   : std_logic;
	signal s_rst_pxs_2_axis    : std_logic;
	signal s_rst_global        : std_logic;

	-- CONFIGURABLE SLIDER OUTPUTS
	signal s_cfg_slider_complete          : std_logic;
	signal s_cfg_slider_en                : std_logic;
	signal s_cfg_slider_activation_matrix : matrix_1d(0 to G_MAX_KERNEL_SIZE * G_LINE_BUFFER_AMOUNT - 1)(G_VECTOR_IN_LENGTH - 1 downto 0);

	-- ROUTED KERNEL CORES OUTPUT
	signal s_kernel_complete : std_logic;
	signal s_kernel_valid    : std_logic;
	signal s_pixel_line      : matrix_1d(0 to G_MAX_OUTPUT_CHANNEL_AMOUNT - 1)(G_VECTOR_OUT_LENGTH - 1 downto 0);

	-- TEMP LAYER ACCUMULATOR OUTPUT
	signal s_current_ic_amount      : std_logic_vector(15 downto 0);
	signal s_actual_kernel_complete : std_logic;
	signal s_actual_kernel_valid    : std_logic;
	signal s_actual_pixel_line      : matrix_1d(0 to G_MAX_OUTPUT_CHANNEL_AMOUNT - 1)(G_VECTOR_IN_LENGTH - 1 downto 0);

	-- Delay lines for control signals

	-- -2 to give accelerator leniency of one cycle for enable
	signal s_en_line           : std_logic_vector(0 to G_NEAR_FULL_THRESHOLD - 2);
	signal s_temp_comp_line    : std_logic_vector(0 to G_CONTROL_DELAY_CYCLES - 1);
	signal s_accel_finish_line : std_logic_vector(0 to G_CONTROL_DELAY_CYCLES - 1);

begin

	DELAY_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' or s_rst_global = '1' then
				s_en_line(s_en_line'low + 1 to s_en_line'high)                               <= (others => '0');
				s_temp_comp_line(s_temp_comp_line'low + 1 to s_temp_comp_line'high)          <= (others => '0');
				s_accel_finish_line(s_accel_finish_line'low + 1 to s_accel_finish_line'high) <= (others => '0');
			else
				s_en_line(s_en_line'low + 1 to s_en_line'high)                               <= s_en_line(s_en_line'low to s_en_line'high - 1);
				s_temp_comp_line(s_temp_comp_line'low + 1 to s_temp_comp_line'high)          <= s_temp_comp_line(s_temp_comp_line'low to s_temp_comp_line'high - 1);
				s_accel_finish_line(s_accel_finish_line'low + 1 to s_accel_finish_line'high) <= s_accel_finish_line(s_accel_finish_line'low to s_accel_finish_line'high - 1);
			end if;
		end if;

	end process DELAY_PROC;

	-- Map Accumulator kernel_comp to temp_comp_line start
	s_temp_comp_line(s_temp_comp_line'low) <= s_actual_kernel_complete;

	-- Current IC Amount also needed by accumulator
	o_current_ic_amount <= s_current_ic_amount;

	control_unit_inst : entity work.control_unit
		generic map (
			G_WEIGHT_BIT_WIDTH   => G_WEIGHT_BIT_WIDTH,
			G_LINE_BUFFER_AMOUNT => G_LINE_BUFFER_AMOUNT,
			G_MAX_KERNEL_SIZE    => G_MAX_KERNEL_SIZE
		)
		port map (
			clk   => clk,
			reset => reset,
			-- AXIS WEIGHT INPUT
			i_wt_s_axis_tdata  => i_wt_s_axis_tdata,
			i_wt_s_axis_tkeep  => i_wt_s_axis_tkeep,
			i_wt_s_axis_tlast  => i_wt_s_axis_tlast,
			o_wt_s_axis_tready => o_wt_s_axis_tready,
			i_wt_s_axis_tvalid => i_wt_s_axis_tvalid,
			-- CONFIG REGISTERS
			o_image_input_length          => s_image_input_length,
			o_image_output_length         => s_image_output_length,
			o_output_channel_size         => open,
			o_input_channel_size          => s_input_channel_size,
			o_pixel_amount                => s_pixel_amount,
			o_input_channel_per_iteration => s_input_channel_per_iteration,
			o_kernel_size                 => s_kernel_size,
			o_padding_size                => s_padding_size,
			o_stride_bit_mask             => s_stride_bit_mask,
			o_shamt                       => s_shamt,
			o_pool_or_conv                => s_pool_or_conv,
			o_enable_relu                 => s_enable_relu,
			-- WEIGHT OUTPUTS
			o_kernel_weight_init   => s_kernel_weight_init,
			o_kernel_weight_error  => s_kernel_weight_error,
			o_kernel_weight_matrix => s_kernel_weight_matrix,
			-- RESET SIGNALS
			o_rst_axis_2_pxs    => s_rst_axis_2_pxs,
			o_rst_config_slider => s_rst_config_slider,
			o_rst_kernel_cores  => s_rst_kernel_cores,
			o_rst_accumulator   => s_rst_accumulator,
			o_rst_pxs_2_axis    => s_rst_pxs_2_axis,
			o_rst_global        => s_rst_global,
			-- CONTROL INPUT SIGNALS
			i_temp_comp_complete => s_temp_comp_line(s_temp_comp_line'high),
			i_accel_finish       => s_accel_finish_line(s_accel_finish_line'high),
			-- DEBUG OUTPUT PORTS
			o_current_oc_amount => o_current_oc_amount,
			o_current_ic_amount => s_current_ic_amount,
			o_current_state     => o_current_state,
			o_overall_done      => o_overall_done,
			o_overall_error     => o_overall_error
		);

	axis_2_configurable_slider_wrapper_inst : entity work.axis_2_configurable_slider_wrapper
		generic map (
			G_VECTOR_BYTE_LENGTH          => G_VECTOR_IN_LENGTH / 8,
			G_IMG_MAX_LENGTH              => G_IMG_MAX_LENGTH,
			G_KERNEL_SIZE                 => G_KERNEL_SIZE,
			G_PADDING_SIZE                => G_PADDING_SIZE,
			G_INPUT_BYTE_WIDTH            => G_INPUT_DATA_BYTE_WIDTH,
			G_OUTPUT_BYTE_WIDTH           => G_OUTPUT_BYTE_WIDTH,
			G_INPUT_CHANNEL_PER_ITERATION => G_INPUT_CHANNEL_PER_ITERATION,
			G_MAX_FIFO_DEPTH              => G_MAX_AXIS_2_PXS_FIFO_DEPTH,
			G_NEAR_FULL_THRESHOLD         => 0,
			G_MAX_KERNEL_SIZE             => G_MAX_KERNEL_SIZE,
			G_LINE_BUFFER_AMOUNT          => G_LINE_BUFFER_AMOUNT,
			G_PIPELINE_STEPS              => G_PIPELINE_STEPS
		)
		port map (
			clk   => clk,
			reset => reset or s_rst_global,
			-- RESET SIGNALS
			i_rst_axis_2_pxs          => s_rst_axis_2_pxs,
			i_rst_configurable_slider => s_rst_config_slider,
			--
			i_en => s_en_line(s_en_line'high),
			-- AXIS PIXEL INPUT
			i_s_axis_tdata  => i_px_s_axis_tdata,
			i_s_axis_tkeep  => i_px_s_axis_tkeep,
			i_s_axis_tlast  => i_px_s_axis_tlast,
			o_s_axis_tready => o_px_s_axis_tready,
			i_s_axis_tvalid => i_px_s_axis_tvalid,
			-- CONFIG REGISTERS
			i_image_input_length  => s_image_input_length,
			i_image_output_length => s_image_output_length,
			i_pool_or_conv        => s_pool_or_conv,
			i_kernel_size         => s_kernel_size,
			i_padding_size        => s_padding_size,
			i_stride_bit_mask     => s_stride_bit_mask,
			-- Weight Control Logic
			i_wt_init => s_kernel_weight_init and not s_kernel_weight_error,
			-- Kernel outputs
			o_kernel_complete          => s_cfg_slider_complete,
			o_kernel_en                => s_cfg_slider_en,
			o_kernel_activation_matrix => s_cfg_slider_activation_matrix
		);

	routed_kernel_cores_inst : entity work.routed_kernel_cores
		generic map (
			G_VECTOR_IN_LENGTH          => G_VECTOR_IN_LENGTH,
			G_VECTOR_OUT_LENGTH         => G_VECTOR_OUT_LENGTH,
			G_MAX_KERNEL_SIZE           => G_MAX_KERNEL_SIZE,
			G_LINE_BUFFER_AMOUNT        => G_LINE_BUFFER_AMOUNT,
			G_MAX_CORE_AMOUNT           => G_MAX_CORE_AMOUNT,
			G_MAX_OUTPUT_CHANNEL_AMOUNT => G_MAX_OUTPUT_CHANNEL_AMOUNT
		)
		port map (
			clk   => clk,
			reset => reset or s_rst_kernel_cores or s_rst_global,
			--
			i_en => s_en_line(s_en_line'high),
			-- Configurable Slider Outputs
			i_kernel_complete          => s_cfg_slider_complete,
			i_kernel_en                => s_cfg_slider_en,
			i_kernel_activation_matrix => s_cfg_slider_activation_matrix,
			-- Weight Unit Outputs
			i_kernel_weight_en     => s_kernel_weight_init and not s_kernel_weight_error,
			i_kernel_weight_matrix => s_kernel_weight_matrix,
			i_shamt_line           => (others => (others => '0')),
			i_bias_line            => (others => (others => '0')),
			-- ROUTED KERNEL CORES OUTPUTs
			o_kernel_complete => s_kernel_complete,
			o_kernel_valid    => s_kernel_valid,
			o_pixel_line      => s_pixel_line
		);

	temp_layer_accumulator_inst : entity work.temp_layer_accumulator
		generic map (
			G_VECTOR_LENGTH         => G_VECTOR_OUT_LENGTH,
			g_clipped_vector_length => G_VECTOR_IN_LENGTH,
			g_max_fifo_depth        => G_MAX_TMP_LAYER_ACCUMULATOR_FIFO,
			g_oc_amount             => G_MAX_OUTPUT_CHANNEL_AMOUNT
		)
		port map (
			clk   => clk,
			reset => reset or s_rst_accumulator or s_rst_global,
			--
			i_en => s_en_line(s_en_line'high),
			-- OUTPUT of ROUTING CORES
			i_kernel_complete => s_kernel_complete,
			i_kernel_valid    => s_kernel_valid,
			i_pixel_line      => s_pixel_line,
			-- CONFIG REGISTERS
			i_pixel_amount                => s_pixel_amount,
			i_pool_or_conv                => s_pool_or_conv,
			i_current_ic_amount           => s_current_ic_amount,
			i_input_channel_per_iteration => s_input_channel_per_iteration,
			i_input_channel_size          => s_input_channel_size,
			i_enable_relu                 => s_enable_relu,
			i_shamt                       => s_shamt,
			-- SANITIZED OUTPUTS
			o_kernel_complete => s_actual_kernel_complete,
			o_kernel_valid    => s_actual_kernel_valid,
			o_pixel_line      => s_actual_pixel_line
		);

	pxs_2_axis_inst : entity work.pxs_2_axis
		generic map (
			G_OUTPUT_CHANNELS     => G_OUTPUT_CHANNEL,
			G_DATA_BYTE_WIDTH     => G_INPUT_DATA_BYTE_WIDTH,
			G_BRAM_BYTE_WIDTH     => G_VECTOR_IN_LENGTH / 8,
			G_BRAM_MAX_DEPTH      => G_MAX_PXS_2_AXIS,
			G_NEAR_FULL_THRESHOLD => G_NEAR_FULL_THRESHOLD
		)
		port map (
			clk   => clk,
			reset => reset or s_rst_pxs_2_axis or s_rst_global,
			--
			o_en => s_en_line(s_en_line'low),
			-- TEMP LAYER ACC OUTPUTS
			i_kernel_complete => s_actual_kernel_complete,
			i_kernel_valid    => s_actual_kernel_valid,
			i_pixel_line      => s_actual_pixel_line,
			-- CONTROL LOGIC
			o_accel_finished => s_accel_finish_line(s_accel_finish_line'low),
			-- AXIS PIXEL OUTPUT
			o_px_m_axis_tdata  => o_px_m_axis_tdata,
			o_px_m_axis_tkeep  => o_px_m_axis_tkeep,
			o_px_m_axis_tlast  => o_px_m_axis_tlast,
			i_px_m_axis_tready => i_px_m_axis_tready,
			o_px_m_axis_tvalid => o_px_m_axis_tvalid
		);

	o_image_input_length          <= s_image_input_length;
	o_image_output_length         <= s_image_output_length;
	o_input_channel_size          <= s_input_channel_size;
	o_pixel_amount                <= s_pixel_amount;
	o_input_channel_per_iteration <= s_input_channel_per_iteration;
	o_kernel_size                 <= s_kernel_size;
	o_padding_size                <= s_padding_size;
	o_stride_bit_mask             <= s_stride_bit_mask;
	o_shamt                       <= s_shamt;
	o_pool_or_conv                <= s_pool_or_conv;
	o_enable_relu                 <= s_enable_relu;

end architecture rtl;
