-- Testbench for mem_rom

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;      -- For to_unsigned, unsigned type
use std.textio.all;            -- For general text I/O, report
use ieee.std_logic_textio.all; -- For hread, hwrite

library work;
use work.riscv_config.all;     -- To get ROM_ADDR and ROM_WIDTH constants

entity mem_rom_tb is
end entity mem_rom_tb;

architecture bench of mem_rom_tb is

  -- Component Declaration
  component mem_rom
      Port (
          CLOCK   : IN  STD_LOGIC;
          ENABLE  : IN  STD_LOGIC;
          ADDR_R  : IN  STD_LOGIC_VECTOR(ROM_ADDR-1 DOWNTO 0); -- From riscv_config
          DATA_O  : OUT STD_LOGIC_VECTOR(ROM_WIDTH-1 DOWNTO 0) -- From riscv_config
       );
  end component mem_rom;

  -- Testbench Signals
  signal CLOCK  : STD_LOGIC := '0';
  signal ENABLE : STD_LOGIC;
  signal ADDR_R : STD_LOGIC_VECTOR(ROM_ADDR-1 DOWNTO 0); -- Use ROM_ADDR from config
  signal DATA_O : STD_LOGIC_VECTOR(ROM_WIDTH-1 DOWNTO 0); -- Use ROM_WIDTH from config

  -- Clocking
  constant clock_period   : time    := 10 ns;
  signal stop_the_clock : boolean := false;

  -- Expected values from your PROGROM.mem
  -- In mem_rom_tb.vhd, replace these constants:
constant EXPECTED_DATA_ADDR0        : std_logic_vector(ROM_WIDTH-1 downto 0) := x"004001b7";
constant EXPECTED_DATA_ADDR4        : std_logic_vector(ROM_WIDTH-1 downto 0) := x"00020137"; 
constant EXPECTED_DATA_ADDR8        : std_logic_vector(ROM_WIDTH-1 downto 0) := x"008000ef";
constant EXPECTED_DATA_ADDRC        : std_logic_vector(ROM_WIDTH-1 downto 0) := x"00100073";
constant EXPECTED_DATA_ADDR14_DEC20 : std_logic_vector(ROM_WIDTH-1 downto 0) := x"00812423";

  -- Custom function to convert std_logic_vector to hex string
  function to_hex_string(slv : std_logic_vector) return string is
    variable hexlen : integer;
    variable longslv : std_logic_vector(67 downto 0) := (others => '0');
    variable hex : string(1 to 16);
    variable fourbit : std_logic_vector(3 downto 0);
  begin
    hexlen := (slv'length + 3)/4;
    longslv(slv'length-1 downto 0) := slv;
    for i in hexlen-1 downto 0 loop
        fourbit := longslv(i*4+3 downto i*4);
        case fourbit is
            when "0000" => hex(hexlen-i) := '0';
            when "0001" => hex(hexlen-i) := '1';
            when "0010" => hex(hexlen-i) := '2';
            when "0011" => hex(hexlen-i) := '3';
            when "0100" => hex(hexlen-i) := '4';
            when "0101" => hex(hexlen-i) := '5';
            when "0110" => hex(hexlen-i) := '6';
            when "0111" => hex(hexlen-i) := '7';
            when "1000" => hex(hexlen-i) := '8';
            when "1001" => hex(hexlen-i) := '9';
            when "1010" => hex(hexlen-i) := 'A';
            when "1011" => hex(hexlen-i) := 'B';
            when "1100" => hex(hexlen-i) := 'C';
            when "1101" => hex(hexlen-i) := 'D';
            when "1110" => hex(hexlen-i) := 'E';
            when "1111" => hex(hexlen-i) := 'F';
            when others => hex(hexlen-i) := 'X';
        end case;
    end loop;
    return hex(1 to hexlen);
  end function;

begin

  -- Instantiate the Unit Under Test (UUT)
  uut: mem_rom
    port map (
        CLOCK   => CLOCK,
        ENABLE  => ENABLE,
        ADDR_R  => ADDR_R,
        DATA_O  => DATA_O
    );

  -- Clock Generation Process
  clocking: process
  begin
    if stop_the_clock then
        wait;
    end if;
    CLOCK <= not CLOCK;
    wait for clock_period / 2;
  end process clocking;

  stimulus: process
  procedure read_rom_at_byte_address(
      byte_address_val : in natural;
      description      : in string := "Reading ROM"
  ) is
      variable slv_address : std_logic_vector(ROM_ADDR-1 downto 0);
  begin
      slv_address := std_logic_vector(to_unsigned(byte_address_val, ROM_ADDR));
      report description & " at byte address 0x" & to_hex_string(slv_address) severity note;
      
      ADDR_R <= slv_address;
      wait until falling_edge(CLOCK);
      
      ENABLE <= '1';
      wait until rising_edge(CLOCK);
      wait for 1 ns; -- Small delay after clock edge
      
      ENABLE <= '0';
  end procedure;
  begin
    report "Starting Testbench for mem_rom component." severity note;

    ENABLE <= '0';
    ADDR_R <= (others => '0');
    wait for clock_period;
    wait until rising_edge(CLOCK);

    read_rom_at_byte_address(0, "TC1: Reading address 0x00");
    assert DATA_O = EXPECTED_DATA_ADDR0
        report "TC1: Data mismatch at address 0x00. Expected 0x" & to_hex_string(EXPECTED_DATA_ADDR0) & 
               ", Got 0x" & to_hex_string(DATA_O)
        severity error;
    wait for clock_period;

    read_rom_at_byte_address(4, "TC2: Reading address 0x04");
    assert DATA_O = EXPECTED_DATA_ADDR4
        report "TC2: Data mismatch at address 0x04. Expected 0x" & to_hex_string(EXPECTED_DATA_ADDR4) & 
               ", Got 0x" & to_hex_string(DATA_O)
        severity error;
    wait for clock_period;

    read_rom_at_byte_address(8, "TC3: Reading address 0x08");
    assert DATA_O = EXPECTED_DATA_ADDR8
        report "TC3: Data mismatch at address 0x08. Expected 0x" & to_hex_string(EXPECTED_DATA_ADDR8) & 
               ", Got 0x" & to_hex_string(DATA_O)
        severity error;
    wait for clock_period;

    report "TC4: Attempting read with ENABLE low." severity note;
    ADDR_R <= std_logic_vector(to_unsigned(12, ROM_ADDR));
    ENABLE <= '0';
    wait for clock_period;
    report "TC4: Data out (should be previous from addr 0x08) is 0x" & to_hex_string(DATA_O) severity note;
    assert DATA_O = EXPECTED_DATA_ADDR8
        report "TC4: Data changed while ENABLE was low. Expected 0x" & to_hex_string(EXPECTED_DATA_ADDR8) & 
               ", Got 0x" & to_hex_string(DATA_O)
        severity warning;
    wait for clock_period;

    read_rom_at_byte_address(20, "TC5: Reading address 0x14 (word 5)");
    assert DATA_O = EXPECTED_DATA_ADDR14_DEC20
        report "TC5: Data mismatch at address 0x14. Expected 0x" & to_hex_string(EXPECTED_DATA_ADDR14_DEC20) & 
               ", Got 0x" & to_hex_string(DATA_O)
        severity error;
    wait for clock_period;

    report "TC6: Back-to-back reads." severity note;
   
    ADDR_R <= std_logic_vector(to_unsigned(0, ROM_ADDR));
    ENABLE <= '1';
    wait until rising_edge(CLOCK);
    wait for 1 ns;
    assert DATA_O = EXPECTED_DATA_ADDR0
        report "TC6.1: Data mismatch for addr 0. Expected 0x" & to_hex_string(EXPECTED_DATA_ADDR0) & 
               ", Got 0x" & to_hex_string(DATA_O)
        severity error;

    
    ADDR_R <= std_logic_vector(to_unsigned(4, ROM_ADDR));
    wait until rising_edge(CLOCK);
    wait for 1 ns;
    assert DATA_O = EXPECTED_DATA_ADDR4
        report "TC6.2: Data mismatch for addr 4. Expected 0x" & to_hex_string(EXPECTED_DATA_ADDR4) & 
               ", Got 0x" & to_hex_string(DATA_O)
        severity error;
    
    ENABLE <= '0';
    report "All test cases finished. Stopping clock." severity note;
    stop_the_clock <= true;
    wait;
  end process;
end architecture;