library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

use work.riscv_types.all;
use work.riscv_config.all;

entity mem_rom is 
    Port ( 
        CLOCK   : IN  STD_LOGIC;
        ENABLE  : IN  STD_LOGIC;
        ADDR_R  : IN  STD_LOGIC_VECTOR(ROM_ADDR-1  DOWNTO 0); -- -2 bits because 32b words and not bytes
        DATA_O  : OUT STD_LOGIC_VECTOR(ROM_WIDTH-1 DOWNTO 0)
     );
end mem_rom;


architecture arch of mem_rom is

    TYPE rom_type IS ARRAY (0 TO (ROM_DEPTH-1)) OF STD_LOGIC_VECTOR (ROM_WIDTH-1 DOWNTO 0);

    impure function InitRomFromFile(RamFileName : in string)
      return rom_type is
        file RomFile         : text open read_mode is RamFileName;
        variable RomFileLine : line;
        variable TempVec     : std_logic_vector(ROM_WIDTH-1 downto 0);
        variable ROM_temp    : rom_type;
        variable char_val    : character;
        variable nibble_val  : unsigned(3 downto 0);
    begin
        REPORT "-- PROGRAM MEMORY ROM (Manual Hex Read - No Space Handling)";
        REPORT "-- ROM_ADDR  = " & integer'image(ROM_ADDR);
        REPORT "-- ROM_DEPTH = " & integer'image(ROM_DEPTH);
        REPORT "-- ROM_WIDTH = " & integer'image(ROM_WIDTH);
        REPORT "-- ROM_FILE  = " & RamFileName;

        assert ROM_WIDTH mod 4 = 0 report "ROM_WIDTH must be a multiple of 4 for hex reading" severity failure;

        for I in ROM_temp'range loop
            if endfile(RomFile) then
                REPORT "InitRomFromFile: Reached end of file prematurely at line " & integer'image(I) & ". Filling rest with zeros." severity warning;
                ROM_temp(I) := (others => '0');
            else
                readline(RomFile, RomFileLine);
                TempVec := (others => '0'); -- Initialize

                for char_idx in 0 to (ROM_WIDTH/4 - 1) loop
                    if RomFileLine'length < 1 then
                        REPORT "InitRomFromFile: Line " & integer'image(I) & ", char_idx " & integer'image(char_idx) & " - Line too short. Expected hex digit." severity warning;
                        nibble_val := (others => '0'); -- Default to 0 on error
                    else
                        read(RomFileLine, char_val); -- Read one character
                        case char_val is
                            when '0'        => nibble_val := "0000";
                            when '1'        => nibble_val := "0001";
                            when '2'        => nibble_val := "0010";
                            when '3'        => nibble_val := "0011";
                            when '4'        => nibble_val := "0100";
                            when '5'        => nibble_val := "0101";
                            when '6'        => nibble_val := "0110";
                            when '7'        => nibble_val := "0111";
                            when '8'        => nibble_val := "1000";
                            when '9'        => nibble_val := "1001";
                            when 'A' | 'a'  => nibble_val := "1010";
                            when 'B' | 'b'  => nibble_val := "1011";
                            when 'C' | 'c'  => nibble_val := "1100";
                            when 'D' | 'd'  => nibble_val := "1101";
                            when 'E' | 'e'  => nibble_val := "1110";
                            when 'F' | 'f'  => nibble_val := "1111";
                            when others     =>
                                REPORT "InitRomFromFile: Invalid hex character '" & char_val & "' on line " & integer'image(I) & ". Using 0." severity warning;
                                nibble_val := "0000";
                        end case;
                    end if;
                    TempVec( (ROM_WIDTH - 1 - (char_idx*4)) downto (ROM_WIDTH - (char_idx+1)*4) ) := std_logic_vector(nibble_val);
                end loop;
                ROM_temp(I) := TempVec;
            end if;
        end loop;
        file_close(RomFile);
        REPORT "-- FIN DE CHARGEMENT (Manual Hex Read - No Space Handling)";
        return ROM_temp;
    end function InitRomFromFile;

    SIGNAL memory : rom_type := InitRomFromFile( ROM_FILE ); -- Use ROM_FILE from package
    SIGNAL ADDR   : STD_LOGIC_VECTOR(ROM_ADDR-2-1 DOWNTO 0);

begin

    ADDR <= ADDR_R(ROM_ADDR-1 DOWNTO 2); 

    PROCESS (CLOCK)
    BEGIN
        IF (CLOCK'event AND CLOCK = '1') THEN
            IF ENABLE = '1' THEN
                DATA_O <= memory(to_integer(UNSIGNED(ADDR)));
            END IF;
        END IF;
    END PROCESS;

end arch;