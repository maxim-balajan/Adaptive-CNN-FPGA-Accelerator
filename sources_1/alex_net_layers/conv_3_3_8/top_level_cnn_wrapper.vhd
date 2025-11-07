-- ============================================================================
--  *** AUTO-GENERATED FILE ***
--  This file was generated automatically by adder_tree_gen.py.
--  DO NOT MODIFY THIS FILE MANUALLY.
--  Any changes made to this file may be lost when the file is regenerated.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level_cnn_wrapper is
	generic (
		---------------------------
		-- Configurable Generics
		---------------------------
		-- AXIS Inputs
		G_INPUT_DATA_BYTE_WIDTH : natural := 16
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		-- AXIS WEIGHT INPUTS
		wt_s_axis_tdata  : in std_logic_vector(G_INPUT_DATA_BYTE_WIDTH * 8 - 1 downto 0);
		wt_s_axis_tkeep  : in std_logic_vector(G_INPUT_DATA_BYTE_WIDTH - 1 downto 0);
		wt_s_axis_tlast  : in std_logic;
		wt_s_axis_tready : out std_logic;
		wt_s_axis_tvalid : in std_logic;
		-- AXIS PIXEL INPUTS
		px_s_axis_tdata  : in std_logic_vector(G_INPUT_DATA_BYTE_WIDTH * 8 - 1 downto 0);
		px_s_axis_tkeep  : in std_logic_vector(G_INPUT_DATA_BYTE_WIDTH - 1 downto 0);
		px_s_axis_tlast  : in std_logic;
		px_s_axis_tready : out std_logic;
		px_s_axis_tvalid : in std_logic;
		-- AXIS PIXEL OUTPUTS
		px_m_axis_tdata  : out std_logic_vector(G_INPUT_DATA_BYTE_WIDTH * 8 - 1 downto 0);
		px_m_axis_tkeep  : out std_logic_vector(G_INPUT_DATA_BYTE_WIDTH - 1 downto 0);
		px_m_axis_tlast  : out std_logic;
		px_m_axis_tready : in std_logic;
		px_m_axis_tvalid : out std_logic;
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
end entity top_level_cnn_wrapper;

architecture rtl of top_level_cnn_wrapper is

begin

	top_level_cnn_inst : entity work.top_level_cnn
		generic map (
			G_VECTOR_IN_LENGTH            => 8,
			G_WEIGHT_BIT_WIDTH            => 8,
			G_VECTOR_OUT_LENGTH           => 24,
			G_LINE_BUFFER_AMOUNT          => 80,
			G_MAX_CORE_AMOUNT             => 100,
			G_OUTPUT_CHANNEL              => 1,
			G_MAX_OUTPUT_CHANNEL_AMOUNT   => 16,
			G_INPUT_DATA_BYTE_WIDTH       => G_INPUT_DATA_BYTE_WIDTH,
			G_OUTPUT_BYTE_WIDTH           => 16,
			G_INPUT_CHANNEL_PER_ITERATION => 8,
			G_MAX_KERNEL_SIZE             => 12,
			G_KERNEL_SIZE                 => 3,
			G_PADDING_SIZE                => 1,
			G_PIPELINE_STEPS              => 1
		)
		port map (
			clk                => clk,
			reset              => reset,
			--
			i_wt_s_axis_tdata  => wt_s_axis_tdata,
			i_wt_s_axis_tkeep  => wt_s_axis_tkeep,
			i_wt_s_axis_tlast  => wt_s_axis_tlast,
			o_wt_s_axis_tready => wt_s_axis_tready,
			i_wt_s_axis_tvalid => wt_s_axis_tvalid,
			i_px_s_axis_tdata  => px_s_axis_tdata,
			i_px_s_axis_tkeep  => px_s_axis_tkeep,
			i_px_s_axis_tlast  => px_s_axis_tlast,
			o_px_s_axis_tready => px_s_axis_tready,
			i_px_s_axis_tvalid => px_s_axis_tvalid,
			o_px_m_axis_tdata  => px_m_axis_tdata,
			o_px_m_axis_tkeep  => px_m_axis_tkeep,
			o_px_m_axis_tlast  => px_m_axis_tlast,
			i_px_m_axis_tready => px_m_axis_tready,
			o_px_m_axis_tvalid => px_m_axis_tvalid,
			--
			o_image_input_length          => o_image_input_length,
			o_image_output_length         => o_image_output_length,
			o_input_channel_size          => o_input_channel_size,
			o_pixel_amount                => o_pixel_amount,
			o_input_channel_per_iteration => o_input_channel_per_iteration,
			o_kernel_size                 => o_kernel_size,
			o_padding_size                => o_padding_size,
			o_stride_bit_mask             => o_stride_bit_mask,
			o_shamt                       => o_shamt,
			o_pool_or_conv                => o_pool_or_conv,
			o_enable_relu                 => o_enable_relu,
			--
			o_current_oc_amount => o_current_oc_amount,
			o_current_ic_amount => o_current_ic_amount,
			o_current_state     => o_current_state,
			o_overall_done      => o_overall_done,
			o_overall_error     => o_overall_error
		);

end architecture rtl;
