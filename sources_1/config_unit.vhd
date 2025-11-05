library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity config_unit is
	port (
		clk   : in std_logic;
		reset : in std_logic;
		-- AXIS Interface
		i_wt_s_axis_tdata  : in std_logic_vector(127 downto 0);
		i_wt_s_axis_tkeep  : in std_logic_vector(15 downto 0);
		i_wt_s_axis_tlast  : in std_logic;
		o_wt_s_axis_tready : out std_logic;
		i_wt_s_axis_tvalid : in std_logic;
		-- Control Outputs
		o_config_valid    : out std_logic;
		o_config_valid_1c : out std_logic;
		o_config_error    : out std_logic;
		o_config_error_1c : out std_logic;
		-- CONFIG Outputs
		o_image_input_length          : out std_logic_vector(15 downto 0);
		o_image_output_length         : out std_logic_vector(15 downto 0);
		o_input_channel_size          : out std_logic_vector(15 downto 0);
		o_output_channel_size         : out std_logic_vector(15 downto 0);
		o_pixel_amount                : out std_logic_vector(15 downto 0);
		o_input_channel_per_iteration : out std_logic_vector(15 downto 0);
		o_kernel_size                 : out std_logic_vector(7 downto 0);
		o_padding_size                : out std_logic_vector(7 downto 0);
		o_stride_bit_mask             : out std_logic_vector(7 downto 0);
		o_shamt                       : out std_logic_vector(7 downto 0);
		o_pool_or_conv                : out std_logic;
		o_enable_relu                 : out std_logic
	);
end entity config_unit;

architecture rtl of config_unit is

	signal s_config_memory               : std_logic_vector(127 downto 0);
	alias  a_image_input_length          : std_logic_vector(15 downto 0) is s_config_memory(15 downto 0);
	alias  a_image_output_length         : std_logic_vector(15 downto 0) is s_config_memory(31 downto 16);
	alias  a_input_channel_size          : std_logic_vector(15 downto 0) is s_config_memory(47 downto 32);
	alias  a_output_channel_size         : std_logic_vector(15 downto 0) is s_config_memory(63 downto 48);
	alias  a_pixel_amount                : std_logic_vector(15 downto 0) is s_config_memory(79 downto 64);
	alias  a_input_channel_per_iteration : std_logic_vector(15 downto 0) is s_config_memory(95 downto 80);
	alias  a_kernel_size                 : std_logic_vector(7 downto 0) is s_config_memory(103 downto 96);
	alias  a_padding_size                : std_logic_vector(7 downto 0) is s_config_memory(111 downto 104);
	alias  a_stride_bit_mask             : std_logic_vector(7 downto 0) is s_config_memory(119 downto 112);
	alias  a_pool_or_conv                : std_logic_vector(0 downto 0) is s_config_memory(120 downto 120);
	alias  a_enable_relu                 : std_logic_vector(0 downto 0) is s_config_memory(121 downto 121);
	alias  a_shamt                       : std_logic_vector(5 downto 0) is s_config_memory(127 downto 122);

	signal s_config_valid     : std_logic;
	signal s_config_valid_1c  : std_logic;
	signal s_config_error     : std_logic;
	signal s_config_error_1c  : std_logic;
	signal s_wt_s_axis_tready : std_logic;

begin

	CONFIG_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_config_memory <= (others => '0');

				s_config_valid     <= '0';
				s_config_valid_1c  <= '0';
				s_config_error     <= '0';
				s_config_error_1c  <= '0';
				s_wt_s_axis_tready <= '0';
			else
				-- As long as Config is not initialized and not in error state, try to receive config
				if s_config_valid = '0' and s_config_error = '0' then
					s_wt_s_axis_tready <= '1';
					if s_wt_s_axis_tready = '1' and i_wt_s_axis_tvalid = '1' and i_wt_s_axis_tlast = '1' and i_wt_s_axis_tkeep = x"FFFF" then
						s_config_memory    <= i_wt_s_axis_tdata;
						s_config_valid     <= '1';
						s_config_valid_1c  <= '1';
						s_wt_s_axis_tready <= '0';
					elsif s_wt_s_axis_tready = '1' and i_wt_s_axis_tvalid = '1' then
						-- If only tvalid is set, this means an invalid request was made by the software
						s_config_error     <= '1';
						s_config_error_1c  <= '1';
						s_wt_s_axis_tready <= '0';
					end if;
				else
					s_wt_s_axis_tready <= '0';
					s_config_valid_1c  <= '0';
					s_config_error_1c  <= '0';
				end if;
			end if;
		end if;

	end process CONFIG_PROC;

	----------------------------------------
	-- Set Outputs
	----------------------------------------

	-- Output delayed by one cycle
	OUTPUT_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				-- reset registers
				o_image_input_length          <= (others => '0');
				o_image_output_length         <= (others => '0');
				o_input_channel_size          <= (others => '0');
				o_output_channel_size         <= (others => '0');
				o_pixel_amount                <= (others => '0');
				o_input_channel_per_iteration <= (others => '0');
				o_kernel_size                 <= (others => '0');
				o_padding_size                <= (others => '0');
				o_stride_bit_mask             <= (others => '0');
				o_shamt                       <= (others => '0');
				o_pool_or_conv                <= '0';
				o_enable_relu                 <= '0';
				-- reset control data
				o_config_valid    <= '0';
				o_config_valid_1c <= '0';
				o_config_error    <= '0';
				o_config_error_1c <= '0';
			else
				-- set registers
				o_image_input_length          <= a_image_input_length;
				o_image_output_length         <= a_image_output_length;
				o_input_channel_size          <= a_input_channel_size;
				o_output_channel_size         <= a_output_channel_size;
				o_pixel_amount                <= a_pixel_amount;
				o_input_channel_per_iteration <= a_input_channel_per_iteration;
				o_kernel_size                 <= a_kernel_size;
				o_padding_size                <= a_padding_size;
				o_stride_bit_mask             <= a_stride_bit_mask;
				o_shamt                       <= std_logic_vector(resize(unsigned(a_shamt), o_shamt'length));
				o_pool_or_conv                <= a_pool_or_conv(a_pool_or_conv'low);
				o_enable_relu                 <= a_enable_relu(a_enable_relu'low);
				-- set control data
				o_config_valid    <= s_config_valid;
				o_config_valid_1c <= s_config_valid_1c;
				o_config_error    <= s_config_error;
				o_config_error_1c <= s_config_error_1c;
			end if;
		end if;

	end process OUTPUT_PROC;

	-- Output Control Logic
	o_wt_s_axis_tready <= s_wt_s_axis_tready;

end architecture rtl;
