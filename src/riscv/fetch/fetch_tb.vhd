-- Testbench created online at:
--   https://www.doulos.com/knowhow/perl/vhdl-testbench-creation-using-perl/
-- Copyright Doulos Ltd

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity fetch_tb is
end;

architecture bench of fetch_tb is

  component fetch
  Port (
     CLK                 : in  STD_LOGIC;
     resetn              : in  STD_LOGIC;
     enable_f            : in  STD_LOGIC;
     enable_m            : in  STD_LOGIC;
     jumpOrBranchAddress : in  STD_LOGIC_VECTOR (31 downto 0);
     jumpOrBranch        : in  STD_LOGIC;
     pc_value            : out STD_LOGIC_VECTOR (31 downto 0)
   );
  end component;

  -- Inputs
  signal CLK: STD_LOGIC := '0'; -- Initialize clock
  signal resetn: STD_LOGIC;
  signal enable_f: STD_LOGIC;
  signal enable_m: STD_LOGIC;
  signal jumpOrBranchAddress: STD_LOGIC_VECTOR (31 downto 0);
  signal jumpOrBranch: STD_LOGIC;
  -- Outputs
  signal pc_value: STD_LOGIC_VECTOR (31 downto 0);

  constant clock_period: time := 10 ns;
  signal stop_the_clock: boolean := false; -- Initialize stop_the_clock

begin

  uut: fetch port map ( CLK                 => CLK,
                        resetn              => resetn,
                        enable_f            => enable_f,
                        enable_m            => enable_m,
                        jumpOrBranchAddress => jumpOrBranchAddress,
                        jumpOrBranch        => jumpOrBranch,
                        pc_value            => pc_value );

  clocking: process
  begin
    while not stop_the_clock loop
      CLK <= not CLK; -- Toggle clock
      wait for clock_period / 2;
    end loop;
    wait;
  end process;

  stimulus: process
  begin
    report "Starting Testbench for fetch component" severity note;

    -- Put initialisation code here
    resetn              <= '0';
    enable_f            <= '0';
    enable_m            <= '0';
    jumpOrBranchAddress <= (others => '0');
    jumpOrBranch        <= '0';
    wait for clock_period * 2;

    resetn <= '1';
    report "Reset de-asserted. PC should be 0x00000000" severity note;
    wait for clock_period;
    assert pc_value = x"00000000" report "Initial PC not 0 after reset" severity error;


    -- Test Case 1: PC increment with enable_f
    report "Test Case 1: PC increment" severity note;
    enable_f <= '1';
    enable_m <= '0';
    jumpOrBranch <= '0';
    wait for clock_period; -- PC should become 4
    assert pc_value = x"00000004" report "TC1.1: PC not 4 after first increment" severity error;

    wait for clock_period; -- PC should become 8
    assert pc_value = x"00000008" report "TC1.2: PC not 8 after second increment" severity error;

    wait for clock_period; -- PC should become C
    assert pc_value = x"0000000C" report "TC1.3: PC not C after third increment" severity error;
    enable_f <= '0';
    wait for clock_period; -- PC should remain C
    assert pc_value = x"0000000C" report "TC1.4: PC changed while enable_f is low" severity error;


    -- Test Case 2: Jump/Branch (enable_f is low, so jump condition can be met)
    report "Test Case 2: Jump/Branch to 0x00000100" severity note;
    enable_f            <= '0'; -- Ensure increment condition is false
    enable_m            <= '1';
    jumpOrBranch        <= '1';
    jumpOrBranchAddress <= x"00000100";
    wait for clock_period;
    assert pc_value = x"00000100" report "TC2.1: PC not 0x100 after jump" severity error;

    enable_m     <= '0';
    jumpOrBranch <= '0';
    wait for clock_period * 2;
    assert pc_value = x"00000100" report "TC2.2: PC changed while no enable or jump" severity error;

    -- Test Case 3: Jump/Branch followed by increment
    report "Test Case 3: Jump to 0xAA and then increment" severity note;
    enable_f            <= '0'; -- Ensure increment condition is false for the jump
    enable_m            <= '1';
    jumpOrBranch        <= '1';
    jumpOrBranchAddress <= x"000000AA";
    wait for clock_period;
    assert pc_value = x"000000AA" report "TC3.1: PC not 0xAA after jump" severity error;

    enable_f     <= '1'; -- Now enable fetch increment
    enable_m     <= '0';
    jumpOrBranch <= '0';
    wait for clock_period; -- PC should become 0xAA + 4 = 0xAE
    assert pc_value = x"000000AE" report "TC3.2: PC not 0xAE after incrementing from jump" severity error;

    wait for clock_period; -- PC should become 0xAE + 4 = 0xB2
    assert pc_value = x"000000B2" report "TC3.3: PC not 0xB2 after second increment" severity error;

    -- Test Case 4: enable_f='1', enable_m='1', jumpOrBranch='1'
    -- According to VHDL, enable_f takes precedence.
    report "Test Case 4: enable_f='1', enable_m='1', jumpOrBranch='1' (expect increment)" severity note;
    -- PC is currently 0x000000B2
    enable_f            <= '1';
    enable_m            <= '1';
    jumpOrBranch        <= '1';
    jumpOrBranchAddress <= x"0000BEEF"; -- This jump address will be ignored this cycle
    wait for clock_period;
    -- PC should be 0x000000B2 + 4 = 0x000000B6 because enable_f='1' is the first true condition
    assert pc_value = x"000000B6" report "TC4.1: PC not 0xB6. Increment should occur due to enable_f priority." severity error;

    -- Test Case 5: enable_f='1', enable_m='1', jumpOrBranch='0'
    -- According to VHDL, enable_f takes precedence.
    report "Test Case 5: enable_f='1', enable_m='1', jumpOrBranch='0' (expect increment)" severity note;
    -- PC is currently 0x000000B6
    enable_f            <= '1';
    enable_m            <= '1';
    jumpOrBranch        <= '0'; -- Jump condition (enable_m='1' AND jumpOrBranch='1') is FALSE
    -- jumpOrBranchAddress is still 0xBEEF, but jumpOrBranch is '0'
    wait for clock_period;
    -- PC should be 0x000000B6 + 4 = 0x000000BA because enable_f='1' is the first true condition
    assert pc_value = x"000000BA" report "TC5.1: PC not 0xBA. Increment should occur due to enable_f." severity error;

    -- Test Case 6: Verify jump still works if enable_f is then disabled
    report "Test Case 6: enable_f='0', enable_m='1', jumpOrBranch='1' (expect jump)" severity note;
    -- PC is currently 0x000000BA
    enable_f            <= '0'; -- Disable fetch increment to allow jump condition to be met
    enable_m            <= '1';
    jumpOrBranch        <= '1';
    jumpOrBranchAddress <= x"0000DEAD";
    wait for clock_period;
    assert pc_value = x"0000DEAD" report "TC6.1: PC not 0xDEAD. Jump should occur." severity error;


    report "All test cases finished." severity note;
    stop_the_clock <= true;
    wait;
  end process;

end bench;