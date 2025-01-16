
module top
    (input  CLK
    ,input  BTN_N
    ,input  RX
    ,output TX
    );

    alu
       #(.DATA_WIDTH_P(8)
        )
    alu_inst
        (.clk_i(CLK)
        ,.reset_ni(BTN_N)
        ,.rxd_i(RX)
        ,.txd_o(TX)
        );

endmodule
