LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.ENV.FINISH; -- For the DUT's EBREAK

-- If you have specific configurations for memory size, include your package
USE work.riscv_config.all;

ENTITY riscv_tb IS
END riscv_tb;

ARCHITECTURE behavior OF riscv_tb IS

    -- Component Declaration for the DUT
    COMPONENT riscv
        Port (
            CLK           : in  STD_LOGIC;
            resetn        : in  STD_LOGIC;
            im_addr       : out STD_LOGIC_VECTOR (31 downto 0);
            im_rdata      : in  STD_LOGIC_VECTOR (31 downto 0);
            dm_addr       : out STD_LOGIC_VECTOR (31 downto 0);
            dm_rdata      : in  STD_LOGIC_VECTOR (31 downto 0);
            dm_wdata      : out STD_LOGIC_VECTOR (31 downto 0);
            dm_wmask      : out STD_LOGIC_VECTOR ( 3 downto 0);
            dm_rd         : out STD_LOGIC;
            dm_wr         : out STD_LOGIC
        );
    END COMPONENT;

    -- Clock period
    CONSTANT CLK_PERIOD : TIME := 10 ns;

    -- Signals for DUT
    SIGNAL tb_clk      : STD_LOGIC := '0';
    SIGNAL tb_resetn   : STD_LOGIC;
    SIGNAL tb_im_addr  : STD_LOGIC_VECTOR (31 downto 0);
    SIGNAL tb_im_rdata : STD_LOGIC_VECTOR (31 downto 0);
    SIGNAL tb_dm_addr  : STD_LOGIC_VECTOR (31 downto 0);
    SIGNAL tb_dm_rdata : STD_LOGIC_VECTOR (31 downto 0);
    SIGNAL tb_dm_wdata : STD_LOGIC_VECTOR (31 downto 0);
    SIGNAL tb_dm_wmask : STD_LOGIC_VECTOR ( 3 downto 0);
    SIGNAL tb_dm_rd    : STD_LOGIC;
    SIGNAL tb_dm_wr    : STD_LOGIC;

    -- Instruction Memory Model
    CONSTANT IMEM_ADDR_WIDTH : INTEGER := 10; -- 2^10 = 1024 words (4KB)
    CONSTANT IMEM_SIZE       : INTEGER := 2**IMEM_ADDR_WIDTH;
    TYPE imem_array_t IS ARRAY (0 TO IMEM_SIZE-1) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL imem_data : imem_array_t;

    -- Data Memory Model
    CONSTANT DMEM_ADDR_WIDTH : INTEGER := 10; -- 2^10 = 1024 words (4KB)
    CONSTANT DMEM_SIZE       : INTEGER := 2**DMEM_ADDR_WIDTH;
    TYPE dmem_array_t IS ARRAY (0 TO DMEM_SIZE-1) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL dmem_data : dmem_array_t := (others => (others => '0')); -- Initialize to all zeros

    -- Simple program (Assembly -> Machine Code)
    -- 0x00000000: addi x1, x0, 5        (0x00500093)
    -- 0x00000004: addi x2, x0, 10       (0x00A00113)
    -- 0x00000008: add  x3, x1, x2       (0x002081B3) -> x3 = 15
    -- 0x0000000C: sw   x3, 4(x0)        (0x00302223) -> M[4] = 15 (store at address 0x00000004)
    -- 0x00000010: lw   x4, 4(x0)        (0x00402203) -> x4 = M[4] = 15
    -- 0x00000014: ebreak                (0x00100073)

    CONSTANT PROG_START_ADDR : NATURAL := 0;

BEGIN

    -- Instantiate the Unit Under Test (UUT)
    UUT : riscv
        PORT MAP (
            CLK      => tb_clk,
            resetn   => tb_resetn,
            im_addr  => tb_im_addr,
            im_rdata => tb_im_rdata,
            dm_addr  => tb_dm_addr,
            dm_rdata => tb_dm_rdata,
            dm_wdata => tb_dm_wdata,
            dm_wmask => tb_dm_wmask,
            dm_rd    => tb_dm_rd,
            dm_wr    => tb_dm_wr
        );

    -- Clock generation process
    clk_gen_proc : PROCESS
    BEGIN
        tb_clk <= '0';
        WAIT FOR CLK_PERIOD / 2;
        tb_clk <= '1';
        WAIT FOR CLK_PERIOD / 2;
    END PROCESS clk_gen_proc;

    -- Reset generation process
    reset_proc : PROCESS
    BEGIN
        tb_resetn <= '0'; -- Assert reset
        WAIT FOR CLK_PERIOD * 5;
        tb_resetn <= '1'; -- De-assert reset
        WAIT;
    END PROCESS reset_proc;

    -- Instruction Memory Model
    imem_proc : PROCESS
        VARIABLE imem_addr_word : NATURAL;
    BEGIN
        -- Initialize Instruction Memory
        -- This can also be done by reading from a .hex or .mif file for larger programs
        imem_data(PROG_START_ADDR + 0) <= x"00500093"; -- addi x1, x0, 5
        imem_data(PROG_START_ADDR + 1) <= x"00A00113"; -- addi x2, x0, 10
        imem_data(PROG_START_ADDR + 2) <= x"002081B3"; -- add  x3, x1, x2
        imem_data(PROG_START_ADDR + 3) <= x"00302223"; -- sw   x3, 4(x0)
        imem_data(PROG_START_ADDR + 4) <= x"00402203"; -- lw   x4, 4(x0)
        imem_data(PROG_START_ADDR + 5) <= x"00100073"; -- ebreak
        -- Fill rest with NOPs (addi x0, x0, 0  -> 0x00000013) or default value
        FOR i IN (PROG_START_ADDR + 6) TO IMEM_SIZE-1 LOOP
            imem_data(i) <= x"00000013"; -- NOP
        END LOOP;

        WAIT UNTIL tb_resetn = '1'; -- Start after reset is de-asserted

        LOOP
            WAIT UNTIL rising_edge(tb_clk); -- Or wait on tb_im_addr change for combinatorial
            -- The DUT provides byte address, IMEM is word addressed
            imem_addr_word := to_integer(unsigned(tb_im_addr(IMEM_ADDR_WIDTH + 1 DOWNTO 2)));
            IF imem_addr_word < IMEM_SIZE THEN
                tb_im_rdata <= imem_data(imem_addr_word);
            ELSE
                tb_im_rdata <= x"00000013"; -- Return NOP for out-of-bounds access
                -- REPORT "IMEM: Address out of bounds: " & to_hstring(tb_im_addr) SEVERITY WARNING;
            END IF;
        END LOOP;
    END PROCESS imem_proc;

    -- Data Memory Model
    dmem_proc : PROCESS
        VARIABLE dmem_addr_word : NATURAL;
        VARIABLE byte_offset    : NATURAL;
    BEGIN
        WAIT UNTIL tb_resetn = '1'; -- Start after reset is de-asserted

        LOOP
            WAIT UNTIL rising_edge(tb_clk);
            dmem_addr_word := to_integer(unsigned(tb_dm_addr(DMEM_ADDR_WIDTH + 1 DOWNTO 2)));
            byte_offset    := to_integer(unsigned(tb_dm_addr(1 DOWNTO 0)));

            -- Handle Write
            IF tb_dm_wr = '1' THEN
                IF dmem_addr_word < DMEM_SIZE THEN
                    -- Byte-addressable write based on dm_wmask
                    -- Assumes tb_dm_wdata is aligned for the lowest byte of the operation
                    -- Example: For SW, dm_wmask = "1111"
                    -- For SH, dm_wmask = "0011" (addr(1:0)="00") or "1100" (addr(1:0)="10")
                    -- For SB, dm_wmask = "0001" (addr(1:0)="00"), "0010" (addr(1:0)="01"), etc.
                    FOR i IN 0 TO 3 LOOP
                        IF tb_dm_wmask(i) = '1' THEN
                            dmem_data(dmem_addr_word)((i*8)+7 DOWNTO i*8) <= tb_dm_wdata((i*8)+7 DOWNTO i*8);
                        END IF;
                    END LOOP;
                    -- REPORT "DMEM: Wrote " & to_hstring(tb_dm_wdata) &
                    --        " to addr " & to_hstring(tb_dm_addr) &
                    --        " with mask " & to_hstring(tb_dm_wmask) SEVERITY NOTE;
                ELSE
                    REPORT "DMEM: Write address out of bounds: " & to_hstring(tb_dm_addr) SEVERITY WARNING;
                END IF;
            END IF;

            -- Handle Read (Data available in the same cycle as dm_rd asserted)
            -- The DUT's M stage uses dm_rdata one cycle after dm_rd is asserted in E stage.
            -- So, dm_rdata must be valid when dm_rd is high.
            IF tb_dm_rd = '1' THEN
                IF dmem_addr_word < DMEM_SIZE THEN
                    tb_dm_rdata <= dmem_data(dmem_addr_word);
                    -- REPORT "DMEM: Read " & to_hstring(dmem_data(dmem_addr_word)) &
                    --        " from addr " & to_hstring(tb_dm_addr) SEVERITY NOTE;

                ELSE
                    tb_dm_rdata <= (others => 'X'); -- Return X for out-of-bounds read
                    REPORT "DMEM: Read address out of bounds: " & to_hstring(tb_dm_addr) SEVERITY WARNING;
                END IF;
            ELSE
                 tb_dm_rdata <= (others => 'Z'); -- Not reading, drive Z
            END IF;

        END LOOP;
    END PROCESS dmem_proc;

    -- Optional: Timeout process to prevent simulation from running forever
    -- if ebreak is not reached.
    timeout_proc: PROCESS
    BEGIN
        WAIT FOR CLK_PERIOD * 200; -- Adjust timeout value as needed
        REPORT "SIMULATION TIMEOUT! EBREAK not reached." SEVERITY FAILURE;
        FINISH; -- Stop simulation
    END PROCESS timeout_proc;

END behavior;