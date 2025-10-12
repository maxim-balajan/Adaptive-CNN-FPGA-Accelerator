library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity configurable_slider_input_demux is
	generic (
		G_DATA_BYTE_WIDTH             : integer range 1 to 128 := 16;
		G_BRAM_BYTE_WIDTH             : integer range 1 to 128 := 1;
		G_INPUT_CHANNEL_PER_ITERATION : natural                := 3;
		G_IMG_MAX_LENGTH              : natural                := 300
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		--
		i_en : in std_logic;
		-- Control Inputs [REGISTERED after reset]
		i_image_input_length : in std_logic_vector(15 downto 0);
		i_padding_size       : in std_logic_vector(7 downto 0);
		-- Control Inputs [Not REGISTERED after reset]
		i_wt_init : in std_logic;
		i_cs_init : in std_logic;
		-- BRAM signals
		o_rd_en       : out std_logic_vector(G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);
		i_data_stream : in std_logic_vector(G_DATA_BYTE_WIDTH * 8 - 1 downto 0);
		i_empty       : in std_logic_vector(G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);
		--
		o_valid_pixel_streams : out std_logic;
		o_pixel_streams       : out matrix_1d(0 to G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1)(G_BRAM_BYTE_WIDTH * 8 - 1 downto 0)
	);
end entity configurable_slider_input_demux;

architecture rtl of configurable_slider_input_demux is

	-- Constant for knowing range of demultiplexers
	constant C_BRAM_PER_IC : natural := G_DATA_BYTE_WIDTH / (G_INPUT_CHANNEL_PER_ITERATION * G_BRAM_BYTE_WIDTH);

	signal s_current_read_id     : natural range 0 to C_BRAM_PER_IC - 1;
	signal s_pixel_input_x       : signed(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) downto 0);
	signal s_pixel_input_y       : signed(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) + 1 downto 0);
	signal s_actual_input_length : signed(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) + 1 downto 0);

	signal s_rd_en      : std_logic;
	signal s_is_padding : std_logic;

	-- BRAM signals delayed by one cycle

	signal s_pipeline_valid_line : std_logic_vector(0 to 2);
	signal s_pixel_streams       : std_logic_vector(G_DATA_BYTE_WIDTH * 8 - 1 downto 0);
	-- array representation of bram signals
	signal s_pixel_streams_matrix : matrix_1d(0 to G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1)(G_BRAM_BYTE_WIDTH * 8 - 1 downto 0);

begin

	CONTROL_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_current_read_id                     <= 0;
				s_pixel_input_x                       <= (others => '0');
				s_pixel_input_y                       <= (others => '0');
				s_pixel_input_y(i_padding_size'high downto 0) <= signed(i_padding_size);
				s_actual_input_length                 <= RESIZE(signed(i_image_input_length) + SHIFT_LEFT(signed(i_padding_size), 1), s_actual_input_length'length);
				--
				s_rd_en                  <= '0';
				s_pipeline_valid_line(0) <= '0';
			elsif i_en = '1' and (s_is_padding = '1' or i_empty(s_current_read_id) = '0') and (i_wt_init = '1' or i_cs_init = '0') then
				if s_is_padding = '1' then
					-- If no padding, dont read from bram, but pipeline valid
					s_rd_en <= '0';
				elsif i_empty(s_current_read_id) = '0' then
					s_current_read_id <= s_current_read_id + 1;
					s_rd_en           <= '1';
				end if;
				s_pipeline_valid_line(0) <= '1';
				-- Increment pixel address after pipeline was started
				s_pixel_input_x <= s_pixel_input_x + 1;
				if s_pixel_input_x = s_actual_input_length - 1 then
					s_pixel_input_x <= (others => '0');
					s_pixel_input_y <= s_pixel_input_y + 1;
					-- keep s_pixel_y at s_actual_input_length to always treat it as padding
					-- -> only 0 will be pipelined at the end, no actual values
					if s_pixel_input_y = s_actual_input_length then
						s_pixel_input_y <= s_pixel_input_y;
					end if;
				end if;
			else
				s_rd_en                  <= '0';
				s_pipeline_valid_line(0) <= '0';
			end if;
		end if;

	end process CONTROL_PROC;

	BRAM_PIPELINE : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_pipeline_valid_line(1 to 2) <= (others => '0');
				s_pixel_streams               <= (others => '0');
			else
				-- shift valid by two cycles to conform bram delay
				s_pipeline_valid_line(1 to 2) <= s_pipeline_valid_line(0 to 1);
				-- delay bram output by one cycle
				s_pixel_streams <= i_data_stream;
			end if;
		end if;

	end process BRAM_PIPELINE;

	----------------------------------------
	-- Asynchrones signals
	----------------------------------------
	s_is_padding <= '1' when s_pixel_input_x < RESIZE(signed(i_padding_size), s_actual_input_length'length)
	                         or (s_actual_input_length - s_pixel_input_x - 1) < RESIZE(signed(i_padding_size), s_actual_input_length'length)
	                         or (s_actual_input_length - s_pixel_input_y - 1) < RESIZE(signed(i_padding_size), s_actual_input_length'length) else
	                '0';

	-- Map pixel stream to matrix to be able to multiplex signal
	PIXEL_MAP_GEN : for i in s_pixel_streams_matrix'range generate
		s_pixel_streams_matrix(i) <= s_pixel_streams((i + 1) * (G_BRAM_BYTE_WIDTH * 8) - 1 downto i * (G_BRAM_BYTE_WIDTH * 8));
	end generate PIXEL_MAP_GEN;

	----------------------------------------
	-- Set outputs
	----------------------------------------

	-- Demultiplex rd signal to correct BRAM
	RD_GEN : for j in o_rd_en'range generate
		o_rd_en(j) <= s_rd_en when s_current_read_id = (j mod C_BRAM_PER_IC) else '0';
	end generate RD_GEN;

	-- Multiplex correct BRAM data to first G_INPUT_CHANNEL_PER_ITERATION slots of output pixel stream
	OUTPUT_GEN : for i in 0 to G_INPUT_CHANNEL_PER_ITERATION - 1 generate
		o_pixel_streams(i) <= s_pixel_streams_matrix(s_current_read_id + i * C_BRAM_PER_IC);
	end generate OUTPUT_GEN;

	o_pixel_streams(G_INPUT_CHANNEL_PER_ITERATION to o_pixel_streams'high) <= (others => (others => '0'));
	o_valid_pixel_streams                                                      <= s_pipeline_valid_line(s_pipeline_valid_line'high);

end architecture rtl;
