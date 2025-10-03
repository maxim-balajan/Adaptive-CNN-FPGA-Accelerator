library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.libmatrix.all;
use work.libutil.all;

entity adder_tree_gen_tb is
end entity adder_tree_gen_tb;

architecture bench of adder_tree_gen_tb is

	-- Clock period
	constant clk_period    : time    := 10 ns;
	constant c_wait_cycles : integer := 2;
	-- Generics
	-- Ports
	signal clk   : std_logic := '1';
	signal reset : std_logic;
	--
	signal i_en : std_logic := '0';
	--
	signal i_kernel_complete          : std_logic;
	signal i_kernel_en                : std_logic;
	signal i_kernel_activation_matrix : matrix_1d(0 to 5 * 10 - 1)(24 - 1 downto 0);
	signal i_kernel_weight_en         : std_logic := '0';
	signal i_kernel_weight_matrix     : matrix_1d(0 to 5 * 10 - 1)(24 - 1 downto 0);
	signal i_shamt_line               : matrix_1d(0 to 10 - 1)(24 - 1 downto 0) := (others => (others => '0') ) ;
	signal i_bias_line                : matrix_1d(0 to 10 - 1)(24 - 1 downto 0) := (others => (others => '0') ) ;
	signal o_kernel_complete          : std_logic;
	signal o_kernel_valid             : std_logic;
	signal o_pixel_line               : matrix_1d(0 to 3 - 1)(24 - 1 downto 0);

	constant c_results : int_list := (-31, -137);
	signal   c_id      : integer  := 0;

begin

	routed_kernel_cores_inst : entity work.routed_kernel_cores
		port map (
			clk                        => clk,
			reset                      => reset,
			i_en                       => i_en,
			i_kernel_complete          => i_kernel_complete,
			i_kernel_en                => i_kernel_en,
			i_kernel_activation_matrix => i_kernel_activation_matrix,
			i_kernel_weight_en         => i_kernel_weight_en,
			i_kernel_weight_matrix     => i_kernel_weight_matrix,
			i_shamt_line               => i_shamt_line,
			i_bias_line                => i_bias_line,
			o_kernel_complete          => o_kernel_complete,
			o_kernel_valid             => o_kernel_valid,
			o_pixel_line               => o_pixel_line
		);

	clk <= not clk after clk_period / 2;
	i_en <= not i_en after clk_period;

	INPUT_PROC : process is
	begin

		reset                      <= '1';
		i_kernel_complete          <= '0';
		i_kernel_en                <= '0';
		i_kernel_activation_matrix <= (others => (others => '0'));
		i_kernel_weight_matrix     <= (others => (others => '0'));
		wait for  2 * clk_period;
		reset                      <= '0';
		wait for clk_period;

		-- First Valid Kernel
		i_kernel_complete <= '0';
		i_kernel_en       <= '1';

		i_kernel_activation_matrix(0) <= std_logic_vector(to_signed(5, i_kernel_activation_matrix(0)'length));
		i_kernel_activation_matrix(1) <= std_logic_vector(to_signed(-3, i_kernel_activation_matrix(1)'length));
		i_kernel_activation_matrix(2) <= std_logic_vector(to_signed(7, i_kernel_activation_matrix(2)'length));
		i_kernel_activation_matrix(3) <= std_logic_vector(to_signed(0, i_kernel_activation_matrix(3)'length));
		i_kernel_activation_matrix(4) <= std_logic_vector(to_signed(-8, i_kernel_activation_matrix(4)'length));
		i_kernel_activation_matrix(5) <= std_logic_vector(to_signed(2, i_kernel_activation_matrix(5)'length));
		i_kernel_activation_matrix(6) <= std_logic_vector(to_signed(-1, i_kernel_activation_matrix(6)'length));
		i_kernel_activation_matrix(7) <= std_logic_vector(to_signed(9, i_kernel_activation_matrix(7)'length));
		i_kernel_activation_matrix(8) <= std_logic_vector(to_signed(-6, i_kernel_activation_matrix(8)'length));

		i_kernel_weight_matrix(0) <= std_logic_vector(to_signed(-2, i_kernel_weight_matrix(0)'length));
		i_kernel_weight_matrix(1) <= std_logic_vector(to_signed(6, i_kernel_weight_matrix(1)'length));
		i_kernel_weight_matrix(2) <= std_logic_vector(to_signed(-9, i_kernel_weight_matrix(2)'length));
		i_kernel_weight_matrix(3) <= std_logic_vector(to_signed(3, i_kernel_weight_matrix(3)'length));
		i_kernel_weight_matrix(4) <= std_logic_vector(to_signed(0, i_kernel_weight_matrix(4)'length));
		i_kernel_weight_matrix(5) <= std_logic_vector(to_signed(10, i_kernel_weight_matrix(5)'length));
		i_kernel_weight_matrix(6) <= std_logic_vector(to_signed(-7, i_kernel_weight_matrix(6)'length));
		i_kernel_weight_matrix(7) <= std_logic_vector(to_signed(1, i_kernel_weight_matrix(7)'length));
		i_kernel_weight_matrix(8) <= std_logic_vector(to_signed(-4, i_kernel_weight_matrix(8)'length));

		wait until rising_edge(i_en);
		--wait for clk_period;
		-- Invalid Kernels
		i_kernel_complete          <= '0';
		i_kernel_en                <= '0';
		i_kernel_activation_matrix <= (others => (others => '1'));
		i_kernel_weight_matrix     <= (others => (others => '1'));
		--wait for c_wait_cycles * clk_period;
		for i in 0 to c_wait_cycles loop
			wait until rising_edge(i_en);
		end loop;
		-- Second Valid Kernel
		i_kernel_complete <= '0';
		i_kernel_en       <= '1';
		-- i_kernel_weight_matrix assignments
		i_kernel_weight_matrix(0) <= std_logic_vector(to_signed(-4, i_kernel_weight_matrix(0)'length));
		i_kernel_weight_matrix(1) <= std_logic_vector(to_signed(10, i_kernel_weight_matrix(1)'length));
		i_kernel_weight_matrix(2) <= std_logic_vector(to_signed(3, i_kernel_weight_matrix(2)'length));
		i_kernel_weight_matrix(3) <= std_logic_vector(to_signed(-7, i_kernel_weight_matrix(3)'length));
		i_kernel_weight_matrix(4) <= std_logic_vector(to_signed(0, i_kernel_weight_matrix(4)'length));
		i_kernel_weight_matrix(5) <= std_logic_vector(to_signed(5, i_kernel_weight_matrix(5)'length));
		i_kernel_weight_matrix(6) <= std_logic_vector(to_signed(-9, i_kernel_weight_matrix(6)'length));
		i_kernel_weight_matrix(7) <= std_logic_vector(to_signed(2, i_kernel_weight_matrix(7)'length));
		i_kernel_weight_matrix(8) <= std_logic_vector(to_signed(-1, i_kernel_weight_matrix(8)'length));

		-- i_kernel_activation_matrix assignments
		i_kernel_activation_matrix(0) <= std_logic_vector(to_signed(8, i_kernel_activation_matrix(0)'length));
		i_kernel_activation_matrix(1) <= std_logic_vector(to_signed(-6, i_kernel_activation_matrix(1)'length));
		i_kernel_activation_matrix(2) <= std_logic_vector(to_signed(4, i_kernel_activation_matrix(2)'length));
		i_kernel_activation_matrix(3) <= std_logic_vector(to_signed(-3, i_kernel_activation_matrix(3)'length));
		i_kernel_activation_matrix(4) <= std_logic_vector(to_signed(7, i_kernel_activation_matrix(4)'length));
		i_kernel_activation_matrix(5) <= std_logic_vector(to_signed(-10, i_kernel_activation_matrix(5)'length));
		i_kernel_activation_matrix(6) <= std_logic_vector(to_signed(1, i_kernel_activation_matrix(6)'length));
		i_kernel_activation_matrix(7) <= std_logic_vector(to_signed(-5, i_kernel_activation_matrix(7)'length));
		i_kernel_activation_matrix(8) <= std_logic_vector(to_signed(9, i_kernel_activation_matrix(8)'length));

		wait until rising_edge(i_en);
		--wait for clk_period;
		-- Finish up
		i_kernel_complete <= '1';
		i_kernel_en       <= '0';
		wait;

	end process INPUT_PROC;

	FINISH_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if o_kernel_complete = '1' then
				report "Simulation finished successfully!";
				std.env.finish;
			elsif o_kernel_valid = '1' and i_en = '1' then
				assert signed(o_pixel_line(0)) = to_signed(c_results(c_id), o_pixel_line(0)'length)
					report "In Iteration " & INTEGER'image(c_id) & ": Result should be " & INTEGER'image(c_results(c_id)) & " but is " & INTEGER'image(to_integer(signed(o_pixel_line(0))))
					severity failure;

				c_id <= c_id + 1;
			end if;
		end if;

	end process FINISH_PROC;

end architecture bench;
