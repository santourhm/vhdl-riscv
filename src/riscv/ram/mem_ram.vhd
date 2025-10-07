library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
library work;
use work.riscv_config.all;

entity mem_ram is
    Port ( 
        CLOCK   : IN  STD_LOGIC;
        ADDR_RW : IN  STD_LOGIC_VECTOR(RAM_ADDR-1  DOWNTO 0);
        ENABLE  : IN  STD_LOGIC;
        WRITE_M : IN  STD_LOGIC_VECTOR(          3 DOWNTO 0);
        DATA_W  : IN  STD_LOGIC_VECTOR(RAM_WIDTH-1 DOWNTO 0);
        DATA_R  : OUT STD_LOGIC_VECTOR(RAM_WIDTH-1 DOWNTO 0)
     );
END mem_ram;


architecture arch of mem_ram is 

    TYPE   ram_type IS ARRAY (0 TO (RAM_DEPTH-1)) OF STD_LOGIC_VECTOR (RAM_WIDTH-1 DOWNTO 0);

   impure function InitRomFromFile(RamFileName : in string)
      return ram_type is
         file RamFile         : text open read_mode is RamFileName;
         variable RamFileLine : line;
         variable RAM         : ram_type;
    BEGIN
        REPORT "-- PROGRAM MEM RAM";
        REPORT "-- RAM_ADDR  = " & integer'image(RAM_ADDR);
        REPORT "-- RAM_DEPTH = " & integer'image(RAM_DEPTH);
        REPORT "-- RAM_WIDTH = " & integer'image(RAM_WIDTH);
        REPORT "-- RAM_FILE  = " & RAM_FILE;
        for I in ram_type'range loop
            readline(RamFile, RamFileLine);
            hread(RamFileLine, RAM(I));
        END loop;
        REPORT "-- FIN DE CHARGEMENT";
        return RAM;
   END function;

   SIGNAL MEM : ram_type := InitRomFromFile( RAM_FILE );
   SIGNAL R_ADDR : STD_LOGIC_VECTOR(RAM_ADDR-2-1 DOWNTO 0); 

BEGIN
    
    R_ADDR <= ADDR_RW(RAM_ADDR-1 DOWNTO 2); 

    PROCESS (CLOCK)
    BEGIN
        IF (CLOCK'event AND CLOCK = '1') THEN
            IF ENABLE = '1' then
                IF WRITE_M = "0000" then
                    DATA_R <= MEM( to_integer(UNSIGNED(R_ADDR)) );
                END IF;
            END IF;
        END IF;
    END PROCESS;

    PROCESS(CLOCK)
        VARIABLE address : integer;   
    BEGIN   
        IF rising_edge(CLOCK) then
            IF ENABLE = '1' AND WRITE_M /= "0000" then
                address := TO_INTEGER( unsigned(R_ADDR) );
                IF WRITE_M(0) = '1' then 
                   MEM(address)(7 DOWNTO 0) <= DATA_W(7 DOWNTO 0); 
                END IF;
                IF WRITE_M(1) = '1' then 
                   MEM(address)(15 DOWNTO  8) <= DATA_W(15 DOWNTO 8); 
                END IF;
                IF WRITE_M(2) = '1' then 
                   MEM(address)(23 DOWNTO 16) <= DATA_W(23 DOWNTO 16); 
                END IF;
                IF WRITE_M(3) = '1' then 
                    MEM(address)(31 DOWNTO 24) <= DATA_W(31 DOWNTO 24); END IF;
            END IF;
        END IF;
   END PROCESS;



END arch;
 
