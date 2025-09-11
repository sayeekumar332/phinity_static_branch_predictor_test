# REASONING.md

## Debugging & Fix Log – Static Branch Predictor

**Module:** `static_branch_predict.sv`  
**Engineer:** [Junior Engineer]  
**Date:** [YYYY-MM-DD]  

---

## 1. Observations

After running the cocotb testbench `harness/test_static_branch_predict.py`, the following behaviors were noticed:

### Uncompressed branches are never predicted taken
- Backward branches (e.g., loops) fail all predictions.  
- Forward branches sometimes behave correctly for jumps but fail for conditional branches.  

### Branch target PC is incorrect
- For backward branches, the predicted PC points ahead of the current PC.  
- Forward branches sometimes predict a target behind the current PC.  

---

## 2. Investigation

### Step 1 – Examine branch detection logic
- Reviewed signals that identify branch instructions (`instr_b`) for uncompressed instructions.  
- Compared opcode extraction with RISC-V ISA manual.  
- Noticed that some standard B-type instructions are not triggering the `instr_b` signal.  
- **Reasoning:** If the opcode comparison is wrong, uncompressed branches are ignored, causing mispredictions.  

### Step 2 – Examine predicted PC calculation
- Observed `predict_branch_pc_o` calculation.  
- Checked the sign-extension of immediates (`branch_imm`).  
- Realized that adding vs. subtracting the branch offset affects forward/backward targets:  
  - If the offset is subtracted, backward branches move forward and forward branches move backward.  
- **Correct behavior:** predicted PC = fetch PC + branch offset (signed).  

---

## 3. Fix Implementation

### Branch detection
- Corrected logic to properly detect all uncompressed B-type branch instructions based on opcode.  
- Ensured `instr_b` signal now correctly asserts for standard branches.  

### Branch PC calculation
- Updated predicted PC calculation to **add the signed branch offset** to the current fetch PC.  

---

## 4. Verification
- Ran `test_static_branch_predict.py` after fixes.  
- All tests passed successfully, including:  
  - Forward branches  
  - Backward branches  
  - JAL and JALR  
  - Compressed jumps and branches (CJ, CB)  

**Test log snippet:**
**COCOTB log:**
MODULE=test_static_branch_predict TESTCASE= TOPLEVEL=static_branch_predict TOPLEVEL_LANG=verilog \
         /usr/bin/vvp -M /home/dell/.local/lib/python3.8/site-packages/cocotb/libs -m libcocotbvpi_icarus   sim_build/sim.vvp  
     -.--ns INFO     gpi                                ..mbed/gpi_embed.cpp:79   in set_program_name_in_venv        Did not detect Python virtual environment. Using system-wide Python interpreter
     -.--ns INFO     gpi                                ../gpi/GpiCommon.cpp:101  in gpi_print_registered_impl       VPI registered
     0.00ns INFO     cocotb                             Running on Icarus Verilog version 10.3 (stable)
     0.00ns INFO     cocotb                             Running tests with cocotb v1.9.2 from /home/dell/.local/lib/python3.8/site-packages/cocotb
     0.00ns INFO     cocotb                             Seeding Python random module with 1757503985
     0.00ns INFO     cocotb.regression                  Found test test_static_branch_predict.test_static_branch_predict
     0.00ns INFO     cocotb.regression                  running test_static_branch_predict (1/1)
                                                          Test Static Branch Predictor for different branch and jump scenarios.
    10.00ns INFO     cocotb.static_branch_predict       Running test case: Branch taken, PC offset negative (B-type), [BEQ]
    10.00ns INFO     cocotb.static_branch_predict       fetch_rdata_i: 8C218363, fetch_pc_i: 00001000, Register Operand: 00000000, Valid: 1
    10.00ns INFO     cocotb.static_branch_predict       Expected Taken: 1, Actual Taken: 1
    10.00ns INFO     cocotb.static_branch_predict       Expected PC: 000000C6, Actual PC: 000000C6
    30.00ns INFO     cocotb.static_branch_predict       Running test case: Branch taken, PC offset positive (B-type), [BEQ]
    30.00ns INFO     cocotb.static_branch_predict       fetch_rdata_i: 6C2183E3, fetch_pc_i: 00001000, Register Operand: 00000000, Valid: 1
    30.00ns INFO     cocotb.static_branch_predict       Expected Taken: 0, Actual Taken: 0
    30.00ns INFO     cocotb.static_branch_predict       Expected PC: 00001EC6, Actual PC: 00001EC6
    50.00ns INFO     cocotb.static_branch_predict       Running test case: Jump taken (J-type) with negative offset, [JAL]
    50.00ns INFO     cocotb.static_branch_predict       fetch_rdata_i: 926CF16F, fetch_pc_i: 00001000, Register Operand: 00000000, Valid: 1
    50.00ns INFO     cocotb.static_branch_predict       Expected Taken: 1, Actual Taken: 1
    50.00ns INFO     cocotb.static_branch_predict       Expected PC: FFFD0126, Actual PC: FFFD0126
    70.00ns INFO     cocotb.static_branch_predict       Running test case: Jump taken (J-type) with positive offset, [JAL]
    70.00ns INFO     cocotb.static_branch_predict       fetch_rdata_i: 126CF16F, fetch_pc_i: 00001000, Register Operand: 00000000, Valid: 1
    70.00ns INFO     cocotb.static_branch_predict       Expected Taken: 1, Actual Taken: 1
    70.00ns INFO     cocotb.static_branch_predict       Expected PC: 000D0126, Actual PC: 000D0126
    90.00ns INFO     cocotb.static_branch_predict       Running test case: Jump taken (JALR) with negative offset, [JALR]
    90.00ns INFO     cocotb.static_branch_predict       fetch_rdata_i: F63101E7, fetch_pc_i: 00001000, Register Operand: 00000000, Valid: 1
    90.00ns INFO     cocotb.static_branch_predict       Expected Taken: 1, Actual Taken: 1
    90.00ns INFO     cocotb.static_branch_predict       Expected PC: 00000F63, Actual PC: 00000F63
   110.00ns INFO     cocotb.static_branch_predict       Running test case: Jump taken (JALR) with positive offset, [JALR]
   110.00ns INFO     cocotb.static_branch_predict       fetch_rdata_i: 763101E7, fetch_pc_i: 00001000, Register Operand: 00000000, Valid: 1
   110.00ns INFO     cocotb.static_branch_predict       Expected Taken: 1, Actual Taken: 1
   110.00ns INFO     cocotb.static_branch_predict       Expected PC: 00001763, Actual PC: 00001763
   130.00ns INFO     cocotb.static_branch_predict       Running test case: Compressed Jump taken (J-type) with positive offset, [C.J]
   130.00ns INFO     cocotb.static_branch_predict       fetch_rdata_i: 4840006F, fetch_pc_i: 00001000, Register Operand: 00000000, Valid: 1
   130.00ns INFO     cocotb.static_branch_predict       Expected Taken: 1, Actual Taken: 1
   130.00ns INFO     cocotb.static_branch_predict       Expected PC: 00001484, Actual PC: 00001484
   150.00ns INFO     cocotb.static_branch_predict       Running test case: Compressed Jump taken (J-type) with positive offset, [C.JAL]
   150.00ns INFO     cocotb.static_branch_predict       fetch_rdata_i: 484000EF, fetch_pc_i: 00001000, Register Operand: 00000000, Valid: 1
   150.00ns INFO     cocotb.static_branch_predict       Expected Taken: 1, Actual Taken: 1
   150.00ns INFO     cocotb.static_branch_predict       Expected PC: 00001484, Actual PC: 00001484
   170.00ns INFO     cocotb.static_branch_predict       Running test case: Compressed Branch Taken, PC offset positive (B-type), [C.BEQZ]
   170.00ns INFO     cocotb.static_branch_predict       fetch_rdata_i: 08040A63, fetch_pc_i: 00001000, Register Operand: 00000000, Valid: 1
   170.00ns INFO     cocotb.static_branch_predict       Expected Taken: 0, Actual Taken: 0
   170.00ns INFO     cocotb.static_branch_predict       Expected PC: 00001094, Actual PC: 00001094
   190.00ns INFO     cocotb.static_branch_predict       Running test case: Invalid fetch (not valid)
   190.00ns INFO     cocotb.static_branch_predict       fetch_rdata_i: 00000001, fetch_pc_i: 00002000, Register Operand: 00000000, Valid: 0
   190.00ns INFO     cocotb.static_branch_predict       Expected Taken: 0, Actual Taken: 0
   190.00ns INFO     cocotb.static_branch_predict       Expected PC: 00002000, Actual PC: 00002000
   210.00ns INFO     cocotb.static_branch_predict       Running test case: No branch or jump
   210.00ns INFO     cocotb.static_branch_predict       fetch_rdata_i: 00000000, fetch_pc_i: 00002000, Register Operand: 00000000, Valid: 1
   210.00ns INFO     cocotb.static_branch_predict       Expected Taken: 0, Actual Taken: 0
   210.00ns INFO     cocotb.static_branch_predict       Expected PC: 00002000, Actual PC: 00002000
   230.00ns INFO     cocotb.static_branch_predict       Running test case: Improper Instruction Encoding
   230.00ns INFO     cocotb.static_branch_predict       fetch_rdata_i: FE000E63, fetch_pc_i: 00001000, Register Operand: 00000000, Valid: 1
   230.00ns INFO     cocotb.static_branch_predict       Expected Taken: 1, Actual Taken: 1
   230.00ns INFO     cocotb.static_branch_predict       Expected PC: 000007FC, Actual PC: 000007FC
   240.00ns INFO     cocotb.regression                  test_static_branch_predict passed
   240.00ns INFO     cocotb.regression                  ***************************************************************************************************************
                                                        ** TEST                                                   STATUS  SIM TIME (ns)  REAL TIME (s)  RATIO (ns/s) **
                                                        ***************************************************************************************************************
                                                        ** test_static_branch_predict.test_static_branch_predict   PASS         240.00           0.01      26111.15  **
                                                        ***************************************************************************************************************
                                                        ** TESTS=1 PASS=1 FAIL=0 SKIP=0                                         240.00           0.14       1688.14  **
                                                        ***************************************************************************************************************

**SV Testbench Log:**
VCD info: dumpfile static_branch_predict.vcd opened for output.
Starting testbench for Static Branch Predictor...
Running test case: Branch taken, PC offset negative (B-type),[BEQ]
Branch taken, PC offset negative (B-type),[BEQ] - fetch_rdata_i = 8c218363, fetch_pc_i = 1000, Valid = 1
Branch taken, PC offset negative (B-type),[BEQ] - Expected taken = 1, Actual taken = 1 
Branch taken, PC offset negative (B-type),[BEQ] - Expected PC = c6, Actual PC = c6
Branch taken, PC offset negative (B-type),[BEQ] - Test passed: (predict_branch_taken_o is correct: 1)
Branch taken, PC offset negative (B-type),[BEQ] - Test passed: (predict_branch_pc_o is correct: c6)
Running test case: Branch taken, PC offset positive (B-type)[BEQ]
Branch taken, PC offset positive (B-type)[BEQ] - fetch_rdata_i = 6c2183e3, fetch_pc_i = 1000, Valid = 1
Branch taken, PC offset positive (B-type)[BEQ] - Expected taken = 0, Actual taken = 0 
Branch taken, PC offset positive (B-type)[BEQ] - Expected PC = 1ec6, Actual PC = 1ec6
Branch taken, PC offset positive (B-type)[BEQ] - Test passed: (predict_branch_taken_o is correct: 0)
Branch taken, PC offset positive (B-type)[BEQ] - Test passed: (predict_branch_pc_o is correct: 1ec6)
Running test case: Jump taken (J-type) with negative offset[JAL]
Jump taken (J-type) with negative offset[JAL] - fetch_rdata_i = 926cf16f, fetch_pc_i = 1000, Valid = 1
Jump taken (J-type) with negative offset[JAL] - Expected taken = 1, Actual taken = 1 
Jump taken (J-type) with negative offset[JAL] - Expected PC = fffd0126, Actual PC = fffd0126
Jump taken (J-type) with negative offset[JAL] - Test passed: (predict_branch_taken_o is correct: 1)
Jump taken (J-type) with negative offset[JAL] - Test passed: (predict_branch_pc_o is correct: fffd0126)
Running test case: Jump taken (J-type) with positive offset[JAL]
Jump taken (J-type) with positive offset[JAL] - fetch_rdata_i = 126cf16f, fetch_pc_i = 1000, Valid = 1
Jump taken (J-type) with positive offset[JAL] - Expected taken = 1, Actual taken = 1 
Jump taken (J-type) with positive offset[JAL] - Expected PC = d0126, Actual PC = d0126
Jump taken (J-type) with positive offset[JAL] - Test passed: (predict_branch_taken_o is correct: 1)
Jump taken (J-type) with positive offset[JAL] - Test passed: (predict_branch_pc_o is correct: d0126)
Running test case: Jump taken (J-type) with negative offset[JALR]
Jump taken (J-type) with negative offset[JALR] - fetch_rdata_i = f63101e7, fetch_pc_i = 1000, Valid = 1
Jump taken (J-type) with negative offset[JALR] - Expected taken = 1, Actual taken = 1 
Jump taken (J-type) with negative offset[JALR] - Expected PC = f63, Actual PC = f63
Jump taken (J-type) with negative offset[JALR] - Test passed: (predict_branch_taken_o is correct: 1)
Jump taken (J-type) with negative offset[JALR] - Test passed: (predict_branch_pc_o is correct: f63)
Running test case: Jump taken (J-type) with positive offset[JALR]
Jump taken (J-type) with positive offset[JALR] - fetch_rdata_i = 763101e7, fetch_pc_i = 1000, Valid = 1
Jump taken (J-type) with positive offset[JALR] - Expected taken = 1, Actual taken = 1 
Jump taken (J-type) with positive offset[JALR] - Expected PC = 1763, Actual PC = 1763
Jump taken (J-type) with positive offset[JALR] - Test passed: (predict_branch_taken_o is correct: 1)
Jump taken (J-type) with positive offset[JALR] - Test passed: (predict_branch_pc_o is correct: 1763)
Running test case: Compressed Jump taken (J-type) with positive offset[C.J]
Compressed Jump taken (J-type) with positive offset[C.J] - fetch_rdata_i = 4840006f, fetch_pc_i = 1000, Valid = 1
Compressed Jump taken (J-type) with positive offset[C.J] - Expected taken = 1, Actual taken = 1 
Compressed Jump taken (J-type) with positive offset[C.J] - Expected PC = 1484, Actual PC = 1484
Compressed Jump taken (J-type) with positive offset[C.J] - Test passed: (predict_branch_taken_o is correct: 1)
Compressed Jump taken (J-type) with positive offset[C.J] - Test passed: (predict_branch_pc_o is correct: 1484)
Running test case: Compressed Jump taken (J-type) with positive offset[C.JAL]
Compressed Jump taken (J-type) with positive offset[C.JAL] - fetch_rdata_i = 484000ef, fetch_pc_i = 1000, Valid = 1
Compressed Jump taken (J-type) with positive offset[C.JAL] - Expected taken = 1, Actual taken = 1 
Compressed Jump taken (J-type) with positive offset[C.JAL] - Expected PC = 1484, Actual PC = 1484
Compressed Jump taken (J-type) with positive offset[C.JAL] - Test passed: (predict_branch_taken_o is correct: 1)
Compressed Jump taken (J-type) with positive offset[C.JAL] - Test passed: (predict_branch_pc_o is correct: 1484)
Running test case: Compressed Branch Taken , PC offset positive(B-type)[C.BEQZ]
Compressed Branch Taken , PC offset positive(B-type)[C.BEQZ] - fetch_rdata_i = 8040a63, fetch_pc_i = 1000, Valid = 1
Compressed Branch Taken , PC offset positive(B-type)[C.BEQZ] - Expected taken = 0, Actual taken = 0 
Compressed Branch Taken , PC offset positive(B-type)[C.BEQZ] - Expected PC = 1094, Actual PC = 1094
Compressed Branch Taken , PC offset positive(B-type)[C.BEQZ] - Test passed: (predict_branch_taken_o is correct: 0)
Compressed Branch Taken , PC offset positive(B-type)[C.BEQZ] - Test passed: (predict_branch_pc_o is correct: 1094)
Running test case: Invalid fetch (not valid)
Invalid fetch (not valid) - fetch_rdata_i = 1, fetch_pc_i = 2000, Valid = 0
Invalid fetch (not valid) - Expected taken = 0, Actual taken = 0 
Invalid fetch (not valid) - Expected PC = 2000, Actual PC = 2000
Invalid fetch (not valid) - Test passed: (predict_branch_taken_o is correct: 0)
Invalid fetch (not valid) - Test passed: (predict_branch_pc_o is correct: 2000)
Running test case: No branch or jump
No branch or jump - fetch_rdata_i = 0, fetch_pc_i = 2000, Valid = 1
No branch or jump - Expected taken = 0, Actual taken = 0 
No branch or jump - Expected PC = 2000, Actual PC = 2000
No branch or jump - Test passed: (predict_branch_taken_o is correct: 0)
No branch or jump - Test passed: (predict_branch_pc_o is correct: 2000)
Running test case: Branch taken, PC offset negative (B-type)[BEQ]
Branch taken, PC offset negative (B-type)[BEQ] - fetch_rdata_i = fe000e63, fetch_pc_i = 1000, Valid = 1
Branch taken, PC offset negative (B-type)[BEQ] - Expected taken = 1, Actual taken = 1 
Branch taken, PC offset negative (B-type)[BEQ] - Expected PC = 7fc, Actual PC = 7fc
Branch taken, PC offset negative (B-type)[BEQ] - Test passed: (predict_branch_taken_o is correct: 1)
Branch taken, PC offset negative (B-type)[BEQ] - Test passed: (predict_branch_pc_o is correct: 7fc)

## 5. Notes & Recommendations
- Branch detection and PC computation are now correct and synthesizable.  
- Further improvements could include dynamic branch prediction using a 2-bit predictor or branch history table.  
- All fixes were based on RTL behavior and testbench feedback, without directly referencing buggy line numbers.  

**Status:** Module fixed, all tests passing, reasoning documented.
