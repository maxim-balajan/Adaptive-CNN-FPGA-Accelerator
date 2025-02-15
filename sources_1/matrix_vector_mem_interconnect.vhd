library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;
use work.libmemory.all;
use work.libutil.all;

entity matrix_vector_mem_interconnect is
	generic (
		vector_length : natural := 8;
		--! max_weight_{width | height} \geq max(weight_{widths | heights}), otherwise code could break
		max_weight_width  : natural := 400;
		max_weight_height : natural := 120;
		--! len(weight_widths) == len(weight_heights) == len(weight_paths), otherwise code could break
		weight_widths  : int_list    := (400, 120, 84);
		weight_heights : int_list    := (120, 84, 10);
		weight_paths   : string_list := ("../data/layer_weight_2.data",
										 "../data/layer_weight_3.data",
										 "../data/layer_weight_4.data")
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

		variable tmp_ram         : matrix_1d(0 to sum_int_list(weight_widths) - 1)(vector_length - 1 downto 0);
		variable individual_rams : matrix_2d(0 to weight_paths'length - 1)(0 to max_weight_width - 1)(vector_length - 1 downto 0);
		variable tmp_length      : natural;
		variable old_tmp_length  : natural;

	begin

		-- Get individual RAM values for all layers
		for i in individual_rams'range loop

			individual_rams(i)(0 to weight_widths(i) - 1) := read_weight_row(weight_paths(i),
	                                                                 vector_length, weight_heights(i), weight_widths(i), curr_row);

		end loop;

		-- Concat all individual RAM lists into tmp_ram
		tmp_length                   := weight_widths(weight_widths'low);
		tmp_ram(0 to tmp_length - 1) := individual_rams(individual_rams'low)(0 to tmp_length - 1);
		old_tmp_length               := tmp_length;

		for i in 1 to individual_rams'length - 1 loop

			tmp_length                   := tmp_length + weight_widths(i);
			tmp_ram(0 to tmp_length - 1) := concat_matrix1d(tmp_ram(0 to old_tmp_length - 1), individual_rams(i)(0 to weight_widths(i) - 1));
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
				addr_line                <= (others => (others => '0'));
				addr_line(addr_line'low) <= base_addr;
			else
				-- Set start of enable pipeline
				if bram_enable_line(bram_enable_line'low) = '1' then
					-- This is to prevent OOB errors
					if unsigned(addr_line(addr_line'low)) >= max_weight_width then
						addr_line(addr_line'low) <= (others => '0');
					else
						addr_line(addr_line'low) <= std_logic_vector(unsigned(addr_line(addr_line'low)) + 1);
					end if;
				end if;
				-- Shift values
				addr_line(addr_line'low + 1 to addr_line'high) <= addr_line(addr_line'low to addr_line'high - 1);
			end if;
		end if;

	end process ADDR_PROC;

	BRAM_GEN : for i in 0 to max_weight_height - 1 generate

		BRAM_INST : entity work.bram_single_port
			generic map (
				vector_length => vector_length,
				depth         => sum_int_list(weight_widths),
				data          => get_BRAM_data(i + 1)
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
