library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;


entity mem_load is 
    Port ( 
        ADDR_R      : IN  STD_LOGIC_VECTOR( 1 DOWNTO 0);
        DATA_R      : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        is_byte     : IN  STD_LOGIC;
        is_half     : IN  STD_LOGIC;
        is_sign_ext : IN  STD_LOGIC;
        data_value : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
     );
end mem_load;


architecture arch of mem_load is

   SIGNAL M_LOAD_H    : STD_LOGIC_VECTOR (15 downto 0);
   SIGNAL M_LOAD_B    : STD_LOGIC_VECTOR ( 7 downto 0);
   SIGNAL M_LOAD_sign : STD_LOGIC;
   SIGNAL EXTENDED_B    : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL EXTENDED_H    : STD_LOGIC_VECTOR(31 DOWNTO 0);
begin


    M_LOAD_B    <= DATA_R(7 DOWNTO 0)   WHEN  ADDR_R = "00" ELSE 
                   DATA_R(15 DOWNTO 8)  WHEN  ADDR_R = "01" ELSE 
                   DATA_R(23 DOWNTO 16) WHEN  ADDR_R = "10" ELSE 
                   DATA_R(31 DOWNTO 24) ;
   
    M_LOAD_H    <= DATA_R(15 DOWNTO 0)   WHEN  ADDR_R(1) = '0' ELSE 
                   DATA_R(31 DOWNTO 16) ;
    
    EXTENDED_B <= (31 downto 8 => M_LOAD_B(7)) & M_LOAD_B WHEN is_sign_ext = '1' ELSE
                  (31 downto 8 => '0') & M_LOAD_B ;
    
    EXTENDED_H <= (31 downto 16 => M_LOAD_H(15)) & M_LOAD_H WHEN is_sign_ext = '1' ELSE
                  (31 downto 16 => '0') & M_LOAD_H ;

    data_value  <= EXTENDED_B WHEN is_byte  = '1' ELSE 
                   EXTENDED_H  WHEN is_half = '1' ELSE
                   DATA_R;  
   
end arch;