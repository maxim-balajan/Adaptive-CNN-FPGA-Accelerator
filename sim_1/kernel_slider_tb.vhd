
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.MATH_REAL.all;
use work.libmatrix.all;
use std.env.finish;

entity kernel_slider_tb is
end entity kernel_slider_tb;

architecture bench of kernel_slider_tb is

	-- Clock period
	constant clk_period : time := 5 ns;
	-- Generics
	constant vector_length     : natural := 8;
	constant G_IMG_MAX_LENGTH  : natural := 16;
	constant G_KERNEL_MAX_SIZE : natural := 7;
	constant kernel_size       : natural := 5;
	-- Ports
	signal clk   : std_logic := '0';
	signal reset : std_logic;
	signal en    : std_logic;

	signal s_pixel_stream, pixel_stream : std_logic_vector(vector_length - 1 downto 0) := (others => '0');
	signal image_length                 : std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
	signal padding_size                 : std_logic_vector(integer(ceil(log2(real(G_IMG_MAX_LENGTH)))) - 1 downto 0);
	signal init_complete                : std_logic;
	signal kernel_activation_matrix     : matrix_1d(0 to G_KERNEL_MAX_SIZE ** 2 - 1)(vector_length - 1 downto 0);

begin

	kernel_slider_inst : entity work.kernel_slider
		generic map (
			vector_length     => vector_length,
			G_IMG_MAX_LENGTH  => G_IMG_MAX_LENGTH,
			G_KERNEL_MAX_SIZE => G_KERNEL_MAX_SIZE,
			kernel_size       => kernel_size
		)
		port map (
			clk                      => clk,
			reset                    => reset,
			en                       => en,
			pixel_stream             => pixel_stream,
			image_length             => image_length,
			padding_size             => padding_size,
			init_complete            => init_complete,
			kernel_activation_matrix => kernel_activation_matrix
		);

	clk <= not clk after clk_period / 2;

	process is
	begin

		reset        <= '1';
		image_length <= std_logic_vector(to_unsigned(12, image_length'length));
		padding_size <= std_logic_vector(to_unsigned(2, image_length'length));
		wait for clk_period;
		reset        <= '0';
		wait for 256 * clk_period;

	end process;

	process is
	begin

		pixel_stream <= (others => '0');
		en           <= '0';
		wait for clk_period;

		for j in 0 to 12 + 1 loop

			en           <= '1';
			pixel_stream <= (others => '0');
			wait for 2 * clk_period;

			for i in 0 to 12 - 1 loop

				s_pixel_stream <= std_logic_vector(signed(s_pixel_stream) + 1);
				pixel_stream   <= std_logic_vector(signed(s_pixel_stream) + 1);
				en             <= '1';
				wait for clk_period;
				pixel_stream   <= (others => '1');
				en             <= '0';
				wait for 2 * clk_period;

			end loop;

			en           <= '1';
			pixel_stream <= (others => '0');
			wait for 2 * clk_period;

		end loop;

	end process;

	CHECK_PROC : process (clk, init_complete) is
	begin

		if rising_edge(clk) and init_complete = '1' then
			assert kernel_activation_matrix(0 to 4) = (x"00", x"00", x"00", x"00", x"00")
				report "First row should be (0, 0, 0, 0, 0), got something else instead!"
				severity FAILURE;
			assert kernel_activation_matrix(7 to 11) = (x"00", x"00", x"00", x"00", x"00")
				report "Second row should be (0, 0, 0, 0, 0), got something else instead!"
				severity FAILURE;
			assert kernel_activation_matrix(14 to 18) = (x"00", x"00", x"01", x"02", x"03")
				report "Third row should be (0, 0, 0, 0, 0), got something else instead!"
				severity FAILURE;
			assert kernel_activation_matrix(21 to 25) = (x"00", x"00", x"0d", x"0e", x"0f")
				report "Forth row should be (0, 0, 0, 0, 0), got something else instead!"
				severity FAILURE;
			assert kernel_activation_matrix(28 to 32) = (x"00", x"00", x"19", x"1a", x"1b")
				report "Fifth row should be (0, 0, 0, 0, 0), got something else instead!"
				severity FAILURE;
			
			report "Correct initial window was received!";

			finish;
		end if;

	end process CHECK_PROC;


end architecture bench;
