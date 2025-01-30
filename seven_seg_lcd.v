module seven_seg_lcd (
    input  wire        clk_i,
    input  wire        rst_ni,
    input  wire        en_i,
    input  wire        we_i,
    input  wire [31:0] waddr_i,
    input  wire [31:0] wdata_i,
    output wire [31:0] disp_o
);
    // Internal wires
    reg [31:0] lcd_content_r;

    // Parameters
    localparam BASE_ADDR = 32'h60000000;

    always @(posedge clk_i) begin
        if (!rst_ni) begin
            lcd_content_r <= 32'h0;
        end else if (en_i && we_i && waddr_i == BASE_ADDR) begin
            lcd_content_r <= wdata_i;
        end
    end

    // Assign output
    assign disp_o = lcd_content_r;
endmodule
