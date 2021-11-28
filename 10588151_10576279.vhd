library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity project_reti_logiche is
  port (
    i_clk : in std_logic;
    i_rst : in std_logic;
    i_start : in std_logic;
    i_data : in std_logic_vector(7 downto 0);
    o_address : out std_logic_vector(15 downto 0);
    o_done : out std_logic;
    o_en : out std_logic;
    o_we : out std_logic;
    o_data : out std_logic_vector (7 downto 0)
    );
end project_reti_logiche;

Architecture Behavioral of project_reti_logiche is

  type state_type is (S_RST,S_START,S_LOAD_COL,S_LOAD_RIG,S_CALC_ADDR,S_LOAD_PIXEL,S_MIN_MAX,S_SHIFT,S_LOAD_PIXEL_NEW,S_NEW_PIXEL,S_SAVE_PIXEL,S_RETURN_LOAD,S_DONE);

  --Segnali per registri dello stato della FSM
  
  signal current_state: state_type;
  signal next_state: state_type;

  --Segnali per registri colonna e riga

  signal col: std_logic_vector(7 downto 0);
  signal rig: std_logic_vector(7 downto 0);

  --Segnali per accesso alla RAM
  signal current_address: std_logic_vector(15 downto 0);
  signal current_address_next: std_logic_vector(15 downto 0);
  signal new_address: std_logic_vector(15 downto 0);
  signal new_address_next: std_logic_vector(15 downto 0);
  signal offset: std_logic_vector(15 downto 0);
  signal final_address: std_logic_vector(15 downto 0);
  signal base_address: std_logic_vector(15 downto 0);

  --Segnale per i due loop
  signal flag : std_logic;
  
  --Segnale per il registro per il pixel considerato
  signal pixel: std_logic_vector(7 downto 0);

  --Segnale per il pixel temporaneo
  signal pixel_temp: std_logic_vector(15 downto 0);

  --Segnale per il nuovo pixel
  signal new_pixel: std_logic_vector(7 downto 0);
  
  --Segnali minimo e massimo valore
  signal max_v: std_logic_vector(7 downto 0);
  signal min_v: std_logic_vector(7 downto 0);

  --Segnali per lo shift value
  signal delta: std_logic_vector(7 downto 0);
  signal floor_v: std_logic_vector(7 downto 0);
  signal shift_temp: std_logic_vector(7 downto 0);
  signal shift_level: integer;
  
  --Conversioni necessarie
  signal pixel_16: std_logic_vector(15 downto 0);
  signal min_16: std_logic_vector(15 downto 0);
  
begin

    process(i_clk, i_rst, next_state)
    begin
        if(rising_edge(i_clk)) then
            if(i_rst = '1') then
                current_state <= S_RST;
            else
                current_state <= next_state;
            end if;
        end if;
    end process;
  
	process(current_state, i_start, i_data, max_v, min_v, delta, floor_v, shift_temp, shift_level, base_address, offset, current_address, current_address_next, new_address, new_address_next, final_address, pixel, pixel_temp, new_pixel, flag)
	begin
		next_state <= current_state;
		case current_state is
			when S_RST =>
				if (i_start = '1') then
				    o_done <= '0';
					o_en <= '0';
				    o_we <= '0';
				    flag <= '0';
				    next_state <= S_START;
				else
				    o_done <= '0';
					next_state <= S_RST;
				end if;
			when S_START =>
			    o_en <= '1';
			    o_address <= "0000000000000000";
				next_state <= S_LOAD_COL;
			when S_LOAD_COL =>
                col <= i_data;	
                o_address <= "0000000000000001";		    
				next_state <= S_LOAD_RIG;
			when S_LOAD_RIG =>
			    rig <= i_data;
			    current_address <= base_address;
			    o_address <= base_address;
				next_state <= S_CALC_ADDR;
			when S_CALC_ADDR =>
				if (offset = "0000000000000000") then
					next_state <= S_DONE;
				else
				    new_address <= final_address - "0000000000000001" ;
					next_state <= S_LOAD_PIXEL;
				end if;
			when S_LOAD_PIXEL =>
			    current_address_next <= current_address + "0000000000000001";
			    if (current_address = final_address) then
				    next_state <= S_SHIFT;
				else
				    o_address <= current_address;
			        pixel <= i_data;
		      	    next_state <= S_MIN_MAX;
				end if;
			when S_MIN_MAX =>
			    current_address <= current_address_next;
			    if (current_address = "0000000000000010") then
				   max_v <= pixel;
				   min_v <= pixel;
			    else
				   if (pixel > max_v)then
				      max_v <= pixel;
			       elsif (pixel < min_v) then
			       	  min_v <= pixel;
			       end if ;
			    end if ;
		      	next_state <= S_LOAD_PIXEL;				
			when S_SHIFT =>
			    current_address <= base_address; 
			    o_address <= base_address;
				delta <= max_v - min_v;
				if (delta = "00000000") then
					floor_v <= "00000000";
				elsif (delta >= "00000001" and delta <= "00000010") then
					floor_v <= "00000001";
				elsif (delta >= "00000011" and delta <= "00000110") then
					floor_v <= "00000010";
				elsif (delta >= "00000111" and delta <= "00001110") then
					floor_v <= "00000011";
				elsif (delta >= "00001111" and delta <= "00011110") then
					floor_v <= "00000100";
				elsif (delta >= "00011111" and delta <= "00111110") then
					floor_v <= "00000101";
				elsif (delta >= "00111111" and delta <= "01111110") then
					floor_v <= "00000110";
				elsif (delta >= "01111111" and delta <= "11111110") then
					floor_v <= "00000111";
				elsif (delta = "11111111") then
					floor_v <= "00001000";					
				end if;
				shift_temp <= "00001000" - floor_v;
				shift_level <= TO_INTEGER(unsigned(shift_temp));
				next_state <= S_LOAD_PIXEL_NEW;
			when S_LOAD_PIXEL_NEW =>
			    current_address_next <= current_address + "0000000000000001";
		        new_address_next <= new_address + "0000000000000001";
			    if (current_address = final_address) then
					next_state <= S_DONE;
				else
				     pixel <= i_data;
			         next_state <= S_NEW_PIXEL;
			     end if;
		     when S_NEW_PIXEL =>
			    current_address <= current_address_next;
			    new_address <= new_address_next;
				pixel_temp <= std_logic_vector(shift_left(unsigned(pixel_16-min_16), shift_level));
				if (pixel_temp < "0000000011111111") then
					new_pixel <= pixel_temp(7 downto 0);
				else
					new_pixel <= "11111111";
				end if ;		    
				next_state <= S_SAVE_PIXEL;
			when S_SAVE_PIXEL =>
			    o_we <= '1';
				o_address <= new_address;
			    o_data <= new_pixel;
				next_state <= S_RETURN_LOAD;
			when S_RETURN_LOAD =>
			    o_we <= '0';
			    o_address <= current_address;
			    next_state <= S_LOAD_PIXEL_NEW;
			when S_DONE =>
			    o_en <= '0';
			    o_we <= '0';
				o_done <= '1';
				if (i_start = '1') then
					next_state <= S_DONE;
				else
					next_state <= S_RST;
				end if;
		end case;
	end process;
  
  --Calcolo e assegnamento dei registri responsabili degli indirizzamenti in memoria
  
  offset <= col*rig;
  base_address <= "0000000000000010";
  final_address <= base_address + offset;
  
  --Conversione registri interessati
  pixel_16 <= X"00" & pixel;
  min_16 <=  X"00" & min_v;
  
end Behavioral;