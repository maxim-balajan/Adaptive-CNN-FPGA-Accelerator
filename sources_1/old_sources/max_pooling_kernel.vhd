
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.libmatrix.all;

entity max_pooling_kernel is
	generic (
		number_width : natural := 8;
		width        : natural := 2;
		height       : natural := 2;
		--! kernel_size is required to be square
		kernel_size : natural := 2;
		x           : natural;
		y           : natural
	);
	port (
		clk      : in std_logic;
		reset    : in std_logic;
		en       : in std_logic;
		input    : in matrix_2d(0 to width - 1)(0 to height - 1)(number_width - 1 downto 0);
		output   : out std_logic_vector(number_width - 1 downto 0);
		finished : out std_logic
	);
end entity max_pooling_kernel;

architecture Behavioral of max_pooling_kernel is

	signal s_finished         : std_logic_vector(0 to kernel_size * kernel_size - 1);
	signal s_intermediate_res : matrix_2d(0 to kernel_size - 1)(0 to kernel_size - 1)(number_width - 1 downto 0);

begin

	gen_outputs4 : for off_x in kernel_size - 1 downto 0 generate

		gen_outputs5 : for off_y in kernel_size - 1 downto 0 generate

			gen1 : if off_x /= kernel_size - 1 or off_y /= kernel_size - 1 generate
				-- okay this is not the first entry in the area we are looking at
				-- this means we need to combine the current element an a previous one
				-- question: which previous element do we need to combine now?

				gen2 : if off_y = kernel_size - 1 generate
					-- combine with the element from the previous column
					max_pooling_max_unit_inst : entity work.max_pooling_max_unit
						generic map (
							number_width => number_width
						)
						port map (
							clk   => clk,
							reset => reset,

							input1_en => s_finished((off_x + 1) * kernel_size + 0),
							input1    => s_intermediate_res(off_x + 1)(0),

							input2_en => en,
							input2    => input(x * kernel_size + off_x)(y * kernel_size + off_y),

							output   => s_intermediate_res(off_x)(off_y),
							finished => s_finished(off_x * kernel_size + off_y)
						);

				else generate
					-- combine with the element from the current column
					max_pooling_max_unit_inst : entity work.max_pooling_max_unit
						generic map (
							number_width => number_width
						)
						port map (
							clk   => clk,
							reset => reset,

							input1_en => s_finished(off_x * kernel_size + off_y + 1),
							input1    => s_intermediate_res(off_x)(off_y + 1),

							input2_en => en,
							input2    => input(x * kernel_size + off_x)(y * kernel_size + off_y),

							output   => s_intermediate_res(off_x)(off_y),
							finished => s_finished(off_x * kernel_size + off_y)
						);

				end generate gen2;

			else generate
				s_intermediate_res(off_x)(off_y)        <= input(x * kernel_size + off_x)(y * kernel_size + off_y);
				s_finished(off_x * kernel_size + off_y) <= en;
			end generate gen1;

		end generate gen_outputs5;

	end generate gen_outputs4;

	finished <= s_finished(0);
	output   <= s_intermediate_res(0)(0);

end architecture Behavioral;
