library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity axis_slave_configurable_slider_wrapper is
	generic (
		G_VECTOR_LENGTH      : natural := 8;
		G_IMG_MAX_LENGTH     : natural := 55;
		G_KERNEL_SIZE        : natural := 5;
		G_PADDING_SIZE       : natural := 2;
		G_MAX_KERNEL_SIZE    : natural := 12;
		G_LINE_BUFFER_AMOUNT : natural := 12 * 3 * 5;
		G_PIPELINE_STEPS     : natural := 2
	);
	port (
		clk   : in std_logic;
		reset : in std_logic;
		-- AXIS Interface
		i_px_s_axis_tdata  : in std_logic_vector(127 downto 0);
		i_px_s_axis_tkeep  : in std_logic_vector(15 downto 0);
		i_px_s_axis_tlast  : in std_logic;
		o_px_s_axis_tready : out std_logic;
		i_px_s_axis_tvalid : in std_logic;
		-- Control Unit OUTPUTS
		i_image_input_length          : in std_logic_vector(15 downto 0);
		i_image_output_length         : in std_logic_vector(15 downto 0);
		i_input_channel_per_iteration : in std_logic_vector(15 downto 0);
		i_kernel_size                 : in std_logic_vector(7 downto 0);
		i_padding_size                : in std_logic_vector(7 downto 0);
		i_stride_bit_mask             : in std_logic_vector(7 downto 0);
		i_weight_init                 : in std_logic;
		-- BRAM FIFO Enable
		i_en : in std_logic;
		-- Pixel window OUTPUTS
		kernel_complete          : out std_logic;
		kernel_en                : out std_logic;
		kernel_activation_matrix : out matrix_1d(0 to G_MAX_KERNEL_SIZE * G_LINE_BUFFER_AMOUNT - 1)(G_VECTOR_LENGTH - 1 downto 0)
	);
end entity axis_slave_configurable_slider_wrapper;

architecture rtl of axis_slave_configurable_slider_wrapper is

	signal s_px_s_axis_tready : std_logic;
	signal s_px_s_axis_tdata  : std_logic_vector(127 downto 0);

begin

	PX_PROC : process (clk) is
	begin

		if rising_edge(clk) then
			if reset = '1' then
				s_px_s_axis_tdata  <= (others => '0');
				s_px_s_axis_tready <= '0';
			elsif i_en = '1' then
				
			end if;
		end if;

	end process PX_PROC;

	configurable_slider_inst : entity work.configurable_slider
		generic map (
			vector_length        => G_VECTOR_LENGTH,
			G_IMG_MAX_LENGTH     => G_IMG_MAX_LENGTH,
			G_KERNEL_SIZE        => G_KERNEL_SIZE,
			G_PADDING_SIZE       => G_PADDING_SIZE,
			G_MAX_KERNEL_SIZE    => G_MAX_KERNEL_SIZE,
			G_LINE_BUFFER_AMOUNT => G_LINE_BUFFER_AMOUNT,
			G_PIPELINE_STEPS     => G_PIPELINE_STEPS
		)
		port map (
			clk                      => clk,
			reset                    => reset,
			--
			valid_pixel_streams      => open,
			pixel_streams            => open,
			--
			input_image_length       => i_image_input_length,
			output_image_length      => i_image_output_length,
			kernel_size              => i_kernel_size,
			padding_size             => i_padding_size,
			stride_bit_mask          => i_stride_bit_mask,
			--
			kernel_complete          => kernel_complete,
			kernel_en                => kernel_en,
			kernel_activation_matrix => kernel_activation_matrix
		);

end architecture rtl;
