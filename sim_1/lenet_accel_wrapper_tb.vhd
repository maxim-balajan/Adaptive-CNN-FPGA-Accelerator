
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.libmatrix.all;
use work.libutil.all;
use work.libmemory.all;
use std.env.finish;

entity lenet_accel_wrapper_tb is
end entity lenet_accel_wrapper_tb;

architecture bench of lenet_accel_wrapper_tb is

	-- Clock period
	constant clk_period : time := 5 ns;
	-- Generics
	-- Ports
	signal clk           : std_logic                    := '0';
	signal reset         : std_logic;
	signal s_axis_tdata  : std_logic_vector(7 downto 0) := (others => '0');
	signal s_axis_tkeep  : std_logic_vector(0 downto 0);
	signal s_axis_tlast  : std_logic;
	signal s_axis_tready : std_logic;
	signal s_axis_tvalid : std_logic;
	signal m_axis_tdata  : std_logic_vector(7 downto 0);
	signal m_axis_tkeep  : std_logic_vector(0 downto 0);
	signal m_axis_tlast  : std_logic;
	signal m_axis_tready : std_logic;
	signal m_axis_tvalid : std_logic;

	constant input_path_2 : string := "../data/input_2.data";

	signal   s_input_stream_2 : matrix_1d(0 to 32*32 - 1)(8 - 1 downto 0) := init_from_file(input_path_2, 8, 32*32);
	constant input_path_7     : string                                                                     := "../data/input_7.data";
	signal   s_input_stream_7 : matrix_1d(0 to 32*32 - 1)(8 - 1 downto 0) := init_from_file(input_path_7, 8, 32*32);
	signal   s_read_pointer   : integer range 0 to (32*32);

	signal s_actual_input_stream : matrix_1d(0 to 32*32 - 1)(8 - 1 downto 0);
	signal s_invalid_delay       : integer range 0 to 3;
	signal s_iteration           : integer := 0;

begin

	s_actual_input_stream <= s_input_stream_2 when s_iteration = 0 else s_input_stream_7;

	STREAM_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_axis_tdata    <= (others => '0');
				s_axis_tvalid   <= '0';
				s_invalid_delay <= 0;
				s_read_pointer  <= 0;
			else
				if s_read_pointer < (32*32) then
					if s_invalid_delay = 0 then
						s_axis_tdata   <= s_actual_input_stream(s_read_pointer);
						s_read_pointer <= s_read_pointer + 1;
						s_axis_tvalid  <= '1';
					else
						s_axis_tvalid <= '0';
					end if;

					-- if s_invalid_delay /= 3 then
					-- 	s_invalid_delay <= s_invalid_delay + 1;
					-- else
					-- 	s_invalid_delay <= 0;
					-- end if;
				else
					s_axis_tdata <= (others => '0');
					s_axis_tvalid  <= '0';

					if m_axis_tvalid = '1' and s_iteration = 1 then
						s_read_pointer <= 0;
					end if;
				end if;
			end if;
		end if;

	end process STREAM_PROC;

	lenet_accel_wrapper_inst : entity work.lenet_accel_wrapper
		port map (
			clk           => clk,
			reset         => reset,
			s_axis_tdata  => s_axis_tdata,
			s_axis_tkeep  => s_axis_tkeep,
			s_axis_tlast  => s_axis_tlast,
			s_axis_tready => s_axis_tready,
			s_axis_tvalid => s_axis_tvalid,
			m_axis_tdata  => m_axis_tdata,
			m_axis_tkeep  => m_axis_tkeep,
			m_axis_tlast  => m_axis_tlast,
			m_axis_tready => m_axis_tready,
			m_axis_tvalid => m_axis_tvalid
		);

	clk   <= not clk after clk_period / 2;
	reset <= '1' after 0 ns, '0' after 10 ns;

	s_axis_tkeep  <= "1";
	s_axis_tlast  <= '0' after 0 ns, '1' after 55 ns, '0' after 200 ns;
	m_axis_tready <= '1';

	CHECK_COMP_COMPLETE : process (m_axis_tvalid) is
		begin
	
			if rising_edge(m_axis_tvalid) then
				s_iteration <= s_iteration + 1;
			end if;
	
		end process CHECK_COMP_COMPLETE;
	
		TB : process is
		begin
	
			wait for 20000 * clk_period;
			finish;
	
		end process TB;
end architecture bench;
