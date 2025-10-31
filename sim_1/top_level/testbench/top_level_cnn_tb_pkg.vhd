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
		--
		i_use_rnd : boolean;
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
		o_current_oc_amount :  std_logic_vector(15 downto 0);
		o_current_state     :  std_logic_vector(2 downto 0);
		o_overall_done      :  std_logic;
		o_overall_error     :  std_logic;
	end record t_tb_i;

	----------------------------------------------------------------------
	-- FUNCTIONs
	----------------------------------------------------------------------

	impure function hexstr_to_slv (
		str_i : string
	) return std_logic_vector;

	impure function get_input_length (
		str_i : string
	) return integer;

	impure function get_output_length (
		str_i : string
	) return integer;

	impure function get_input_channel_amount (
		str_i : string
	) return integer;

	impure function get_output_channel_amount (
		str_i : string
	) return integer;

	impure function get_pixel_amount (
		str_i : string
	) return integer;

	impure function get_ic_per_iteration_amount (
		str_i : string
	) return integer;

	impure function get_kernel_size (
		str_i : string
	) return integer;

	impure function get_padding_size (
		str_i : string
	) return integer;

	impure function get_stride_bit_mask (
		str_i : string
	) return integer;

	impure function get_weight_per_iteration (
		str_i : string
	) return integer;

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

	impure function get_input_length (
		str_i : string
	) return integer is
	begin

		return to_integer(unsigned(hexstr_to_slv(str_i(29 to 32))));

	end function get_input_length;

	impure function get_output_length (
		str_i : string
	) return integer is
	begin

		return to_integer(unsigned(hexstr_to_slv(str_i(25 to 28))));

	end function get_output_length;

	impure function get_input_channel_amount (
		str_i : string
	) return integer is
	begin

		return to_integer(unsigned(hexstr_to_slv(str_i(21 to 24))));

	end function get_input_channel_amount;

	impure function get_output_channel_amount (
		str_i : string
	) return integer is
	begin

		return to_integer(unsigned(hexstr_to_slv(str_i(17 to 20))));

	end function get_output_channel_amount;

	impure function get_pixel_amount (
		str_i : string
	) return integer is
	begin

		return to_integer(unsigned(hexstr_to_slv(str_i(13 to 16))));

	end function get_pixel_amount;

	impure function get_ic_per_iteration_amount (
		str_i : string
	) return integer is
	begin

		return to_integer(unsigned(hexstr_to_slv(str_i(9 to 12))));

	end function get_ic_per_iteration_amount;

	impure function get_kernel_size (
		str_i : string
	) return integer is
	begin

		return to_integer(unsigned(hexstr_to_slv(str_i(7 to 8))));

	end function get_kernel_size;

	impure function get_padding_size (
		str_i : string
	) return integer is
	begin

		return to_integer(unsigned(hexstr_to_slv(str_i(5 to 6))));

	end function get_padding_size;

	impure function get_stride_bit_mask (
		str_i : string
	) return integer is
	begin

		return to_integer(unsigned(hexstr_to_slv(str_i(3 to 4))));

	end function get_stride_bit_mask;

	impure function get_weight_per_iteration (
		str_i : string
	) return integer is
	begin

		return to_integer(unsigned(hexstr_to_slv(str_i(9 to 12)))) * to_integer(unsigned(hexstr_to_slv(str_i(7 to 8)))) * to_integer(unsigned(hexstr_to_slv(str_i(7 to 8))));

	end function get_weight_per_iteration;

	impure function hexstr_to_slv (
		str_i : string
	) return std_logic_vector is

		variable hex_v  : std_logic_vector(3 downto 0);
		variable vect_v : std_logic_vector(str_i'length * 4 - 1 downto 0);

	begin

		vect_v := (others => '0');

		for i in 1 to str_i'length loop

			case str_i(str_i'length - i + str_i'low) is
				when '0' => hex_v := x"0";
				when '1' => hex_v := x"1";
				when '2' => hex_v := x"2";
				when '3' => hex_v := x"3";
				when '4' => hex_v := x"4";
				when '5' => hex_v := x"5";
				when '6' => hex_v := x"6";
				when '7' => hex_v := x"7";
				when '8' => hex_v := x"8";
				when '9' => hex_v := x"9";
				when 'a' | 'A' => hex_v := x"A";
				when 'b' | 'B' => hex_v := x"B";
				when 'c' | 'C' => hex_v := x"C";
				when 'd' | 'D' => hex_v := x"D";
				when 'e' | 'E' => hex_v := x"E";
				when 'f' | 'F' => hex_v := x"F";
				when others =>
					report "hexstr_to_slv_error: Configuration string contains illegal char! Change and retry again..."
						severity FAILURE;
			end case;

			vect_v(3 + (i - 1) * 4 downto 0 + (i - 1) * 4) := hex_v;

		end loop;

		return vect_v;

	end function hexstr_to_slv;

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
		tb_o.i_use_rnd          <= False;

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
