library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;
use std.env.finish;

entity configurable_slider_tb is
end entity configurable_slider_tb;

architecture bench of configurable_slider_tb is

	-- Clock period
	constant clk_period : time := 10 ns;
	-- Generics
	constant vector_length        : natural   := 16;
	constant G_IMG_MAX_LENGTH     : natural   := 20;
	constant G_KERNEL_SIZE        : natural   := 5;
	constant G_MAX_KERNEL_SIZE    : natural   := 12;
	constant G_LINE_BUFFER_AMOUNT : natural   := 15;
	constant G_PIPELINE_STEPS     : natural   := 2;
	constant G_DEBUG_FLAG         : std_logic := '1';
	constant c_padding            : natural   := 2;
	constant c_input_size         : natural   := 10;
	-- Ports
	signal clk                      : std_logic                                    := '0';
	signal reset                    : std_logic;
	signal valid_pixel_streams      : std_logic;
	signal s_pixel_stream           : std_logic_vector(vector_length - 1 downto 0) := (others => '0');
	signal pixel_streams            : matrix_1d(0 to G_LINE_BUFFER_AMOUNT - 1)(vector_length - 1 downto 0);
	signal input_image_length       : std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
	signal output_image_length      : std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
	signal kernel_size              : std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
	signal padding_size             : std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
	signal stride_bit_mask          : std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
	signal kernel_complete          : std_logic;
	signal kernel_en                : std_logic;
	signal kernel_activation_matrix : matrix_1d(0 to G_MAX_KERNEL_SIZE * G_LINE_BUFFER_AMOUNT - 1)(vector_length - 1 downto 0);

begin

	configurable_slider_inst : entity work.configurable_slider
		generic map (
			vector_length        => vector_length,
			G_IMG_MAX_LENGTH     => G_IMG_MAX_LENGTH,
			G_KERNEL_SIZE        => G_KERNEL_SIZE,
			G_PADDING_SIZE       => c_padding,
			G_MAX_KERNEL_SIZE    => G_MAX_KERNEL_SIZE,
			G_LINE_BUFFER_AMOUNT => G_LINE_BUFFER_AMOUNT,
			G_PIPELINE_STEPS     => G_PIPELINE_STEPS,
			G_DEBUG_FLAG         => G_DEBUG_FLAG
		)
		port map (
			clk                      => clk,
			reset                    => reset,
			valid_pixel_streams      => valid_pixel_streams,
			pixel_streams            => pixel_streams,
			input_image_length       => input_image_length,
			output_image_length      => output_image_length,
			kernel_size              => kernel_size,
			padding_size             => padding_size,
			stride_bit_mask          => stride_bit_mask,
			kernel_complete          => kernel_complete,
			kernel_en                => kernel_en,
			kernel_activation_matrix => kernel_activation_matrix
		);

	clk <= not clk after clk_period / 2;

	RESET_PROC : process is
	begin

		reset               <= '1';
		input_image_length  <= std_logic_vector(to_unsigned(c_input_size, input_image_length'length));
		kernel_size         <= std_logic_vector(to_unsigned(G_KERNEL_SIZE, kernel_size'length));
		output_image_length <= std_logic_vector(to_unsigned((c_input_size + 2 * c_padding - G_KERNEL_SIZE) / 2 + 1, output_image_length'length));
		padding_size        <= std_logic_vector(to_unsigned(c_padding, padding_size'length));
		stride_bit_mask     <= std_logic_vector(to_unsigned(1, stride_bit_mask'length));
		wait for clk_period;
		reset               <= '0';
		wait until rising_edge(kernel_complete) for 5000 * clk_period;
		reset <= '1';
		wait for 1.5 * clk_period;
		reset <= '0';
		wait;

	end process RESET_PROC;

	PIXEL_STREAM_PROC : process is
	begin

		pixel_streams       <= (others => (others => '0'));
		valid_pixel_streams <= '0';
		wait for clk_period;

		for j in 0 to c_input_size + 1 loop

			valid_pixel_streams <= '1';
			pixel_streams       <= (others => (others => '0'));
			wait for c_padding * clk_period;

			for i in 0 to c_input_size - 1 loop

				s_pixel_stream      <= std_logic_vector(signed(s_pixel_stream) + 1);
				pixel_streams       <= (others => std_logic_vector(signed(s_pixel_stream) + 1));
				valid_pixel_streams <= '1';
				wait for clk_period;
				pixel_streams       <= (others => (others => '1'));
				valid_pixel_streams <= '0';
				wait for 2 * clk_period;

			end loop;

			valid_pixel_streams <= '1';
			pixel_streams       <= (others => (others => '0'));
			wait for c_padding * clk_period;

		end loop;

	end process PIXEL_STREAM_PROC;

	TB : process is
	begin

		wait until rising_edge(kernel_complete) for 5000 * clk_period;
		assert kernel_complete = '1'
			report "Kernel Complete was not set in time after 50us! Aborting further simulation..."
			severity FAILURE;
		wait until rising_edge(kernel_complete) for 5000 * clk_period;
			assert kernel_complete = '1'
				report "Kernel Complete was not set in time after 50us! Aborting further simulation..."
				severity FAILURE;
		finish;

	end process TB;

end architecture bench;
