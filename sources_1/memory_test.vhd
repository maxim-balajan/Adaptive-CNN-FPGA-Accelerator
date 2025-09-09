library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;


entity memory_test is
	port (
		clk   : in std_logic;
		reset : in std_logic;
		-- Weight Inputs
		i_wt_s_axis_tdata  : in std_logic_vector(1023 downto 0);
		i_wt_s_axis_tkeep  : in STD_LOGIC_VECTOR(127 downto 0);
		i_wt_s_tlast       : in std_logic;
        o_wt_s_axis_tready : out std_logic;
		i_wt_s_axis_tvalid : in std_logic;
		-- Activation Pixel Input
		i_px_m_axis_tdata  : in std_logic_vector(7 downto 0);
		i_px_m_axis_tkeep  : in std_logic_vector(0 downto 0);
		i_px_m_axis_tlast  : in std_logic;
		o_px_m_axis_tready : out std_logic;
		i_px_m_axis_tvalid : in std_logic;
        -- Result Pixel Output
        o_px_m_axis_tdata  : out std_logic_vector(7 downto 0);
		o_px_m_axis_tkeep  : out std_logic_vector(0 downto 0);
		o_px_m_axis_tlast  : out std_logic;
		i_px_m_axis_tready : in std_logic;
		o_px_m_axis_tvalid : out std_logic
	);
end entity memory_test;


architecture rtl of memory_test is

begin

    

end architecture;
