library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity line_route_unit is
	generic (
		vector_length        : natural   := 8;
		G_KERNEL_SIZE        : natural   := 5;
		G_MAX_KERNEL_SIZE    : natural   := 12;
		G_LINE_BUFFER_AMOUNT : natural   := 12 * 3 * 5;
		G_PIPELINE_STEPS     : natural   := 2;
		G_DEBUG_FLAG         : std_logic := '0'
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		--
		valid_pixel_streams : in std_logic;
		pixel_streams_in    : in matrix_1d(0 to G_LINE_BUFFER_AMOUNT - 1)(vector_length - 1 downto 0);
		activation_matrix   : in matrix_2d(0 to G_LINE_BUFFER_AMOUNT - 1)(0 to G_MAX_KERNEL_SIZE - 1)(vector_length - 1 downto 0);
		enable_matrix       : in matrix_1d(0 to G_LINE_BUFFER_AMOUNT - 1)(0 to G_MAX_KERNEL_SIZE - 1);
		--
		init_complete         : out std_logic;
		activation_matrix_out : out matrix_1d(0 to G_LINE_BUFFER_AMOUNT * G_MAX_KERNEL_SIZE - 1)(vector_length - 1 downto 0);
		pixel_streams_out     : out matrix_1d(0 to G_LINE_BUFFER_AMOUNT - 1)(vector_length - 1 downto 0);
		set_full_stream_out   : out std_logic_vector(0 to G_LINE_BUFFER_AMOUNT - 1);
		enable_stream_out     : out std_logic_vector(0 to G_LINE_BUFFER_AMOUNT - 1)
	);
end entity line_route_unit;

architecture rtl of line_route_unit is

	signal s_pixel_streams_out     : matrix_2d(0 to G_PIPELINE_STEPS)(0 to G_LINE_BUFFER_AMOUNT - 1)(vector_length - 1 downto 0);
	signal s_enable_stream_out     : matrix_1d(0 to G_PIPELINE_STEPS)(0 to G_LINE_BUFFER_AMOUNT - 1);
	signal s_activation_matrix_out : matrix_2d(0 to G_LINE_BUFFER_AMOUNT - 1)(0 to G_MAX_KERNEL_SIZE - 1)(vector_length - 1 downto 0);

	signal s_tp_enable_matrix : matrix_1d(0 to G_MAX_KERNEL_SIZE - 1)(0 to G_LINE_BUFFER_AMOUNT - 1);

begin

	-- Process for introduction G_PIPELINE_STEPS many delay cycles
	DELAY_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_pixel_streams_out(s_pixel_streams_out'low + 1 to s_pixel_streams_out'high) <= (others => (others => (others => '0')));
				s_enable_stream_out(s_enable_stream_out'low + 1 to s_enable_stream_out'high) <= (others => (others => '0'));
			else
				if valid_pixel_streams = '1' then
					s_pixel_streams_out(s_pixel_streams_out'low + 1 to s_pixel_streams_out'high)
 						<= s_pixel_streams_out(s_pixel_streams_out'low to s_pixel_streams_out'high - 1);
					s_enable_stream_out(s_enable_stream_out'low + 1 to s_enable_stream_out'high)
 						<= s_enable_stream_out(s_enable_stream_out'low to s_enable_stream_out'high - 1);
				end if;
			end if;
		end if;

	end process DELAY_PROC;

	PIXEL_STREAMS_OUT_GEN : for i in 0 to G_LINE_BUFFER_AMOUNT - 1 generate

		CHECK_PS_IN_GEN : if i mod G_KERNEL_SIZE = 0 generate
			s_pixel_streams_out(s_pixel_streams_out'low)(i) <= pixel_streams_in(i);
			s_enable_stream_out(s_enable_stream_out'low)(i) <= valid_pixel_streams;
		else generate
			s_pixel_streams_out(s_pixel_streams_out'low)(i) <= activation_matrix(i - 1)(activation_matrix'low);
			s_enable_stream_out(s_enable_stream_out'low)(i) <= enable_matrix(i - 1)(enable_matrix'low);
		end generate CHECK_PS_IN_GEN;

		ACTIVATION_MATRIX_ROUTE_GEN : for j in 0 to G_MAX_KERNEL_SIZE - 1 generate

			ACTIVATION_MATRIX_ROUTE_VAL_GEN : if (j < G_KERNEL_SIZE) and ((G_LINE_BUFFER_AMOUNT / G_KERNEL_SIZE) * G_KERNEL_SIZE >= i) generate
				s_activation_matrix_out(i)(j) <= activation_matrix(i)(j);
			else generate
				s_activation_matrix_out(i)(j) <= (others => G_DEBUG_FLAG);
			end generate ACTIVATION_MATRIX_ROUTE_VAL_GEN;

		end generate ACTIVATION_MATRIX_ROUTE_GEN;

	end generate PIXEL_STREAMS_OUT_GEN;

	-- TODO: mirror this design accordingly

	FLAT_GEN : for j in 0 to G_LINE_BUFFER_AMOUNT * G_MAX_KERNEL_SIZE - 1 generate
		activation_matrix_out(j) <= s_activation_matrix_out(j / G_MAX_KERNEL_SIZE)(j mod G_MAX_KERNEL_SIZE);
	end generate FLAT_GEN;

	-- Set outputs
	s_tp_enable_matrix <= transpose_matrix1d(enable_matrix);
	init_complete      <= and s_tp_enable_matrix(G_KERNEL_SIZE - 1);
	pixel_streams_out  <= s_pixel_streams_out(s_pixel_streams_out'high);
	enable_stream_out  <= s_enable_stream_out(s_enable_stream_out'high);
	-- TODO: implement this...
	set_full_stream_out <= (others => '0');

end architecture rtl;
