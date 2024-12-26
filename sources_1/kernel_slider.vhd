library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity kernel_slider is
	generic (
		vector_length : integer := 8;
		input_width   : integer := 32;
		input_height  : integer := 32;
		kernel_size   : integer := 5
	);
	port (
		clk                      : in std_logic;
		reset                    : in std_logic;
		input_matrix             : in matrix_2d(0 to input_width - 1)(0 to input_height - 1)(vector_length - 1 downto 0);
		kernel_complete          : out std_logic;
		kernel_en                : out std_logic;
		kernel_activation_matrix : out matrix_2d(0 to kernel_size - 1)(0 to kernel_size - 1)(vector_length - 1 downto 0)
	);
end entity kernel_slider;

architecture rtl of kernel_slider is

	-- Values in order to retrieve pixels from input stream
	signal s_pixel_input_x : unsigned(integer(ceil(log2(real(input_width)))) - 1 downto 0);
	signal s_pixel_input_y : unsigned(integer(ceil(log2(real(input_height)))) downto 0);
	-- Current pixel to be pipelined
	signal s_current_pixel : std_logic_vector(vector_length - 1 downto 0);
	-- "Kernel matrix" + 1 because we have to take inputs into consideration
	signal s_kernel_matrix : matrix_2d(0 to kernel_size)(0 to kernel_size - 1)(vector_length - 1 downto 0);
	-- Line Buffer wr_en line
	signal s_line_buffer_wr_en : std_logic_vector(0 to kernel_size - 1);

	-- Helper signals to dertermine which kernels are valid and when computation needs to end
	signal s_full_delay      : std_logic_vector(0 to kernel_size);
	signal s_line_x          : unsigned(integer(ceil(log2(real(input_width)))) - 1 downto 0);
	signal s_kernel_complete : std_logic;

begin

	BUFFER_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_pixel_input_x        <= (others => '0');
				s_pixel_input_y        <= (others => '0');
				s_current_pixel        <= (others => '0');
				s_line_buffer_wr_en(0) <= '0';
				s_line_x               <= (others => '0');
				s_kernel_complete      <= '0';
			else
				-- Get current pixel
				-- And if s_pixel_input_y is OOB, then finish computation
				if s_pixel_input_y = input_height then
					s_pixel_input_y <= s_pixel_input_y;
					s_current_pixel <= (others => '0');
					-- set s_kernel_comp that needs to be delayed by one cycle before outputting
					s_kernel_complete <= s_pixel_input_y ?= input_height;
				else
					s_current_pixel <= input_matrix(to_integer(s_pixel_input_x))(to_integer(s_pixel_input_y));
					s_pixel_input_x <= s_pixel_input_x + 1;
					if s_pixel_input_x = input_width - 1 then
						s_pixel_input_x <= (others => '0');
						s_pixel_input_y <= s_pixel_input_y + 1;
					end if;
					s_kernel_complete <= '0';
				end if;

				-- Shift values through kernel window
				s_kernel_matrix(s_kernel_matrix'low + 1 to s_kernel_matrix'high) <= s_kernel_matrix(s_kernel_matrix'low to s_kernel_matrix'high - 1);

				-- Shift full delay line by one
				s_full_delay(s_full_delay'low + 1 to s_full_delay'high) <= s_full_delay(s_full_delay'low to s_full_delay'high - 1);

				-- If init is finished, accumulate s_line_x
				if s_full_delay(s_full_delay'high) = '1' then
					s_line_x <= s_line_x + 1;
					if s_line_x = input_width - 1 then
						s_line_x <= (others => '0');
					end if;
				end if;

				-- Set values for line buffers
				s_line_buffer_wr_en(s_line_buffer_wr_en'low) <= '1';
			end if;
		end if;

	end process BUFFER_PROC;

	-- set current pixel to start of pipeline
	s_kernel_matrix(s_kernel_matrix'low)(s_kernel_matrix'low) <= s_current_pixel;

	-- Map full signal of last FIFO to full delay line
	s_full_delay(s_full_delay'low) <= s_line_buffer_wr_en(s_line_buffer_wr_en'high);

	-- only kernel_size - 1 many line_buffer need to be created

	LINE_BUFFER_GEN : for j in 0 to kernel_size - 2 generate

		LINE_BUFF : entity work.line_buffer
			generic map (
				vector_length => vector_length,
				-- ung-bunga -1 to solve the timing problem
				-- (I don't think you can solve this differently with BRAM blocks and without considerable amount of HW)
				depth => input_width - 1
			)
			port map (
				clk                 => clk,
				reset               => reset,
				wr_en               => s_line_buffer_wr_en(j),
				full                => open,
				full_read_and_write => s_line_buffer_wr_en(j + 1),
				din                 => s_kernel_matrix(s_kernel_matrix'low)(j),
				dout                => s_kernel_matrix(s_kernel_matrix'low)(j + 1)
			);

	end generate LINE_BUFFER_GEN;

	-- Set outputs
	kernel_activation_matrix <= s_kernel_matrix(s_kernel_matrix'low + 1 to s_kernel_matrix'high);
	kernel_en                <= '1' when s_full_delay(s_full_delay'high) = '1' and (s_line_x < input_width - kernel_size + 1) else '0';
	kernel_complete          <= s_kernel_complete;

end architecture rtl;
