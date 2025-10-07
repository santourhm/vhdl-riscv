library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity immediate is
Port ( 
   INSTR    : in  STD_LOGIC_VECTOR (31 downto 0);
   isStore  : in  STD_LOGIC;
   isLoad   : in  STD_LOGIC;
   isbranch : in  STD_LOGIC;
   isJAL    : in  STD_LOGIC;
   isAuipc  : in  STD_LOGIC;
   isLui    : in  STD_LOGIC;
   imm      : out STD_LOGIC_VECTOR (31 downto 0)
 );
end immediate;


architecture arch of immediate is


   SIGNAL Iimm : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL Simm : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL Uimm : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL Jimm : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL Bimm : STD_LOGIC_VECTOR (31 downto 0);

begin

    
    -- I-Type
    Iimm <= (31 downto 12 => INSTR(31)) & INSTR(31 downto 20);
    
    -- S-Type
    Simm <= (31 downto 12 => INSTR(31)) & INSTR(31 downto 25) & INSTR(11 downto 7);
    
    -- U-Type
    Uimm <= INSTR(31 downto 12) & (11 downto 0 => '0'); 
    
    -- J-Type
    Jimm <= (31 downto 21 => INSTR(31)) & INSTR(31) & INSTR(19 downto 12) & INSTR(20) & INSTR(30 downto 21) & '0';
    
    -- B-Type
    Bimm <= (31 downto 13 => INSTR(31)) & INSTR(31) & INSTR(7) & INSTR(30 downto 25) & INSTR(11 downto 8) & '0';

    imm  <= Simm WHEN isStore = '1' else 
            Iimm WHEN isLoad  = '1' else
            Jimm WHEN isJAL   = '1' else 
            Bimm WHEN isbranch = '1' else
            Uimm WHEN isAuipc = '1' or isLui = '1' else
            Iimm;

end arch;