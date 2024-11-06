library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package libmatrix is

	-- shape: x,<Vector Length>

	type matrix_1d is array (natural range <>) of std_logic_vector;

	-- shape: x,y,<Vector Length>

	type matrix_2d is array (natural range <>) of matrix_1d;

	-- shape: channel,x,y,<Vector Length>

	type matrix_3d is array (natural range <>) of matrix_2d;

end package libmatrix;
