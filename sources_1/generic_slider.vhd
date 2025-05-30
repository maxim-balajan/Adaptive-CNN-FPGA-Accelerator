library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity generic_slider is
	generic (
		vector_length     : natural := 8;
		G_IMG_MAX_LENGTH  : natural := 227;
		G_KERNEL_MAX_SIZE : natural := 11;
		kernel_size       : natural := 5
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		--
		valid_pixel  : in std_logic;
		pixel_stream : in std_logic_vector(vector_length - 1 downto 0);
		--
		input_image_length  : in std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
		output_image_length : in std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
		-- normally padding size would not be necessary, but it enables skipping a lot of initialization
		padding_size    : in std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
		stride_bit_mask : in std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
		--
		kernel_complete          : out std_logic;
		kernel_en                : out std_logic;
		kernel_activation_matrix : out matrix_1d(0 to G_KERNEL_MAX_SIZE ** 2 - 1)(vector_length - 1 downto 0)
	);
end entity generic_slider;

architecture rtl of generic_slider is

	-- pixel locations of input stream (in first convolution this would be 28x28)
	signal s_pixel_input_x : unsigned(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
	signal s_pixel_input_y : unsigned(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) downto 0);
	-- pixel locations of output stream (in first convolution this would be 14x14)
	signal s_pixel_output_x : unsigned(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
	signal s_pixel_output_y : unsigned(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) downto 0);
	-- Helper signal to store the addition of s_padding_size + s_input_image_length
	signal s_actual_input_length : unsigned(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);

	-- Current pixel to be pipelined
	signal s_current_pixel : std_logic_vector(vector_length - 1 downto 0);
	signal s_current_valid : std_logic;

	-- Register for storing meta data
	signal s_input_image_length  : std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
	signal s_output_image_length : std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
	signal s_padding_size        : std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
	signal s_stride_bit_mask     : std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);

	-- Helper signals to determine which kernels are valid and when computation needs to end
	signal s_init_complete   : std_logic;
	signal s_valid_kernel    : std_logic;
	signal s_stride_reached  : std_logic;
	signal s_kernel_en       : std_logic;
	signal s_kernel_complete : std_logic;

begin

	GET_PIXEL_ADDR_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_pixel_input_x <= (others => '0');
				-- The first padding inputs are skipped, which is why the y-address is directly correlating to the padding
				s_pixel_input_y(s_pixel_input_y'high)              <= '0';
				s_pixel_input_y(s_pixel_input_y'high - 1 downto 0) <= unsigned(padding_size);
				s_current_pixel                                    <= (others => '0');
				s_kernel_complete                                  <= '0';
				s_current_valid                                    <= '0';
				-- Setting of meta data registers
				s_input_image_length  <= input_image_length;
				s_output_image_length <= output_image_length;
				s_padding_size        <= padding_size;
				s_stride_bit_mask     <= stride_bit_mask;
			else
				if valid_pixel = '1' then
					-- Get current pixel
					s_current_pixel <= pixel_stream;
					s_current_valid <= valid_pixel;
				else
					s_current_valid <= '0';
				end if;

				-- after init is finished just iterate other the image; disregard overflows by s_pixel_input_y
				if s_init_complete = '1' and s_current_valid = '1' then
					s_pixel_input_x <= s_pixel_input_x + 1;
					if s_pixel_input_x = unsigned(s_actual_input_length) - 1 then
						s_pixel_input_x <= (others => '0');
						s_pixel_input_y <= s_pixel_input_y + 1;
					end if;
				end if;

				-- after final pixel has been reached, set complete flag;
				-- This has to be written exactly like this because otherwise undefined behavior of HW after completion will mess with this flag
				if s_pixel_output_x = unsigned(s_output_image_length) - 1 and s_pixel_output_y = unsigned(s_output_image_length) - 1 then
					s_kernel_complete <= '1';
				end if;
			end if;
		end if;

	end process GET_PIXEL_ADDR_PROC;

	-- Instantiation of main component that gets all valid (and invalid) kernels

	KERNEL_SLIDER_INST : entity work.kernel_slider
		generic map (
			vector_length     => vector_length,
			G_IMG_MAX_LENGTH  => G_IMG_MAX_LENGTH,
			G_KERNEL_MAX_SIZE => G_KERNEL_MAX_SIZE,
			kernel_size       => kernel_size
		)
		port map (
			clk   => clk,
			reset => reset,
			--
			en           => s_current_valid,
			pixel_stream => s_current_pixel,
			-- image_length not delayed, because it will be again delayed by bram_fifo
			image_length => input_image_length,
			-- padding is also not delayed because it is needed during the reset
			padding_size => padding_size,
			--
			init_complete            => s_init_complete,
			kernel_activation_matrix => kernel_activation_matrix
		);

	-- store how large the actual image is
	s_actual_input_length <= unsigned(s_input_image_length) + shift_left(unsigned(padding_size), 1);

	-- This is a helper signal that stores wether a kernel is definitely valid (is the kernel split over two rows?) or not (but is not the sole criteria)
	s_valid_kernel <= '1' when s_pixel_input_x < s_actual_input_length - kernel_size + 1 else '0';

	-- This signal shows wether the correct striding window has been reached or not
	s_stride_reached <= (not (or (std_logic_vector(s_pixel_input_x) and s_stride_bit_mask)))
	                    and (not (or (std_logic_vector(s_pixel_input_y(s_pixel_input_y'high - 1 downto 0)) and s_stride_bit_mask)));

	s_kernel_en <= '1' when s_init_complete = '1'
	                        and s_current_valid = '1'
	                        and s_valid_kernel = '1'
	                        and s_kernel_complete = '0'
	                        and s_stride_reached = '1' else
	               '0';

	-- Set destination of new convolution value
	GET_OUTPUT_ADDR : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				-- set x-address to uint_max (or -1) because before the init the first pixel has not been reached
				s_pixel_output_x <= (others => '1');
				s_pixel_output_y <= (others => '0');
			elsif s_kernel_en = '1' then
				s_pixel_output_x <= s_pixel_output_x + 1;
				if s_pixel_output_x = unsigned(s_output_image_length) - 1 then
					s_pixel_output_x <= (others => '0');
					s_pixel_output_y <= s_pixel_output_y + 1;
				end if;
			end if;
		end if;

	end process GET_OUTPUT_ADDR;

	kernel_en       <= s_kernel_en;
	kernel_complete <= s_kernel_complete;

end architecture rtl;
