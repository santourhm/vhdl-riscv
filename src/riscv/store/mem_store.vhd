library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity mem_store is
    Port (
        ADDR_W     : IN  STD_LOGIC_VECTOR( 1 DOWNTO 0); 
        DATA_W     : IN  STD_LOGIC_VECTOR(31 DOWNTO 0); 
        is_byte    : IN  STD_LOGIC;                   
        is_half    : IN  STD_LOGIC;                    
        data_mask  : OUT STD_LOGIC_VECTOR( 3 DOWNTO 0); 
        data_value : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)  
     );
end mem_store;

architecture arch of mem_store is

begin

    data_mask <=
        "1111" when is_byte = '0' and is_half = '0' else 
        "0001" when is_byte = '1' and ADDR_W = "00" else 
        "0010" when is_byte = '1' and ADDR_W = "01" else
        "0100" when is_byte = '1' and ADDR_W = "10" else 
        "1000" when is_byte = '1' and ADDR_W = "11" else 
        "0011" when is_half = '1' and ADDR_W(1) = '0' else
        "1100" when is_half = '1' and ADDR_W(1) = '1' else 
        "0000"; 

    data_value <=
        DATA_W when is_byte = '0' and is_half = '0' else

        ( (31 downto 8 => '0') & DATA_W(7 downto 0) )                                 when is_byte = '1' and ADDR_W = "00" else 
        ((31 downto 16 => '0') & DATA_W(7 downto 0) & (7 downto 0 => '0') ) when is_byte = '1' and ADDR_W = "01" else -- Byte 1
        ((31 downto 24 => '0') & DATA_W(7 downto 0) & (15 downto 0 => '0')) when is_byte = '1' and ADDR_W = "10" else -- Byte 2
        ( DATA_W(7 downto 0) & (23 downto 0 => '0') )                                 when is_byte = '1' and ADDR_W = "11" else 

        ( (31 downto 16 => '0') & DATA_W(15 downto 0) )                               when is_half = '1' and ADDR_W(1) = '0' else 
        ( DATA_W(15 downto 0) & (15 downto 0 => '0') )                               when is_half = '1' and ADDR_W(1) = '1' else 
        (others => 'X'); 

end arch;
