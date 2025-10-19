library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library vunit_lib;
	context vunit_lib.vunit_context;

library osvvm;
	context osvvm.OsvvmContext;
use osvvm.RandomPkg.all;

library tb_lib;
use tb_lib.libmatrix.all;

package top_level_cnn_tb_pkg is

	----------------------------------------------------------------------
	-- TYPEs
	----------------------------------------------------------------------

	----------------------------------------------------------------------
	-- CONSTANTs
	----------------------------------------------------------------------
	constant C_CLK_PERIOD           : TIME    := 10 ns;
	constant C_MAX_WEIGHT_BIT_WIDTH : integer := 128;
	constant C_MAX_WEIGHT_AMOUNT    : natural := 512;

	----------------------------------------------------------------------
	-- RECORDs
	----------------------------------------------------------------------
	-- TB output record

	type t_tb_o is record
		reset : std_logic;
		-- Control Logic
		i_px_m_axis_tready : std_logic;
	end record t_tb_o;

	-- TB input record

	type t_tb_i is record
		-- generics
		g_log_level : integer range 0 to 2;
		-- clock
		clk : std_logic;
		-- AXIS Interface
		o_wt_s_axis_tready : std_logic;
		-- CONFIG Outputs
		o_px_m_axis_tdata  :  std_logic_vector(127 downto 0);
		o_px_m_axis_tkeep  :  std_logic_vector(15 downto 0);
		o_px_m_axis_tlast  :  std_logic;
		o_px_m_axis_tvalid :  std_logic;
		-- Control OUTPUT PORTS
		o_current_ic_amount :  std_logic_vector(15 downto 0);
		o_current_state     :  std_logic_vector(2 downto 0);
		o_overall_done      :  std_logic;
		o_overall_error     :  std_logic;
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

end package top_level_cnn_tb_pkg;

package body top_level_cnn_tb_pkg is

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
		wait for 2 * C_CLK_PERIOD;

		tb_o.i_px_m_axis_tready <= '0';

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

end package body top_level_cnn_tb_pkg;
