library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;
use work.libutil.f_sum_bits_slv;


entity weight_unit is
	generic (
		g_weight_bit_width : integer range 2 to 128 := 8;
		g_weight_amount    : natural                := 128
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		-- WEIGHT AXIS Interface
		i_wt_s_axis_tdata  : in std_logic_vector(127 downto 0);
		i_wt_s_axis_tkeep  : in std_logic_vector(15 downto 0);
		i_wt_s_axis_tlast  : in std_logic;
		o_wt_s_axis_tready : out std_logic;
		i_wt_s_axis_tvalid : in std_logic;
		-- CONFIG MODULE OUTPUTS
		i_input_channel_per_iteration : in std_logic_vector(15 downto 0);
		i_kernel_size                 : in std_logic_vector(7 downto 0);
		-- WEIGHT MODULE OUTPUTS
		o_kernel_weight_init   : out std_logic;
		o_kernel_weight_error  : out std_logic;
		o_kernel_weight_matrix : out matrix_1d(0 to g_weight_amount - 1)(g_weight_bit_width - 1 downto 0)
	);
end entity weight_unit;


architecture rtl of weight_unit is

	signal s_sa_wt_tdata      : matrix_1d(0 to 128 / g_weight_bit_width - 1)(g_weight_bit_width - 1 downto 0);
	signal s_weight_mem       : matrix_1d(0 to g_weight_amount - 1)(g_weight_bit_width - 1 downto 0);
	signal s_wt_s_axis_tready : std_logic;
	signal s_weight_init      : std_logic;
	signal s_weight_error     : std_logic;

	signal s_weight_amount      : unsigned(31 downto 0);
	signal s_init_weight_amount : unsigned(31 downto 0);

begin

	----------------------------------------
	-- TDATA Mapping
	----------------------------------------

	TDATA_MAP_GEN : for i in s_sa_wt_tdata'range generate
		s_sa_wt_tdata(i) <= i_wt_s_axis_tdata((i + 1) * g_weight_bit_width - 1 downto i * g_weight_bit_width)
	                                               when i_wt_s_axis_tkeep(i) = '1' else
	                                               (others => '0');
	end generate TDATA_MAP_GEN;

	WEIGHT_PROC : process (clk) is

		variable v_weight_amount : unsigned(31 downto 0);

	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_weight_mem       <= (others => (others => '0'));
				s_wt_s_axis_tready <= '0';
				s_weight_init      <= '0';

				-- Amount of weights needed to be stored by the unit
				v_weight_amount := UNSIGNED(i_input_channel_per_iteration) * UNSIGNED(i_kernel_size) * UNSIGNED(i_kernel_size);
				s_weight_amount <= v_weight_amount;

				if v_weight_amount <= g_weight_amount then
					s_weight_error <= '0';
				else
					s_weight_error <= '1';
				end if;
				s_init_weight_amount <= (others => '0');
			else
				----------------------------------------
				-- Weight Retrieval
				----------------------------------------
				if s_weight_init = '0' and s_weight_error = '0' then
					s_wt_s_axis_tready <= '1';

					if s_wt_s_axis_tready = '1' and i_wt_s_axis_tvalid = '1' then
						-- Retrieve Memory with indexer
						for i in 0 to 128 / g_weight_bit_width - 1 loop
							s_weight_mem(to_integer(s_init_weight_amount + i)) <= s_sa_wt_tdata(i);
						end loop;
						--s_weight_mem <=  s_sa_wt_tdata & s_weight_mem(0 to s_weight_mem'high - s_sa_wt_tdata'length);
						-- Increment amount of weights received, take tkeep into account!
						-- TODO: change to add 0xFFFF always because the unit will break if tkeep is not 0xFFFF during tlast=1
						v_weight_amount := s_init_weight_amount + 16;
						-- Weights are filled completely
						if v_weight_amount >= s_weight_amount then
							-- set completion flag depending if transaction was valid or not
							if i_wt_s_axis_tlast = '1' then
								s_weight_init <= '1';
							else
								s_weight_error <= '1';
							end if;
							-- All weights received (or error) 
                            -- -> Module is finished and shouldn't assert ready anymore
							s_wt_s_axis_tready <= '0';
						end if;
						s_init_weight_amount <= v_weight_amount;
					end if;
				else
					s_wt_s_axis_tready <= '0';
				end if;
			end if;
		end if;

	end process WEIGHT_PROC;

	----------------------------------------
	-- Set Outputs
	----------------------------------------

	-- Output Control Logic
	o_wt_s_axis_tready    <= s_wt_s_axis_tready;
	o_kernel_weight_init  <= s_weight_init;
	o_kernel_weight_error <= s_weight_error;

	-- Output actual memory
	o_kernel_weight_matrix <= s_weight_mem;

end architecture rtl;
