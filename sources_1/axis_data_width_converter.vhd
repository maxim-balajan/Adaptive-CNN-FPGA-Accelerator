library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity axis_data_width_converter is
	generic (
		G_INPUT_BYTE_WIDTH  : INTEGER range 1 to 128 := 16;
		G_OUTPUT_BYTE_WIDTH : INTEGER range 1 to 128 := 15
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		-- AXIS INPUT
		i_s_axis_tdata  : in std_logic_vector(G_INPUT_BYTE_WIDTH * 8 - 1 downto 0);
		i_s_axis_tkeep  : in std_logic_vector(G_INPUT_BYTE_WIDTH - 1 downto 0);
		i_s_axis_tlast  : in std_logic;
		o_s_axis_tready : out std_logic;
		i_s_axis_tvalid : in std_logic;
		-- AXIS OUTPUT
		o_m_axis_tdata  : out std_logic_vector(G_OUTPUT_BYTE_WIDTH * 8 - 1 downto 0);
		o_m_axis_tkeep  : out std_logic_vector(G_OUTPUT_BYTE_WIDTH - 1 downto 0);
		o_m_axis_tlast  : out std_logic;
		i_m_axis_tready : in std_logic;
		o_m_axis_tvalid : out std_logic
	);
end entity axis_data_width_converter;

architecture rtl of axis_data_width_converter is

	-- Method for multiplexing incoming data into the buffer

	function f_mux_incoming_data (
		s_axis_tdata    : std_logic_vector;
		internal_memory : std_logic_vector;
		byte_size       : integer
	) return std_logic_vector is
	begin

		return (internal_memory'length - 1 downto (G_INPUT_BYTE_WIDTH + byte_size) * 8 => 'U')
                & s_axis_tdata(G_INPUT_BYTE_WIDTH * 8 - 1 downto 0)
                & internal_memory(byte_size * 8 - 1 downto 0);

	end function f_mux_incoming_data;

begin

	PASSTHROUGH_GEN : if G_INPUT_BYTE_WIDTH = G_OUTPUT_BYTE_WIDTH generate
	begin

		-- Passthrough pipelined for helping when reconfiguring unit

		process (clk) is
		begin

			if rising_edge(clk) then
				if reset = '1' then
					o_s_axis_tready <= '0';
					--
					o_m_axis_tdata  <= (others => '0');
					o_m_axis_tkeep  <= (others => '0');
					o_m_axis_tlast  <= '0';
					o_m_axis_tvalid <= '0';
				else
					o_s_axis_tready <= i_m_axis_tready;
					--
					o_m_axis_tdata  <= i_s_axis_tdata;
					o_m_axis_tkeep  <= i_s_axis_tkeep;
					o_m_axis_tlast  <= i_s_axis_tlast;
					o_m_axis_tvalid <= i_s_axis_tvalid;
				end if;
			end if;

		end process;

	end generate PASSTHROUGH_GEN;

	DOWNSIZE_GEN : if G_INPUT_BYTE_WIDTH > G_OUTPUT_BYTE_WIDTH generate
		signal s_internal_memory : std_logic_vector(G_INPUT_BYTE_WIDTH * 8 + G_OUTPUT_BYTE_WIDTH * 8 - 1 downto 0);

		signal s_s_axis_tready : std_logic;

		signal s_m_axis_tdata  : std_logic_vector(o_m_axis_tdata'range);
		signal s_m_axis_tkeep  : std_logic_vector(o_m_axis_tkeep'range);
		signal s_m_axis_tlast  : std_logic;
		signal s_m_axis_tvalid : std_logic;

		signal s_element_count : unsigned(integer(log2(ceil(real(s_internal_memory'length)))) - 1 downto 0);

	begin

		SHIFT_MUX_PROC : process (clk) is

			variable v_tmp_internal_memory : std_logic_vector(s_internal_memory'range);
			variable v_tmp_element_count   : natural range 0 to s_internal_memory'length - 1;

		begin

			if rising_edge(clk) then
				if reset = '1' then
					s_internal_memory <= (others => '0');
					s_s_axis_tready   <= '0';
					-- Note: tlast is always at '0' because its not necessary for the top level currently
					s_m_axis_tlast <= '0';

					s_m_axis_tdata  <= (others => '0');
					s_m_axis_tkeep  <= (others => '0');
					s_m_axis_tvalid <= '0';

					s_element_count <= (others => '0');
				else
					v_tmp_element_count := to_integer(s_element_count);
					-- Mux incoming data into temporary buffer
					v_tmp_internal_memory := s_internal_memory;

					if i_m_axis_tready = '1' and (v_tmp_element_count >= G_OUTPUT_BYTE_WIDTH) then
						s_m_axis_tvalid <= '0';
						s_m_axis_tlast  <= '0';
					end if;

					-- Read data from slave
					if (i_s_axis_tvalid and s_s_axis_tready) = '1' then
						s_s_axis_tready <= '0';

						-- Mux incoming data into temporary buffer
						v_tmp_internal_memory := f_mux_incoming_data(i_s_axis_tdata, v_tmp_internal_memory, v_tmp_element_count);
						v_tmp_element_count   := v_tmp_element_count + G_INPUT_BYTE_WIDTH;
					end if;

					-- Write data to master
					if (s_m_axis_tvalid and i_m_axis_tready) = '1' then
						-- Consume data
						v_tmp_internal_memory := (G_OUTPUT_BYTE_WIDTH * 8 - 1 downto 0 => 'U') & v_tmp_internal_memory(v_tmp_internal_memory'length - 1 downto G_OUTPUT_BYTE_WIDTH * 8);
						s_m_axis_tkeep        <= (others => '0');
						v_tmp_element_count   := v_tmp_element_count - G_OUTPUT_BYTE_WIDTH;
					end if;

					if v_tmp_element_count >= G_OUTPUT_BYTE_WIDTH then
						s_m_axis_tvalid <= '1';
						s_m_axis_tdata <= v_tmp_internal_memory(G_OUTPUT_BYTE_WIDTH * 8 - 1 downto 0);
						s_m_axis_tkeep  <= (others => '1');
					end if;

					if (v_tmp_internal_memory'length) / 8 - v_tmp_element_count >= G_INPUT_BYTE_WIDTH then 
						s_s_axis_tready <= '1';
					end if;

					-- Write back internal variables
					s_element_count   <= to_unsigned(v_tmp_element_count, s_element_count'length);
					s_internal_memory <= v_tmp_internal_memory;
				end if;
			end if;

		end process SHIFT_MUX_PROC;

		-------------------------------------------
		-- Set Outputs
		-------------------------------------------
		-- Set Slave tready
		o_s_axis_tready <= s_s_axis_tready;

		-- Set Master AXIS Interface
		o_m_axis_tdata  <= s_m_axis_tdata;
		o_m_axis_tkeep  <= s_m_axis_tkeep;
		o_m_axis_tvalid <= s_m_axis_tvalid;
		o_m_axis_tlast  <= s_m_axis_tlast;
	end generate DOWNSIZE_GEN;

	UPSIZE_GEN : if G_INPUT_BYTE_WIDTH < G_OUTPUT_BYTE_WIDTH generate
		assert FALSE
			report "Upsizing of AXIS Interfaces currently not supported!"
			severity FAILURE;
	end generate UPSIZE_GEN;

end architecture rtl;
