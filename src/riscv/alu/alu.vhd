library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity alu is
Port (
   rs1_v             : in  STD_LOGIC_VECTOR (31 downto 0);  -- rs_1 value
   rs2_v             : in  STD_LOGIC_VECTOR (31 downto 0);  -- rs_2 value
   isALUreg          : in  STD_LOGIC;                       -- does computation invole rs_1 and rs_2 ? or imm ?
   isBranch          : in  STD_LOGIC;                       -- branch instruction ?
   isAluSubstraction : in  STD_LOGIC;                       -- From funct7(5) for R-type ADD/SUB, or indicates SUB for I-type IF needed by control
   isCustom          : in  STD_LOGIC;                       -- custom instruction
   func3             : in  STD_LOGIC_VECTOR ( 2 downto 0);  -- funct3 field
   func7             : in  STD_LOGIC_VECTOR ( 6 downto 0);  -- funct7 field (specifically func7(5) for SRL/SRA and potentially SUB)
   imm_v             : in  STD_LOGIC_VECTOR (31 downto 0);  -- immediate value

   aluOut_v          : out STD_LOGIC_VECTOR (31 downto 0);  -- result of the ALU computation
   aluPlus_v         : out STD_LOGIC_VECTOR (31 downto 0);  -- result of the adder (rs_1 + (rs_2 or imm))
   takeBranch        : out STD_LOGIC
 );
end alu;


architecture arch of alu is

   signal operand_1    : STD_LOGIC_VECTOR(31 downto 0);
   signal operand_2    : STD_LOGIC_VECTOR(31 downto 0);
   signal alu_result   : STD_LOGIC_VECTOR(31 downto 0);
   signal branch_taken : STD_LOGIC := '0';
   signal shift_amount : UNSIGNED(4 downto 0);

BEGIN

    operand_1 <= rs1_v;
    operand_2 <= rs2_v WHEN isALUreg = '1' ELSe
                 imm_v;

    aluPlus_v <= STD_LOGIC_VECTOR(SIGNED(operand_1) + SIGNED(operand_2));

    shift_amount <= UNSIGNED(operand_2(4 downto 0));

    process(operand_1, operand_2, isBranch, isAluSubstraction, func3, func7, shift_amount, isCustom)
        variable temp_result : STD_LOGIC_VECTOR(31 downto 0);
    BEGIN

        temp_result  := (OTHERS => 'X'); 
        branch_taken <= '0';             

        IF isCustom = '1' then
           
            temp_result := x"DEADBEEF"; 
            branch_taken <= '0';

        ELSIF isBranch = '1' then
            -- Branch condition logic
            case func3 is
                WHEN "000" => -- BEQ (rs1 == rs2)
                    IF operand_1 = operand_2 then
                        branch_taken <= '1';
                    END IF;
                WHEN "001" => -- BNE (rs1 != rs2)
                    IF operand_1 /= operand_2 then
                        branch_taken <= '1';
                    END IF;
                WHEN "100" => -- BLT (rs1 < rs2, SIGNED)
                    IF SIGNED(operand_1) < SIGNED(operand_2) then
                        branch_taken <= '1';
                    END IF;
                WHEN "101" => -- BGE (rs1 >= rs2, SIGNED)
                    IF SIGNED(operand_1) >= SIGNED(operand_2) then
                        branch_taken <= '1';
                    END IF;
                WHEN "110" => -- BLTU (rs1 < rs2, UNSIGNED)
                    IF UNSIGNED(operand_1) < UNSIGNED(operand_2) then
                        branch_taken <= '1';
                    END IF;
                WHEN "111" => -- BGEU (rs1 >= rs2, UNSIGNED)
                    IF UNSIGNED(operand_1) >= UNSIGNED(operand_2) then
                        branch_taken <= '1';
                    END IF;
                WHEN OTHERS =>
                    branch_taken <= '0';
            END CASE;
           
            temp_result := (OTHERS => '0');

        ELSe 
            case func3 is
                WHEN "000" => -- ADD, SUB, ADDI
                    IF isAluSubstraction = '1' then -- SUB
                        temp_result := STD_LOGIC_VECTOR(SIGNED(operand_1) - SIGNED(operand_2));
                    ELSe -- ADD or ADDI
                        temp_result := STD_LOGIC_VECTOR(SIGNED(operand_1) + SIGNED(operand_2));
                    END IF;

                WHEN "001" => -- SLL, SLLI (Shift Left Logical)
                    temp_result := STD_LOGIC_VECTOR(shift_left(UNSIGNED(operand_1), to_integer(shift_amount)));

                WHEN "010" => -- SLT, SLTI (Set Less Than, SIGNED)
                    IF SIGNED(operand_1) < SIGNED(operand_2) then
                        temp_result := STD_LOGIC_VECTOR(to_UNSIGNED(1, 32));
                    ELSe
                        temp_result := STD_LOGIC_VECTOR(to_UNSIGNED(0, 32));
                    END IF;

                WHEN "011" =>
                    IF UNSIGNED(operand_1) < UNSIGNED(operand_2) then
                        temp_result := STD_LOGIC_VECTOR(to_UNSIGNED(1, 32));
                    ELSe
                        temp_result := STD_LOGIC_VECTOR(to_UNSIGNED(0, 32));
                    END IF;

                WHEN "100" => -- XOR, XORI
                    temp_result := operand_1 xor operand_2;

                WHEN "101" => 
                IF isALUreg = '1' then -- R-type (SRL or SRA)
                    IF func7(5) = '1' then -- SRA 
                        temp_result := STD_LOGIC_VECTOR(shift_right(SIGNED(operand_1), to_integer(UNSIGNED(operand_2(4 downto 0)))));
                    ELSe -- SRL
                        temp_result := STD_LOGIC_VECTOR(shift_right(UNSIGNED(operand_1), to_integer(UNSIGNED(operand_2(4 downto 0)))));
                    END IF;
                ELSe 
                    IF imm_v(10) = '1' then 
                        temp_result := STD_LOGIC_VECTOR(shift_right(SIGNED(operand_1)  , to_integer(UNSIGNED(imm_v(4 downto 0)))));
                    ELSe -- SRLI 
                        temp_result := STD_LOGIC_VECTOR(shift_right(SIGNED(operand_1)  , to_integer(UNSIGNED(imm_v(4 downto 0)))));
                    END IF;
                END IF;

                WHEN "110" => 
                    temp_result := operand_1 or operand_2;

                WHEN "111" => -- AND, ANDI
                    temp_result := operand_1 and operand_2;

                WHEN OTHERS =>
                    temp_result := (OTHERS => 'X'); 
            END CASE;
        END IF;
        alu_result <= temp_result; 
    end process;

    aluOut_v   <= alu_result;
    takeBranch <= branch_taken;

end architecture arch;