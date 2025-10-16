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
		G_VECTOR_IN_LENGTH          : natural := %%CORE_INPUT_LENGTH%%;
		G_VECTOR_OUT_LENGTH         : natural := %%CORE_OUTPUT_LENGTH%%;
		G_LINE_BUFFER_AMOUNT        : natural := %%LINE_BUFFER_AMOUNT%%;
		G_MAX_CORE_AMOUNT           : natural := %%MAX_CORE_AMOUNT%%;
		G_OUTPUT_CHANNEL            : natural := %%XXX_TBD_XXX%%;
		G_MAX_OUTPUT_CHANNEL_AMOUNT : natural := %%MAX_OUTPUT_CHANNELS%%
		-- AXIS Inputs
		G_INPUT_DATA_BYTE_WIDTH       : natural                := %%XXX_TBD_XXX%%;
		G_OUTPUT_BYTE_WIDTH           : integer range 1 to 128 := %%XXX_TBD_XXX%%;
		G_INPUT_CHANNEL_PER_ITERATION : natural                := %%XXX_TBD_XXX%%;
		-- IMG Generics
		G_MAX_KERNEL_SIZE : natural := %%XXX_TBD_XXX%%;
		G_KERNEL_SIZE     : natural := %%XXX_TBD_XXX%%;
		G_PADDING_SIZE    : natural := %%XXX_TBD_XXX%%;
		-- Configurable Slider
		G_PIPELINE_STEPS : natural := %%XXX_TBD_XXX%%;
		---------------------------
		-- Hard-Coded Generics
		---------------------------
		-- Control
		G_CONTROL_DELAY_CYCLES : natural := 2;
		-- Weight Generics
		G_WEIGHT_BIT_WIDTH : natural := 8;
		G_WEIGHT_AMOUNT    : natural := 512;
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
		o_current_ic_amount : out std_logic_vector(15 downto 0);
		o_current_state     : out std_logic_vector(2 downto 0);
		o_overall_done      : out std_logic;
		o_overall_error     : out std_logic
	);
end entity top_level_cnn_wrapper;

architecture rtl of top_level_cnn_wrapper is

begin

	top_level_cnn_inst : entity %%CORE_COMPILE_LIB%%.top_level_cnn
		generic map (
			G_VECTOR_IN_LENGTH               => G_VECTOR_IN_LENGTH,
			G_VECTOR_OUT_LENGTH              => G_VECTOR_OUT_LENGTH,
			G_LINE_BUFFER_AMOUNT             => G_LINE_BUFFER_AMOUNT,
			G_MAX_CORE_AMOUNT                => G_MAX_CORE_AMOUNT,
			G_OUTPUT_CHANNEL                 => G_OUTPUT_CHANNEL,
			G_MAX_OUTPUT_CHANNEL_AMOUNT      => G_MAX_OUTPUT_CHANNEL_AMOUNT,
			G_INPUT_DATA_BYTE_WIDTH          => G_INPUT_DATA_BYTE_WIDTH,
			G_OUTPUT_BYTE_WIDTH              => G_OUTPUT_BYTE_WIDTH,
			G_INPUT_CHANNEL_PER_ITERATION    => G_INPUT_CHANNEL_PER_ITERATION,
			G_MAX_KERNEL_SIZE                => G_MAX_KERNEL_SIZE,
			G_KERNEL_SIZE                    => G_KERNEL_SIZE,
			G_PADDING_SIZE                   => G_PADDING_SIZE,
			G_PIPELINE_STEPS                 => G_PIPELINE_STEPS,
			G_CONTROL_DELAY_CYCLES           => G_CONTROL_DELAY_CYCLES,
			G_WEIGHT_BIT_WIDTH               => G_WEIGHT_BIT_WIDTH,
			G_WEIGHT_AMOUNT                  => G_WEIGHT_AMOUNT,
			G_IMG_MAX_LENGTH                 => G_IMG_MAX_LENGTH,
			G_MAX_AXIS_2_PXS_FIFO_DEPTH      => G_MAX_AXIS_2_PXS_FIFO_DEPTH,
			G_MAX_TMP_LAYER_ACCUMULATOR_FIFO => G_MAX_TMP_LAYER_ACCUMULATOR_FIFO,
			G_NEAR_FULL_THRESHOLD            => G_NEAR_FULL_THRESHOLD,
			G_MAX_PXS_2_AXIS                 => G_MAX_PXS_2_AXIS
		)
		port map (
			clk                 => clk,
			reset               => reset,
			i_wt_s_axis_tdata   => i_wt_s_axis_tdata,
			i_wt_s_axis_tkeep   => i_wt_s_axis_tkeep,
			i_wt_s_axis_tlast   => i_wt_s_axis_tlast,
			o_wt_s_axis_tready  => o_wt_s_axis_tready,
			i_wt_s_axis_tvalid  => i_wt_s_axis_tvalid,
			i_px_s_axis_tdata   => i_px_s_axis_tdata,
			i_px_s_axis_tkeep   => i_px_s_axis_tkeep,
			i_px_s_axis_tlast   => i_px_s_axis_tlast,
			o_px_s_axis_tready  => o_px_s_axis_tready,
			i_px_s_axis_tvalid  => i_px_s_axis_tvalid,
			o_px_m_axis_tdata   => o_px_m_axis_tdata,
			o_px_m_axis_tkeep   => o_px_m_axis_tkeep,
			o_px_m_axis_tlast   => o_px_m_axis_tlast,
			i_px_m_axis_tready  => i_px_m_axis_tready,
			o_px_m_axis_tvalid  => o_px_m_axis_tvalid,
			o_current_ic_amount => o_current_ic_amount,
			o_current_state     => o_current_state,
			o_overall_done      => o_overall_done,
			o_overall_error     => o_overall_error
		);

end architecture rtl;
