LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--This entity also slows the clock_50 down but using 21 bits

ENTITY counter IS
GENERIC (N : INTEGER := 20);
PORT (sclr, enable, clk	: IN STD_LOGIC;
		cout					: OUT STD_LOGIC);
END ENTITY;

ARCHITECTURE behaviour OF counter IS
SIGNAL Q					: STD_LOGIC_VECTOR (N DOWNTO 0);
SIGNAL adder, D		: UNSIGNED(N DOWNTO 0);
BEGIN

adder <= (0 => '1', OTHERS => '0');				-- Sets adder = "0000...01"

PROCESS(clk)
BEGIN

	IF(rising_edge(clk) AND sclr = '1') THEN
		Q <= (OTHERS => '0');	
	ELSIF (rising_edge(clk) AND enable = '1') THEN
		Q <= STD_LOGIC_VECTOR(D + adder);
	END IF;
	D <= UNSIGNED(Q);	
END PROCESS;
cout <= Q(Q'left);	

END behaviour;