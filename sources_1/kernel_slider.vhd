library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity kernel_slider is
	generic (
		vector_length : integer := 8;
		input_width   : integer := 32;
		kernel_size   : integer := 5
	);
	port (
		clk                      : in std_logic;
		reset                    : in std_logic;
		en                       : in std_logic;
		pixel_stream             : in std_logic_vector(vector_length - 1 downto 0);
		init_complete            : out std_logic;
		kernel_activation_matrix : out matrix_2d(0 to kernel_size - 1)(0 to kernel_size - 1)(vector_length - 1 downto 0)
	);
end entity kernel_slider;

architecture rtl of kernel_slider is

	-- "Kernel matrix" + 1 because we have to take inputs into consideration
	signal s_kernel_matrix : matrix_2d(0 to kernel_size)(0 to kernel_size - 1)(vector_length - 1 downto 0);
	-- Line Buffer wr_en line
	signal s_line_buffer_wr_en : std_logic_vector(0 to kernel_size - 1);

	-- Helper signal to dertermine when initialization of pipeline is finished
	signal s_full_delay : std_logic_vector(0 to kernel_size);

begin

	-- This process sifts all control values and all kernel values through the pipeline

	BUFFER_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				-- Is set to one because initial buffer should always write
				s_line_buffer_wr_en(s_line_buffer_wr_en'low) <= '1';
			elsif en = '1' then
				-- Shift values through kernel window
				s_kernel_matrix(s_kernel_matrix'low + 1 to s_kernel_matrix'high) <= s_kernel_matrix(s_kernel_matrix'low to s_kernel_matrix'high - 1);

				-- Shift full delay line by one
				s_full_delay(s_full_delay'low + 1 to s_full_delay'high) <= s_full_delay(s_full_delay'low to s_full_delay'high - 1);
			end if;
		end if;

	end process BUFFER_PROC;

	-- set current pixel to start of pipeline
	s_kernel_matrix(s_kernel_matrix'low)(s_kernel_matrix'low) <= pixel_stream;

	-- Map full signal of last FIFO to full delay line
	s_full_delay(s_full_delay'low) <= s_line_buffer_wr_en(s_line_buffer_wr_en'high);

	-- only kernel_size - 1 many line_buffer need to be created

	LINE_BUFFER_GEN : for j in 0 to kernel_size - 2 generate

		LINE_BUFF : entity work.line_buffer
			generic map (
				vector_length => vector_length,
				-- unga-bunga -1 to solve the timing problem
				-- (I don't think you can solve this differently with BRAM blocks and without considerable amount of HW)
				depth => input_width - 1
			)
			port map (
				clk                 => clk,
				reset               => reset,
				en                  => en,
				wr_en               => s_line_buffer_wr_en(j),
				full                => open,
				full_read_and_write => s_line_buffer_wr_en(j + 1),
				din                 => s_kernel_matrix(s_kernel_matrix'low)(j),
				dout                => s_kernel_matrix(s_kernel_matrix'low)(j + 1)
			);

	end generate LINE_BUFFER_GEN;

	-- Set outputs
	kernel_activation_matrix <= s_kernel_matrix(s_kernel_matrix'low + 1 to s_kernel_matrix'high);
	-- This is important so that Pooling and Convolution know when they have valid kernel
	init_complete <= s_full_delay(s_full_delay'high);

end architecture rtl;
