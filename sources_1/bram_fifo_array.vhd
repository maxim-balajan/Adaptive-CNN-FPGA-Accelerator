library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity bram_fifo_array is
	generic (
		G_DATA_BYTE_WIDTH        : integer range 1 to 128 := 16;
		G_BRAM_BYTE_WIDTH        : integer range 1 to 128 := 1;
		G_MAX_DEPTH              : natural                := 512;
		G_NEAR_FULL_THRESHOLD    : natural                := 0;
		G_NEAR_EMPTY_THRESHOLD   : natural                := 1;
		G_NEAR_EMPTY_THRESHOLD_2 : natural                := 2
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		--
		i_input_stream : in std_logic_vector(G_DATA_BYTE_WIDTH * 8 - 1 downto 0);
		i_wr_en        : in std_logic_vector(G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);
		i_rd_en        : in std_logic_vector(G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);
		--
		o_output_stream  : out std_logic_vector(G_DATA_BYTE_WIDTH * 8 - 1 downto 0);
		o_full           : out std_logic_vector(G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);
		o_nearly_full    : out std_logic_vector(G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);
		o_empty          : out std_logic_vector(G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);
		o_nearly_empty   : out std_logic_vector(G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0);
		o_nearly_empty_2 : out std_logic_vector(G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 downto 0)
	);
end entity bram_fifo_array;

architecture rtl of bram_fifo_array is

	impure function f_is_power_of_two (
		N : natural
	) return integer is

		variable temp : natural := N;

	begin

		if N = 0 then
			return 0;
		end if;

		while temp > 1 loop

			if temp mod 2 /= 0 then
				return 0;
			end if;

			temp := temp / 2;

		end loop;

		return 1;

	end function f_is_power_of_two;

	constant C_DEPTH : std_logic_vector := std_logic_vector(to_unsigned(G_MAX_DEPTH, f_is_power_of_two(G_MAX_DEPTH) + integer(ceil(log2(real(G_MAX_DEPTH))))));

begin

	assert G_DATA_BYTE_WIDTH mod G_BRAM_BYTE_WIDTH = 0
		report "G_DATA_BYTE_WIDTH needs to be a multiple of G_BRAM_BYTE_WIDTH!"
		severity FAILURE;

	BRAM_GEN : for i in 0 to G_DATA_BYTE_WIDTH / G_BRAM_BYTE_WIDTH - 1 generate

		bram_fifo_inst : entity work.bram_fifo
			generic map (
				vector_length          => G_BRAM_BYTE_WIDTH * 8,
				G_MAX_DEPTH            => to_integer(unsigned(C_DEPTH)) + f_is_power_of_two(G_MAX_DEPTH),
				G_NEAR_FULL_THRESHOLD  => G_NEAR_FULL_THRESHOLD,
				G_NEAR_EMPTY_THRESHOLD => G_NEAR_EMPTY_THRESHOLD
			)
			port map (
				clk   => clk,
				reset => reset,
				--
				set_full => '0',
				depth    => C_DEPTH,
				--
				din   => i_input_stream((i + 1) * (G_BRAM_BYTE_WIDTH * 8) - 1 downto i * (G_BRAM_BYTE_WIDTH * 8)),
				wr_en => i_wr_en(i),
				rd_en => i_rd_en(i),
				--
				dout       => o_output_stream((i + 1) * (G_BRAM_BYTE_WIDTH * 8) - 1 downto i * (G_BRAM_BYTE_WIDTH * 8)),
				near_full  => o_nearly_full(i),
				near_empty => o_nearly_empty(i),
				near_empty_2 => o_nearly_empty_2(i),
				full       => o_full(i),
				empty      => o_empty(i)
			);

	end generate BRAM_GEN;

end architecture rtl;
