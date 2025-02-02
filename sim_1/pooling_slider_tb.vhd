library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;
use std.env.finish;

entity pooling_slider_tb is
end entity pooling_slider_tb;

architecture bench of pooling_slider_tb is

	-- Clock period
	constant clk_period : time := 10 ns;
	-- Generics
	constant vector_length         : integer := 32;
	constant original_input_width  : integer := 14;
	constant original_input_height : integer := 14;
	constant kernel_size           : integer := 5;
	constant pooling_size          : integer := 2;
	-- Ports
	signal clk                      : std_logic := '0';
	signal reset                    : std_logic;
	signal pixel_stream             : std_logic_vector(vector_length - 1 downto 0);
	signal valid_pixel              : std_logic;
	signal kernel_complete          : std_logic;
	signal kernel_en                : std_logic;
	signal kernel_activation_matrix : matrix_1d(0 to pooling_size**2 - 1)(vector_length - 1 downto 0);
	signal pixel_x                  : std_logic_vector(integer(ceil(log2(real(original_input_width - kernel_size + 1) / 2.0))) - 1 downto 0);
	signal pixel_y                  : std_logic_vector(integer(ceil(log2(real(original_input_height - kernel_size + 1) / 2.0))) downto 0);

begin

	pooling_slider_inst : entity work.pooling_slider
		generic map (
			vector_length         => vector_length,
			original_input_width  => original_input_width,
			original_input_height => original_input_height,
			kernel_size           => kernel_size,
			pooling_size          => 2
		)
		port map (
			clk                      => clk,
			reset                    => reset,
			pixel_stream             => pixel_stream,
			valid_pixel              => valid_pixel,
			kernel_complete          => kernel_complete,
			kernel_en                => kernel_en,
			kernel_activation_matrix => kernel_activation_matrix
		);

	clk   <= not clk after clk_period / 2;
	reset <= '1' after 0 ns, '0' after 2 * clk_period;

	PIXEL_STREAM_PROC : process is
	begin

		wait for 2 * clk_period;

		y : for j in 0 to original_input_height - kernel_size loop

			x : for i in 0 to original_input_width - kernel_size loop

				-- Check legal pixels
				pixel_stream <= std_logic_vector(to_unsigned(i + (original_input_width - kernel_size + 1) * j + 1, pixel_stream'length));
				valid_pixel  <= '1';
				wait for clk_period;
				if i mod 3 = 0 then
					-- Check that illegal pixels are not pipelined
					pixel_stream <= (others => '1');
					valid_pixel  <= '0';
					-- wait for clk_period;
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
