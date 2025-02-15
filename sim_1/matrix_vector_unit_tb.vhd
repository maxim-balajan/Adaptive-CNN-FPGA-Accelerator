library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;
use std.env.finish;

entity matrix_vector_unit_tb is
end entity matrix_vector_unit_tb;

architecture bench of matrix_vector_unit_tb is

	-- Clock period
	constant clk_period : time := 10 ns;
	-- Generics
	constant weight_width  : integer := 400;
	constant weight_height : integer := 120;
	constant vector_length : integer := 8;
	-- Ports
	signal clk              : std_logic := '1';
	signal reset            : std_logic;
	signal en               : std_logic;
	signal weights          : matrix_1d(0 to weight_height - 1)(vector_length - 1 downto 0);
	signal input            : std_logic_vector(vector_length - 1 downto 0);
	signal bram_enable_line : std_logic_vector(0 to weight_height - 1);
	signal results          : matrix_1d(0 to weight_height - 1)(vector_length - 1 downto 0);
	signal comp_complete    : std_logic;

	constant c_actual_weight_width  : std_logic_vector(integer(ceil(log2(real(weight_width)))) downto 0)  := std_logic_vector(to_unsigned(5, integer(ceil(log2(real(weight_width)))) + 1));
	constant c_actual_weight_height : std_logic_vector(integer(ceil(log2(real(weight_height)))) downto 0) := std_logic_vector(to_unsigned(4, integer(ceil(log2(real(weight_height)))) + 1));

	constant c_input_delay_amount : integer := 3;
	signal   s_invalid_delay      : integer;

begin

	matrix_vector_unit_inst : entity work.matrix_vector_unit
		generic map (
			max_weight_width  => weight_width,
			max_weight_height => weight_height,
			vector_length     => vector_length,
			enable_shift      => 1
		)
		port map (
			clk                  => clk,
			reset                => reset,
			en                   => en,
			weights              => weights,
			actual_weight_width  => c_actual_weight_width,
			actual_weight_height => c_actual_weight_height,
			input                => input,
			shamt                => x"01",
			bram_enable_line     => bram_enable_line,
			results              => results,
			comp_complete        => comp_complete
		);

	clk   <= not clk after clk_period / 2;
	reset <= '1' after 0 ns, '0' after 2 * clk_period;

	INPUT_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				input           <= (others => '0');
				en              <= '0';
				s_invalid_delay <= 0;
			else
				if s_invalid_delay = 0 then
					if signed(input) >= signed(c_actual_weight_width) then
						en <= '0';
					else
						input <= std_logic_vector(signed(input) + 1);
						en    <= '1';
					end if;
				else
					en <= '0';
				end if;

				if s_invalid_delay /= c_input_delay_amount then
					s_invalid_delay <= s_invalid_delay + 1;
				else
					s_invalid_delay <= 0;
				end if;
			end if;
		end if;

	end process INPUT_PROC;

	WEIGHT_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then

				for i in 0 to  to_integer(unsigned(c_actual_weight_height)) - 1 loop

					weights(i) <= std_logic_vector(to_signed(i + 2, weights(i)'length));

				end loop;

				for i in to_integer(unsigned(c_actual_weight_height)) to weights'high loop

					weights(i) <= (others => '0');

				end loop;

			else

				for i in 0 to to_integer(unsigned(c_actual_weight_height)) - 1 loop

					if bram_enable_line(i) = '1' then
						weights(i) <= std_logic_vector(signed(weights(i)) + 1);
					end if;

				end loop;

			end if;
		end if;

	end process WEIGHT_PROC;

	TB : process is
	begin

		wait for 30 * clk_period;
		finish;

	end process TB;

end architecture bench;
