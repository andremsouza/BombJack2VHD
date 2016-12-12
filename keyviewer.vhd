library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

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
	type bg is array (0 to 1199) of std_logic_vector(15 downto 0);
	type lvlpf is array (2 downto 0) of std_logic_vector(0 to 1199); --PLATFORMS
	type lvlbb is array (1 downto 0) of std_logic_vector(0 to 1199); -- BOMBS
	type lvlbn is array (1 downto 0) of integer;
	type lvlip is array (2 downto 0) of std_logic_vector(0 to 15); -- INITIAL POSITION
	type lvlep is array (1 downto 0) of std_logic_vector(0 to 15); -- ENEMY POSITION
	
	signal VIDEOE: std_logic_vector(7 downto 0);
	
	signal JACKPOS: std_logic_vector(15 downto 0);
	signal JACKPOSA: std_logic_vector(15 downto 0) := x"FFFF";
	signal JACKCHAR: std_logic_vector(7 downto 0);
	signal JACKCOLOR: std_logic_vector(3 downto 0);
	signal JDELAY: std_logic_vector(31 downto 0);
	signal JACKSTATE: std_logic_vector(7 downto 0);
	signal JUMPSTATE: std_logic_vector(7 downto 0);
	
	signal LVLSTATE: integer := 0;
	signal LVLSTATEA: integer := 99;
	signal PLATFORM: lvlpf := 
		(
		0 => (0 to 39|1160 to 1199|172 downto 162|504 downto 493|796 downto 789|970 downto 963 => '1', others => '0'), 
		1 => (0 to 39|1160 to 1199|217 to 225|280 to 290|610 to 615|630 to 639|960 to 971 => '1', others => '0'),
		2 => (others => '0')
		);
	signal BOMB: lvlbb := 
		(
		0 => (203|206|209|319|320|455|458|461|479|480|535|538|541|639|640|799|800|926 => '1', others => '0'), 
		1 => (216|249|336|456|466|569|576|586|671|674|677|706|826|922|925|928|931|946 => '1', others => '0')
		);
	signal BNUMBER: lvlbn := (0 => 18, 1 => 18);
	signal JACKPOSI: lvlip := (0 => (x"0072"), 1 => x"004A", 2 => x"0243");
	
	signal ENEMYCHAR: std_logic_vector(7 downto 0) := x"04";
	signal ENEMYCOLOR: std_logic_vector(3 downto 0) := x"F";
	signal EDELAY: std_logic_vector(31 downto 0);
	
	signal ENEMY0: lvlep := (0 => (x"007F"), 1 => x"0399");
	signal ENEMY0POS: std_logic_vector(15 downto 0);
	signal ENEMY0POSA: std_logic_vector(15 downto 0) := x"FFFF";
	signal E0STATE: std_logic_vector(7 downto 0);
	signal ENEMY1: lvlep := (0 => (x"0481"), 1 => x"047A");
	signal ENEMY1POS: std_logic_vector(15 downto 0);
	signal ENEMY1POSA: std_logic_vector(15 downto 0) := x"FFFF";
	signal E1STATE: std_logic_vector(7 downto 0);
	signal EMAXDELAY: std_logic_vector(31 downto 0) := x"0000FFFF";
	
	signal BACKGROUND: bg;
	signal BGMAKE: std_logic := '0';
	signal BGREMAKE: std_logic := '0';
	signal BGDRAW: std_logic := '0';
begin
	process(clk, reset) -- Enemy0
		variable delay0: std_logic_vector(31 downto 0) := x"00000000"; -- tempo para mudar de posicao -- ajustar max
		variable lr: std_logic := '0';
	begin
		if(reset = '1') then
			ENEMY0POS <= ENEMY0(0);
			E0STATE <= x"00";
			delay0 := x"00000000";
			lr := '0';
		elsif (clk'event and clk = '1') then
				if(LVLSTATEA /= LVLSTATE) then
					ENEMY0POS <= ENEMY0(LVLSTATE);
				end if;
			case E0STATE is -- Controle de movimento
				when x"00" => -- Left
					case lr is
						when '0' =>
							if(PLATFORM(LVLSTATE)(conv_integer(ENEMY0POS) + 39) = '1' and not((conv_integer(ENEMY0POS) mod 40) = 0)) then
								ENEMY0POS <= ENEMY0POS - x"01";
								E0STATE <= x"01";
							else
								lr := '1';
								E0STATE <= x"01";
							end if;
						when '1' =>
							if(PLATFORM(LVLSTATE)(conv_integer(ENEMY0POS) + 41) = '1' and not((conv_integer(ENEMY0POS) mod 40) = 39)) then
								ENEMY0POS <= ENEMY0POS + x"01";
								E0STATE <= x"01";
							else
								lr := '0';
								E0STATE <= x"01";
							end if;
					end case;
				when x"01" =>
					if delay0 >= EMAXDELAY then --ajustar
						delay0 := x"00000000"; --ajustar
						E0STATE <= x"00";
					else
						delay0 := delay0 + x"01";
					end if;
				when others =>
			end case;
		end if;
	end process;
	process(clk, reset) -- ENEMY1
		variable delay1: std_logic_vector(31 downto 0) := x"00000000"; -- tempo para mudar de posicao -- ajustar max
		variable lr: std_logic := '0';
	begin
		if(reset = '1') then
			ENEMY1POS <= ENEMY1(0);
			E1STATE <= x"00";
			delay1 := x"00000000";
			lr := '0';
		elsif (clk'event and clk = '1') then
				if(LVLSTATEA /= LVLSTATE) then
					ENEMY1POS <= ENEMY1(LVLSTATE);
				end if;
			case E1STATE is -- Controle de movimento
				when x"00" => -- Left
					case lr is
						when '0' =>
							if(PLATFORM(LVLSTATE)(conv_integer(ENEMY1POS) + 39) = '1' and not((conv_integer(ENEMY1POS) mod 40) = 0)) then
								ENEMY1POS <= ENEMY1POS - x"01";
								E1STATE <= x"01";
							else
								lr := '1';
								E1STATE <= x"01";
							end if;
						when '1' =>
							if(PLATFORM(LVLSTATE)(conv_integer(ENEMY1POS) + 41) = '1' and not((conv_integer(ENEMY1POS) mod 40) = 39)) then
								ENEMY1POS <= ENEMY1POS + x"01";
								E1STATE <= x"01";
							else
								lr := '0';
								E1STATE <= x"01";
							end if;
					end case;
				when x"01" =>
					if delay1 >= (conv_integer(EMAXDELAY)/2) then --ajustar
						delay1 := x"00000000"; --ajustar
						E1STATE <= x"00";
					else
						delay1 := delay1 + x"01";
					end if;
				when others =>
			end case;
		end if;
	end process;

	process(clk, reset) -- Level Control
		variable delaylc: std_logic_vector(7 downto 0) := x"00";
	begin
		if(reset = '1') then
			LVLSTATE <= 0;
			BOMB <=
				(0 => (203|206|209|319|320|455|458|461|479|480|535|538|541|639|640|799|800|926 => '1', others => '0'), 
				1 => (216|249|336|456|466|569|576|586|671|674|677|706|826|922|925|928|931|946 => '1', others => '0'));
			BNUMBER <= (0 => 18, 1 => 18);
			delaylc := x"00";
			LVLSTATEA <= 99;
			EMAXDELAY <= x"0000FFFF";
		elsif(clk'event and clk = '1') then
			if(LVLSTATEA /= LVLSTATE) then
				if(EMAXDELAY > x"00004E20") then
					EMAXDELAY <= EMAXDELAY - x"00004E20";
				else
					EMAXDELAY <= x"00000FFF";
				end if;
			end if;
			if(BGREMAKE = '1') then
				BGREMAKE <= '0';
			end if;
			if(JACKPOS = ENEMY0POS or JACKPOS = ENEMY1POS) then
				LVLSTATE <= 2;
			end if;
			case LVLSTATE is
				when 0 =>
					if (BOMB(LVLSTATE)(conv_integer(JACKPOS)) = '1' or BOMB(LVLSTATE)(conv_integer(JACKPOS) - 40) = '1') then
						BOMB(LVLSTATE)(conv_integer(JACKPOS)) <= '0';
						BOMB(LVLSTATE)(conv_integer(JACKPOS) - 40) <= '0';
						BNUMBER(LVLSTATE) <= BNUMBER(LVLSTATE) - 1;
						BGREMAKE <= '1';
					end if;
					if(BNUMBER(LVLSTATE) = 0) then
						LVLSTATE <= 1;
						BGREMAKE <= '1';
					else
						LVLSTATEA <= LVLSTATE;
					end if;
				when 1 =>
						if (BOMB(LVLSTATE)(conv_integer(JACKPOS)) = '1' or BOMB(LVLSTATE)(conv_integer(JACKPOS) - 40) = '1') then
						BOMB(LVLSTATE)(conv_integer(JACKPOS)) <= '0';
						BOMB(LVLSTATE)(conv_integer(JACKPOS) - 40) <= '0';
						BNUMBER(LVLSTATE) <= BNUMBER(LVLSTATE) - 1;
						BGREMAKE <= '1';
					end if;
					if(BNUMBER(LVLSTATE) = 0) then
						LVLSTATE <= 0;
						BOMB <=
						(0 => (203|206|209|319|320|455|458|461|479|480|535|538|541|639|640|799|800|926 => '1', others => '0'), 
						1 => (216|249|336|456|466|569|576|586|671|674|677|706|826|922|925|928|931|946 => '1', others => '0'));
						BNUMBER <= (0 => 18, 1 => 18);
						BGREMAKE <= '1';
					else
						LVLSTATEA <= LVLSTATE;
					end if;
				when 2 =>
					if(delaylc > x"00") then
						LVLSTATEA <= LVLSTATE;
						delaylc := x"00";
					else
						delaylc := delaylc + x"01";
					end if;
				when others =>
			end case;
		end if;
	end process;
	process(clk, reset) -- Draw Background
	begin
		if(reset = '1') then
			BGMAKE <= '0';
			BACKGROUND <= (others => (15 downto 12|11 downto 8|7|1 => '0', others => '1'));
		elsif(clk'event and clk='1') then
			if(BGREMAKE = '1') then
				BGMAKE <= '0';
			end if;
			if(BGMAKE = '0' and LVLSTATE /= 2) then
				for I in 0 to 1199 loop
					if(PLATFORM(LVLSTATE)(I) = '1') then
						BACKGROUND(I)(15 downto 12) <= x"0";
						BACKGROUND(I)(11 downto 8) <= x"3";
						BACKGROUND(I)(7 downto 0) <= x"02";
					elsif(BOMB(LVLSTATE)(I) = '1') then
						BACKGROUND(I)(15 downto 12) <= x"0";
						BACKGROUND(I)(11 downto 8) <= x"9";
						BACKGROUND(I)(7 downto 0) <= x"2A";
					else
						BACKGROUND(I) <= (15 downto 12|11 downto 8|7|1 => '0', others => '1');
					end if;
				end loop;
				BACKGROUND(1)(15 downto 12) <= x"0";
				BACKGROUND(1)(11 downto 8) <= x"F";
				BACKGROUND(1)(7 downto 0) <= x"53";
				BACKGROUND(2)(15 downto 12) <= x"0";
				BACKGROUND(2)(11 downto 8) <= x"F";
				BACKGROUND(2)(7 downto 0) <= x"43";
				BACKGROUND(3)(15 downto 12) <= x"0";
				BACKGROUND(3)(11 downto 8) <= x"F";
				BACKGROUND(3)(7 downto 0) <= x"4F";
				BACKGROUND(4)(15 downto 12) <= x"0";
				BACKGROUND(4)(11 downto 8) <= x"F";
				BACKGROUND(4)(7 downto 0) <= x"52";
				BACKGROUND(5)(15 downto 12) <= x"0";
				BACKGROUND(5)(11 downto 8) <= x"F";
				BACKGROUND(5)(7 downto 0) <= x"45";
				BACKGROUND(6)(15 downto 12) <= x"0";
				BACKGROUND(6)(11 downto 8) <= x"F";
				BACKGROUND(6)(7 downto 0) <= x"3A";
				BACKGROUND(7)(15 downto 12) <= x"0";
				BACKGROUND(7)(11 downto 8) <= x"F";
				BACKGROUND(7)(7 downto 0) <= x"20";
				BGMAKE <= '1';
			end if;
			if(LVLSTATE = 2) then
				BACKGROUND <= (others => (15 downto 12|11 downto 8|7|1 => '0', others => '1'));
				BACKGROUND(575)(15 downto 12) <= x"0";
				BACKGROUND(575)(11 downto 8) <= x"F";
				BACKGROUND(575)(7 downto 0) <= x"47";
				BACKGROUND(576)(15 downto 12) <= x"0";
				BACKGROUND(576)(11 downto 8) <= x"F";
				BACKGROUND(576)(7 downto 0) <= x"41";
				BACKGROUND(577)(15 downto 12) <= x"0";
				BACKGROUND(577)(11 downto 8) <= x"F";
				BACKGROUND(577)(7 downto 0) <= x"4D";
				BACKGROUND(578)(15 downto 12) <= x"0";
				BACKGROUND(578)(11 downto 8) <= x"F";
				BACKGROUND(578)(7 downto 0) <= x"45";
				BACKGROUND(579)(15 downto 12) <= x"0";
				BACKGROUND(579)(11 downto 8) <= x"F";
				BACKGROUND(579)(7 downto 0) <= x"20";
				BACKGROUND(580)(15 downto 12) <= x"0";
				BACKGROUND(580)(11 downto 8) <= x"F";
				BACKGROUND(580)(7 downto 0) <= x"4F";
				BACKGROUND(581)(15 downto 12) <= x"0";
				BACKGROUND(581)(11 downto 8) <= x"F";
				BACKGROUND(581)(7 downto 0) <= x"56";
				BACKGROUND(582)(15 downto 12) <= x"0";
				BACKGROUND(582)(11 downto 8) <= x"F";
				BACKGROUND(582)(7 downto 0) <= x"45";
				BACKGROUND(583)(15 downto 12) <= x"0";
				BACKGROUND(583)(11 downto 8) <= x"F";
				BACKGROUND(583)(7 downto 0) <= x"52";
			end if;
		end if;
	end process;

	process(clk, reset) --Jack movement
		variable delayj1: std_logic_vector(31 downto 0) := x"00000000"; -- tempo para mudar de posicao -- ajustar max
		variable delayj2: std_logic_vector(31 downto 0) := x"00000000"; -- tempo para parar de subir -- ajustar max
	begin
		if(reset = '1') then
			JACKCHAR <= x"01";
			JACKCOLOR <= x"C";
			JACKPOS <= JACKPOSI(LVLSTATE);
			JDELAY <= x"00000000";
			JUMPSTATE <= x"00";
			JACKSTATE <= x"00";
		elsif (clk'event and clk = '1') then
			if(LVLSTATEA /= LVLSTATE) then
				JACKPOS <= JACKPOSI(LVLSTATE);
			end if;
			if(PLATFORM(LVLSTATE)(conv_integer(JACKPOS) + 40) = '0' and JUMPSTATE = x"00") then
				JUMPSTATE <= x"02";
			end if;
			case JUMPSTATE is -- Controle de pulo
				when x"00" => -- Parado (vertical)
				when x"01" => -- Subindo
					if(PLATFORM(LVLSTATE)(conv_integer(JACKPOS) - 2*40) = '0') then
						if(delayj2 >= x"00000010") then --ajustar
							delayj2 := x"00000000"; --ajustar
							JUMPSTATE <= x"02";
						else
							if(delayj1 >= x"000023FF") then --ajustar
								delayj1 := x"00000000"; -- ajustar
								delayj2 := delayj2 + x"01";
								JACKPOS <= JACKPOS - x"28";
							else
								delayj1 := delayj1 + x"01";
							end if;
						end if;
					else
						delayj1 := x"00000000";
						delayj2 := x"00000000";
						JUMPSTATE <= x"02";
					end if;
				when x"02" => -- Caindo
					if(PLATFORM(LVLSTATE)(conv_integer(JACKPOS) + 40) = '0') then
						if(delayj1 >= x"000037FF") then -- ajustar
							delayj1 := x"00000000"; --ajustar
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
						when x"61"|x"41" => -- A -- Esquerda
							if(not((conv_integer(JACKPOS) mod 40) = 0) and PLATFORM(LVLSTATE)(conv_integer(JACKPOS) - 1) = '0' and PLATFORM(LVLSTATE)(conv_integer(JACKPOS) - 41) = '0') then
								JACKPOS <= JACKPOS - x"01";
							end if;
						when x"20"|x"77" => -- Space -- new
							if(JUMPSTATE = x"00") then
								JUMPSTATE <= x"01";
							end if; -- end new
						when x"64"|x"44" => -- D -- Direita
							if(not((conv_integer(JACKPOS) mod 40) = 39) and PLATFORM(LVLSTATE)(conv_integer(JACKPOS) + 1) = '0' and PLATFORM(LVLSTATE)(conv_integer(JACKPOS) - 39) = '0') then
								JACKPOS <= JACKPOS + x"01";
							end if;		
						when others =>
					end case;
					JACKSTATE <= x"01";
				when x"01" =>
					if JDELAY >= x"00000FFF" then --ajustar
						JDELAY <= x"00000000"; --ajustar
						JACKSTATE <= x"00";
					else
						JDELAY <= JDELAY + x"01";
					end if;
				when others =>
			end case;
		end if;
	end process;

	process(clk, reset) -- Draw video
	VARIABLE DRAWPOS: std_logic_vector(15 downto 0) := (others => '0');
	variable score: std_logic_vector(7 downto 0) := x"00";
	variable scoredraw: std_logic := '0';
	begin
		if (reset='1') then
			VIDEOE <= x"00";
			videodraw <= '0';
			--JACKPOSA <= x"0000";
			--ENEMY0POSA <= x"0000";
			BGDRAW <= '0';
			scoredraw := '0';
			DRAWPOS := x"0000";
			score := x"00";
		elsif (clk'event and clk = '1') then
			if(LVLSTATEA /= LVLSTATE) then
				BGDRAW <= '0';
				scoredraw := '0';
				DRAWPOS := x"0000";
				if(LVLSTATE /= 2)then
					score := score + x"01";
				end if;
			end if;
			case VIDEOE is
				when x"00" => -- draw background
					if(BGDRAW = '0') then
						if(conv_integer(DRAWPOS) <= 1199) then
							videochar <= BACKGROUND(conv_integer(DRAWPOS));
							videopos <= DRAWPOS;
							videodraw <= '1';
							DRAWPOS := DRAWPOS + x"01";
						else
							BGDRAW <= '1';
						end if;
					end if;
					VIDEOE <= x"01";
				when x"01" => --videodraw
					videodraw <= '0';
					if(BGDRAW = '0') then
						VIDEOE <= x"00";
					else
						VIDEOE <= x"32";
					end if;
				when x"32" => -- desenha n0
					if(scoredraw = '0') then
						videochar(15 downto 12) <= "0000";
						videochar(11 downto 8) <= x"F";
						videochar(7 downto 0) <= score + x"30";
						videopos(15 downto 0) <= x"0008";
						videodraw <= '1';
						scoredraw := '1';
					end if;
					VIDEOE <= x"33";
				when x"33" => --videodraw
					videodraw <= '0';
					VIDEOE <= x"34";
					
					videodraw <= '0';
					VIDEOE <= x"02";
				when x"02" => --Apaga Jack Head
					if(JACKPOSA = JACKPOS) then
						VIDEOE <= x"10";
					else
						videochar <= BACKGROUND(conv_integer(JACKPOSA) - 40);
						videopos(15 downto 0) <= JACKPOSA - 40;
						videodraw <= '1';
						VIDEOE <= x"03";
					end if;
				when x"03" => -- videodraw
					videodraw <= '0';
					VIDEOE <= x"04";
				when x"04" => -- Apaga Jack Body
					if(JACKPOSA = JACKPOS) then
						VIDEOE <= x"10";
					else
						videochar <= BACKGROUND(conv_integer(JACKPOSA));
						videopos(15 downto 0) <= JACKPOSA;
						videodraw <= '1';
						VIDEOE <= x"05";
					end if;
				when x"05" => -- videodraw
					videodraw <= '0';
					VIDEOE <= x"06";
				when x"06" => -- Draw Jack Head
					videochar(15 downto 12) <= "0000";
					videochar(11 downto 8) <= JACKCOLOR;
					videochar(7 downto 0) <= x"00";
					videopos(15 downto 0) <= JACKPOS - 40;
					JACKPOSA <= JACKPOS;
					videodraw <= '1';
					VIDEOE <= x"07";
				when x"07" => -- videodraw
					videodraw <= '0';
					VIDEOE <= x"08";
				when x"08" => -- draw jack body
					videochar(15 downto 12) <= "0000";
					videochar(11 downto 8) <= JACKCOLOR;
					videochar(7 downto 0) <= JACKCHAR;
					videopos(15 downto 0) <= JACKPOS;
					JACKPOSA <= JACKPOS;
					videodraw <= '1';
					VIDEOE <= x"09";
				when x"09" => -- videodraw
					videodraw <= '0';
					VIDEOE <= x"10";
				when x"10" => -- apaga enemy0 head
					if(ENEMY0POSA = ENEMY0POS) then
						VIDEOE <= x"18";
					else
						videochar <= BACKGROUND(conv_integer(ENEMY0POSA) - 40);
						videopos(15 downto 0) <= ENEMY0POSA - 40;
						videodraw <= '1';
						VIDEOE <= x"11";
					end if;
				when x"11" => -- videodraw
					videodraw <= '0';
					VIDEOE <= x"12";
				when x"12" => -- apaga enemy0 body
					if(ENEMY0POSA = ENEMY0POS) then
						VIDEOE <= x"18";
					else
						videochar <= BACKGROUND(conv_integer(ENEMY0POSA));
						videopos(15 downto 0) <= ENEMY0POSA;
						videodraw <= '1';
						VIDEOE <= x"13";
					end if;
				when x"13" => -- videodraw
					videodraw <= '0';
					VIDEOE <= x"14";
				when x"14" => -- draw enemy0 body
					videochar(15 downto 12) <= "0000";
					videochar(11 downto 8) <= ENEMYCOLOR;
					videochar(7 downto 0) <= ENEMYCHAR;
					videopos(15 downto 0) <= ENEMY0POS;
					ENEMY0POSA <= ENEMY0POS;
					videodraw <= '1';
					VIDEOE <= x"15";
				when x"15" => -- videodraw
					videodraw <= '0';
					VIDEOE <= x"16";
				when x"16" => --draw enemy0 head
					videochar(15 downto 12) <= "0000";
					videochar(11 downto 8) <= ENEMYCOLOR;
					videochar(7 downto 0) <= x"03";
					videopos(15 downto 0) <= ENEMY0POS - 40;
					ENEMY0POSA <= ENEMY0POS;
					videodraw <= '1';
					VIDEOE <= x"17";
				when x"17" => --videodraw
					videodraw <= '0';
					VIDEOE <= x"18";
				when x"18" => -- apaga enemy1 head
					if(ENEMY1POSA = ENEMY1POS) then
						VIDEOE <= x"00";
					else
						videochar <= BACKGROUND(conv_integer(ENEMY1POSA) - 40);
						videopos(15 downto 0) <= ENEMY1POSA - 40;
						videodraw <= '1';
						VIDEOE <= x"19";
					end if;
				when x"19" => -- videodraw
					videodraw <= '0';
					VIDEOE <= x"1A";
				when x"1A" => -- apaga ENEMY1 body
					if(ENEMY1POSA = ENEMY1POS) then
						VIDEOE <= x"00";
					else
						videochar <= BACKGROUND(conv_integer(ENEMY1POSA));
						videopos(15 downto 0) <= ENEMY1POSA;
						videodraw <= '1';
						VIDEOE <= x"1B";
					end if;
				when x"1B" => -- videodraw
					videodraw <= '0';
					VIDEOE <= x"1C";
				when x"1C" => -- draw ENEMY1 body
					videochar(15 downto 12) <= "0000";
					videochar(11 downto 8) <= ENEMYCOLOR;
					videochar(7 downto 0) <= ENEMYCHAR;
					videopos(15 downto 0) <= ENEMY1POS;
					ENEMY1POSA <= ENEMY1POS;
					videodraw <= '1';
					VIDEOE <= x"1D";
				when x"1D" => -- videodraw
					videodraw <= '0';
					VIDEOE <= x"1E";
				when x"1E" => --draw ENEMY1 head
					videochar(15 downto 12) <= "0000";
					videochar(11 downto 8) <= ENEMYCOLOR;
					videochar(7 downto 0) <= x"03";
					videopos(15 downto 0) <= ENEMY1POS - 40;
					ENEMY1POSA <= ENEMY1POS;
					videodraw <= '1';
					VIDEOE <= x"1F";
				when x"1F" => --videodraw
					videodraw <= '0';
					VIDEOE <= x"20";
				when others =>
					videodraw <= '0';
					VIDEOE <= x"00";
			end case;
		end if;
	end process;

end behav;