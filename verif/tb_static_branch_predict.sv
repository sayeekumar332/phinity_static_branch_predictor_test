module tb_static_branch_predict;

  // Parameters and signals for testing
  logic [31:0] fetch_rdata_i;
  logic [31:0] fetch_pc_i;
  logic [31:0] register_addr_i;
  logic fetch_valid_i;
  logic predict_branch_taken_o;
  logic [31:0] predict_branch_pc_o;

  // Instantiate the Device Under Test (DUT)
  static_branch_predict dut (
    .fetch_rdata_i(fetch_rdata_i),
    .fetch_pc_i(fetch_pc_i),
    .register_addr_i(register_addr_i),
    .fetch_valid_i(fetch_valid_i),
    .predict_branch_taken_o(predict_branch_taken_o),
    .predict_branch_pc_o(predict_branch_pc_o)
  );

  // Task to run a test case
  task run_test_case(
    input logic [31:0] test_instr,          // Test instruction input
    input logic [31:0] test_pc,             // Test program counter input
    input logic [31:0] test_register_operand,// Test register containing address
    input logic test_valid,                 // Test validity flag
    input logic expected_taken,             // Expected branch taken output
    input logic [31:0] expected_pc,         // Expected branch target output
    input string case_name                  // Name of the test case
  );
    begin
      // Apply inputs
      fetch_rdata_i = test_instr;
      fetch_pc_i = test_pc;
      fetch_valid_i = test_valid;
      register_addr_i = test_register_operand;
      #10;  // Wait for the outputs to stabilize

      // Print actual results for debugging
      $display("Running test case: %s", case_name);
      $display("%s - fetch_rdata_i = %0h, fetch_pc_i = %0h, Valid = %b", case_name, test_instr, test_pc, test_valid);
      $display("%s - Expected taken = %b, Actual taken = %b ", case_name, expected_taken, predict_branch_taken_o);
      $display("%s - Expected PC = %0h, Actual PC = %0h", case_name, expected_pc, predict_branch_pc_o);
      
      // Check predict_branch_taken_o and display values
      if (predict_branch_taken_o !== expected_taken) begin
        $error("%s - Test failed: (predict_branch_taken_o mismatch: expected = %0b, actual = %0b)", 
                case_name, expected_taken, predict_branch_taken_o);
      end else begin
        $display("%s - Test passed: (predict_branch_taken_o is correct: %0b)", case_name, predict_branch_taken_o);
      end
      
      // Check predict_branch_pc_o and display values
      if (predict_branch_pc_o !== expected_pc) begin
        $error("%s - Test failed: (predict_branch_pc_o mismatch: expected = %0h, actual = %0h)", 
                case_name, expected_pc, predict_branch_pc_o);
      end else begin
        $display("%s - Test passed: (predict_branch_pc_o is correct: %0h)", case_name, predict_branch_pc_o);
      end
    end
  endtask

  // Enable waveform dump
  initial begin
    $dumpfile("static_branch_predict.vcd");  // VCD file name
    $dumpvars(0, tb_static_branch_predict);  // Dump all variables in this module
  end

  // Testbench procedure
  initial begin
    $display("Starting testbench for Static Branch Predictor...");

    // Test Cases
    // 1. Uncompressed Control Transfer
    // Branch taken case with opcode for branch (7'h63) and negative offset (B-type)
    run_test_case(32'h8C218363, 32'h00001000, 32'h00000000,1'b1, 1'b1, 32'h000000C6, "Branch taken, PC offset negative (B-type),[BEQ]");// Test for BEQ instruction with negative offset

    run_test_case(32'h6C2183E3, 32'h00001000, 32'h00000000,1'b1, 1'b0, 32'h00001EC6, "Branch taken, PC offset positive (B-type)[BEQ]");// Test for BEQ instruction with positive offset
    
    // Jump taken case with opcode for jump (7'h6f)
    run_test_case(32'h926CF16F, 32'h00001000, 32'h00000000,1'b1, 1'b1, 32'hFFFD0126, "Jump taken (J-type) with negative offset[JAL]"); // Test for JAL instruction with negative offset
    
    run_test_case(32'h126CF16F, 32'h00001000, 32'h00000000,1'b1, 1'b1, 32'h000D0126, "Jump taken (J-type) with positive offset[JAL]"); // Test for JAL instruction with positive offset
    
    
    // Jump taken case with opcode for jump (7'h67)
    run_test_case(32'hF63101E7, 32'h00001000, 32'h00000000,1'b1, 1'b1, 32'h00000F63, "Jump taken (J-type) with negative offset[JALR]"); // Test for JAL instruction with negative offset
    
    run_test_case(32'h763101E7, 32'h00001000, 32'h00000000,1'b1, 1'b1, 32'h00001763, "Jump taken (J-type) with positive offset[JALR]"); // Test for JALR instruction with positive offset
    
    // 2. Compressed Control Transfer
    run_test_case(32'h4840006F, 32'h00001000, 32'h00000000,1'b1, 1'b1, 32'h00001484, "Compressed Jump taken (J-type) with positive offset[C.J]"); // Test for C.J instruction with positive offset
    
    run_test_case(32'h484000EF, 32'h00001000, 32'h00000000,1'b1, 1'b1, 32'h00001484, "Compressed Jump taken (J-type) with positive offset[C.JAL]"); // Test for C.JAL instruction with positive offset
    
    run_test_case(32'h08040A63, 32'h00001000, 32'h00000000,1'b1, 1'b0, 32'h00001094, "Compressed Branch Taken , PC offset positive(B-type)[C.BEQZ]"); // Test for C.BEQZ instruction with positive offset
    
    // Invalid fetch case
    run_test_case(32'h00000001, 32'h00002000, 32'h00000000 , 1'b0, 1'b0, 32'h00002000, "Invalid fetch (not valid)");
    
    // No branch or jump case
    run_test_case(32'h00000000, 32'h00002000, 32'h00000000, 1'b1, 1'b0, 32'h00002000, "No branch or jump");

    // Failure Test Case
    run_test_case(32'hfe000e63, 32'h00001000, 32'h00000000, 1'b1, 1'b1, 32'h000007FC, "Branch taken, PC offset negative (B-type)[BEQ]"); // Test case for improper instruction encoding for BEQ 
                                                                                                                                        // instruction with negative offset

    #100;  // Ensure simulation runs for enough time
    $finish;
  end

endmodule


 
