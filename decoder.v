module decoder (
    input  wire [31:0] addr_i,
    output wire        en_ram_o,
    output wire        en_leds_o,
    output wire        en_7_seg_lcd_o,
    output wire        en_buttons_o
);
    // Local parameters for start and end of MMIOs
    localparam LEDS_START      = 32'h50000000;
    localparam LEDS_END        = 32'h50000fff;
    localparam SEVEN_SEG_START = 32'h60000000;
    localparam SEVEN_SEG_END   = 32'h60000fff;
    localparam BUTTONS_START   = 32'h70000000;
    localparam BUTTONS_END     = 32'h70000fff;
    localparam RAM_START       = 32'h80000000;
    localparam RAM_END         = 32'h9fffffff;

    // Assign outputs
    assign en_ram_o       = (addr_i >= RAM_START       && addr_i <= RAM_END)       ? 1'b1 : 1'b0;
    assign en_leds_o      = (addr_i >= LEDS_START      && addr_i <= LEDS_END)      ? 1'b1 : 1'b0;
    assign en_7_seg_lcd_o = (addr_i >= SEVEN_SEG_START && addr_i <= SEVEN_SEG_END) ? 1'b1 : 1'b0;
    assign en_buttons_o   = (addr_i >= BUTTONS_START   && addr_i <= BUTTONS_END)   ? 1'b1 : 1'b0;
endmodule
