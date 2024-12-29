library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity convolution_slider is
	generic (
		vector_length : integer := 8;
		input_width   : integer := 32;
		input_height  : integer := 32;
		kernel_size   : integer := 5
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		-- Dynamic input slicing is very expensive (roughly 2000 LUTs for one conv_slider => not worth it)
		-- input_matrix             : in matrix_2d(0 to input_width - 1)(0 to input_height - 1)(vector_length - 1 downto 0);
		pixel_stream             : in std_logic_vector(vector_length - 1 downto 0);
		valid_pixel              : in std_logic;
		kernel_complete          : out std_logic;
		kernel_en                : out std_logic;
		kernel_activation_matrix : out matrix_2d(0 to kernel_size - 1)(0 to kernel_size - 1)(vector_length - 1 downto 0)
	);
end entity convolution_slider;

architecture rtl of convolution_slider is

	-- Values in order to retrieve pixels from input stream
	signal s_pixel_input_x : unsigned(integer(ceil(log2(real(input_width)))) - 1 downto 0);
	signal s_pixel_input_y : unsigned(integer(ceil(log2(real(input_height)))) downto 0);
	-- Current pixel to be pipelined
	signal s_current_pixel : std_logic_vector(vector_length - 1 downto 0);

	-- Helper signals to dertermine which kernels are valid and when computation needs to end
	signal s_line_x          : unsigned(integer(ceil(log2(real(input_width)))) - 1 downto 0);
	signal s_init_complete   : std_logic;
	signal s_kernel_complete : std_logic;

begin

	-- This process computes the current pixel (provided by a regfile for example)
	-- And also sets a few control signal wether the kernel provided is valid or if all pixels were processed

	GET_PIXEL_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_pixel_input_x   <= (others => '0');
				s_pixel_input_y   <= (others => '0');
				s_current_pixel   <= (others => '0');
				s_line_x          <= (others => '0');
				s_kernel_complete <= '0';
			elsif valid_pixel = '1' then
				-- Get current pixel
				-- And if s_pixel_input_y is OOB, then finish computation
				if s_pixel_input_y = input_height then
					s_pixel_input_y <= s_pixel_input_y;
					s_current_pixel <= (others => '0');
					-- set s_kernel_comp that needs to be delayed by one cycle before outputting
					s_kernel_complete <= '1';
				else
					-- s_current_pixel <= input_matrix(to_integer(s_pixel_input_x))(to_integer(s_pixel_input_y));
					s_current_pixel <= pixel_stream;
					s_pixel_input_x <= s_pixel_input_x + 1;
					if s_pixel_input_x = input_width - 1 then
						s_pixel_input_x <= (others => '0');
						s_pixel_input_y <= s_pixel_input_y + 1;
					end if;
					s_kernel_complete <= '0';
				end if;

				-- If init is finished, accumulate s_line_x
				if s_init_complete = '1' then
					s_line_x <= s_line_x + 1;
					if s_line_x = input_width - 1 then
						s_line_x <= (others => '0');
					end if;
				end if;
			end if;
		end if;

	end process GET_PIXEL_PROC;

	-- Instantiation of main component that gets all valid (and invalid) kernels

	KERNEL_SLIDER_INST : entity work.kernel_slider
		generic map (
			vector_length => vector_length,
			input_width   => input_width,
			kernel_size   => kernel_size
		)
		port map (
			clk                      => clk,
			reset                    => reset,
			en                       => valid_pixel,
			pixel_stream             => s_current_pixel,
			init_complete            => s_init_complete,
			kernel_activation_matrix => kernel_activation_matrix
		);

	-- These signals are important for the computation and pooling unit directly followed after this unit
	kernel_en       <= '1' when s_init_complete = '1' and (s_line_x < input_width - kernel_size + 1) else '0';
	kernel_complete <= s_kernel_complete;

end architecture rtl;
