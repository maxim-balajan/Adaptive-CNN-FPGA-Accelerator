library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity pooling_slider is
	generic (
		vector_length         : natural              := 8;
		original_input_width  : natural              := 32;
		original_input_height : natural              := 32;
		kernel_size           : natural              := 5;
		pooling_size          : integer range 2 to 2 := 2
	);
	port (
		clk                      : in std_logic;
		reset                    : in std_logic;
		pixel_stream             : in std_logic_vector(vector_length - 1 downto 0);
		valid_pixel              : in std_logic;
		kernel_complete          : out std_logic;
		kernel_en                : out std_logic;
		pixel_x                  : out std_logic_vector(integer(ceil(log2(real(original_input_width - kernel_size + 1) / 2.0))) - 1 downto 0);
		pixel_y                  : out std_logic_vector(integer(ceil(log2(real(original_input_height - kernel_size + 1) / 2.0))) downto 0);
		kernel_activation_matrix : out matrix_2d(0 to pooling_size - 1)(0 to pooling_size - 1)(vector_length - 1 downto 0)
	);
end entity pooling_slider;

architecture rtl of pooling_slider is

	-- Image dimensions of input (in first convolution this would be 28x28)
	constant c_old_image_width  : real := real(original_input_width - kernel_size + 1);
	constant c_old_image_height : real := real(original_input_height - kernel_size + 1);
	-- Image dimensions of output (in first convolution this would be 14x14)
	constant c_new_image_width  : real := real(original_input_width - kernel_size + 1) / 2.0;
	constant c_new_image_height : real := real(original_input_height - kernel_size + 1) / 2.0;

	-- pixel locations of input stream (in first convolution this would be 28x28)
	signal s_pixel_input_x : unsigned(integer(ceil(log2(c_old_image_width))) - 1 downto 0);
	signal s_pixel_input_y : unsigned(integer(ceil(log2(c_old_image_height))) downto 0);
	-- pixel locations of output stream (in first convolution this would be 14x14)
	signal s_pixel_output_x : unsigned(integer(ceil(log2(c_new_image_width))) - 1 downto 0);
	signal s_pixel_output_y : unsigned(integer(ceil(log2(c_new_image_height))) downto 0);

	-- Current pixel to be pipelined
	signal s_current_pixel : std_logic_vector(vector_length - 1 downto 0);
	signal s_current_valid : std_logic;

	-- Helper signals to dertermine which kernels are valid and when computation needs to end
	signal s_init_complete   : std_logic;
	signal s_kernel_en       : std_logic;
	signal s_kernel_complete : std_logic;

begin

	GET_PIXEL_ADDR_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_pixel_input_x   <= (others => '0');
				s_pixel_input_y   <= (others => '0');
				s_current_pixel   <= (others => '0');
				s_kernel_complete <= '0';
				s_current_valid   <= '0';
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
					if s_pixel_input_x = integer(c_old_image_width) - 1 then
						s_pixel_input_x <= (others => '0');
						s_pixel_input_y <= s_pixel_input_y + 1;
					end if;
				end if;

				-- This will most likely break for other pooling sizes
				-- after final pixel has been reached, set complete flag;
				-- This has to be written exactly like this because otherwise undefined behaviour of HW after completion will mess with this flag
				if s_pixel_output_x = integer(c_new_image_width) - 1 and s_pixel_output_y = integer(c_new_image_height) - 1 and s_kernel_en = '1' then
					s_kernel_complete <= '1';
				end if;
			end if;
		end if;

	end process GET_PIXEL_ADDR_PROC;

	-- Instantiation of main component that gets all valid (and invalid) kernels

	KERNEL_SLIDER_INST : entity work.kernel_slider
		generic map (
			vector_length => vector_length,
			input_width   => integer(c_old_image_width),
			kernel_size   => pooling_size
		)
		port map (
			clk                      => clk,
			reset                    => reset,
			en                       => s_current_valid,
			pixel_stream             => s_current_pixel,
			init_complete            => s_init_complete,
			kernel_activation_matrix => kernel_activation_matrix
		);

	-- These signals are important for the actual pooling unit directly followed after this unit
	s_kernel_en <= '1' when s_init_complete = '1'
	                        and s_current_valid = '1'
	                        and s_pixel_input_x(s_pixel_input_x'low) = '0'
	                        and s_pixel_input_y(s_pixel_input_y'low) = '0' else
	               '0';

	kernel_en <= s_kernel_en;

	-- Set destination of new pooled value
	s_pixel_output_x <= resize(shift_right(s_pixel_input_x, 1), s_pixel_output_x'length);
	s_pixel_output_y <= resize(shift_right(s_pixel_input_y, 1), s_pixel_output_y'length);
	pixel_x          <= std_logic_vector(s_pixel_output_x);
	pixel_y          <= std_logic_vector(s_pixel_output_y);

	kernel_complete <= s_kernel_complete;

end architecture rtl;
