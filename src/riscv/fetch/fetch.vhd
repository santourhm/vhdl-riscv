library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity fetch is
Port ( 
   CLK                 : in  STD_LOGIC;
   resetn              : in  STD_LOGIC;
   enable_f            : in  STD_LOGIC;
   enable_m            : in  STD_LOGIC;
   jumpOrBranchAddress : in  STD_LOGIC_VECTOR (31 downto 0);
   jumpOrBranch        : in  STD_LOGIC;
   pc_value            : out STD_LOGIC_VECTOR (31 downto 0)
 );
end fetch;


architecture arch of fetch is

   SIGNAL pc_addr : UNSIGNED (31 downto 0);

begin

   
    process(clk)
   begin   
       if rising_edge(clk) THEN
       
          
           if resetn='0' THEN
               pc_addr     <= (others => '0');
            ELSif enable_m = '1'  and  jumpOrBranch='1' THEN
               pc_addr     <= UNSIGNED(jumpOrBranchAddress);
               
          
            ELSif enable_f = '1' THEN
               pc_addr     <=pc_addr +TO_UNSIGNED(4, 32);
                    
          
           end if;
       end if;
   end process;
  pc_value <= STD_LOGIC_VECTOR(pc_addr);
end arch;
 
