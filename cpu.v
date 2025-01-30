module cpu (
    input  wire        clk_i,
    input  wire        rst_ni,
    input  wire [31:0] rdata_i,
    input  wire        irq_i,
    output wire [31:0] addr_o,
    output wire [31:0] wdata_o,
    output wire        we_o
);

  ////////////////////
  // Internal Wires
  ////////////////////
  wire [31:0] instruction_w;
  wire        branch_op_w;
  wire [31:0] imm_w;
  wire        ir_en_w;
  wire        pc_add_imm_w;
  wire        cont_pc_en_w;
  wire        pc_sel_alu_w;
  wire        pc_sel_pc_base_w;
  wire        pc_sel_mtvec_w;
  wire        pc_sel_mepc_w;
  wire        rf_we_w;
  wire        sel_addr_w;
  wire        sel_b_w;
  wire        sel_mem_w;
  wire        sel_pc_w;
  wire        sel_imm_w;
  wire        sel_csr_w;
  wire [ 5:0] alu_op_w;
  wire [31:0] ra_w;
  wire [31:0] rb_w;
  wire [31:0] op_b_w;
  wire [31:0] alu_res_w;
  wire [31:0] next_pc_addr_w;
  wire        pc_en_w;
  wire [31:0] alu_mux_imm_w;
  wire [31:0] pc_mux_rdata_w;
  wire        sel_pc_or_mem_w;
  wire [31:0] alu_pc_res_w;
  wire [31:0] final_mux_w;

  // CSR related wires
  wire        csr_we_w;
  wire        csr_set_w;
  wire        csr_clear_w;
  wire        csr_interrupt_w;
  wire        csr_mret_w;
  wire [31:0] csr_rdata_w;
  wire [31:0] mtvec_w;
  wire [31:0] mepc_w;
  wire        ipending_w;

  ////////////////////////
  // Instruction Register
  ////////////////////////
  ir ir_inst (
      .clk_i   (clk_i),
      .enable_i(ir_en_w),
      .d_i     (rdata_i),
      .q_o     (instruction_w)
  );

  //////////////
  // Controller
  //////////////
  controller controller_inst (
      .clk_i           (clk_i),
      .rst_ni          (rst_ni),
      .instruction_i   (instruction_w),
      .ipending_i      (ipending_w),
      .branch_op_o     (branch_op_w),
      .imm_o           (imm_w),
      .ir_en_o         (ir_en_w),
      .pc_add_imm_o    (pc_add_imm_w),
      .pc_en_o         (cont_pc_en_w),
      .pc_sel_alu_o    (pc_sel_alu_w),
      .pc_sel_pc_base_o(pc_sel_pc_base_w),
      .pc_sel_mtvec_o  (pc_sel_mtvec_w),
      .pc_sel_mepc_o   (pc_sel_mepc_w),
      .rf_we_o         (rf_we_w),
      .sel_addr_o      (sel_addr_w),
      .sel_b_o         (sel_b_w),
      .sel_mem_o       (sel_mem_w),
      .sel_pc_o        (sel_pc_w),
      .sel_imm_o       (sel_imm_w),
      .sel_csr_o       (sel_csr_w),
      .we_o            (we_o),
      .alu_op_o        (alu_op_w),
      .csr_write_o     (csr_we_w),
      .csr_set_o       (csr_set_w),
      .csr_clear_o     (csr_clear_w),
      .csr_interrupt_o (csr_interrupt_w),
      .csr_mret_o      (csr_mret_w)
  );

  ///////////////////
  // Register File
  ///////////////////
  register_file rf_inst (
      .clk_i   (clk_i),
      .aa_i    (instruction_w[19:15]),
      .ab_i    (instruction_w[24:20]),
      .aw_i    (instruction_w[11:7]),
      .wren_i  (rf_we_w),
      .wrdata_i(final_mux_w),
      .a_o     (ra_w),
      .b_o     (rb_w)
  );

  /////////////////////////////////
  // Immediate vs Register B Mux
  /////////////////////////////////
  mux2x32 mux_inst_imm_rb (
      .a_i  (imm_w),
      .b_i  (rb_w),
      .sel_i(sel_b_w),
      .o_o  (op_b_w)
  );

  ///////
  // ALU
  ///////
  alu alu_inst (
      .a_i     (ra_w),
      .b_i     (op_b_w),
      .op_i    (alu_op_w),
      .result_o(alu_res_w)
  );

  /////////////////////
  // Program Counter
  /////////////////////
  assign pc_en_w = (branch_op_w && alu_res_w[0]) || cont_pc_en_w;
  pc pc_inst (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .en_i         (pc_en_w),
      .sel_alu_i    (pc_sel_alu_w),
      .sel_pc_base_i(pc_sel_pc_base_w),
      .sel_mtvec_i  (pc_sel_mtvec_w),
      .sel_mepc_i   (pc_sel_mepc_w),
      .add_imm_i    (pc_add_imm_w),
      .imm_i        (imm_w),
      .alu_i        (alu_res_w),
      .mtvec_i      (mtvec_w),
      .mepc_i       (mepc_w),
      .addr_o       (next_pc_addr_w)
  );

  /////////////////////////////
  // ALU Result vs Immediate Mux
  /////////////////////////////
  mux2x32 mux_inst_alu_imm (
      .a_i  (alu_res_w),
      .b_i  (imm_w),
      .sel_i(sel_imm_w),
      .o_o  (alu_mux_imm_w)
  );

  //////////////////////////////////
  // Next PC vs Memory Data Mux
  //////////////////////////////////
  mux2x32 mux_inst_mem_pc (
      .a_i  (next_pc_addr_w),
      .b_i  (rdata_i),
      .sel_i(sel_mem_w),
      .o_o  (pc_mux_rdata_w)
  );

  /////////////////////////////
  // Data Mux for ALU and PC
  /////////////////////////////
  assign sel_pc_or_mem_w = sel_pc_w || sel_mem_w;
  mux2x32 mux_inst_alu_pc (
      .a_i  (alu_mux_imm_w),
      .b_i  (pc_mux_rdata_w),
      .sel_i(sel_pc_or_mem_w),
      .o_o  (alu_pc_res_w)
  );

  ///////////////////////////////////////
  // Writeback Final Mux CSR and ALU/PC
  ///////////////////////////////////////
  mux2x32 mux_inst_final (
      .a_i  (alu_pc_res_w),
      .b_i  (csr_rdata_w),
      .sel_i(sel_csr_w),
      .o_o  (final_mux_w)
  );

  ///////////////////////////
  // Memory Address Mux
  ///////////////////////////
  mux2x32 mux_inst_mem_addr (
      .a_i  (next_pc_addr_w),
      .b_i  (alu_res_w),
      .sel_i(sel_addr_w),
      .o_o  (addr_o)
  );

  ///////////////////////////
  // Imm/CSR Mux
  ///////////////////////////
  wire [31:0] imm_csr_w;
  mux2x32 mux_inst_imm_csr (
      .a_i  (ra_w),
      .b_i  (imm_w),
      .sel_i(sel_imm_w),
      .o_o  (imm_csr_w)
  );

  ///////////////////////////
  // CSR Module
  ///////////////////////////
  csr csr_inst (
      .clk_i      (clk_i),
      .rst_ni     (rst_ni),
      .addr_i     (instruction_w[31:20]),
      .wdata_i    (imm_csr_w),
      .irq_i      (irq_i),
      .pc_i       (next_pc_addr_w),
      .write_i    (csr_we_w),
      .set_i      (csr_set_w),
      .clear_i    (csr_clear_w),
      .interrupt_i(csr_interrupt_w),
      .mret_i     (csr_mret_w),
      .rdata_o    (csr_rdata_w),
      .mtvec_o    (mtvec_w),
      .mepc_o     (mepc_w),
      .ipending_o (ipending_w)
  );

  ///////////////////////////
  // Output
  ///////////////////////////
  assign wdata_o = rb_w;

endmodule
