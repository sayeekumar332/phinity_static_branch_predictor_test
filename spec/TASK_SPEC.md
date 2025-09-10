Task: Debug & Correct Static Branch Predictor RTL
--------------------------------------------------

Objective
----------
The static branch predictor module calculates whether a branch or jump is taken and the predicted branch target PC in a RISC-V pipeline. Currently, some predictions are incorrect. Your task is to identify the logic issues, fix them, and verify correctness using the provided testbench.

File to Work On :
------------------
--> rtl/static_branch_predict.sv


Test Harness
-------------
A cocotb-based testbench is provided:

--> test_static_branch_predict.py


System Verilog Testbench
------------------------
--> verif/tb_static_branch_predict.sv


This testbench verifies the correctness of branch prediction for:

JAL, JALR

Conditional branches (B-type)

Compressed jumps and branches (CJ and CB types)


Observed Symptoms / Issues :
-----------------------------
1. Uncompressed branch instructions are mispredicted

   Some standard RISC-V B-type instructions are never predicted as taken, even when the branch condition should cause them to be taken.

2. Branch target PC calculation is incorrect

   Predicted PC addresses are wrong in some cases:

     Backward branches may point to addresses ahead of the current PC.

     Forward branches may point backward.

Requirements
--------------
1. Branch detection
---------------------
Investigate why some uncompressed branches are not recognized.

Correct the detection logic so that all uncompressed branch instructions are properly handled.

2. Branch target calculation
------------------------------
--> Verify that the predicted branch target PC is consistent with the fetch PC and branch offset.

--> Correct any logic errors that result in the wrong target address.

3. Testing & Verification
---------------------------
--> Run the cocotb testbench harness/test_static_branch_predict.py.

--> Ensure all tests pass.

--> Use test logs to understand which cases fail and why.

Documentation
--------------
--> Write a debug reasoning document (docs/REASONING.md) describing:

    --> How you identified the issues

    --> How you fixed them

    --> Any assumptions made


Deliverables 
-------------
1. Fixed RTL:
--------------
rtl/static_branch_predict.sv


2. Debug Reasoning :
---------------------
docs/REASONING.md

3. Evidence of passing tests (e.g., cocotb log outputs).


Notes
------
--> Do not assume the exact lines of the error; investigate using tests and RTL behavior.

--> Focus on logical correctness of branch detection and target calculation.

--> Performance optimization is not required.



This abstracted spec ensures the task is non-trivial and requires reasoning about:

--> RISC-V opcodes

--> Branch type decoding

--> Signed immediate offsets

--> Branch PC computation
