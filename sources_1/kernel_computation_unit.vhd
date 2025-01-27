library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.libmatrix.all;

entity kernel_computation_unit is
	generic (
		--! pool_or_conv = 1 means Convolution; pool_or_conv = 0 means Pooling
		pool_or_conv : integer range 0 to 1 := 1;
		--! enables clipping after every addition
		enable_clip_adder : integer range 0 to 1 := 1;
		--! enables the multiplication line in the beginning (only matters for pool_or_conv = 1)
		enable_multiplication_line : integer range 0 to 1 := 1;
		--! enables the shift before bias addition (only matters for pool_or_conv = 1)
		enable_shift : integer range 0 to 1 := 1;
		--! enables the bias addition before relu at the end (only matters for pool_or_conv = 1 and enable_shift = 1)
		enable_bias : integer range 0 to 1 := 1;
		--! enables the relu step at the end of the computation (only matters for pool_or_conv = 1)
		enable_relu   : integer range 0 to 1                                                                  := 1;
		input_length  : natural                                                                               := 8;
		output_length : integer range 0 to ((3 ** enable_multiplication_line) ** pool_or_conv) * input_length := 8;
		kernel_size   : natural                                                                               := 5
	);
	port (
		clk               : in std_logic;
		reset             : in std_logic;
		activation_matrix : in matrix_2d(0 to kernel_size - 1)(0 to kernel_size - 1)(input_length - 1 downto 0);
		-- only used for some convolutions; unused for pooling
		weight_matrix : in matrix_2d(0 to kernel_size - 1)(0 to kernel_size - 1)(input_length - 1 downto 0);
		-- bias and shamt could also be passed as generics (or static port inputs) but for now keep it as it is
		shamt           : in std_logic_vector(input_length - 1 downto 0);
		bias            : in std_logic_vector(output_length - 1 downto 0);
		kernel_en       : in std_logic;
		kernel_complete : in std_logic;
		new_pixel       : out std_logic_vector(output_length - 1 downto 0);
		valid_pixel     : out std_logic;
		comp_complete   : out std_logic
	);
end entity kernel_computation_unit;

architecture rtl of kernel_computation_unit is

	-- This conditional declaration can only be done via a function...

	impure function get_pipeline_vector_length (
		c : integer
	)
        return integer is
	begin

		if c = 1  and enable_multiplication_line = 1 then
			return 3 * input_length;
		else
			return input_length;
		end if;

	end function get_pipeline_vector_length;

	-- conditionally find out which length the pipeline should have
	constant c_pipeline_vector_length : integer := get_pipeline_vector_length(pool_or_conv);

	-- This constant stores the amount of convolution steps that are needed
	constant c_conv_step_count : integer := integer(ceil(log2(real(kernel_size ** 2))));
	-- This signal is for all pipelined values that are used for the convolution computation
	-- it also contains double the amount of signals because it is easier to write that way and shouldn't result in more HW
	signal s_pipeline_values : matrix_2d(0 to c_conv_step_count)(0 to kernel_size ** 2 - 1)(c_pipeline_vector_length - 1 downto 0);
	alias  s_pipeline_end    is s_pipeline_values(s_pipeline_values'high)(s_pipeline_values'low);
	-- This signal contains all multiplications or all start values for comparisions
	signal s_pipeline_start : matrix_1d(0 to kernel_size ** 2 - 1)(c_pipeline_vector_length - 1 downto 0);

	-- These are just the pipelined controll signes
	signal s_kernel_en_line       : std_logic_vector(0 to c_conv_step_count);
	signal s_kernel_complete_line : std_logic_vector(0 to c_conv_step_count);

	-- These signals are necessary when shifting
	signal s_kernel_en_shift       : std_logic;
	signal s_kernel_complete_shift : std_logic;
	signal s_pipeline_begin_shift  : std_logic_vector(c_pipeline_vector_length - 1 downto 0);
	signal s_pipeline_result_shift : std_logic_vector(c_pipeline_vector_length - 1 downto 0);

	-- These signals are necessary when having bias
	signal s_kernel_en_bias       : std_logic;
	signal s_kernel_complete_bias : std_logic;
	signal s_pipeline_begin_bias  : std_logic_vector(c_pipeline_vector_length - 1 downto 0);
	signal s_pipeline_result_bias : std_logic_vector(c_pipeline_vector_length - 1 downto 0);

	-- These signals are necessary when having ReLU
	signal s_kernel_en_relu       : std_logic;
	signal s_kernel_complete_relu : std_logic;
	signal s_pipeline_begin_relu  : std_logic_vector(output_length - 1 downto 0);
	signal s_pipeline_result_relu : std_logic_vector(output_length - 1 downto 0);

	-- This signals contain the result of the computation (without the ReLU step)
	signal s_new_pixel     : std_logic_vector(output_length - 1 downto 0);
	signal s_valid_pixel   : std_logic;
	signal s_comp_complete : std_logic;

begin

	-- Multiplication line that computes all the multiplications for the convolution; only necessary for convolution

	MULT_GEN_1 : for i in activation_matrix'range generate

		MULT_GEN_2 : for j in activation_matrix(activation_matrix'low)'range generate

			CONV_MUL_LINE_GEN : if pool_or_conv = 1 and enable_multiplication_line = 1 generate
				-- resize necessary because target signal has to exactly match resulting size of multiplication
				-- Multiplication never has to be clipped because the vectors are increased accordingly
				s_pipeline_start(i * kernel_size + j) <= std_logic_vector(resize(signed(activation_matrix(i)(j)), 2 * activation_matrix(i)(j)'length) * signed(weight_matrix(i)(j)));
			else generate
				s_pipeline_start(i * kernel_size + j) <= activation_matrix(i)(j);
			end generate CONV_MUL_LINE_GEN;

		end generate MULT_GEN_2;

	end generate MULT_GEN_1;

	-- Generate all convolutions/pooling steps that are necessary for the addition/comparison of all input values
	-- Basically works like the "Divide by 2"-Algorithm

	KERNEL_STEP_GEN : for i in 0 to c_conv_step_count - 1 generate

		KERNEL_STEP_INST : entity work.kernel_computation_step
			generic map (
				vector_length => c_pipeline_vector_length,
				input_width   => integer(ceil(real(kernel_size ** 2) / real(2 ** i))),
				pool_or_conv  => pool_or_conv
			)
			port map (
				clk                 => clk,
				reset               => reset,
				input_matrix        => s_pipeline_values(i)(0 to integer(ceil(real(kernel_size ** 2) / real(2 ** i))) - 1),
				kernel_en           => s_kernel_en_line(i),
				kernel_complete     => s_kernel_complete_line(i),
				output_matrix       => s_pipeline_values(i + 1)(0 to integer(ceil(real(kernel_size ** 2) / real(2 ** (i + 1)))) - 1),
				kernel_en_del       => s_kernel_en_line(i + 1),
				kernel_complete_del => s_kernel_complete_line(i + 1)
			);

	end generate KERNEL_STEP_GEN;

	-- Set inputs of pipeline
	s_pipeline_values(s_pipeline_values'low)           <= s_pipeline_start;
	s_kernel_en_line(s_kernel_en_line'low)             <= kernel_en;
	s_kernel_complete_line(s_kernel_complete_line'low) <= kernel_complete;

	-- Set outputs of pipeline

	SET_NEW_PIXEL : if pool_or_conv = 1 generate

		ADD_SHIFT : if enable_shift = 1 generate

			SHIFT_DELAY_PROC : process (clk) is
			begin

				if rising_edge(clk) then
					if reset = '1' then
						s_kernel_en_shift       <= '0';
						s_kernel_complete_shift <= '0';
						s_pipeline_begin_shift  <= (others => '0');
					else
						s_kernel_en_shift       <= s_kernel_en_line(s_kernel_en_line'high);
						s_kernel_complete_shift <= s_kernel_complete_line(s_kernel_complete_line'high);
						s_pipeline_begin_shift  <= s_pipeline_end;
					end if;
				end if;

			end process SHIFT_DELAY_PROC;

			-- Shift can always be a shift right because value will always decrease => no need for multiplexing
			s_pipeline_result_shift <= std_logic_vector(shift_right(signed(s_pipeline_begin_shift), to_integer(unsigned(shamt))));

			ADD_BIAS : if enable_bias = 1 generate

				BIAS_DELAY_PROC : process (clk) is
				begin

					if rising_edge(clk) then
						if reset = '1' then
							s_kernel_en_bias       <= '0';
							s_kernel_complete_bias <= '0';
							s_pipeline_begin_bias  <= (others => '0');
						else
							s_kernel_en_bias       <= s_kernel_en_shift;
							s_kernel_complete_bias <= s_kernel_complete_shift;
							s_pipeline_begin_bias  <= s_pipeline_result_shift;
						end if;
					end if;

				end process BIAS_DELAY_PROC;

				CLIP_ADD_GEN : if enable_clip_adder = 1 generate

					CLIP_ADD_INST : entity work.clip_adder
						generic map (
							vector_length => input_length
						)
						port map (
							din0 => s_pipeline_begin_bias,
							din1 => bias,
							dout => s_pipeline_result_bias
						);

				else generate
					s_pipeline_result_bias <= std_logic_vector(signed(s_pipeline_begin_bias) + signed(bias));
				end generate CLIP_ADD_GEN;

				-- Shift + bias + Clipping
				s_new_pixel     <= std_logic_vector(to_signed(- 2 ** (output_length - 1), s_new_pixel'length)) when signed(s_pipeline_result_bias) < (- 2 ** (output_length - 1)) else
	                   std_logic_vector(to_signed(2 ** (output_length - 1) - 1, s_new_pixel'length)) when signed(s_pipeline_result_bias) > (2 ** (output_length - 1) - 1) else
	                   s_pipeline_result_bias(output_length - 1 downto 0);
				s_valid_pixel   <= s_kernel_en_bias;
				s_comp_complete <= s_kernel_complete_bias;
			else generate
				-- Shift + Clipping
				s_new_pixel     <= std_logic_vector(to_signed(- 2 ** (output_length - 1), s_new_pixel'length)) when signed(s_pipeline_result_shift) < (- 2 ** (output_length - 1)) else
	                   std_logic_vector(to_signed(2 ** (output_length - 1) - 1, s_new_pixel'length)) when signed(s_pipeline_result_shift) > (2 ** (output_length - 1) - 1) else
	                   s_pipeline_result_shift(output_length - 1 downto 0);
				s_valid_pixel   <= s_kernel_en_shift;
				s_comp_complete <= s_kernel_complete_shift;
			end generate ADD_BIAS;

		else generate
			-- Clipping
			s_new_pixel     <= std_logic_vector(to_signed(-2 ** (output_length - 1), s_new_pixel'length)) when signed(s_pipeline_end) < (-2 ** (output_length - 1)) else
	                   std_logic_vector(to_signed(2 ** (output_length - 1) - 1, s_new_pixel'length)) when signed(s_pipeline_end) > (2 ** (output_length - 1) - 1) else
	                   s_pipeline_end(output_length - 1 downto 0);
			s_valid_pixel   <= s_kernel_en_line(s_kernel_en_line'high);
			s_comp_complete <= s_kernel_complete_line(s_kernel_complete_line'high);
		end generate ADD_SHIFT;

	else generate
		-- Do nothing (only for pooling)
		s_new_pixel     <= s_pipeline_end(output_length - 1 downto 0);
		s_valid_pixel   <= s_kernel_en_line(s_kernel_en_line'high);
		s_comp_complete <= s_kernel_complete_line(s_kernel_complete_line'high);
	end generate SET_NEW_PIXEL;

	RELU_GEN : if enable_relu = 1 and pool_or_conv = 1 generate

		RELU_DELAY_PROC : process (clk) is
		begin

			if rising_edge(clk) then
				if reset = '1' then
					s_kernel_en_relu       <= '0';
					s_kernel_complete_relu <= '0';
					s_pipeline_begin_relu  <= (others => '0');
				else
					s_kernel_en_relu       <= s_valid_pixel;
					s_kernel_complete_relu <= s_comp_complete;
					s_pipeline_begin_relu  <= s_new_pixel;
				end if;
			end if;

		end process RELU_DELAY_PROC;

		-- ReLU computation
		s_pipeline_result_relu <= (others => '0') when signed(s_pipeline_begin_relu) < 0 else s_pipeline_begin_relu;
		-- Set outputs
		new_pixel     <= s_pipeline_result_relu;
		valid_pixel   <= s_kernel_en_relu;
		comp_complete <= s_kernel_complete_relu;
	else generate
		new_pixel     <= s_new_pixel;
		valid_pixel   <= s_valid_pixel;
		comp_complete <= s_comp_complete;
	end generate RELU_GEN;

end architecture rtl;
