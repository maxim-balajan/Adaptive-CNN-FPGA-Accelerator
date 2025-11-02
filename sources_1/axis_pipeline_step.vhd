library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity axis_pipeline_step is
	generic (
		G_BYTE_WIDTH : integer range 1 to 128 := 16
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		-- AXIS INPUT
		i_s_axis_tdata  : in std_logic_vector(G_BYTE_WIDTH * 8 - 1 downto 0);
		i_s_axis_tkeep  : in std_logic_vector(G_BYTE_WIDTH - 1 downto 0);
		i_s_axis_tlast  : in std_logic;
		o_s_axis_tready : out std_logic;
		i_s_axis_tvalid : in std_logic;
		-- AXIS OUTPUT
		o_m_axis_tdata  : out std_logic_vector(G_BYTE_WIDTH * 8 - 1 downto 0);
		o_m_axis_tkeep  : out std_logic_vector(G_BYTE_WIDTH - 1 downto 0);
		o_m_axis_tlast  : out std_logic;
		i_m_axis_tready : in std_logic;
		o_m_axis_tvalid : out std_logic
	);
end entity axis_pipeline_step;

architecture rtl of axis_pipeline_step is

	-- expansion registers
	signal expansion_data_reg  : std_logic_vector(G_BYTE_WIDTH * 8 - 1 downto 0);
	signal expansion_valid_reg : std_logic;
	signal expansion_tlast_reg : std_logic;
	signal expansion_tkeep_reg : std_logic_vector(G_BYTE_WIDTH - 1 downto 0);

	-- standard registers
	signal primary_data_reg  : std_logic_vector(G_BYTE_WIDTH * 8 - 1 downto 0);
	signal primary_valid_reg : std_logic;
	signal primary_tlast_reg : std_logic;
	signal primary_tkeep_reg : std_logic_vector(G_BYTE_WIDTH - 1 downto 0);

	signal s_s_axis_tready : std_logic;

begin

	process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				primary_data_reg  <= (others => '0');
				primary_valid_reg <= '0';
				primary_tlast_reg <= '0';
				primary_tkeep_reg <= (others => '0');
				--
				expansion_data_reg  <= (others => '0');
				expansion_valid_reg <= '0';
				expansion_tlast_reg <= '0';
				expansion_tkeep_reg <= (others => '0');
			else
				-- accept data if ready is high
				if s_s_axis_tready = '1' then
					primary_valid_reg <= i_s_axis_tvalid;
					primary_data_reg  <= i_s_axis_tdata;
					primary_tkeep_reg <= i_s_axis_tkeep;
					primary_tlast_reg <= i_s_axis_tlast;
					-- when ds is not ready, accept data into expansion reg until it is valid
					if i_m_axis_tready = '0' then
						expansion_valid_reg <= primary_valid_reg;
						expansion_data_reg  <= primary_data_reg;
						expansion_tlast_reg <= primary_tlast_reg;
						expansion_tkeep_reg <= primary_tkeep_reg;
					end if;
				end if;

				-- when ds becomes ready the expansion reg data is accepted and we must clear the valid register
				if i_m_axis_tready = '1' then
					expansion_valid_reg <= '0';
				end if;
			end if;
		end if;

	end process;

	-- ready as long as there is nothing in the expansion register
	s_s_axis_tready <= not expansion_valid_reg and not reset;
	o_s_axis_tready <= s_s_axis_tready;

	-- selecting the expansion register if it has valid data
	o_m_axis_tvalid <= expansion_valid_reg or primary_valid_reg;
	o_m_axis_tlast  <= expansion_tlast_reg when expansion_valid_reg else primary_tlast_reg;
	o_m_axis_tdata  <= expansion_data_reg when expansion_valid_reg else primary_data_reg;
	o_m_axis_tkeep  <= expansion_tkeep_reg when expansion_valid_reg else primary_tkeep_reg;

end architecture rtl;
