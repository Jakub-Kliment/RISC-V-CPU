module pc (
    input  wire        clk_i,
    input  wire        rst_ni,
    input  wire        en_i,
    input  wire        sel_alu_i,
    input  wire        sel_pc_base_i,
    input  wire        sel_mtvec_i,
    input  wire        sel_mepc_i,
    input  wire        add_imm_i,
    input  wire [31:0] imm_i,
    input  wire [31:0] alu_i,
    input  wire [31:0] mtvec_i,
    input  wire [31:0] mepc_i,
    output wire [31:0] addr_o
);
    // Internal nets
    reg [31:0] current_address_r;
    reg [31:0] next_address_r;

    // Local parameters
    localparam RESET_VALUE        = 32'h80000000;
    localparam MASK_LAST_TWO_BITS = 32'hfffffffc;

    // Next address logic
    always @(*) begin
        next_address_r = current_address_r;
        if (add_imm_i) begin
            next_address_r = current_address_r + imm_i;
        end else begin
            next_address_r = current_address_r + 4;
        end
    end

    // Address memory block
    always @(posedge clk_i) begin
        if (!rst_ni) begin
            current_address_r <= RESET_VALUE;
        end else if (en_i) begin
            if (sel_pc_base_i) begin
                current_address_r <= next_address_r - 4;
            end else if (sel_alu_i) begin
                current_address_r <= (alu_i & MASK_LAST_TWO_BITS);
            end else if (sel_mtvec_i) begin
                current_address_r <= (mtvec_i & MASK_LAST_TWO_BITS);
            end else if (sel_mepc_i) begin
                current_address_r <= mepc_i;
            end else begin
                current_address_r <= next_address_r;
            end
        end
    end

    // Assign output
    assign addr_o = current_address_r;
endmodule
