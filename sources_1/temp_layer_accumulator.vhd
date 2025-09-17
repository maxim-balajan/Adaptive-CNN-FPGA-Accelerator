library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity temp_layer_accumulator is
	generic (
		g_vector_length         : natural := 24;
		g_clipped_vector_length : natural := 8;
		g_max_fifo_depth        : natural := 27 ** 2;
		g_oc_amount             : natural := 5
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		-- Reset unit except of the BRAM FIFO
		partial_reset : in std_logic;
		-- OUTPUT of ROUTING CORES
		i_kernel_complete : in std_logic;
		i_kernel_valid    : in std_logic;
		i_pixel_line      : in matrix_1d(0 to g_oc_amount - 1)(g_vector_length - 1 downto 0);
		-- INPUTS of BRAM FIFO
		i_pixel_amount : in std_logic_vector(integer(ceil(log2(real(g_max_fifo_depth)))) - 1 downto 0);
		-- CONTROL LOGIC
		i_retrieve_output : in std_logic;
		i_enable_relu     : in std_logic;
		i_shamt           : in std_logic_vector(g_vector_length - 1 downto 0);
		-- Sanitized Outputs
		o_kernel_complete : out std_logic;
		o_kernel_valid    : out std_logic;
		o_pixel_line      : out matrix_1d(0 to g_oc_amount - 1)(g_clipped_vector_length - 1 downto 0)
	);
end entity temp_layer_accumulator;

architecture rtl of temp_layer_accumulator is

	signal s_valid_pixel_line     : std_logic_vector(0 to 1);
	signal s_kernel_complete_line : std_logic_vector(0 to 1);

	signal s_pixel_lines : matrix_2d(0 to 1)(0 to g_oc_amount  - 1)(g_vector_length - 1 downto 0);

	signal s_retrieve_output : std_logic;
	signal s_enable_relu     : std_logic;
	signal s_shamt           : std_logic_vector(g_vector_length - 1 downto 0);

	-- FIFO signals
	signal s_temp_layer_pixel         : std_logic_vector(g_vector_length - 1 downto 0);
	signal s_added_temp_layer_pixel   : std_logic_vector(g_vector_length - 1 downto 0);
	signal s_shifted_temp_layer_pixel : std_logic_vector(g_vector_length - 1 downto 0);

begin

	DELAY_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' or partial_reset = '1' then
				s_valid_pixel_line     <= (others => '0');
				s_kernel_complete_line <= (others => '0');
				--
				s_pixel_lines <= (others => (others => (others => '0')));
				--
				s_retrieve_output <= i_retrieve_output;
				s_enable_relu     <= i_enable_relu;
				s_shamt           <= i_shamt;
			else
				-- set first constant delays
				s_valid_pixel_line(0)     <= i_kernel_valid;
				s_kernel_complete_line(0) <= i_kernel_complete;
				s_pixel_lines(0)          <= i_pixel_line;

				-- delay other pixel lines and enable lines
				s_valid_pixel_line(1)                  <= s_valid_pixel_line(0) and s_retrieve_output;
				s_kernel_complete_line(1)              <= s_kernel_complete_line(0);
				s_pixel_lines(1)(1 to g_oc_amount - 1) <= s_pixel_lines(0)(1 to g_oc_amount - 1);

				-- set first pixel line with shifted + relu'd value
				if (signed(s_shifted_temp_layer_pixel) > 0 or s_enable_relu = '0') and s_retrieve_output = '1' then
					s_pixel_lines(1)(0) <= s_shifted_temp_layer_pixel;
				else
					s_pixel_lines(1)(0) <= (others => '0');
				end if;
			end if;
		end if;

	end process DELAY_PROC;

	s_shifted_temp_layer_pixel <= std_logic_vector(shift_right(signed(s_added_temp_layer_pixel), to_integer(unsigned(i_shamt))));

	bram_fifo_inst : entity work.bram_fifo
		generic map (
			vector_length => g_vector_length,
			G_MAX_DEPTH   => g_max_fifo_depth
		)
		port map (
			clk   => clk,
			reset => reset,
			--
			set_full => '1',
			depth    => i_pixel_amount,
			--
			din   => s_added_temp_layer_pixel,
			wr_en => s_valid_pixel_line(0) and not s_kernel_complete_line(0),
			rd_en => i_kernel_valid and not i_kernel_complete,
			--
			dout  => s_temp_layer_pixel,
			full  => open,
			empty => open
		);

	clip_adder_inst : entity work.clip_adder
		generic map (
			vector_length => g_vector_length
		)
		port map (
			din0 => s_pixel_lines(0)(0),
			din1 => s_temp_layer_pixel,
			dout => s_added_temp_layer_pixel
		);

	-------------------------------------------
	-- Set Outputs
	-------------------------------------------

	o_kernel_valid    <= s_valid_pixel_line(s_valid_pixel_line'high);
	o_kernel_complete <= s_kernel_complete_line(s_kernel_complete_line'high);

	PIXEL_LINE_GEN : for i in 0 to g_oc_amount - 1 generate
		o_pixel_line(i) <= s_pixel_lines(s_pixel_lines'high)(i)(g_clipped_vector_length - 1 downto 0);
	end generate PIXEL_LINE_GEN;

end architecture rtl;
