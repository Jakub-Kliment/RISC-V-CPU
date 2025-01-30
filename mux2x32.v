module mux2x32 (
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    input  wire        sel_i,
    output reg  [31:0] o_o
);
    // Output logic
    always @(*) begin
        o_o = 32'b0;
        if (sel_i) begin
            o_o = b_i;
        end else begin
            o_o = a_i;
        end
    end
endmodule
