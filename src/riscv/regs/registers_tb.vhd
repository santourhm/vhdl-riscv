library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity registers_tb is
end;

architecture bench of registers_tb is

  component registers
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
  end component;

  signal CLOCK: STD_LOGIC;
  signal RS1_id: STD_LOGIC_VECTOR( 4 DOWNTO 0);
  signal DATA_rs1: STD_LOGIC_VECTOR(31 DOWNTO 0);
  signal RS2_id: STD_LOGIC_VECTOR( 4 DOWNTO 0);
  signal DATA_rs2: STD_LOGIC_VECTOR(31 DOWNTO 0);
  signal RD_id: STD_LOGIC_VECTOR( 4 DOWNTO 0);
  signal RD_id_we: STD_LOGIC;
  signal DATA_rd: STD_LOGIC_VECTOR(31 DOWNTO 0);

  constant clock_period: time := 10 ns;
  signal stop_the_clock: boolean := false;

begin

  uut: registers port map ( 
    CLOCK    => CLOCK,
    RS1_id   => RS1_id,
    DATA_rs1 => DATA_rs1,
    RS2_id   => RS2_id,
    DATA_rs2 => DATA_rs2,
    RD_id    => RD_id,
    RD_id_we => RD_id_we,
    DATA_rd  => DATA_rd
  );

  stimulus: process
  begin
    -- Initialization
    RS1_id <= (others => '0');
    RS2_id <= (others => '0');
    RD_id <= (others => '0');
    RD_id_we <= '0';
    DATA_rd <= (others => '0');
    
    wait for clock_period;
    
    report "Test 1: Verify all registers initialize to 0";
    for i in 0 to 31 loop
      RS1_id <= std_logic_vector(to_unsigned(i, 5));
      RS2_id <= std_logic_vector(to_unsigned(i, 5));
      wait until rising_edge(CLOCK);
      wait for 1 ns;
      assert DATA_rs1 = x"00000000" 
        report "Register " & integer'image(i) & " rs1 not initialized to 0" severity error;
      assert DATA_rs2 = x"00000000" 
        report "Register " & integer'image(i) & " rs2 not initialized to 0" severity error;
    end loop;
    
    report "Test 2: Write to register and verify read";
    RD_id <= "00001"; -- Register x1
    DATA_rd <= x"ABCD1234";
    RD_id_we <= '1';
    wait until rising_edge(CLOCK);
    RD_id_we <= '0';
    
    RS1_id <= "00001";
    wait until rising_edge(CLOCK);
    wait for 1 ns;
    assert DATA_rs1 = x"ABCD1234" report "Write to x1 failed" severity error;
    
   
    report "Test 3: Verify x0 reads as 0";

    RD_id <= "00000"; -- Register x0
    DATA_rd <= x"FFFFFFFF";
    RD_id_we <= '1';
    wait until rising_edge(CLOCK);
    RD_id_we <= '0';

    RS1_id <= "00000";
    wait until rising_edge(CLOCK);
    wait for 1 ns;
    assert DATA_rs1 = x"00000000" report "x0 register should read as 0" severity error;
    
    report "Test 4: Read and write different registers";

    RD_id <= "00010"; -- Register x2
    DATA_rd <= x"11112222";
    RD_id_we <= '1';
    RS1_id <= "00001"; -- Read x1
    RS2_id <= "00010"; -- Read x2 (being written)
    wait until rising_edge(CLOCK);
    
    wait until rising_edge(CLOCK);
    wait for 1 ns;
    assert DATA_rs1 = x"ABCD1234" report "Read of x1 failed" severity error;
    assert DATA_rs2 = x"11112222" report "Read of x2 failed" severity error;
    
    RD_id_we <= '0';
    
    report "Test 5: Multiple register operations";
    -- Write to x3
    RD_id <= "00011";
    DATA_rd <= x"33333333";
    RD_id_we <= '1';
    wait until rising_edge(CLOCK);
    
    RD_id <= "00100";
    DATA_rd <= x"44444444";
    RD_id_we <= '1';
    wait until rising_edge(CLOCK);
    RD_id_we <= '0';
    
    RS1_id <= "00011";
    RS2_id <= "00100";
    wait until rising_edge(CLOCK);
    wait for 1 ns;
    assert DATA_rs1 = x"33333333" report "Read of x3 failed" severity error;
    assert DATA_rs2 = x"44444444" report "Read of x4 failed" severity error;
    
    
    report "Test 6: Verify write to x0 doesn't affect other registers";

    RD_id <= "00000";
    DATA_rd <= x"55555555";
    RD_id_we <= '1';
    wait until rising_edge(CLOCK);
    RD_id_we <= '0';
    
    RS1_id <= "00001";
    wait until rising_edge(CLOCK);
    wait for 1 ns;
    assert DATA_rs1 = x"ABCD1234" report "Write to x0 affected x1" severity error;
    

    report "All tests completed";
    stop_the_clock <= true;
    wait;
  end process;

  clocking: process
  begin
    while not stop_the_clock loop
      CLOCK <= '0', '1' after clock_period / 2;
      wait for clock_period;
    end loop;
    wait;
  end process;

end;