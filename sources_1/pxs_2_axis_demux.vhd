library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity pxs_2_axis_demux is
	generic (
		G_OUTPUT_CHANNELS : natural;
		G_DATA_BYTE_WIDTH : integer range 1 to 128 := 16;
		G_BRAM_BYTE_WIDTH : integer range 1 to 128 := 1
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		--
		i_en : in std_logic;
		-- ROUTING CORES OUTPUTS
		i_kernel_complete : in std_logic;
		i_kernel_valid    : in std_logic;
		i_pixel_line      : in matrix_1d(0 to G_DATA_BYTE_WIDTH - 1)(G_BRAM_BYTE_WIDTH * 8 - 1 downto 0);
		-- BRAM FIFO ARRAY INPUTS
		o_input_stream : out std_logic_vector(G_DATA_BYTE_WIDTH * 8 - 1 downto 0);
		o_wr_en        : out std_logic_vector(G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0)
	);
end entity pxs_2_axis_demux;

architecture rtl of pxs_2_axis_demux is

	signal s_valid_pixel  : std_logic;
	signal s_pixel_values : std_logic_vector(o_input_stream'range);

	type unsigned_array_t is array (0 to G_OUTPUT_CHANNELS - 1) of unsigned(integer(ceil(log2(real(G_DATA_BYTE_WIDTH)))) downto 0);

	signal s_current_write_id     : unsigned_array_t;
	signal s_current_write_id_del : unsigned_array_t;

begin

	DELAY_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_valid_pixel  <= '0';
				s_pixel_values <= (others => '0');

				s_current_write_id     <= (others => (others => '0') );
				s_current_write_id_del <= (others => (others => '0') );
			elsif i_en = '1' and i_kernel_valid = '1' and i_kernel_complete = '0' then
				-- Determine if pixel is valid or not
				s_valid_pixel <= '1';

				-- Map Pixel values to slv
				for i in i_pixel_line'range loop

					s_pixel_values((i + 1) * G_BRAM_BYTE_WIDTH * 8 - 1 downto i * G_BRAM_BYTE_WIDTH * 8) <= i_pixel_line(i);

				end loop;

				-- Increment write pointers
				for i in s_current_write_id'range loop

					s_current_write_id(i) <= s_current_write_id(i) + 1;
					if s_current_write_id(i) >= G_DATA_BYTE_WIDTH / G_OUTPUT_CHANNELS - 1 then
						s_current_write_id(i) <= (others => '0');
					end if;

				end loop;

				-- Delay write pointers by one cycle
				s_current_write_id_del <= s_current_write_id;
			else
				s_valid_pixel <= '0';
			end if;
		end if;

	end process DELAY_PROC;

	----------------------------------------
	-- Set outputs
	----------------------------------------

	OUTPUT_GEN : for i in 0 to G_OUTPUT_CHANNELS - 1 generate

		BRAM_OUTPUT_GEN : for j in 0 to o_wr_en'length / G_OUTPUT_CHANNELS - 1 generate
			o_wr_en(i * (o_wr_en'length / G_OUTPUT_CHANNELS) + j) <= '1' when (s_valid_pixel = '1') and j = s_current_write_id_del(i) else '0';
			o_input_stream((i * (o_wr_en'length / G_OUTPUT_CHANNELS) + j + 1) * G_BRAM_BYTE_WIDTH * 8 - 1 downto (i * (o_wr_en'length / G_OUTPUT_CHANNELS) + j) * G_BRAM_BYTE_WIDTH * 8)
                                                            <= s_pixel_values((i + 1) * G_BRAM_BYTE_WIDTH * 8 - 1 downto i * G_BRAM_BYTE_WIDTH * 8);
		end generate BRAM_OUTPUT_GEN;

	end generate OUTPUT_GEN;

end architecture rtl;
