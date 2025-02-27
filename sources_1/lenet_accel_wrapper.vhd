library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity lenet_accel_wrapper is
	port (
		clk   : in std_logic;
		reset : in std_logic;

		s_axis_tdata  : in std_logic_vector(7 downto 0);
		s_axis_tkeep  : in std_logic_vector(0 downto 0);
		s_axis_tlast  : in std_logic;
		s_axis_tready : out std_logic;
		s_axis_tvalid : in std_logic;

		m_axis_tdata  : out std_logic_vector(7 downto 0);
		m_axis_tkeep  : out std_logic_vector(0 downto 0);
		m_axis_tlast  : out std_logic;
		m_axis_tready : in std_logic;
		m_axis_tvalid : out std_logic
	);
end entity lenet_accel_wrapper;

architecture Behavioral of lenet_accel_wrapper is

	signal s_valid_pixel   : std_logic;
	signal s_image_label   : std_logic_vector(integer(ceil(log2(real(10)))) - 1 downto 0);
	signal s_comp_complete : std_logic;
	signal s_accel_reset   : std_logic;
	signal s_accel_reset_manual   : std_logic;

	signal s_s_axis_tready : std_logic;
	signal s_m_axis_tvalid : std_logic;

	signal s_data_cnt : unsigned(integer(ceil(log2(real(32*32 + 1)))) - 1 downto 0);
begin

	-- we only signal the accelerator to start when we accept data and there is a valid pixel
	s_valid_pixel <= s_s_axis_tready and s_axis_tvalid;
	s_axis_tready <= s_s_axis_tready;
	m_axis_tvalid <= s_m_axis_tvalid;

	lenet_accel_inst : entity work.lenet_accel
		port map (
			clk           => clk,
			reset         => s_accel_reset,
			pixel_stream  => s_axis_tdata,
			valid_pixel   => s_valid_pixel,
			image_label   => s_image_label,
			comp_complete => s_comp_complete
		);
    s_accel_reset <= reset or s_accel_reset_manual;

	process (clk, reset) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				m_axis_tkeep    <= "1";
				m_axis_tlast    <= '0';
				s_m_axis_tvalid <= '0';

				s_s_axis_tready <= '0';

				s_data_cnt <= (others => '0');
				s_accel_reset_manual <= '0';
				
				m_axis_tdata <= (others => '0');
			else
				-- we are ready to receive data if this module is currently not active
				if s_data_cnt < 32*32 - 1 then
    				s_s_axis_tready <= '1';
                else
                	s_s_axis_tready <= '0';
				end if;

				if s_s_axis_tready = '1' and s_axis_tvalid = '1' then
					s_data_cnt <= s_data_cnt + 1;
				end if;

				if s_comp_complete = '1' and s_accel_reset_manual = '0' then
					-- computation is complete, start sending result
					m_axis_tlast    <= '1';
					s_m_axis_tvalid <= '1';
					m_axis_tdata(integer(ceil(log2(real(10)))) - 1 downto 0) <= s_image_label;

					s_accel_reset_manual <= '1';
				else
					s_accel_reset_manual <= '0';
				end if;

				if s_m_axis_tvalid = '1' and m_axis_tready = '1' then
					-- sending of result is finished
					s_m_axis_tvalid <= '0';
					m_axis_tlast    <= '0';
					s_data_cnt <= (others => '0');
				end if;
			end if;
		end if;

	end process;

end architecture Behavioral;
