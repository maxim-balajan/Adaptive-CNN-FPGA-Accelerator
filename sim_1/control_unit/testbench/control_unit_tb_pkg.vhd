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

package control_unit_tb_pkg is

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
		i_temp_comp_complete : std_logic;
	end record t_tb_o;

	-- TB input record

	type t_tb_i is record
		-- generics
		g_log_level        : integer range 0 to 2;
		g_weight_bit_width : integer range 2 to 128;
		g_weight_amount    : natural;
		-- clock
		clk : std_logic;
		-- AXIS Interface
		o_wt_s_axis_tready : std_logic;
		-- CONFIG Outputs
		o_image_input_length          : std_logic_vector(15 downto 0);
		o_image_output_length         : std_logic_vector(15 downto 0);
		o_input_channel_size          : std_logic_vector(15 downto 0);
		o_output_channel_size         : std_logic_vector(15 downto 0);
		o_input_channel_per_iteration : std_logic_vector(15 downto 0);
		o_kernel_size                 : std_logic_vector(7 downto 0);
		o_padding_size                : std_logic_vector(7 downto 0);
		o_stride_bit_mask             : std_logic_vector(7 downto 0);
		o_shamt                       : std_logic_vector(7 downto 0);
		o_pool_or_conv                : std_logic;
		o_enable_relu                 : std_logic;
		-- WEIGHT MODULE OUTPUTS
		o_kernel_weight_init   : std_logic;
		o_kernel_weight_error  : std_logic;
		o_kernel_weight_matrix : matrix_1d(0 to C_MAX_WEIGHT_AMOUNT - 1)(7 downto 0);
		-- RESET OUTPUTS
		o_rst_config_slider : std_logic;
		o_rst_kernel_cores  : std_logic;
		o_rst_accumulator   : std_logic;
		o_rst_bram_fifo     : std_logic;
		-- Control Signals
		o_current_ic_amount : std_logic_vector(15 downto 0);
		o_current_oc_amount : std_logic_vector(15 downto 0);
		o_current_state     : std_logic_vector(2 downto 0);
		o_overall_done      : std_logic;
		o_overall_error     : std_logic;
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

end package control_unit_tb_pkg;

package body control_unit_tb_pkg is

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

		tb_o.i_temp_comp_complete <= '0';

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

end package body control_unit_tb_pkg;
