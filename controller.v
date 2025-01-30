module controller (
    input wire clk_i,
    input wire rst_ni,

    // Current instruction
    input wire [31:0] instruction_i,

    // Pending interrupt
    input wire ipending_i,

    // Branch operation
    output reg branch_op_o,

    // Immediate value correctly extended
    output reg [31:0] imm_o,

    // Instruction Register control signals
    output reg ir_en_o,

    // PC control signals
    output reg pc_add_imm_o,
    output reg pc_en_o,
    output reg pc_sel_alu_o,
    output reg pc_sel_pc_base_o,

    output reg pc_sel_mtvec_o,
    output reg pc_sel_mepc_o,

    // Register file control signals
    output reg rf_we_o,

    // Multiplexer control signals
    output reg sel_addr_o,
    output reg sel_b_o,
    output reg sel_mem_o,
    output reg sel_pc_o,
    output reg sel_imm_o,

    output reg sel_csr_o,

    // Memory control signals
    output reg we_o,

    // CSR signals
    output reg csr_write_o,
    output reg csr_set_o,
    output reg csr_clear_o,
    output reg csr_interrupt_o,
    output reg csr_mret_o,

    // ALU control signals
    output reg [5:0] alu_op_o
);
    // Internal nets
    reg [3:0]   current_state_r;
    reg [3:0]   next_state_r;

    reg  [1:0]  bits_5_and_4_alu_op_r;
    reg         special_bit_alu_op_r;
    reg  [2:0]  last_3_bits_alu_op_r;

    wire [ 2:0] func3_w;
    wire [ 6:0] func7_w;
    wire [11:0] imm_w;
    wire [ 6:0] op_code_w;

    assign func3_w   = instruction_i[14:12];
    assign func7_w   = instruction_i[31:25];
    assign imm_w     = instruction_i[31:20];
    assign op_code_w = instruction_i[ 6: 0];

    // State identifiers
    localparam FETCH_1            = 4'b0000;
    localparam FETCH_2            = 4'B0001;
    localparam DECODE             = 4'b0010;
    localparam U_TYPE_S           = 4'b0011;
    localparam R_TYPE_S           = 4'b0100;
    localparam S_TYPE_S           = 4'b0101;
    localparam I_TYPE_S           = 4'b0110;
    localparam BREAK_S            = 4'b0111;
    localparam B_TYPE_S           = 4'b1000;
    localparam J_TYPE_S           = 4'b1001;
    localparam JALR_S             = 4'b1010;
    localparam LOAD_1             = 4'b1011;
    localparam LOAD_2             = 4'b1100;
    localparam CSR_S              = 4'b1101;
    localparam INTERRUPT_RETURN_S = 4'b1110;

    // Opcodes
    localparam R_TYPE_OP = 7'b0110011;
    localparam I_TYPE_OP = 7'b0010011;
    localparam U_TYPE_OP = 7'b0110111;
    localparam S_TYPE_OP = 7'b0100011;
    localparam LOAD_OP   = 7'b0000011;
    localparam SYSTEM_OP = 7'b1110011;
    localparam B_TYPE_OP = 7'b1100011;
    localparam J_TYPE_OP = 7'b1101111;
    localparam JALR_OP   = 7'b1100111;

    // Next state logic
    always @(*) begin
        next_state_r = FETCH_1;
        case (current_state_r)
            FETCH_1: next_state_r = FETCH_2;
            FETCH_2: begin
                if (ipending_i) begin
                    next_state_r = FETCH_1;
                end else begin
                    next_state_r = DECODE;
                end
            end
            DECODE: begin
                case (op_code_w)
                    I_TYPE_OP: next_state_r = I_TYPE_S;
                    R_TYPE_OP: next_state_r = R_TYPE_S;
                    U_TYPE_OP: next_state_r = U_TYPE_S;
                    S_TYPE_OP: next_state_r = S_TYPE_S;
                    LOAD_OP:   next_state_r = LOAD_1;
                    SYSTEM_OP:  begin
                        if (imm_w == 1 && func3_w == 3'b0) begin
                            next_state_r = BREAK_S;
                        end else if (imm_w == 12'h302 && func3_w == 3'b0) begin
                            next_state_r = INTERRUPT_RETURN_S;
                        end else begin
                            next_state_r = CSR_S;
                        end
                    end
                    B_TYPE_OP: next_state_r = B_TYPE_S;
                    J_TYPE_OP: next_state_r = J_TYPE_S;
                    JALR_OP:   next_state_r = JALR_S;
                    default:   next_state_r = FETCH_1;
                endcase
            end
            I_TYPE_S: next_state_r = FETCH_2;
            R_TYPE_S: next_state_r = FETCH_2;
            U_TYPE_S: next_state_r = FETCH_2;
            LOAD_1:   next_state_r = LOAD_2;
            LOAD_2:   next_state_r = FETCH_1;
            S_TYPE_S: next_state_r = FETCH_1;
            BREAK_S:  next_state_r = BREAK_S;
            B_TYPE_S: next_state_r = FETCH_1;
            J_TYPE_S: next_state_r = FETCH_1;
            JALR_S:   next_state_r = FETCH_1;
            CSR_S:    next_state_r = FETCH_2;
            INTERRUPT_RETURN_S: next_state_r = FETCH_1;
            default:  next_state_r = FETCH_1;
        endcase
    end

    // State memory
    always @(posedge clk_i) begin
        if (!rst_ni) begin
            current_state_r <= FETCH_1;
        end else begin
            current_state_r <= next_state_r;
        end
    end

    // Output logic
    always @(*) begin
        imm_o            = 32'b0;
        branch_op_o      = 1'b0;
        ir_en_o          = 1'b0;
        pc_add_imm_o     = 1'b0;
        pc_en_o          = 1'b0;
        pc_sel_alu_o     = 1'b0;
        pc_sel_pc_base_o = 1'b0;
        rf_we_o          = 1'b0;
        sel_addr_o       = 1'b0;
        sel_b_o          = 1'b0;
        sel_mem_o        = 1'b0;
        sel_pc_o         = 1'b0;
        sel_imm_o        = 1'b0;
        we_o             = 1'b0;

        sel_csr_o        = 1'b0;
        pc_sel_mepc_o    = 1'b0;
        pc_sel_mtvec_o   = 1'b0;
        csr_write_o      = 1'b0;
        csr_set_o        = 1'b0;
        csr_clear_o      = 1'b0;
        csr_interrupt_o  = 1'b0;
        csr_mret_o       = 1'b0;

        case (current_state_r)
            FETCH_1: begin
                we_o = 1'b0;
            end
            FETCH_2: begin
                pc_en_o = 1'b1;
                if (ipending_i) begin
                    csr_interrupt_o = 1'b1;
                    pc_sel_mtvec_o  = 1'b1;
                end else begin
                    ir_en_o = 1'b1;
                end
            end
            I_TYPE_S: begin
                imm_o   = { {20{imm_w[11]}}, imm_w };
                rf_we_o = 1'b1;
            end
            R_TYPE_S: begin
                rf_we_o = 1'b1;
                sel_b_o = 1'b1;
            end
            U_TYPE_S: begin
                imm_o     = instruction_i[31:12] << 12;
                rf_we_o   = 1'b1;
                sel_imm_o = 1'b1;
            end
            LOAD_1: begin
                imm_o = { {20{imm_w[11]}}, imm_w };
                sel_addr_o = 1'b1;
                we_o       = 1'b0;
            end
            LOAD_2: begin
                imm_o = { {20{imm_w[11]}}, imm_w };
                sel_addr_o = 1'b1;
                sel_mem_o  = 1'b1;
                rf_we_o    = 1'b1;
            end
            S_TYPE_S: begin
                imm_o = $signed({
                    {20{instruction_i[31]}},
                    instruction_i[31:25],
                    instruction_i[11: 7]
                });
                we_o       = 1'b1;
                sel_addr_o = 1'b1;
            end
            B_TYPE_S: begin
                imm_o = $signed({
                    {19{instruction_i[31]}},
                    instruction_i[31],
                    instruction_i[7],
                    instruction_i[30:25],
                    instruction_i[11:8],
                    1'b0
                });
                sel_b_o          = 1'b1;
                branch_op_o      = 1'b1;
                pc_add_imm_o     = 1'b1;
                pc_sel_pc_base_o = 1'b1;
            end
            J_TYPE_S: begin
                imm_o = $signed({
                    {11{instruction_i[31]}},
                    instruction_i[31],
                    instruction_i[19:12],
                    instruction_i[20],
                    instruction_i[30:21],
                    1'b0
                });
                rf_we_o          = 1'b1;
                sel_pc_o         = 1'b1;
                pc_en_o          = 1'b1;
                pc_add_imm_o     = 1'b1;
                pc_sel_pc_base_o = 1'b1;
            end
            JALR_S: begin
                imm_o = { {20{imm_w[11]}}, imm_w };
                pc_en_o      = 1'b1;
                pc_sel_alu_o = 1'b1;
                sel_pc_o     = 1'b1;
                rf_we_o      = 1'b1;
            end
            CSR_S: begin
                sel_csr_o = 1'b1;
                rf_we_o   = 1'b1;
                case (func3_w)
                    3'b001, 3'b101: csr_write_o = 1'b1;
                    3'b010, 3'b110: csr_set_o   = 1'b1;
                    3'b011, 3'b111: csr_clear_o = 1'b1;
                    default: begin
                    end
                endcase
                if (func3_w[2]) begin
                    sel_imm_o = 1'b1;
                    imm_o     = { 27'b0, instruction_i[19:15] };
                end else begin
                    sel_imm_o = 1'b0;
                    imm_o     = 32'b0;
                end
            end
            INTERRUPT_RETURN_S: begin
                csr_mret_o    = 1'b1;
                pc_sel_mepc_o = 1'b1;
                pc_en_o       = 1'b1;
            end
            default: begin
                imm_o            = 32'b0;
                branch_op_o      = 1'b0;
                ir_en_o          = 1'b0;
                pc_add_imm_o     = 1'b0;
                pc_en_o          = 1'b0;
                pc_sel_alu_o     = 1'b0;
                pc_sel_pc_base_o = 1'b0;
                rf_we_o          = 1'b0;
                sel_addr_o       = 1'b0;
                sel_b_o          = 1'b0;
                sel_mem_o        = 1'b0;
                sel_pc_o         = 1'b0;
                sel_imm_o        = 1'b0;
                we_o             = 1'b0;
                sel_csr_o        = 1'b0;
                pc_sel_mepc_o    = 1'b0;
                pc_sel_mtvec_o   = 1'b0;
                csr_write_o      = 1'b0;
                csr_set_o        = 1'b0;
                csr_clear_o      = 1'b0;
                csr_interrupt_o  = 1'b0;
                csr_mret_o       = 1'b0;
            end
        endcase
    end

    // ALU operations
    always @(*) begin
        bits_5_and_4_alu_op_r = 2'b0;
        special_bit_alu_op_r  = 1'b0;
        last_3_bits_alu_op_r  = 3'b0;
        case (op_code_w)
            R_TYPE_OP, I_TYPE_OP: begin
                case (func3_w)
                    3'b000:                 bits_5_and_4_alu_op_r = 2'b00;
                    3'b010, 3'b011:         bits_5_and_4_alu_op_r = 2'b01;
                    3'b100, 3'b110, 3'b111: bits_5_and_4_alu_op_r = 2'b10;
                    3'b001, 3'b101:         bits_5_and_4_alu_op_r = 2'b11;
                    default:                bits_5_and_4_alu_op_r = 2'b00;
                endcase
                if (func3_w == 3'b010 || func3_w == 3'b011) begin
                    last_3_bits_alu_op_r = func3_w << 1;
                end else begin
                    last_3_bits_alu_op_r = func3_w;
                end
                if (op_code_w == I_TYPE_OP && func3_w == 0) begin
                    special_bit_alu_op_r = 1'b0;
                end else if (func7_w == 7'h20) begin
                    special_bit_alu_op_r = 1'b1;
                end else if (bits_5_and_4_alu_op_r == 2'b01) begin
                    special_bit_alu_op_r = 1'b1;
                end else begin
                    special_bit_alu_op_r = 1'b0;
                end
            end
            B_TYPE_OP: begin
                bits_5_and_4_alu_op_r = 2'b01;
                special_bit_alu_op_r  = 1'b1;
                last_3_bits_alu_op_r  = func3_w;
            end
            default: begin
                bits_5_and_4_alu_op_r = 2'b00;
                special_bit_alu_op_r  = 1'b0;
                last_3_bits_alu_op_r  = 3'b000;
            end
        endcase
        alu_op_o = {
            bits_5_and_4_alu_op_r,
            special_bit_alu_op_r,
            last_3_bits_alu_op_r
        };
    end
endmodule
