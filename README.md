**1. Describe a select RTL project and your role.**

Answer : 

**Project selected**: 

A static_branch_predict RTL module for a RISC-V pipeline — a SystemVerilog predictor that decodes branch/jump opcodes, computes sign-extended immediates, and outputs predict_branch_taken_o and predict_branch_pc_o. The repo includes rtl/static_branch_predict.sv, a cocotb harness (harness/test_static_branch_predict.py), and containerized test/synth tooling (Makefile + Docker/GHCR).

**My role here**: 

Senior RTL engineer / exercise author. I designed the module testplan and harness, injected controlled, multi-step bugs to create a realistic debugging exercise, wrote the abstract task spec for a junior engineer, supplied a clean solution branch with fixes and a step-by-step REASONING.md, and produced Docker/cocotb integration and an LLM challenge to validate reasoning and verification.

**2. Cloning a repository**
Answer : An entirely new repository was created "https://github.com/sayeekumar332/phinity_static_branch_predictor_test/tree/main" in my personal github account

**3. Ablate it in some fashion that requires a multistep fix. Essentially, you should break the code, introduce logical errors, etc. in order to require a multistep fix. This is an open-ended task. Feel free to be creative. Please describe the changes you made.**

Answer : 

**Ablations introduced (multi-step)**

**1) Wrong opcode for uncompressed branches** 
**Change made**

  // Was: assign instr_b = instr[6:0] == OPCODE_BRANCH;
  assign instr_b = instr[6:0] == 7'h64; // wrong opcode

**Effect**

Standard B-type (0x63) opcodes are not detected → instr_b never asserts for uncompressed branches.

**How to detect**

Add tests that present raw 32-bit branch opcodes (BEQ/BNE, etc.) and assert instr_b. Inspect waveform/print signals.

**2) Subtracting the branch offset instead of adding it (PC calculation reversed)**

**Change made**

// Was: predict_branch_pc_o = fetch_pc_i + branch_imm;
assign predict_branch_pc_o = fetch_pc_i - branch_imm; // reversed sign

**Effect**

Predicted target addresses flip direction: backward branches appear forward; forward branches appear backward.

**How to detect**

Run targeted tests with known fetch_pc + known immediates and verify arithmetic; inspect sign-extension of branch_imm.

**4. Create a spec or document as if you were asking a junior engineer to fix the issue. The spec can look something of the detail like the spec**

The document mentioning the errors in the static_branch_predict.sv module was abstractly explained without providing the explicit information has been provided.

**5. Create a sample solution/code file to the spec. Document how a junior engineer would reason and fix the issue step by step.**

A separate document called Reasoning.md has been provided in the spec in the solution branch on how to identify the error.

**6. Create one question/answer pair you would ask an LLM (like ChatGPT) in this repository (debugging, code completion, code comprehension, spec to RTL) that you would not expect ChatGPT to solve.**

Respond with input to the LLM and output. Please look at examples here. If your query isn't code comprehension or completion, please attach logs from the testbench to show that the expected solution code passes with no failures.

**Question (LLM prompt)**

The static_branch_predict.sv module contains multiple logical bugs affecting branch detection, immediate decoding, and prediction PC calculation. Without referencing the RISC-V ISA manual or any external resources, deduce the correct bit positions for all immediate encodings (B-type, JAL, JALR, compressed CJ, and compressed CB) purely from the failing cocotb testcases in harness/test_static_branch_predict.py.

Please output a corrected version of static_branch_predict.sv with fixed immediate concatenations, opcode detection, and PC calculation logic. You must also explain how you derived each bit-field placement using only observed input/output behavior from the tests.


**Expected Answer**

This is not realistically solvable by an LLM in a closed setting. The task requires reconstructing ISA encoding formats (bit-field layouts for immediates) without access to the ISA specification. An LLM can guess from prior training, but if constrained to only use the test outcomes, it would have to reverse-engineer the instruction encoding logic empirically. That demands domain knowledge of RISC-V bit-slices plus iterative testing — something far beyond the scope of pure text reasoning.

- Therefore, the LLM would likely fail or hallucinate. The correct solution requires:

- Consulting the RISC-V ISA specification for exact encoding layouts.

- Cross-checking those against simulation results.

- Repairing the RTL to implement correct field concatenations.

**N.B**
- The entire project was **run on Ubuntu 20.04 LTS**
- The **design has been found to be synthesizable** through **Yosys** (**sudo docker compose run synth - command for invoking the yosys through docker-compose.yml**. For **invoking the yosys** a separate **synth_scripts** folder has been created which contains **synth.tcl**
- The **design has been found to be functionally correct** through **standalone invocation of Icarus and invocation of Icarus through COCOTB**

     -  **sudo docker compose run verif** (Command for **invoking Icarus in GHCR**)
     -  **make** (Command for **invoking COCOTB**)         





