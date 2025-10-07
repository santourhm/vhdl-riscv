library IEEE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity registers is
Port ( 
   CLOCK    : in   STD_LOGIC;

   RS1_id   : IN   STD_LOGIC_VECTOR( 4 DOWNTO 0);
   DATA_rs1 : OUT  STD_LOGIC_VECTOR(31 DOWNTO 0);

   RS2_id   : IN   STD_LOGIC_VECTOR( 4 DOWNTO 0);
   DATA_rs2 : OUT  STD_LOGIC_VECTOR(31 DOWNTO 0);

   RD_id    : IN   STD_LOGIC_VECTOR( 4 DOWNTO 0);
   RD_id_we : IN   STD_LOGIC;
   DATA_rd  : IN   STD_LOGIC_VECTOR(31 DOWNTO 0)
 );
end registers;
 

architecture arch of registers is

   ---------------------------------------------------------------------------------------------------
   type RegFile is array (0 to 31) of STD_LOGIC_VECTOR(31 downto 0);

   impure function InitRegisters(RamFileName : in string)
      return RegFile is
         variable RAM : RegFile;
   BEGIN
      for I in RegFile'range loop
         RAM(I) := x"00000000";
      end loop;
      return RAM;
   end function;
   
   SIGNAL registerFile : RegFile := InitRegisters("FAKE_STRING.hex");
  

BEGIN

   PROCESS (CLOCK)
   BEGIN
        IF (RISING_EDGE(CLOCK)) THEN
           IF  RD_id_we = '1'THEN
               IF  TO_INTEGER(UNSIGNED(RD_id)) /= 0 THEN -- no writes in the x0
                   registerFile(TO_INTEGER(UNSIGNED(RD_id))) <= DATA_rd; 
               END IF;
           END IF;
        END IF;
   END PROCESS;

   PROCESS(CLOCK)
    BEGIN
      IF RISING_EDGE(CLOCK) then
        DATA_rs1 <=registerFile(TO_INTEGER(UNSIGNED(RS1_id))); 
        DATA_rs2 <=registerFile(TO_INTEGER(UNSIGNED(RS2_id))); 
      END IF;
   END PROCESS;

end arch;
 

