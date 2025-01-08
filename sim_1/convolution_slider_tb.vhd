library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.libmatrix.all;
use std.env.finish;

entity convolution_slider_tb is
end entity convolution_slider_tb;

architecture bench of convolution_slider_tb is

	-- Clock period
	constant clk_period : time := 10 ns;
	-- Generics
	constant vector_length : integer := 16;
	constant input_width   : integer := 10;
	constant input_height  : integer := 10;
	constant kernel_size   : integer := 5;
	-- Ports
	signal clk                      : std_logic := '1';
	signal reset                    : std_logic;
	signal pixel_stream             : std_logic_vector(vector_length - 1 downto 0);
	signal kernel_comp              : std_logic;
	signal kernel_en                : std_logic;
	signal kernel_activation_matrix : matrix_2d(0 to kernel_size - 1)(0 to kernel_size - 1)(vector_length - 1 downto 0);
	signal valid_pixel : std_logic;

begin

	conv_slider_inst : entity work.convolution_slider
		generic map (
			vector_length => vector_length,
			input_width   => input_width,
			input_height  => input_height,
			kernel_size   => kernel_size
		)
		port map (
			clk                      => clk,
			reset                    => reset,
			pixel_stream             => pixel_stream,
			valid_pixel              => valid_pixel,
			kernel_complete          => kernel_comp,
			kernel_en                => kernel_en,
			kernel_activation_matrix => kernel_activation_matrix
		);

	clk   <= not clk after clk_period / 2;
	reset <= '1' after 0 ns, '0' after 2 * clk_period;

	PIXEL_STREAM_PROC : process is
	begin

		wait for 2 * clk_period;

		y : for j in 0 to input_height - 1 loop

			x : for i in 0 to input_width - 1 loop

				pixel_stream <= std_logic_vector(to_unsigned(i + input_width * j + 1, pixel_stream'length));
				valid_pixel <= '1';
				wait for clk_period;
				if i mod 3 = 0 then
					pixel_stream <= (others => '1');
					valid_pixel <= '0';
					wait for clk_period;
					wait for clk_period;
					wait for clk_period;
				end if;
			end loop x;

		end loop y;

	end process PIXEL_STREAM_PROC;

	TB : process is
	begin

		wait for 300 * clk_period;
		finish;

	end process TB;

end architecture bench;
