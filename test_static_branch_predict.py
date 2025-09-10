import cocotb
from cocotb.triggers import Timer
from random import randint

# Cocotb testbench for static branch predictor module
@cocotb.test()
async def test_static_branch_predict(dut):
    """Test Static Branch Predictor for different branch and jump scenarios."""

    # Define the test vectors based on the SystemVerilog run_test_case task
    test_vectors = [
        # Format: (test_instr, test_pc, test_register_operand, test_valid, expected_taken, expected_pc, case_name)
        (0x8C218363, 0x00001000, 0x00000000, 1, 1, 0x000000C6, "Branch taken, PC offset negative (B-type), [BEQ]"),
        (0x6C2183E3, 0x00001000, 0x00000000, 1, 0, 0x00001EC6, "Branch taken, PC offset positive (B-type), [BEQ]"),
        (0x926CF16F, 0x00001000, 0x00000000, 1, 1, 0xFFFD0126, "Jump taken (J-type) with negative offset, [JAL]"),
        (0x126CF16F, 0x00001000, 0x00000000, 1, 1, 0x000D0126, "Jump taken (J-type) with positive offset, [JAL]"),
        (0xF63101E7, 0x00001000, 0x00000000, 1, 1, 0x00000F63, "Jump taken (JALR) with negative offset, [JALR]"),
        (0x763101E7, 0x00001000, 0x00000000, 1, 1, 0x00001763, "Jump taken (JALR) with positive offset, [JALR]"),
        (0x4840006F, 0x00001000, 0x00000000, 1, 1, 0x00001484, "Compressed Jump taken (J-type) with positive offset, [C.J]"),
        (0x484000EF, 0x00001000, 0x00000000, 1, 1, 0x00001484, "Compressed Jump taken (J-type) with positive offset, [C.JAL]"),
        (0x08040A63, 0x00001000, 0x00000000, 1, 0, 0x00001094, "Compressed Branch Taken, PC offset positive (B-type), [C.BEQZ]"),
        (0x00000001, 0x00002000, 0x00000000, 0, 0, 0x00002000, "Invalid fetch (not valid)"),
        (0x00000000, 0x00002000, 0x00000000, 1, 0, 0x00002000, "No branch or jump"),
        (0xFE000E63, 0x00001000, 0x00000000, 1, 1, 0x000007FC, "Improper Instruction Encoding")
    ]

    # Iterate through the test vectors and apply them to the DUT
    for (test_instr, test_pc, test_register_operand, test_valid, expected_taken, expected_pc, case_name) in test_vectors:
        # Apply inputs
        dut.fetch_rdata_i.value = test_instr
        dut.fetch_pc_i.value = test_pc
        dut.register_addr_i.value = test_register_operand
        dut.fetch_valid_i.value = test_valid

        # Wait for the DUT to process the inputs
        await Timer(10, units="ns")

        # Capture the outputs
        actual_taken = dut.predict_branch_taken_o.value
        actual_pc = dut.predict_branch_pc_o.value

        # Log the test case details
        dut._log.info(f"Running test case: {case_name}")
        dut._log.info(f"fetch_rdata_i: {test_instr:08X}, fetch_pc_i: {test_pc:08X}, Register Operand: {test_register_operand:08X}, Valid: {test_valid}")
        dut._log.info(f"Expected Taken: {expected_taken}, Actual Taken: {actual_taken}")
        dut._log.info(f"Expected PC: {expected_pc:08X}, Actual PC: {int(actual_pc):08X}")

        # Assertions to check if outputs match expectations
        assert actual_taken == expected_taken, f"{case_name} - Predict Branch Taken Mismatch: Expected {expected_taken}, Got {actual_taken}"
        assert int(actual_pc) == expected_pc, f"{case_name} - Predict Branch PC Mismatch: Expected {expected_pc:08X}, Got {int(actual_pc):08X}"

        # Wait for a short time before the next test case
        await Timer(10, units="ns")

    
