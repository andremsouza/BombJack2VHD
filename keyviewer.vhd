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
begin

	process(clk, reset) --Jack movement
	begin
		if(reset = '1') then
			JACKCHAR <= x"24";
			JACKCOLOR <= x"C";
			JACKPOS <= x"026B";
			JDELAY <= x"00000000";
			JACKSTATE <= x"00";
		elsif (clk'event and clk = '1') then
			case JACKSTATE is
				when x"00" =>
					case key is
						when x"61" => -- A
							if(not((conv_integer(JACKPOS) mod 40) = 0)) then
								JACKPOS <= JACKPOS - x"01";
							end if;
						when x"64" => -- D
							if(not((conv_integer(JACKPOS) mod 40) = 39)) then
								JACKPOS <= JACKPOS + x"01";
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
				when others =>
					videodraw <= '0';
					VIDEOE <= x"00";
			end case;
		end if;
	end process;

--	process(clk, reset)
--	variable state: std_logic_vector(3 downto 0);
--	begin
--		if(reset = '1') then
--			state := x"0";
--			videodraw <= '0';
--		elsif(clk'event and clk = '1') then
--			if(key /= x"FF") then
--				case state is
--					when x"0" =>
--						videopos <= x"002D";
--						videochar(7 downto 0) <= key;
--						videochar(11 downto 8) <= x"C";
--						videochar(15 downto 12) <= x"1";
--						videodraw <= '1';
--						state := x"1";
--					when others =>
--						videopos <= x"002D";
--						videochar(7 downto 0) <= key;
--						videochar(11 downto 8) <= x"C";
--						videochar(15 downto 12) <= x"1";
--						videodraw <= '0';
--						state := x"0";
--				end case;
--			end if;
--		end if;
--	end process;

end behav;