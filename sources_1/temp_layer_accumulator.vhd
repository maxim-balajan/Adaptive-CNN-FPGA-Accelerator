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
		-- Global enable: If set to 0, stall entire unit and set outputs to low
		i_en : in std_logic;
		-- OUTPUT of ROUTING CORES
		i_kernel_complete : in std_logic;
		i_kernel_valid    : in std_logic;
		i_pixel_line      : in matrix_1d(0 to g_oc_amount - 1)(g_vector_length - 1 downto 0);
		-- Control unit OUTPUT (Registered)
		i_pixel_amount                : in std_logic_vector(15 downto 0);
		i_pool_or_conv                : in std_logic;
		i_current_ic_amount           : in std_logic_vector(15 downto 0);
		i_input_channel_per_iteration : in std_logic_vector(15 downto 0);
		i_input_channel_size          : in std_logic_vector(15 downto 0);
		i_enable_relu                 : in std_logic;
		i_shamt                       : in std_logic_vector(7 downto 0);
		-- Sanitized Outputs
		o_kernel_complete : out std_logic;
		o_kernel_valid    : out std_logic;
		o_pixel_line      : out matrix_1d(0 to g_oc_amount - 1)(g_clipped_vector_length - 1 downto 0)
	);
end entity temp_layer_accumulator;

architecture rtl of temp_layer_accumulator is

	signal s_valid_pixel_line     : std_logic_vector(0 to 3);
	signal s_kernel_complete_line : std_logic_vector(0 to 3);

	signal s_pixel_lines : matrix_2d(0 to 2)(0 to g_oc_amount  - 1)(g_vector_length - 1 downto 0);

	-- FIFO signals

	signal s_temp_layer_pixel_line       : matrix_1d(0 to 1)(g_vector_length - 1 downto 0);
	signal s_added_temp_layer_pixel_line : matrix_1d(0 to 1)(g_vector_length - 1 downto 0);
	signal s_shifted_temp_layer_pixel    : std_logic_vector(g_vector_length - 1 downto 0);

begin

	DELAY_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_valid_pixel_line     <= (others => '0');
				s_kernel_complete_line <= (others => '0');
				--
				s_pixel_lines <= (others => (others => (others => '0')));
				--
				s_added_temp_layer_pixel_line(1) <= (others => '0');
				s_temp_layer_pixel_line(1)       <= (others => '0');
			elsif i_en = '1' then
				-- set first constant delays of three cycles
				s_valid_pixel_line(0)          <= i_kernel_valid;
				s_valid_pixel_line(1 to 2)     <= s_valid_pixel_line(0 to 1);
				s_kernel_complete_line(0)      <= i_kernel_complete;
				s_kernel_complete_line(1 to 3) <= s_kernel_complete_line(0 to 2);
				s_pixel_lines(0)               <= i_pixel_line;
				s_pixel_lines(1)          	   <= s_pixel_lines(0);

				-- delay temp_layer output from bram to have better timing
				s_temp_layer_pixel_line(1) <= s_temp_layer_pixel_line(0);

				-- delay s_added_temp_layer_pixel input to bram to have better timing
				s_added_temp_layer_pixel_line(1) <= s_added_temp_layer_pixel_line(0);

				-- delay other pixel lines and enable lines
				if unsigned(i_current_ic_amount) + unsigned(i_input_channel_per_iteration) >= unsigned(i_input_channel_size) or i_pool_or_conv = '0' then
					s_valid_pixel_line(3) <= s_valid_pixel_line(2);

					if signed(s_shifted_temp_layer_pixel) < 0 and i_enable_relu = '1' then
						s_pixel_lines(2)(0) <= (others => '0');
					elsif signed(s_shifted_temp_layer_pixel) < to_signed(-2 ** (g_clipped_vector_length - 1), s_shifted_temp_layer_pixel'length) then
						s_pixel_lines(2)(0) <= std_logic_vector(to_signed(-2 ** (g_clipped_vector_length - 1), s_shifted_temp_layer_pixel'length));
					elsif signed(s_shifted_temp_layer_pixel) > to_signed(2 ** (g_clipped_vector_length - 1) - 1, s_shifted_temp_layer_pixel'length) then
						s_pixel_lines(2)(0) <= std_logic_vector(to_signed(2 ** (g_clipped_vector_length - 1) - 1, s_shifted_temp_layer_pixel'length));
					else
						s_pixel_lines(2)(0) <= s_shifted_temp_layer_pixel;
					end if;
				else
					s_valid_pixel_line(3) <= '0';
					s_pixel_lines(2)(0)   <= (others => '0');
				end if;

				s_pixel_lines(2)(1 to g_oc_amount - 1) <= s_pixel_lines(1)(1 to g_oc_amount - 1);
			end if;
		end if;

	end process DELAY_PROC;

	s_shifted_temp_layer_pixel <= std_logic_vector(shift_right(signed(s_added_temp_layer_pixel_line(1)), to_integer(unsigned(i_shamt))));

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
			depth    => i_pixel_amount(integer(ceil(log2(real(g_max_fifo_depth)))) - 1 downto 0),
			--
			din   => s_added_temp_layer_pixel_line(1),
			wr_en => (s_valid_pixel_line(2) and not s_kernel_complete_line(2)) and i_en,
			rd_en => (i_kernel_valid and not i_kernel_complete) and i_en,
			--
			dout  => s_temp_layer_pixel_line(0),
			full  => open,
			empty => open
		);

	clip_adder_inst : entity work.clip_adder
		generic map (
			vector_length => g_vector_length
		)
		port map (
			din0 => s_pixel_lines(1)(0),
			din1 => s_temp_layer_pixel_line(1),
			dout => s_added_temp_layer_pixel_line(0)
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
