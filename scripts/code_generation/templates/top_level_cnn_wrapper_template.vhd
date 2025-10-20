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
		G_INPUT_DATA_BYTE_WIDTH       : natural                := %%INPUT_DATA_BYTE_WIDTH%%
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
			G_VECTOR_IN_LENGTH               => %%CORE_INPUT_LENGTH%%,
			G_WEIGHT_BIT_WIDTH               => %%CORE_INPUT_LENGTH%%,
			G_VECTOR_OUT_LENGTH              => %%CORE_OUTPUT_LENGTH%%,
			G_LINE_BUFFER_AMOUNT             => %%LINE_BUFFER_AMOUNT%%,
			G_MAX_CORE_AMOUNT                => %%MAX_CORE_AMOUNT%%,
			G_OUTPUT_CHANNEL                 => %%OUTPUT_CHANNEL%%,
			G_MAX_OUTPUT_CHANNEL_AMOUNT      => %%INPUT_DATA_BYTE_WIDTH%%,
			G_INPUT_DATA_BYTE_WIDTH          => G_INPUT_DATA_BYTE_WIDTH,
			G_OUTPUT_BYTE_WIDTH              => %%DWC_OUTPUT_BYTE_WIDTH%%,
			G_INPUT_CHANNEL_PER_ITERATION    => %%ROUTE_INPUT_CHANNEL_PER_ITERATION%%,
			G_MAX_KERNEL_SIZE                => %%MAX_KERNEL_SIZE%%,
			G_KERNEL_SIZE                    => %%KERNEL_SIZE%%,
			G_PADDING_SIZE                   => %%PADDING_SIZE%%,
			G_PIPELINE_STEPS                 => %%CS_PIPELINE_STEPS%%
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
