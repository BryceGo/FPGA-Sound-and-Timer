LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--This Entity is a flipflop of STD_LOGIC of 1 bit


ENTITY flipflop IS
PORT (D					: IN STD_LOGIC;
		clk, enable		: IN STD_LOGIC;
		Q					: OUT STD_LOGIC);
END ENTITY;

ARCHITECTURE behaviour OF flipflop IS

BEGIN

PROCESS(clk)
BEGIN

IF (rising_edge(clk) AND enable = '1') THEN
Q <= D;
END IF;

END PROCESS;

END behaviour;

