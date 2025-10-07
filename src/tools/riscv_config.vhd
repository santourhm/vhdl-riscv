library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

-- Package Declaration Section
package riscv_config is

    constant ROM_ADDR  : integer := 16; -- exprimée en bytes !
    constant ROM_DEPTH : integer := 2**(ROM_ADDR-2); -- words
    constant ROM_WIDTH : integer := 32;
    constant ROM_FILE  : string  := "../firmware/PROGROM.mem";

    constant RAM_ADDR  : integer := 16; -- exprimée en bytes !
    constant RAM_DEPTH : integer := 2**(RAM_ADDR-2); -- words
    constant RAM_WIDTH : integer := 32;
    constant RAM_FILE  : string  :=  "../firmware/DATARAM.mem";

        -- ... other types and constants ...
    component mem_rom is
        port (
            CLOCK  : IN  STD_LOGIC;
            ENABLE : IN  STD_LOGIC;
            ADDR_R : IN  STD_LOGIC_VECTOR(ROM_ADDR-1 DOWNTO 0); -- ROM_ADDR should also be in riscv_types or riscv_config
            DATA_O : OUT STD_LOGIC_VECTOR(ROM_WIDTH-1 DOWNTO 0) -- ROM_WIDTH should also be in riscv_types or riscv_config
        );
    end component mem_rom;
        -- ... possibly other components ...

    

end package riscv_config;

--
--
-- Package Body Section
--
--

package body riscv_config is
    

end package body riscv_config;
