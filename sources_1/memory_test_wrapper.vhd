library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity memory_test_wrapper is
	generic (
		vector_length  : natural := 8;
		channel_amount : natural := 16;
		iterations     : natural := 40
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		-- Control Logic Outputs
		o_wt_rx_iterations : out std_logic_vector(15 downto 0);
		o_wt_tx_iterations : out std_logic_vector(15 downto 0);
		--
		o_px_rx_iterations : out std_logic_vector(15 downto 0);
		o_px_tx_iterations : out std_logic_vector(15 downto 0);
		--
		o_done_weight      : out std_logic;
		o_done_activations : out std_logic;
		-- Weight Inputs
		wt_s_axis_tdata  : in std_logic_vector(vector_length * channel_amount - 1 downto 0);
		wt_s_axis_tkeep  : in std_logic_vector(channel_amount - 1 downto 0);
		wt_s_axis_tlast  : in std_logic;
		wt_s_axis_tready : out std_logic;
		wt_s_axis_tvalid : in std_logic;
		-- Activation Pixel Input
		px_s_axis_tdata  : in std_logic_vector(vector_length * channel_amount - 1 downto 0);
		px_s_axis_tkeep  : in std_logic_vector(channel_amount - 1 downto 0);
		px_s_axis_tlast  : in std_logic;
		px_s_axis_tready : out std_logic;
		px_s_axis_tvalid : in std_logic;
		-- Result Pixel Output
		px_m_axis_tdata  : out std_logic_vector(vector_length * channel_amount - 1 downto 0);
		px_m_axis_tkeep  : out std_logic_vector(channel_amount - 1 downto 0);
		px_m_axis_tlast  : out std_logic;
		px_m_axis_tready : in std_logic;
		px_m_axis_tvalid : out std_logic
	);
end entity memory_test_wrapper;

architecture rtl of memory_test_wrapper is

	-- Macro to mark this instance to be not optimized
	attribute dont_touch : string;
	attribute dont_touch of memory_test_inst : label is "true";

begin

	memory_test_inst : entity work.memory_test
		generic map (
			vector_length  => vector_length,
			channel_amount => channel_amount,
			iterations     => iterations
		)
		port map (
			clk   => clk,
			reset => reset,
			-- Control Logic Outputs
			o_wt_rx_iterations => o_wt_rx_iterations,
			o_wt_tx_iterations => o_wt_tx_iterations,
			--
			o_px_rx_iterations => o_px_rx_iterations,
			o_px_tx_iterations => o_px_tx_iterations,
			--
			o_done_weight      => o_done_weight,
			o_done_activations => o_done_activations,
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
			o_px_m_axis_tvalid => px_m_axis_tvalid
		);

end architecture rtl;
