library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

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
		o_m_axis_tdata  : out std_logic_vector(G_INPUT_BYTE_WIDTH * 8 - 1 downto 0);
		o_m_axis_tkeep  : out std_logic_vector(G_INPUT_BYTE_WIDTH - 1 downto 0);
		o_m_axis_tlast  : out std_logic;
		i_m_axis_tready : in std_logic;
		o_m_axis_tvalid : out std_logic
	);
end entity axis_data_width_converter;

architecture rtl of axis_data_width_converter is

begin

	PASSTHROUGH_GEN : if G_INPUT_BYTE_WIDTH = G_OUTPUT_BYTE_WIDTH generate
	begin

		-- Passthrough pipelined for helping when reconfiguring unit

		axis_pipeline_step_inst : entity work.axis_pipeline_step
			generic map (
				G_BYTE_WIDTH => G_INPUT_BYTE_WIDTH
			)
			port map (
				clk   => clk,
				reset => reset,
				-- AXIS INPUT
				i_s_axis_tdata  => i_s_axis_tdata,
				i_s_axis_tkeep  => i_s_axis_tkeep,
				i_s_axis_tlast  => i_s_axis_tlast,
				o_s_axis_tready => o_s_axis_tready,
				i_s_axis_tvalid => i_s_axis_tvalid,
				-- AXIS OUTPUT
				o_m_axis_tdata  => o_m_axis_tdata,
				o_m_axis_tkeep  => o_m_axis_tkeep,
				o_m_axis_tlast  => o_m_axis_tlast,
				i_m_axis_tready => i_m_axis_tready,
				o_m_axis_tvalid => o_m_axis_tvalid
			);

	end generate PASSTHROUGH_GEN;

	DOWNSIZE_GEN : if G_INPUT_BYTE_WIDTH > G_OUTPUT_BYTE_WIDTH generate

		signal s_s_axis_tready : std_logic;

		signal s_m_axis_tdata  : std_logic_vector(G_OUTPUT_BYTE_WIDTH * 8 - 1 downto 0);
		signal s_m_axis_tkeep  : std_logic_vector(G_OUTPUT_BYTE_WIDTH - 1 downto 0);
		signal s_m_axis_tlast  : std_logic;
		signal s_m_axis_tvalid : std_logic;

		signal s_flush_memory : std_logic;

		signal s_internal_memory : std_logic_vector(G_INPUT_BYTE_WIDTH * 8 + G_OUTPUT_BYTE_WIDTH * 8 - 1 downto 0);

		signal s_barrel_shifted_internal_memory : matrix_1d(0 to G_OUTPUT_BYTE_WIDTH)(s_internal_memory'range);

		signal s_element_count : unsigned(integer(log2(ceil(real(s_internal_memory'length)))) - 1 downto 0);

	begin

		-- Function does not work for synthesis so generate all possible shifts via generate statement and multiplex

		BARREL_SHIFT_GEN : for byte_size in 0 to G_OUTPUT_BYTE_WIDTH generate
			s_barrel_shifted_internal_memory(byte_size) <=
			(
			  s_internal_memory'length - 1 downto (G_INPUT_BYTE_WIDTH + byte_size) * 8 => 'U'
			)
			  & i_s_axis_tdata(G_INPUT_BYTE_WIDTH * 8 - 1 downto 0)
			  & s_internal_memory(byte_size * 8 - 1 downto 0
			                     );

		end generate BARREL_SHIFT_GEN;

		SHIFT_MUX_PROC : process (clk) is

			variable v_tmp_internal_memory : std_logic_vector(s_internal_memory'range);
			variable v_tmp_element_count   : natural range 0 to s_internal_memory'length - 1;
			variable v_tmp_flush_memory    : std_logic := '0';

		begin

			if rising_edge(clk) then
				if reset = '1' then
					s_internal_memory <= (others => '0');
					s_s_axis_tready   <= '0';
					s_m_axis_tlast    <= '0';

					s_m_axis_tdata  <= (others => '0');
					s_m_axis_tkeep  <= (others => '0');
					s_m_axis_tvalid <= '0';

					s_element_count <= (others => '0');
					s_flush_memory  <= '0';
				else
					v_tmp_element_count := to_integer(s_element_count);
					-- Mux incoming data into temporary buffer
					v_tmp_internal_memory := s_internal_memory;
					v_tmp_flush_memory    := s_flush_memory;
					-- Reset tlast signal to if flush is enabled
					s_m_axis_tlast <= v_tmp_flush_memory;

					if i_m_axis_tready = '1' and (v_tmp_element_count >= G_OUTPUT_BYTE_WIDTH) then
						if s_m_axis_tlast = '1' then
							v_tmp_flush_memory := '0';
						end if;
						s_m_axis_tvalid <= '0';
						s_m_axis_tlast  <= '0';
					end if;

					-- Read data from slave
					if (i_s_axis_tvalid and s_s_axis_tready) = '1' then
						s_s_axis_tready <= '0';

						-- Mux incoming data into temporary buffer
						v_tmp_internal_memory := s_barrel_shifted_internal_memory(v_tmp_element_count);
						v_tmp_element_count   := v_tmp_element_count + G_INPUT_BYTE_WIDTH;

						if i_s_axis_tlast = '1' then
							v_tmp_flush_memory := '1';
						end if;
					end if;

					-- Write data to master
					if (s_m_axis_tvalid and i_m_axis_tready) = '1' then
						-- Consume data
						v_tmp_internal_memory := (G_OUTPUT_BYTE_WIDTH * 8 - 1 downto 0 => 'U') & v_tmp_internal_memory(v_tmp_internal_memory'length - 1 downto G_OUTPUT_BYTE_WIDTH * 8);
						s_m_axis_tkeep        <= (others => '0');

						-- Clear up for the next frame
						if o_m_axis_tlast = '1' then
							v_tmp_element_count := 0;
							v_tmp_flush_memory  := '0';
						else
							v_tmp_element_count := v_tmp_element_count - G_OUTPUT_BYTE_WIDTH;
						end if;
					end if;

					if v_tmp_element_count >= G_OUTPUT_BYTE_WIDTH or v_tmp_flush_memory = '1' then
						s_m_axis_tvalid <= '1';
						s_m_axis_tdata  <= v_tmp_internal_memory(G_OUTPUT_BYTE_WIDTH * 8 - 1 downto 0);
						-- Dont handle tkeep, because it is not needed by the design
						s_m_axis_tkeep <= (others => '1');

						if v_tmp_element_count <= G_OUTPUT_BYTE_WIDTH and v_tmp_flush_memory = '1' then
							s_m_axis_tlast <= '1';
						end if;
					end if;

					if (v_tmp_internal_memory'length) / 8 - v_tmp_element_count >= G_INPUT_BYTE_WIDTH and v_tmp_flush_memory = '0' then
						s_s_axis_tready <= '1';
					end if;

					-- Write back internal variables
					s_element_count   <= to_unsigned(v_tmp_element_count, s_element_count'length);
					s_internal_memory <= v_tmp_internal_memory;
					s_flush_memory    <= v_tmp_flush_memory;
				end if;
			end if;

		end process SHIFT_MUX_PROC;

		-------------------------------------------
		-- Set Outputs
		-------------------------------------------
		-- Set Slave tready
		o_s_axis_tready <= s_s_axis_tready;

		-- Set Master AXIS Interface
		o_m_axis_tdata(s_m_axis_tdata'range)                             <= s_m_axis_tdata;
		o_m_axis_tdata(o_m_axis_tdata'high downto s_m_axis_tdata'length) <= (others => '0');
		o_m_axis_tkeep(s_m_axis_tkeep'range)                             <= s_m_axis_tkeep;
		o_m_axis_tkeep(o_m_axis_tkeep'high downto s_m_axis_tkeep'length) <= (others => '0');
		o_m_axis_tvalid                                                  <= s_m_axis_tvalid;
		o_m_axis_tlast                                                   <= s_m_axis_tlast and s_m_axis_tvalid;
	end generate DOWNSIZE_GEN;

	UPSIZE_GEN : if G_INPUT_BYTE_WIDTH < G_OUTPUT_BYTE_WIDTH generate
		assert FALSE
			report "Upsizing of AXIS Interfaces currently not supported!"
			severity FAILURE;
	end generate UPSIZE_GEN;

end architecture rtl;
