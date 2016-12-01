library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity keyviewer is
	port(
		clk: in std_logic;
		reset: in std_logic;
		key: in std_logic_vector(7 downto 0);
		videochar: out std_logic_vector(15 downto 0);
		videopos: out std_logic_vector(15 downto 0);
		videodraw: out std_logic
	);
end keyviewer;

architecture behav of keyviewer is
	signal VIDEOE: std_logic_vector(7 downto 0);
	
	signal JACKPOS: std_logic_vector(15 downto 0);
	signal JACKPOSA: std_logic_vector(15 downto 0);
	signal JACKCHAR: std_logic_vector(7 downto 0);
	signal JACKCOLOR: std_logic_vector(3 downto 0);
	
	signal JDELAY: std_logic_vector(31 downto 0);
	
	signal JACKSTATE: std_logic_vector(7 downto 0);
	signal JUMP: std_logic;
	signal FALL: std_logic;
	signal PLATFORM: std_logic_vector(1199 downto 0) <= 0; -- new
begin
	PLATFORM(619 downto 609) <= "1111111111";
	process(clk, reset) --Jack movement
	begin
		if(reset = '1') then
			JACKCHAR <= x"24";
			JACKCOLOR <= x"C";
			JACKPOS <= x"026B";
			JDELAY <= x"00000000";
			JACKSTATE <= x"00";
			JUMP <= '0';
		elsif (clk'event and clk = '1') then
			
			case JACKSTATE is
				when x"00" =>
					case key is
						when x"61" => -- A
							if(not((conv_integer(JACKPOS) mod 40) = 0)) then
								JACKPOS <= JACKPOS - x"01";
								if(PLATFORM(conv_integer(JACKPOS) + 40) = 0) then
									FALL <= 1;
								end if;
							end if;
						when x"20" => -- Space -- new
							if(not(JUMP)) then
								JUMP <= '1';
							end if; -- end new
						when x"64" => -- D
							if(not((conv_integer(JACKPOS) mod 40) = 39)) then
								JACKPOS <= JACKPOS + x"01";
								if(PLATFORM(conv_integer(JACKPOS) + 40) = 0) then
									FALL <= 1;
								end if;
							end if;
						when others =>
					end case;
					JACKSTATE <= x"01";
				when x"01" =>
					if JDELAY >= x"0000FFFF" then
						JDELAY <= x"00000000";
						JACKSTATE <= x"00";
					else
						JDELAY <= JDELAY + x"01";
					end if;
				when others =>
			end case;
		end if;
	end process;
	process(clk, JUMP, FALL) -- Jump state --new
		variable delay: std_logic_vector(31 downto 0) := x"00000000";
	begin
		if(clk'event and clk='1' and (JUMP='1' or FALL='1') then
			while(delay <= 50000000) loop --ajustar
				if(JACKPOS < x"28" or FALL = '1' or PLATFORM(conv_integer(JACKPOS) - 40) = '1') then  --40
					exit;
				end if;
				JACKPOS <= JACKPOS - x"28"; --40
				delay <= delay + x"01";
			end loop;
			JUMP <= '0';
			FALL <= '1';
			while(JACKPOS > x"487" or PLATFORM(conv_integer(JACKPOS) + 40) = '0') loop --1159
				JACKPOS <= JACKPOS + x"28";
			end loop;
			FALL <='0';
		end if;
	end process; -- end new
			
	process(clk, reset) -- Draw video
	begin
		if (reset='1') then
			VIDEOE <= x"00";
			videodraw <= '0';
			JACKPOSA <= x"0000";
		elsif (clk'event and clk = '1') then
			case VIDEOE is
				when x"00" => --Apaga Jack
					if(JACKPOSA = JACKPOS) then
						VIDEOE <= x"00";
					else
						videochar(15 downto 12) <= "0000";
						videochar(11 downto 8) <= x"F";
						videochar(7 downto 0) <= x"23";
						
						videopos(15 downto 0) <= JACKPOSA;
						
						videodraw <= '1';
						VIDEOE <= x"01";
					end if;
				when x"01" => -- videodraw
					videodraw <= '0';
					VIDEOE <= x"02";
					
				when x"02" => -- draw jack
					
					videochar(15 downto 12) <= "0000";
					videochar(11 downto 8) <= JACKCOLOR;
					videochar(7 downto 0) <= JACKCHAR;
					
					videopos(15 downto 0) <= JACKPOS;
					
					JACKPOSA <= JACKPOS;
					videodraw <= '1';
					VIDEOE <= x"03";
				when x"03" => --videodraw
					videodraw <= '0';
					VIDEOE <= x"04";
				when x"04" =>
					videochar(15 downto 12) <= "0000";
					videochar(11 downto 8) <= x"A";
					videochar(7 downto 0) <= x"3A";
					videopos(15 downto 0) <= 614;
					videodraw <= '1';
					VIDEOE <= x"05"
				when others =>
					videodraw <= '0';
					VIDEOE <= x"00";
			end case;
		end if;
	end process;

end behav;