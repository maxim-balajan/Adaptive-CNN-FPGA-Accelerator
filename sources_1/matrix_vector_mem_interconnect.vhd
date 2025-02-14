library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;
use work.libmemory.all;
use work.libutil.all;

entity matrix_vector_mem_interconnect is
	generic (
		max_weight_width  : natural  := 400;
		max_weight_height : natural  := 120;
		weight_widths     : int_list := (400, 120, 84);
		weight_heights    : int_list := (120, 84, 10);
		base_file_name    : string   := "../data/layer_weight_";
		first_layer_id    : natural  := 2;
		file_extension    : string   := ".data";
		vector_length     : natural  := 8
	);
	port (
		clk              : in std_logic;
		reset            : in std_logic;
		bram_enable_line : in std_logic_vector(0 to max_weight_height - 1);
		base_addr        : in std_logic_vector(integer(ceil(log2(real(sum_int_list(weight_widths))))) - 1 downto 0);
		weights          : out matrix_1d(0 to max_weight_height - 1)(vector_length - 1 downto 0)
	);
end entity matrix_vector_mem_interconnect;

architecture rtl of matrix_vector_mem_interconnect is

	signal addr_line : matrix_1d(0 to max_weight_height - 1)(integer(ceil(log2(real(sum_int_list(weight_widths))))) - 1 downto 0);

	-- This function reads the correct rows and concatenates them for later use in BRAM blocks

	impure function get_BRAM_data (
		curr_row : natural
	) return matrix_1d is

		variable tmp_ram         : matrix_1d(0 to sum_int_list(weight_widths))(vector_length - 1 downto 0);
		variable individual_rams : matrix_2d(0 to weight_widths'length - 1)(0 to max_weight_width)(vector_length - 1 downto 0);
		variable tmp_length      : natural;
		variable old_tmp_length  : natural;

	begin

		-- Get individual RAM values for all layers
		for i in individual_rams'range loop

			individual_rams(i) := read_weight_row(base_file_name & integer'image(first_layer_id + i) & file_extension,
	                                      vector_length, weight_heights(i), weight_widths(i), curr_row);

		end loop;

		-- Concat all individual RAM lists into tmp_ram
		tmp_length                   := weight_widths(weight_widths'low);
		tmp_ram(0 to tmp_length - 1) := individual_rams(individual_rams'low)(0 to tmp_length - 1);
		old_tmp_length               := tmp_length;

		for i in 1 to individual_rams'length - 1 loop

			tmp_length                   := tmp_length + weight_widths(i);
			tmp_ram(0 to tmp_length - 1) := concat_matrix1d(tmp_ram(0 to old_tmp_length - 1), individual_rams(i));
			old_tmp_length               := tmp_length;

		end loop;

		return tmp_ram;

	end function get_BRAM_data;

begin

    -- This process sets the base addr and also shifts all values through the chained registers
	ADDR_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				addr_line(addr_line'low) <= base_addr;

				for i in addr_line'low + 1 to addr_line'high loop

					addr_line(i) <= (others => '0');

				end loop;

			else
				addr_line(addr_line'low) <= std_logic_vector(unsigned(addr_line(addr_line'low)) + 1) when bram_enable_line(bram_enable_line'low) = '1' else addr_line(addr_line'low);

				for i in addr_line'low + 1 to addr_line'high loop

					addr_line(i) <= addr_line(i - 1);

				end loop;

			end if;
		end if;

	end process ADDR_PROC;

	BRAM_GEN : for i in 0 to max_weight_height - 1 generate

		BRAM_INST : entity work.bram_single_port
			generic map (
				vector_length => vector_length,
				depth         => sum_int_list(weight_widths),
				data          => get_BRAM_data(i)
			)
			port map (
				clk   => clk,
				rd_en => bram_enable_line(i),
				wr_en => '0',
				addr  => addr_line(i),
				din   => (others => '0'),
				dout  => weights(i)
			);

	end generate BRAM_GEN;

end architecture rtl;
