
module alu
   #(parameter DATA_WIDTH_P = 8
    ,parameter PRESCALE_P = 35
    )
    (input   [0:0]    clk_i
    ,input   [0:0] reset_ni
    ,input   [0:0]    rxd_i
    ,output  [0:0]    txd_o
    );

wire [DATA_WIDTH_P-1:0] data_w;
wire [0:0] valid_w;
wire [0:0] ready_w;

uart_rx
   #(.DATA_WIDTH(DATA_WIDTH_P)
    )
uart_rx_inst
    (.clk(clk_i)
    ,.rst(~reset_ni)
    ,.m_axis_tdata(data_w)
    ,.m_axis_tvalid(valid_w)
    ,.m_axis_tready(ready_w)
    ,.rxd(rxd_i)
    ,.prescale(PRESCALE_P)
    );

uart_tx
   #(.DATA_WIDTH(DATA_WIDTH_P)
    )
uart_tx_inst
    (.clk(clk_i)
    ,.rst(~reset_ni)
    ,.s_axis_tdata(data_w)
    ,.s_axis_tvalid(valid_w)
    ,.s_axis_tready(ready_w)
    ,.txd(txd_o)
    ,.prescale(PRESCALE_P)
    );

endmodule
