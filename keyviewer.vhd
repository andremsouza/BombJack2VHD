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
	signal JUMPSTATE: std_logic_vector(7 downto 0);
	signal PLATFORM: std_logic_vector(1199 downto 0) := (others => '0'); -- new
begin
	PLATFORM(619 downto 609) <= "11111111111";
	PLATFORM(39 downto 0) <= "1111111111111111111111111111111111111111";
	PLATFORM(1199 downto 1160) <= "1111111111111111111111111111111111111111";
	process(clk, reset) --Jack movement
		variable delayj1: std_logic_vector(31 downto 0) := x"00000000"; -- tempo para mudar de posicao -- ajustar max
		variable delayj2: std_logic_vector(31 downto 0) := x"00000000"; -- tempo para parar de subir -- ajustar max
	begin
		if(reset = '1') then
			JACKCHAR <= x"24";
			JACKCOLOR <= x"C";
			JACKPOS <= x"026B";
			JDELAY <= x"00000000";
			JUMPSTATE <= x"00";
			JACKSTATE <= x"00";
		elsif (clk'event and clk = '1') then
			case JUMPSTATE is -- Controle de pulo
				when x"00" => -- Parado
					
				when x"01" => -- Subindo
					if(PLATFORM(conv_integer(JACKPOS) - 40) = '0') then
						if(delayj2 >= x"0000000F") then
							delayj2 := x"00000000";
							JUMPSTATE <= x"02";
						else
							if(delayj1 >= x"00005FFF") then
								delayj1 := x"00000000";
								delayj2 := delayj2 + x"01";
								JACKPOS <= JACKPOS - x"28";
							else
								delayj1 := delayj1 + x"01";
							end if;
						end if;
					else
						JUMPSTATE <= x"02";
					end if;
				when x"02" => -- Caindo
					if(PLATFORM(conv_integer(JACKPOS) + 40) = '0') then
						if(delayj1 >= x"00005FFF") then
							delayj1 := x"00000000";
							JACKPOS <= JACKPOS + x"28";
						else
							delayj1 := delayj1 + x"01";
						end if;
					else 
						JUMPSTATE <= x"00";
					end if;
				when others =>
			end case;
			case JACKSTATE is -- Controle de movimento
				when x"00" =>
					case key is
						when x"61" => -- A -- Esquerda
							if(not((conv_integer(JACKPOS) mod 40) = 0)) then
								JACKPOS <= JACKPOS - x"01";
							end if;
							if(PLATFORM(conv_integer(JACKPOS) + 40) = '0' and JUMPSTATE != x"00") then
								JUMPSTATE <= x"02";
							end if;
						when x"20" => -- Space -- new
							if(JUMPSTATE = x"00") then
								JUMPSTATE <= x"01";
							end if; -- end new
						when x"64" => -- D -- Direita
							if(not((conv_integer(JACKPOS) mod 40) = 39)) then
								JACKPOS <= JACKPOS + x"01";
							end if;
							if(PLATFORM(conv_integer(JACKPOS) + 40) = '0' and JUMPSTATE != x"00") then
								JUMPSTATE <= x"02";
							end if;							
						when others =>
					end case;
					JACKSTATE <= x"01";
				when x"01" =>
					if JDELAY >= x"00000FFF" then
						JDELAY <= x"00000000";
						JACKSTATE <= x"00";
					else
						JDELAY <= JDELAY + x"01";
					end if;
				when others =>
			end case;
		end if;
	end process;
			
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
					videopos(15 downto 0) <= x"0266";
					videodraw <= '1';
					VIDEOE <= x"05";
				when others =>
					videodraw <= '0';
					VIDEOE <= x"00";
			end case;
		end if;
	end process;

end behav;