library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity line_unit is
	generic (
		vector_length     : natural := 16;
		G_IMG_MAX_LENGTH  : natural := 55;
		G_KERNEL_MAX_SIZE : natural := 5
	);
	port (
		clk                  : in std_logic;
		reset                : in std_logic;
		set_line_buffer_full : in std_logic;
		line_buffer_depth    : in std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
		--
		din   : in std_logic_vector(vector_length - 1 downto 0);
		en    : in std_logic;
		wr_en : in std_logic;
		--
		pixel_window_line  : out matrix_1d(0 to G_KERNEL_MAX_SIZE - 1)(vector_length - 1 downto 0);
		enable_window_line : out std_logic_vector(0 to G_KERNEL_MAX_SIZE - 1)
	);
end entity line_unit;

architecture rtl of line_unit is

	signal s_pixel_window_line  : matrix_1d(0 to G_KERNEL_MAX_SIZE)(vector_length - 1 downto 0);
	signal s_enable_window_line : std_logic_vector(0 to G_KERNEL_MAX_SIZE);

	signal s_line_buffer_dout : std_logic_vector(vector_length - 1 downto 0);
	signal s_line_buffer_full : std_logic;

begin

	BUFFER_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_pixel_window_line(s_pixel_window_line'low + 1 to s_pixel_window_line'high)    <= (others => (others => '0'));
				-- If set full is set, all registers have to receive an valid en in order to correctly set the init signal necessary for the control logic
				s_enable_window_line(s_enable_window_line'low + 1 to s_enable_window_line'high) <= (others => set_line_buffer_full);
			else
				-- Shift values through registers
                if (en and wr_en) = '1' then
				    s_pixel_window_line(s_pixel_window_line'low + 1 to s_pixel_window_line'high)    <= s_pixel_window_line(s_pixel_window_line'low to s_pixel_window_line'high - 1);
				    s_enable_window_line(s_enable_window_line'low + 1 to s_enable_window_line'high) <= s_enable_window_line(s_enable_window_line'low to s_enable_window_line'high - 1);
                end if;
            end if;
		end if;

	end process BUFFER_PROC;

	LINE_BUFFER_INST : entity work.line_buffer
		generic map (
			vector_length => vector_length,
			G_MAX_DEPTH   => G_IMG_MAX_LENGTH
		)
		port map (
			clk                 => clk,
			reset               => reset,
			set_full            => set_line_buffer_full,
			depth               => line_buffer_depth,
			din                 => din,
			en                  => en,
			wr_en               => wr_en,
			dout                => s_line_buffer_dout,
			full                => open,
			full_read_and_write => s_line_buffer_full
		);

	-- Set outputs of linebuffer directly to start of shift registers
	s_pixel_window_line(s_pixel_window_line'low)   <= s_line_buffer_dout;
	-- s_line_buffer_full should be overwritten by set_line_buffer_full because the BRAM would overwise delay the signal by one cycle
	s_enable_window_line(s_enable_window_line'low) <= s_line_buffer_full or set_line_buffer_full;

	-- Set outputs
	pixel_window_line  <= s_pixel_window_line(s_pixel_window_line'low + 1 to s_pixel_window_line'high);
	enable_window_line <= s_enable_window_line(s_enable_window_line'low + 1 to s_enable_window_line'high);

end architecture rtl;
