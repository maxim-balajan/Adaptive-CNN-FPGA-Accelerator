library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;
use std.env.finish;

entity generic_slider_tb is
end entity generic_slider_tb;

architecture bench of generic_slider_tb is

	-- Clock period
	constant clk_period : time := 10 ns;
	-- Generics
	constant vector_length     : integer := 16;
	constant G_IMG_MAX_LENGTH  : integer := 20;
	constant G_KERNEL_MAX_SIZE : natural := 11;
	constant c_padding         : natural := 2;
	constant c_input_size      : natural := 13;
	-- Ports
	signal clk                          : std_logic                                    := '1';
	signal reset                        : std_logic;
	signal pixel_stream, s_pixel_stream : std_logic_vector(vector_length - 1 downto 0) := (others => '0');
	signal kernel_comp                  : std_logic;
	signal kernel_en                    : std_logic;
	signal kernel_activation_matrix     : matrix_1d(0 to G_KERNEL_MAX_SIZE ** 2 - 1)(vector_length - 1 downto 0);
	signal valid_pixel                  : std_logic;
	signal kernel_size                  : std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
	signal input_image_length           : std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
	signal output_image_length          : std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
	signal padding_size                 : std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
	signal stride_bit_mask              : std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);

begin

	gen_slider_inst : entity work.generic_slider
		generic map (
			vector_length     => vector_length,
			G_IMG_MAX_LENGTH  => G_IMG_MAX_LENGTH,
			G_KERNEL_MAX_SIZE => G_KERNEL_MAX_SIZE
		)
		port map (
			clk   => clk,
			reset => reset,
			--
			pixel_stream => pixel_stream,
			valid_pixel  => valid_pixel,
			--
			kernel_size         => kernel_size,
			input_image_length  => input_image_length,
			output_image_length => output_image_length,
			padding_size        => padding_size,
			stride_bit_mask     => stride_bit_mask,
			--
			kernel_complete          => kernel_comp,
			kernel_en                => kernel_en,
			kernel_activation_matrix => kernel_activation_matrix
		);

	clk <= not clk after clk_period / 2;

	RESET_PROC : process is
	begin

		reset               <= '1';
		input_image_length  <= std_logic_vector(to_unsigned(c_input_size, input_image_length'length));
		kernel_size         <= std_logic_vector(to_unsigned(5, kernel_size'length));
		output_image_length <= std_logic_vector(to_unsigned((c_input_size + 2 * c_padding - 5) / 2 + 1, output_image_length'length));
		padding_size        <= std_logic_vector(to_unsigned(c_padding, padding_size'length));
		stride_bit_mask     <= std_logic_vector(to_unsigned(1, stride_bit_mask'length));
		wait for clk_period;
		reset               <= '0';
		wait;

	end process RESET_PROC;

	PIXEL_STREAM_PROC : process is
	begin

		pixel_stream <= (others => '0');
		valid_pixel  <= '0';
		wait for clk_period;

		for j in 0 to c_input_size + 1 loop

			valid_pixel  <= '1';
			pixel_stream <= (others => '0');
			wait for c_padding * clk_period;

			for i in 0 to c_input_size - 1 loop

				s_pixel_stream <= std_logic_vector(signed(s_pixel_stream) + 1);
				pixel_stream   <= std_logic_vector(signed(s_pixel_stream) + 1);
				valid_pixel    <= '1';
				wait for clk_period;
				pixel_stream   <= (others => '1');
				valid_pixel    <= '0';
				wait for 2 * clk_period;

			end loop;

			valid_pixel  <= '1';
			pixel_stream <= (others => '0');
			wait for c_padding * clk_period;

		end loop;

	end process PIXEL_STREAM_PROC;

	TB : process (kernel_comp) is
	begin

		if rising_edge(kernel_comp) then
			finish;
		end if;

	end process TB;

end architecture bench;
