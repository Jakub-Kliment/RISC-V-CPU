module add_sub (
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    input  wire        sub_i,
    output reg         carry_o,
    output reg         zero_o,
    output reg  [31:0] r_o
);
    // Declaration of internal net
    wire [31:0] b_xor_w = b_i ^ {32{sub_i}};

    // Assign output values
    assign {carry_o, r_o} = {1'b0, a_i} + {1'b0, b_xor_w} + {32'b0, sub_i};
    assign zero_o = (r_o == 32'b0);

endmodule
