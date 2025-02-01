library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;
use work.libmemory.all;

entity conv_weight_memory is
	generic (
		vector_length        : natural := 8;
		input_amount          : natural := 25;
		total_input_channel  : natural := 1;
		total_output_channel : natural := 6;
		current_channel      : natural := 1;
		--! 0 == for one out_chan all in_chan are written; 1 == for one in_chan all out_chan are written
		init_type : integer range 0 to 1 := 0;
		data_path : string               := "../data/test.data"
	);
	port (
		clk           : in std_logic;
		reset         : in std_logic;
		base_addr     : in std_logic_vector(input_amount * total_input_channel ** (1 - init_type) * total_output_channel ** (init_type) - 1 downto 0);
		mem_valid     : out std_logic;
		weight_matrix : out matrix_1d(0 to input_amount - 1)(vector_length - 1 downto 0)
	);
end entity conv_weight_memory;

architecture rtl of conv_weight_memory is

	-- This function initializes the memory depending on the init_type
	-- Uses the read functionalities of libmemory

	impure function init_memory (
		file_name : in string;
		depth : in natural
	) return matrix_1d is

		variable tmp_memory : matrix_1d(0 to depth - 1)(vector_length - 1 downto 0);

	begin

		if init_type = 0 then
			tmp_memory := read_output_channel(file_name, vector_length, input_amount, total_input_channel, total_output_channel, current_channel);
		else
			tmp_memory := read_input_channel(file_name, vector_length, input_amount, total_input_channel, total_output_channel, current_channel);
		end if;

		return tmp_memory;

	end function init_memory;

	-- Depth is purely dependent on the init type
	constant depth : natural := input_amount * total_input_channel ** (1 - init_type) * total_output_channel ** (init_type);

	signal s_old_addr      : unsigned(depth - 1 downto 0);
	signal s_addr          : unsigned(depth - 1 downto 0);
	signal s_base_addr     : unsigned(depth - 1 downto 0);
	signal s_actual_addr   : std_logic_vector(depth - 1 downto 0);
	signal s_weight_matrix : matrix_1d(0 to input_amount - 1)(vector_length - 1 downto 0);

	signal s_dout      : std_logic_vector(vector_length - 1 downto 0);
	signal s_mem_valid : std_logic;

begin

	RESET_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_base_addr     <= unsigned(base_addr);
				s_old_addr      <= (others => '0');
				s_addr          <= (others => '0');
				s_weight_matrix <= (others => (others => '0'));
				s_mem_valid     <= '0';
			else
				s_old_addr                              <= s_addr;
				s_addr                                  <= s_addr + 1 when s_addr < input_amount - 1 else s_addr;
				s_weight_matrix(to_integer(s_old_addr)) <= s_dout;
				if s_old_addr >= input_amount - 1 then
					s_mem_valid <= '1';
				end if;
			end if;
		end if;

	end process RESET_PROC;

	s_actual_addr <= std_logic_vector(s_base_addr + s_addr);
	mem_valid     <= s_mem_valid;

	BRAM_ENT : entity work.bram_single_port
		generic map (
			vector_length => vector_length,
			depth         => depth,
			data          => init_memory(data_path, depth)
		)
		port map (
			clk   => clk,
			rd_en => not s_mem_valid,
			wr_en => '0',
			addr  => s_actual_addr,
			din   => (others => '0'),
			dout  => s_dout
		);

	-- Mapping of output values

	weight_matrix <= s_weight_matrix;

end architecture rtl;
