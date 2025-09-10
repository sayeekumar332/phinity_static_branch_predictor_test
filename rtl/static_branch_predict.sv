module static_branch_predict (
  
  // Instruction from fetch stage
  input  logic [31:0] fetch_rdata_i,
  input  logic [31:0] fetch_pc_i,
  input  logic [31:0] register_addr_i,
  input  logic        fetch_valid_i,

  // Prediction for supplied instruction
  output logic        predict_branch_taken_o,
  output logic [31:0] predict_branch_pc_o
);
  logic [31:0] reg_addr;
  logic [31:0] imm_jal_type;
  logic [31:0] imm_jalr_type;
  logic [31:0] imm_b_type;
  logic [31:0] imm_cj_type;
  logic [31:0] imm_cb_type;

  logic [31:0] branch_imm;

  logic [31:0] instr;

  logic instr_jal;
  logic instr_jalr;
  logic instr_b;
  logic instr_cj;
  logic instr_cb;

  logic instr_b_taken;
  
    
  localparam OPCODE_BRANCH = 7'h63;
  localparam OPCODE_JAL    = 7'h6F;
  localparam OPCODE_JALR   = 7'h67;
  

  // Provide short internal name for fetch_rdata_i due to reduce line wrapping
  assign instr = fetch_rdata_i;
  assign reg_addr = register_addr_i;

  // Extract and sign-extend to 32-bit the various immediates that may be used to calculate the target

  // Uncompressed immediates
  assign imm_jal_type = { {12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0 };
  assign imm_jalr_type = {{20{instr[31]}}, instr[31:20]}+reg_addr;
  assign imm_b_type = { {19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0 };

  // Compressed immediates
  assign imm_cj_type = { {20{instr[12]}}, instr[12], instr[8], instr[10:9], instr[6], instr[7],
    instr[2], instr[11], instr[5:3], 1'b0 };

  assign imm_cb_type = { {23{instr[12]}}, instr[12], instr[6:5], instr[2], instr[11:10],
    instr[4:3], 1'b0};

  // Determine if the instruction is a branch or a jump

  // Uncompressed branch/jump
  //assign instr_b    = instr[6:0] == OPCODE_BRANCH;
  assign instr_b    = instr[6:0] == 7'h64; // Error Number 1
  assign instr_jal  = instr[6:0] == OPCODE_JAL;
  assign instr_jalr = instr[6:0] == OPCODE_JALR;

  // Compressed branch/jump
  assign instr_cb = (instr[1:0] == 2'b01) & ((instr[15:13] == 3'b110) | (instr[15:13] == 3'b111));
  assign instr_cj = (instr[1:0] == 2'b01) & ((instr[15:13] == 3'b101) | (instr[15:13] == 3'b001));

  // Select out the branch offset for target calculation based upon the instruction type
  always@(*) begin
    branch_imm = imm_b_type;

    //unique case (1'b1) - unique case not supported by Icarus
    case(1'b1)
      instr_jal  : branch_imm = imm_jal_type;
      instr_jalr : branch_imm = imm_jalr_type;
      instr_b    : branch_imm = imm_b_type;
      instr_cj   : branch_imm = imm_cj_type;
      instr_cb   : branch_imm = imm_cb_type;
      default    : ;
    endcase
  end

 
  // Determine branch prediction, taken if offset is negative
  assign instr_b_taken = (instr_b & imm_b_type[31]) | (instr_cb & imm_cb_type[31]);

  // Always predict jumps taken otherwise take prediction from `instr_b_taken`
  assign predict_branch_taken_o = fetch_valid_i & (instr_jal | instr_jalr | instr_cj | instr_b_taken);
  // Calculate target
  //assign predict_branch_pc_o    = fetch_pc_i + branch_imm;
  assign predict_branch_pc_o    = fetch_pc_i - branch_imm; // Error Number 2
endmodule
