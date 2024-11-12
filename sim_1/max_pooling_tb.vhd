
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;
use work.libmatrix.all;

entity max_pooling_tb is
end;

architecture bench of max_pooling_tb is
  -- Clock period
  constant clk_period : time := 5 ns;
  -- Generics
  constant number_width : natural := 8;
  constant width : natural := 4;
  constant height : natural := 4;
  constant channels : natural := 1;
  constant kernel_size : natural := 2;
  -- Ports
  signal clk : std_logic := '1';
  signal reset : std_logic;
  signal en : std_logic;
  signal input : matrix_3d(0 to channels - 1)(0 to width - 1)(0 to height - 1)(number_width - 1 downto 0);
  signal output : matrix_3d(0 to channels - 1)(0 to width / kernel_size - 1)(0 to height / kernel_size - 1)(number_width - 1 downto 0);
  signal finished : std_logic;
begin

  max_pooling_inst : entity work.max_pooling
  generic map (
    number_width => number_width,
    width => width,
    height => height,
    channels => channels,
    kernel_size => kernel_size
  )
  port map (
    clk => clk,
    reset => reset,
    en => en,
    input => input,
    output => output,
    finished => finished
  );

  clk   <= not clk after clk_period / 2;
  reset <= '1' after 0 ns, '0' after  1.5 * clk_period;
  en    <= '0' after 0 ns, '1' after 2 * clk_period;
  input(0) <= (("00101011", "01101011", "10110011", "11010111"), ("11111111", "00001001", "11111111", "10001101"), ("00000101", "00010001", "11001010", "10010101"), ("00000000", "00000011", "00000011", "00000010")) after 0 ns;
  -- input(0) <= (("00101011", "01101011"), ("11111111", "00001001")) after 0 ns;
  -- input(1) <= (("10110011", "11010111"), ("11111111", "10001101")) after 0 ns;
  -- input(2) <= (("00000101", "00010001"), ("00000000", "00000011")) after 0 ns;
  -- input(3) <= (("11001010", "10010101"), ("00000011", "00000010")) after 0 ns;

  WAITFORRES : process is
  begin

	  wait for 10 * clk_period;
	  finish;

  end process WAITFORRES;
end;