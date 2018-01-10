LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--Debouncer Circuit

-- This entity & architecture directly corresponds to the figure given on slide set 2 for debouncer circuit


ENTITY debouncer IS
GENERIC (N : INTEGER := 20);
PORT (key,clk		: IN STD_LOGIC;
		debounced	: OUT STD_LOGIC);
END ENTITY;

ARCHITECTURE behaviour OF debouncer IS

COMPONENT counter
GENERIC ( N : INTEGER := 20);
PORT (sclr, enable, clk	: IN STD_LOGIC;
		cout					: OUT STD_LOGIC);
END COMPONENT;

COMPONENT flipflop
PORT (D					: IN STD_LOGIC;
		clk, enable		: IN STD_LOGIC;
		Q					: OUT STD_LOGIC);
END COMPONENT;

SIGNAL wire1, wire2,wire3, wire4	: STD_LOGIC;
BEGIN

ff1: flipflop PORT MAP(key,clk, '1', wire1); --Connects the first and second flipflops
ff2: flipflop PORT MAP(wire1,clk,'1',wire2);
ff3: flipflop PORT MAP(wire2,clk, wire4, debounced);

counter1: counter GENERIC MAP(20) PORT MAP(wire3,NOT(wire4), clk, wire4); --Calls the counter circuit (set to 21 bits)

wire3 <= wire1 XOR wire2;


END behaviour;	