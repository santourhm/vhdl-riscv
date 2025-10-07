library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;
use IEEE.std_logic_textio.all; -- For hprint/to_hstring if needed in reports
use std.textio.all;            -- For report

library work;
use work.riscv_config.all; -- Crucial for RAM_ADDR, RAM_WIDTH, RAM_FILE

entity mem_ram_tb is
end entity mem_ram_tb;

architecture bench of mem_ram_tb is

  component mem_ram
      Port (
          CLOCK   : IN  STD_LOGIC;
          ADDR_RW : IN  STD_LOGIC_VECTOR(RAM_ADDR-1 DOWNTO 0);
          ENABLE  : IN  STD_LOGIC;
          WRITE_M : IN  STD_LOGIC_VECTOR(          3 DOWNTO 0);
          DATA_W  : IN  STD_LOGIC_VECTOR(RAM_WIDTH-1 DOWNTO 0); -- Should match config
          DATA_R  : OUT STD_LOGIC_VECTOR(RAM_WIDTH-1 DOWNTO 0)  -- Should match config
       );
  end component;

  -- Signals for UUT
  signal CLOCK   : STD_LOGIC := '0';
  signal ADDR_RW : STD_LOGIC_VECTOR(RAM_ADDR-1 DOWNTO 0);
  signal ENABLE  : STD_LOGIC;
  signal WRITE_M : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal DATA_W  : STD_LOGIC_VECTOR(RAM_WIDTH-1 DOWNTO 0);
  signal DATA_R  : STD_LOGIC_VECTOR(RAM_WIDTH-1 DOWNTO 0);

  -- Clock generation
  constant clock_period : time    := 10 ns;
  signal stop_the_clock : boolean := false;

  -- Test results tracking
  signal tests_passed : integer := 0;
  signal tests_failed : integer := 0;

begin

  uut: mem_ram
    port map (
      CLOCK   => CLOCK,
      ADDR_RW => ADDR_RW,
      ENABLE  => ENABLE,
      WRITE_M => WRITE_M,
      DATA_W  => DATA_W,
      DATA_R  => DATA_R
    );

  clocking: process
  begin
    while not stop_the_clock loop
      CLOCK <= not CLOCK;
      wait for clock_period / 2;
    end loop;
    wait;
  end process clocking;

  stimulus: process
    -- Expected initial values from the provided DATAMEM.hex snippet
    constant MEM_INIT_VAL_0 : std_logic_vector(RAM_WIDTH-1 downto 0) := x"29696928";
    constant MEM_INIT_VAL_1 : std_logic_vector(RAM_WIDTH-1 downto 0) := x"0000000a";
    constant MEM_INIT_VAL_2 : std_logic_vector(RAM_WIDTH-1 downto 0) := x"29696928";
    constant ORIG_VAL_W4    : std_logic_vector(RAM_WIDTH-1 downto 0) := x"77204f4c";
    constant ORIG_VAL_W5    : std_logic_vector(RAM_WIDTH-1 downto 0) := x"646c726f";
    constant ORIG_VAL_W6    : std_logic_vector(RAM_WIDTH-1 downto 0) := x"000a2120";

    procedure check(
        test_description : string;
        expected_value   : std_logic_vector(RAM_WIDTH-1 downto 0);
        actual_value     : std_logic_vector(RAM_WIDTH-1 downto 0)
    ) is
    begin
        wait for 1 ns;
        if expected_value = actual_value then
            report "CHECK: " & test_description & " - PASSED. Expected " & to_hstring(expected_value) & ", Got " & to_hstring(actual_value);
            tests_passed <= tests_passed + 1;
        else
            report "CHECK: " & test_description & " - FAILED! Expected " & to_hstring(expected_value) & ", Got " & to_hstring(actual_value) severity error;
            tests_failed <= tests_failed + 1;
        end if;
    end procedure check;

  begin
    report "TB: Starting testbench stimulus...";
    
    ENABLE  <= '0';
    WRITE_M <= "0000"; 
    DATA_W  <= (others => 'X');
    ADDR_RW <= (others => '0');
    wait for clock_period; -- Initial wait

    report "TB: Test 1: Reading initial values (loaded from " & RAM_FILE & ")...";
    ENABLE <= '1'; 

    
    ADDR_RW <= std_logic_vector(to_unsigned(0, RAM_ADDR));
    WRITE_M <= "0000"; -- Read operation
    wait until rising_edge(CLOCK); 
    wait until rising_edge(CLOCK); 
    check("Read word 0 (byte_addr 0x00)", MEM_INIT_VAL_0, DATA_R);

    ADDR_RW <= std_logic_vector(to_unsigned(4, RAM_ADDR));
    
    wait until rising_edge(CLOCK);
    wait until rising_edge(CLOCK); 
    check("Read word 1 (byte_addr 0x04)", MEM_INIT_VAL_1, DATA_R);

    ADDR_RW <= std_logic_vector(to_unsigned(8, RAM_ADDR));
    wait until rising_edge(CLOCK); 
    wait until rising_edge(CLOCK); 
    check("Read word 2 (byte_addr 0x08)", MEM_INIT_VAL_2, DATA_R);

    report "TB: Test 2: Full word write and read back...";
    ADDR_RW <= std_logic_vector(to_unsigned(16, RAM_ADDR));
    DATA_W  <= x"AAAAAAAA";
    WRITE_M <= "1111"; -- Write all 4 bytes
    -- ENABLE is still '1'
    wait until rising_edge(CLOCK); 
                                   


    WRITE_M <= "0000"; 
    wait until rising_edge(CLOCK); 
                                  
    wait until rising_edge(CLOCK); 
    check("Read back after full write (byte_addr 0x10)", x"AAAAAAAA", DATA_R);

    
    report "TB: Test 3: Partial word write (bytes 0,1,2 masked) and read back...";
    
    ADDR_RW <= std_logic_vector(to_unsigned(20, RAM_ADDR));
    DATA_W  <= x"AABBCCDD";
    WRITE_M <= "0111";
    wait until rising_edge(CLOCK);

    
    WRITE_M <= "0000"; 
    wait until rising_edge(CLOCK); 
                                   
    wait until rising_edge(CLOCK);
    check("Read back after partial write (byte_addr 0x14, mask 0111)", x"64BBCCDD", DATA_R);

    report "TB: Test 4: Partial word write (bytes 1,3 masked) and read back...";

    ADDR_RW <= std_logic_vector(to_unsigned(24, RAM_ADDR));
    DATA_W  <= x"11223344";
    WRITE_M <= "1010";
    wait until rising_edge(CLOCK); 
                                   
    WRITE_M <= "0000"; 
    wait until rising_edge(CLOCK); 
                                  
    wait until rising_edge(CLOCK); 
    check("Read back after partial write (byte_addr 0x18, mask 1010)", x"110A3320", DATA_R);

    ENABLE <= '0';
    wait for clock_period * 2;
    stop_the_clock <= true;
    wait; 
  end process stimulus;

end architecture bench;