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

architecture Behavioral of project_reti_logiche is

  type state_type is (S_RST,S_START,S_LOAD_COL,S_LOAD_RIG,S_CALC_ADDR,S_LOAD_PIXEL,S_MIN_MAX,S_SHIFT,S_NEW_PIXEL,S_SAVE_PIXEL,S_DONE);

  --Segnali per registri dello stato della FSM
  
  signal current_state: state_type;
  signal next_state: state_type;

  --Segnali per registri colonna e riga

  signal col_8: std_logic_vector(7 downto 0);
  signal col_16: std_logic_vector(15 downto 0);
  signal rig_8: std_logic_vector(7 downto 0);
  signal rig_16: std_logic_vector(15 downto 0);

  --Segnali per accesso alla RAM
  signal current_address: std_logic_vector(15 downto 0);
  signal current_address_next: std_logic_vector(15 downto 0);
  signal offset: std_logic_vector(15 downto 0);
  signal final_address: std_logic_vector(15 downto 0);
  signal base_address: std_logic_vector(15 downto 0);
  signal count: std_logic_vector(15 downto 0);
  signal count_next: std_logic_vector(15 downto 0);

  --Segnale per i due loop
  signal flag : std_logic;
  
  --Segnale per il registro per il pixel considerato
  signal pixel: std_logic_vector(7 downto 0);
  
  --Segnale minimo e massimo valore
  signal max: std_logic_vector(7 downto 0);
  signal min: std_logic_vector(7 downto 0);

begin

    process(i_clk, i_rst, next_state)
    begin
        if(rising_edge(i_clk)) then
            if(i_rst = '1') then
                current_state <= S_RST;
            else
                current_state <= S_START;
            end if;
        end if;
    end process;
  
	process(current_state, i_start, offset, current_address, final_address, flag  )
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
					next_state <= S_RST;
				end if;
			when S_START =>
			    o_address <= "0000000000000000";
			    o_en <= '1';
				next_state <= S_LOAD_COL;
			when S_LOAD_COL =>
                col_8 <= i_data;	
                o_address <= "0000000000000001";		    
				next_state <= S_LOAD_RIG;
			when S_LOAD_RIG =>
			    rig_8 <= i_data;
			    o_address <= "0000000000000010";
			    current_address <= base_address;
			    o_en <= '0';
				next_state <= S_CALC_ADDR;
			when S_CALC_ADDR =>
			    count <= offset;
				if (offset ="0000000000000000")then
					next_state <= S_DONE;
				else
					next_state <= S_LOAD_PIXEL;
					o_en <= '1';
				end if;
			when S_LOAD_PIXEL =>
			    pixel <= i_data;
				if (flag = '0') then
				    o_en <= '0';
					next_state <= S_MIN_MAX;
				elsif (flag = '1') then
				    o_en <= '0';
					next_state <= S_NEW_PIXEL;
				end if;
			when S_MIN_MAX =>
			    current_address_next <= current_address + "0000000000000001";
			    count_next <= count - "0000000000000001"; 
				if (count = "0000000000000000") then
					next_state <= S_SHIFT;
				elsif (count /= "0000000000000000") then
					next_state <= S_LOAD_PIXEL;				
				end if ;
			when S_SHIFT =>
				next_state <= S_LOAD_PIXEL;
			when S_NEW_PIXEL =>
			    o_en <= '1';
			    o_we <= '1';
				next_state <= S_SAVE_PIXEL;
			when S_SAVE_PIXEL =>
			    o_address <= current_address + base_address;
			    o_data <= pixel;
				if (current_address = offset) then
					next_state <= S_DONE;
				elsif (current_address /= offset) then
					next_state <= S_LOAD_PIXEL;
				end if ;
			when S_DONE =>
				if (i_start = '1')then
					next_state <= S_DONE;
				else
				next_state <= S_RST;
				end if;
		end case;
	end process;
  
  --Calcolo e assegnamento dei registri responsabili degli indirizzamenti in memoria
  
  col_16 <= std_logic_vector(resize(unsigned(col_8), col_16'length));
  rig_16 <= std_logic_vector(resize(unsigned(rig_8), rig_16'length));
  offset <= std_logic_vector(unsigned(col_16(15 downto 0))*unsigned(rig_16(15 downto 0)));
  base_address <= "0000000000000010";
  final_address <= std_logic_vector(unsigned(offset(15 downto 0)) + unsigned(base_address(15 downto 0)));
  
end Behavioral;