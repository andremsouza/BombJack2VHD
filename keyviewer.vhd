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
	type bg is array (0 to 1199) of std_logic_vector(15 downto 0);
	type lvlpf is array (1 downto 0) of std_logic_vector(0 to 1199); --PLATFORMS
	type lvlbb is array (1 downto 0) of std_logic_vector(0 to 1199); -- BOMBS
	type lvlbn is array (1 downto 0) of integer;
	type lvlip is array (1 downto 0) of std_logic_vector(15 downto 0); -- INITIAL POSITION
	type lvlep0 is array (1 downto 0) of std_logic_vector(15 downto 0); -- ENEMY POSITION
	type lvlep1 is array (1 downto 0) of std_logic_vector(15 downto 0); -- ENEMY POSITION
	
	signal VIDEOE: std_logic_vector(7 downto 0);
	
	signal JACKPOS: std_logic_vector(15 downto 0);
	signal JACKPOSA: std_logic_vector(15 downto 0);
	signal JACKCHAR: std_logic_vector(7 downto 0);
	signal JACKCOLOR: std_logic_vector(3 downto 0);
	signal JDELAY: std_logic_vector(31 downto 0);
	signal JACKSTATE: std_logic_vector(7 downto 0);
	signal JUMPSTATE: std_logic_vector(7 downto 0);
	
	signal LVLE: std_logic_vector(3 downto 0) := x"0";
	signal PLATFORM: lvlpf := (0 => (0 to 39|1160 to 1199|172 downto 162|504 downto 493|796 downto 789|970 downto 963 => '1', others => '0'), 1 => (others => '0')); -- Falta nivel 2
	signal BOMB: lvlbb := (0 => (203|206|209|319|320|455|458|461|479|480|535|538|541|639|640|799|800|926 => '1', others => '0'), 1 => (others => '0')); -- Falta nivel 2
	signal BNUMBER :lvlbn := (18, 0); -- Falta nÃ­vel 2
	signal JACKPOSI: lvlip := (0 => (x"0072"), 1 => (others => '0')); -- Falta nivel 2
	signal ENEMY0: lvlep0 := (0 => (x"007F"), 1 => (others => '0')); -- Falta nivel 2
	signal ENEMY1: lvlep0 := (0 => (x"0481"), 1 => (others => '0')); -- Falta nivel 2
	
	signal BACKGROUND: bg;
	signal BGMAKE: std_logic := '0';
	signal BGDRAW: std_logic := '0';
begin
	process(clk, reset) -- Draw Background
	begin
		if(reset = '1') then
			BGMAKE <= '0';
			BACKGROUND <= (others => (15 downto 12|11 downto 8|7|1 => '0', others => '1'));
		elsif(clk'event and clk='1') then
			if(BGMAKE = '0') then
				for I in 0 to 1199 loop
					if(PLATFORM(conv_integer(LVLE))(I) = '1') then
						BACKGROUND(I)(15 downto 12) <= x"0";
						BACKGROUND(I)(11 downto 8) <= x"3";
						BACKGROUND(I)(7 downto 0) <= x"02";
					elsif(BOMB(conv_integer(LVLE))(I) = '1') then
						BACKGROUND(I)(15 downto 12) <= x"0";
						BACKGROUND(I)(11 downto 8) <= x"9";
						BACKGROUND(I)(7 downto 0) <= x"2A";
					else
						BACKGROUND(I) <= "0000000001111101";
					end if;
				end loop;
				BGMAKE <= '1';
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
			JACKPOS <= JACKPOSI(conv_integer(LVLE));
			JDELAY <= x"00000000";
			JUMPSTATE <= x"00";
			JACKSTATE <= x"00";
		elsif (clk'event and clk = '1') then
			if(PLATFORM(conv_integer(LVLE))(conv_integer(JACKPOS) + 40) = '0' and JUMPSTATE = x"00") then
				JUMPSTATE <= x"02";
			end if;
			case JUMPSTATE is -- Controle de pulo
				when x"00" => -- Parado (vertical)
				when x"01" => -- Subindo
					if(PLATFORM(conv_integer(LVLE))(conv_integer(JACKPOS) - 2*40) = '0') then
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
					if(PLATFORM(conv_integer(LVLE))(conv_integer(JACKPOS) + 40) = '0') then
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
							if(not((conv_integer(JACKPOS) mod 40) = 0) and PLATFORM(conv_integer(LVLE))(conv_integer(JACKPOS) - 1) = '0') then-- and PLATFORM(conv_integer(LVLE))(conv_integer(JACKPOS) - 41) = '0') then
								JACKPOS <= JACKPOS - x"01";
							end if;
						when x"20"|x"77" => -- Space -- new
							if(JUMPSTATE = x"00") then
								JUMPSTATE <= x"01";
							end if; -- end new
						when x"64"|x"44" => -- D -- Direita
							if(not((conv_integer(JACKPOS) mod 40) = 39) and PLATFORM(conv_integer(LVLE))(conv_integer(JACKPOS) + 1) = '0' )then-- and PLATFORM(conv_integer(LVLE))(conv_integer(JACKPOS) - 39) = '0') then
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
	begin
		if (reset='1') then
			VIDEOE <= x"00";
			videodraw <= '0';
			--JACKPOSA <= x"0000";
			BGDRAW <= '0';
		elsif (clk'event and clk = '1') then
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
						VIDEOE <= x"02";
					end if;
				when x"02" => --Apaga Jack Head
					if(JACKPOSA = JACKPOS) then
						VIDEOE <= x"00";
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
						VIDEOE <= x"00";
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
					VIDEOE <= x"0A";
				when others =>
					videodraw <= '0';
					VIDEOE <= x"00";
			end case;
		end if;
	end process;

end behav;