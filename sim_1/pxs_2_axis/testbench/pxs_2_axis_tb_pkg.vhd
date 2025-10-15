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

package pxs_2_axis_tb_pkg is

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
		-- ROUTING CORES OUTPUTS
		i_kernel_complete : std_logic;
		i_kernel_valid    : std_logic;
		i_pixel_line      : matrix_1d(0 to C_MAX_INPUT_BYTE_WIDTH - 1)(7 downto 0);
	end record t_tb_o;

	-- TB input record

	type t_tb_i is record
		-- generics
		g_log_level           : integer range 0 to 2;
		G_OUTPUT_CHANNELS     : natural;
		G_DATA_BYTE_WIDTH     : integer range 1 to 128;
		G_BRAM_BYTE_WIDTH     : integer range 1 to 128;
		G_BRAM_MAX_DEPTH      : natural;
		G_NEAR_FULL_THRESHOLD : natural;
		-- clock
		clk : std_logic;
		-- Pixel Stream Output
		o_en : std_logic;
		-- Control Logic
		o_accel_finished : std_logic;
		-- AXIS INTERFACES
		o_px_m_axis_tdata  : std_logic_vector(C_MAX_INPUT_BYTE_WIDTH * 8 - 1 downto 0);
		o_px_m_axis_tkeep  : std_logic_vector(C_MAX_INPUT_BYTE_WIDTH - 1 downto 0);
		o_px_m_axis_tlast  : std_logic;
		i_px_m_axis_tready : std_logic;
		o_px_m_axis_tvalid : std_logic;
	end record t_tb_i;

	----------------------------------------------------------------------
	-- FUNCTIONs
	----------------------------------------------------------------------

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

end package pxs_2_axis_tb_pkg;

package body pxs_2_axis_tb_pkg is

	----------------------------------------------------------------------
	-- FUNCTIONs
	----------------------------------------------------------------------

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

		tb_o.i_kernel_complete <= '0';
		tb_o.i_kernel_valid    <= '0';
		tb_o.i_pixel_line      <= (others => (others => '0'));

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

end package body pxs_2_axis_tb_pkg;
