module logic_unit (
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    input  wire [ 2:0] op_i,
    output reg [31:0] r_o
);
    // Assign outputs
    assign r_o = (op_i == 3'b100) ? (a_i ^ b_i) :
                 (op_i == 3'b110) ? (a_i | b_i) :
                 (op_i == 3'b111) ? (a_i & b_i) :
                 32'b0;
endmodule
