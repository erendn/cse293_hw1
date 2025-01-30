
module icebreaker
    (input  CLK
    ,input  BTN_N
    ,input  RX
    ,output TX
    );

localparam BAUD_RATE = 115200;
localparam PRESCALE = 25;
localparam CLK_FREQ = 8.0 * BAUD_RATE * PRESCALE;

wire clk_12 = CLK;
wire clk_o;

// icepll -i 12 -o 32.256
SB_PLL40_PAD
   #(.FEEDBACK_PATH("SIMPLE"),
     .DIVR(4'd0),
     .DIVF(7'd60),
     .DIVQ(3'd5),
     .FILTER_RANGE(3'd1)
    )
pll
    (.LOCK()
    ,.RESETB(1'b1)
    ,.BYPASS(1'b0)
    ,.PACKAGEPIN(clk_12)
    ,.PLLOUTCORE(clk_o)
    );

alu
   #(.PRESCALE_P(PRESCALE)
    )
alu_inst
    (.clk_i(clk_o)
    ,.reset_ni(BTN_N)
    ,.rxd_i(RX)
    ,.txd_o(TX)
    );

endmodule
