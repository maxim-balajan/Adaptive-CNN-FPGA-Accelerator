library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.libmatrix.all;
use work.libmemory.all;
use std.env.finish;

entity combine_pipeline_tb is
end entity combine_pipeline_tb;

architecture bench of combine_pipeline_tb is

	-- Clock period
	constant clk_period : time := 10 ns;
	-- Generics
	constant vector_length              : natural              := 8;
	constant input_width                : natural              := 14;
	constant input_height               : natural              := 14;
	constant input_amount               : natural              := 6;
	constant kernel_size                : natural              := 5;
	constant pooling_size               : integer range 2 to 2 := 2;
	constant enable_weights             : integer range 0 to 1 := 0;
	constant total_input_channel        : natural              := 1;
	constant total_output_channel       : natural              := 1;
	constant current_channel            : natural              := 1;
	constant init_type                  : integer range 0 to 1 := 1;
	constant weight_path                : string               := "../data/test2.data";
	constant current_scale              : natural              := 1;
	constant scale_path                 : string               := "../data/test_scale.data";
	constant enable_multiplication_line : integer range 0 to 1 := 0;
	constant enable_shift               : integer range 0 to 1 := 1;
	-- ReLU is disabled for test purposes, but behavior should be "the same" (just without the ReLU)
	constant enable_relu : integer range 0 to 1 := 0;

	constant output_length : integer range 0 to ((3 ** enable_multiplication_line)) * vector_length := 8;
	-- Ports
	signal clk               : std_logic := '1';
	signal reset             : std_logic;
	signal activation_matrix : matrix_1d(0 to input_amount - 1)(vector_length - 1 downto 0);
	signal kernel_en         : std_logic;
	signal kernel_complete   : std_logic;
	signal weights_valid     : std_logic;
	signal new_pixel         : std_logic_vector(output_length - 1 downto 0);
	signal valid_pixel       : std_logic;
	signal comp_complete     : std_logic;

begin

	clk   <= not clk after clk_period / 2;
	reset <= '1' after 0 ns, '0' after 2 * clk_period;
    kernel_complete <= '0';

    SET_ACT_MATRIX : process
    begin
        activation_matrix <= (others => (others => '0') );
        kernel_en <= '0'; 
        wait for clk_period;
        activation_matrix <= (x"01", x"02", x"03", x"04", x"05", x"06");
        kernel_en <= '1';
        wait for clk_period;
        activation_matrix <= (others => (others => '1') ) ;
        kernel_en <= '1';
        wait for clk_period;
        activation_matrix <= (others => (others => '0') );
        kernel_en <= '0'; 
        wait for clk_period;
        activation_matrix <= (x"01", x"02", x"03", x"04", x"05", x"7F");
        kernel_en <= '1';
        wait for clk_period;
        activation_matrix <= (x"01", x"01", x"01", x"01", x"01", x"01");
        kernel_en <= '1';
        wait for clk_period;       
        activation_matrix <= (x"01", x"02", x"03", x"01", x"02", x"03");
        kernel_en <= '1';
        wait for clk_period;            
    end process;

	conv_pool_pipeline_inst : entity work.conv_pool_pipeline
		generic map (
			input_length               => vector_length,
			input_width                => input_width,
			input_height               => input_height,
			input_amount               => input_amount,
			kernel_size                => kernel_size,
			pooling_size               => pooling_size,
			enable_weights             => enable_weights,
			total_input_channel        => total_input_channel,
			total_output_channel       => total_output_channel,
			current_channel            => current_channel,
			init_type                  => init_type,
			weight_path                => weight_path,
			current_scale              => current_scale,
			scale_path                 => scale_path,
			enable_clip_adder          => 1,
			enable_multiplication_line => enable_multiplication_line,
			enable_shift               => enable_shift,
			enable_relu                => enable_relu,
			output_length              => output_length
		)
		port map (
			clk               => clk,
			reset             => reset,
			activation_matrix => activation_matrix,
			kernel_en         => kernel_en,
			kernel_complete   => kernel_complete,
			base_addr         => (others => '0'),
			weights_valid     => weights_valid,
			new_pixel         => new_pixel,
			valid_pixel       => valid_pixel,
			comp_complete     => comp_complete
		);

	TB : process is
	begin

		wait for 1000 * clk_period;
		finish;

	end process TB;

end architecture bench;
