library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library tb_lib;
use tb_lib.libmatrix.all;

library vunit_lib;
	context vunit_lib.vunit_context;

library osvvm;
	context osvvm.OsvvmContext;
use osvvm.RandomPkg.all;

package axis_2_pxs_tb_pkg is

	----------------------------------------------------------------------
	-- TYPEs
	----------------------------------------------------------------------

	----------------------------------------------------------------------
	-- CONSTANTs
	----------------------------------------------------------------------
	constant C_CLK_PERIOD            : TIME    := 10 ns;
	constant C_MAX_INPUT_BYTE_WIDTH  : integer := 16;
	constant C_MAX_OUTPUT_BYTE_WIDTH : integer := 16;

	----------------------------------------------------------------------
	-- RECORDs
	----------------------------------------------------------------------
	-- TB output record

	type t_tb_o is record
		reset : std_logic;
		--
		i_en : std_logic;
		-- Control Inputs [REGISTERED after reset]
		i_image_input_length :std_logic_vector(15 downto 0);
		i_padding_size       :std_logic_vector(7 downto 0);
		-- Control Inputs [Not REGISTERED after reset]
		i_wt_init :std_logic;
		i_cs_init :std_logic;
	end record t_tb_o;

	-- TB input record

	type t_tb_i is record
		-- generics
		g_log_level                   : integer range 0 to 2;
		G_INPUT_BYTE_WIDTH            : integer range 1 to 128;
		G_OUTPUT_BYTE_WIDTH           : integer range 1 to 128;
		G_BRAM_BYTE_WIDTH             : natural;
		G_INPUT_CHANNEL_PER_ITERATION : natural;
		G_IMG_MAX_LENGTH              : natural;
		G_MAX_FIFO_DEPTH              : natural;
		G_NEAR_FULL_THRESHOLD         : natural;
		-- clock
		clk : std_logic;
		-- Pixel Stream Output
		o_valid_pixel_streams : std_logic;
		o_pixel_streams       : matrix_1d(0 to C_MAX_INPUT_BYTE_WIDTH - 1)(7 downto 0);
	end record t_tb_i;

	----------------------------------------------------------------------
	-- FUNCTIONs
	----------------------------------------------------------------------

	function f_create_start_stream (
		signal tb_i : in t_tb_i
	) return std_logic_vector;

	function f_create_data_stream (
		signal tb_i : in t_tb_i;
		constant start_slv : std_logic_vector
	) return std_logic_vector;
	----------------------------------------------------------------------
	-- PROCEDUREs
	----------------------------------------------------------------------
	-- TC

	procedure tc_init (
		signal tb_o : out t_tb_o;
		signal tb_i : in t_tb_i;
		do_dut_init : boolean := TRUE
	);

	procedure tc_end (
		signal tb_o : out t_tb_o;
		signal tb_i : in t_tb_i
	);
	-- DUT

	procedure dut_init (
		signal tb_o : out t_tb_o;
		signal tb_i : in t_tb_i
	);

	----------------------------------------------------------------------
	-- SHARED VARIABLES (cannot be in generic packages -> local copy!)
	----------------------------------------------------------------------
	shared variable sv_rnd : RandomPType;

end package axis_2_pxs_tb_pkg;

package body axis_2_pxs_tb_pkg is

	----------------------------------------------------------------------
	-- FUNCTIONs
	----------------------------------------------------------------------

	function f_create_start_stream (
		signal tb_i : in t_tb_i
	) return std_logic_vector is

		variable start_slv : std_logic_vector(tb_i.G_INPUT_BYTE_WIDTH * 8 - 1 downto 0) := (others => '0');
		constant px_amount_per_ic : natural                                             := tb_i.G_INPUT_BYTE_WIDTH / tb_i.G_INPUT_CHANNEL_PER_ITERATION;

	begin

		for i in 0 to tb_i.G_INPUT_BYTE_WIDTH - 1 loop

			start_slv := std_logic_vector(to_unsigned((i / px_amount_per_ic + 1) mod tb_i.G_INPUT_CHANNEL_PER_ITERATION, 8)) & start_slv(start_slv'high downto 8);

		end loop;

		return start_slv;

	end function f_create_start_stream;

	function f_create_data_stream (
		signal tb_i : in t_tb_i;
		constant start_slv : std_logic_vector
	) return std_logic_vector is

		variable new_vector : std_logic_vector(tb_i.G_INPUT_BYTE_WIDTH * 8 - 1 downto 0) := start_slv;
		variable bit_difference : natural                                                := (tb_i.G_INPUT_BYTE_WIDTH - tb_i.G_OUTPUT_BYTE_WIDTH) * 8;

	begin

		if tb_i.G_INPUT_BYTE_WIDTH = tb_i.G_OUTPUT_BYTE_WIDTH then
			return new_vector;
		else
			new_vector                                                          := std_logic_vector(shift_right(unsigned(new_vector), bit_difference));
			new_vector(new_vector'high downto new_vector'high - bit_difference) := new_vector(new_vector'low + bit_difference downto new_vector'low);
			return new_vector;
		end if;

	end function f_create_data_stream;

	----------------------------------------------------------------------
	-- PROCEDUREs
	----------------------------------------------------------------------
	-- TC

	procedure tc_init (
		signal tb_o : out t_tb_o;
		signal tb_i : in t_tb_i;
		do_dut_init : boolean := TRUE
	) is
	begin

		tb_o.reset <= '1';
		wait for 2 * C_CLK_PERIOD;

		if do_dut_init then
			-- wait until rising_edge(tb_i.clk);
			-- initialize DUT
			dut_init(tb_o, tb_i);
		end if;

		wait for 0 ns;

	end procedure tc_init;

	procedure tc_end (
		signal tb_o : out t_tb_o;
		signal tb_i : in t_tb_i
	) is
	begin

		wait for 0 ns;

		if get_checker_stat.n_failed > 0 then
			report " # TEST CASE RESULT: FAILED"
				severity failure;
		else
			report " # TEST CASE RESULT: PASSED"
				severity note;
		end if;

	end procedure tc_end;

	-- DUT

	procedure dut_init (
		signal tb_o : out t_tb_o;
		signal tb_i : in t_tb_i
	) is
	begin

		wait until rising_edge(tb_i.clk);
		tb_o.reset <= '1';
		wait until rising_edge(tb_i.clk);
		tb_o.reset <= '0';
		wait for 0 ns;

	end procedure dut_init;

end package body axis_2_pxs_tb_pkg;
