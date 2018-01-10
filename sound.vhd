LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;




ENTITY sound IS
	PORT (CLOCK_50,CLOCK2_50, AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK,AUD_ADCDAT			:IN STD_LOGIC;
			KEY																:IN STD_LOGIC_VECTOR(3 DOWNTO 0);
			SW																	:IN STD_LOGIC_VECTOR(17 downto 0);	
			LEDG																:OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			LEDR																:OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
			I2C_SDAT															:INOUT STD_LOGIC;
			I2C_SCLK,AUD_DACDAT,AUD_XCK								:OUT STD_LOGIC);
END sound;

ARCHITECTURE Behavior OF sound IS

													  
   -- CODEC Cores.  These will be included in your design as is
	
	COMPONENT clock_generator
		PORT(	CLOCK2_50													:IN STD_LOGIC;
		    	reset															:IN STD_LOGIC;
				AUD_XCK														:OUT STD_LOGIC);
	END COMPONENT;

	COMPONENT audio_and_video_config
		PORT(	CLOCK_50,reset												:IN STD_LOGIC;
		    	I2C_SDAT														:INOUT STD_LOGIC;
				I2C_SCLK														:OUT STD_LOGIC);
	END COMPONENT;
	
	COMPONENT audio_codec
		PORT(	CLOCK_50,reset,read_s,write_s							:IN STD_LOGIC;
				writedata_left, writedata_right						:IN STD_LOGIC_VECTOR(23 DOWNTO 0);
				AUD_ADCDAT,AUD_BCLK,AUD_ADCLRCK,AUD_DACLRCK		:IN STD_LOGIC;
				read_ready, write_ready									:OUT STD_LOGIC;
				readdata_left, readdata_right							:OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
				AUD_DACDAT													:OUT STD_LOGIC);
	END COMPONENT;

	
	COMPONENT debouncer
	GENERIC ( N : INTEGER := 20);
		PORT (key,clk		: IN STD_LOGIC;
				debounced	: OUT STD_LOGIC);
	END COMPONENT;

        -- local signals and constants.  You will want to add some stuff here
	SIGNAL read_ready, write_ready									: STD_LOGIC;
	SIGNAL readdata_left, readdata_right							: STD_LOGIC_VECTOR(23 DOWNTO 0);
	SIGNAL reset,read_s,write_s										: STD_LOGIC;
	SIGNAL writedata_left, writedata_right							: STD_LOGIC_VECTOR(23 DOWNTO 0);
	
	TYPE ARRAY8INTS is array (7 downto 0) of integer;
	TYPE ARRAY8SIGN24 is array (7 downto 0) of signed(23 DOWNTO 0);
	TYPE ARRAY8UNSIGN8 is array (7 downto 0) of unsigned(7 DOWNTO 0);
	TYPE ARRAY8SIGN2 is array (7 downto 0) of signed (1 downto 0);
	
	SIGNAL clk																: STD_LOGIC;
	SIGNAL sentCount, sentCountD										: ARRAY8UNSIGN8;
	SIGNAL amplitude														: ARRAY8SIGN24;
	SIGNAL counter_reset													: STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL switch															: STD_LOGIC_VECTOR(7 DOWNTO 0);
	
	CONSTANT MAXSAMPLE: ARRAY8INTS := (168, 150, 133, 126, 112, 100, 89, 84); 
	CONSTANT HI			: SIGNED(23 DOWNTO 0) := (18 => '1', OTHERS => '0'); -- 2^16
BEGIN


   -- The audio core requires an active high reset signal
	reset <= NOT(KEY(3));
	
	-- we will never read from the microphone in this lab, so we might as well set read_s to 0.
	read_s <= '0';

	-- instantiate the parts of the audio core. 
	my_clock_gen: clock_generator PORT MAP (CLOCK2_50, reset, AUD_XCK);
	cfg: audio_and_video_config PORT MAP (CLOCK_50, reset, I2C_SDAT, I2C_SCLK);
	codec: audio_codec PORT MAP(CLOCK_50,reset,read_s,write_s,writedata_left, writedata_right,
			AUD_ADCDAT,AUD_BCLK,AUD_ADCLRCK,AUD_DACLRCK,read_ready, write_ready,readdata_left, readdata_right,AUD_DACDAT);

-- the rest of your code goes here
--Debouncing switches
--debouncing: For i in 0 to 7 GENERATE
--debounceswitch: debouncer PORT MAP(clk => CLOCK_50, key => sw(i),debounced => switch(i));
--END GENERATE;

--switch <= SW(7 DOWNTO 0);

debouncesw7: debouncer GENERIC MAP(10) PORT MAP(clk => CLOCK_50, key => sw(7),debounced => switch(7));
debouncesw6: debouncer GENERIC MAP(10) PORT MAP(clk => CLOCK_50, key => sw(6),debounced => switch(6));
debouncesw5: debouncer GENERIC MAP(10) PORT MAP(clk => CLOCK_50, key => sw(5),debounced => switch(5));
debouncesw4: debouncer GENERIC MAP(20) PORT MAP(clk => CLOCK_50, key => sw(4),debounced => switch(4));
debouncesw3: debouncer GENERIC MAP(20) PORT MAP(clk => CLOCK_50, key => sw(3),debounced => switch(3));
debouncesw2: debouncer GENERIC MAP(20) PORT MAP(clk => CLOCK_50, key => sw(2),debounced => switch(2));
debouncesw1: debouncer GENERIC MAP(16) PORT MAP(clk => CLOCK_50, key => sw(1),debounced => switch(1));
debouncesw0: debouncer GENERIC MAP(5) PORT MAP(clk => CLOCK_50, key => sw(0),debounced => switch(0));


statemachine:PROCESS(CLOCK_50, reset)
VARIABLE PS	: STD_LOGIC := '0'; --2 states: 0 is hold, 1 is drive
VARIABLE LEVEL: STD_LOGIC_VECTOR(7 DOWNTO 0) := "11111111";
VARIABLE audiosignal	: SIGNED(23 DOWNTO 0);

BEGIN
	--IFL
	IF(reset = '1' or write_ready = '0') THEN --async reset
		PS := '0';
	ELSIF (write_ready = '1') then
		PS := '1';
	END IF;
	
	--OFL
	IF (PS = '0') then --hold state	
		write_s <= '0';
	ELSIF (PS = '1') then --drive state
		audiosignal := (others => '0');
		For i in 0 to 7 loop
			if (switch(i) = '1') then
				if (level(i) = '1') THEN
					amplitude(i) <= HI;
				elsif(level(i) = '0') THEN
					amplitude(i) <= NOT(HI) + 1;
				end if;
				audiosignal := audiosignal + amplitude(i);
		  end if;
			
			if (sentcount(i) = MAXSAMPLE(i)) then
				level(i) := NOT(level(i));
				counter_reset(i) <= '1';
			else 
				counter_reset(i) <= '0';
			end if;
		end loop;
	
		writedata_left <= std_LOGIC_VECTOR(audiosignal);
		writedata_right <= std_LOGIC_VECTOR(audiosignal);
		write_s <= '1';
	END IF;
END PROCESS;

counters:PROCESS(write_ready, reset) --counter circuit
BEGIN
for i in 0 to 7 loop
	IF(reset = '1' or counter_reset(i) = '1') THEN
		sentCount(i) <= (0 => '1', OTHERS => '0'); -- essentially "000...01"s
	ELSIF (rising_edge(write_ready)) then
		sentcount(i) <= sentCountD(i) + 1;
	END IF;
end loop;
END PROCESS;
sentCountD <= sentCount;

LEDR(7 downto 0) <= switch(7 downto 0);

END ARCHITECTURE;
