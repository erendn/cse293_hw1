
module alu_runner;

reg  CLK;
reg  BTN_N = 0;
reg  RX;
wire TX;

// Test variables
integer data_len;

initial begin
    CLK = 0;
    forever begin
        #41.666ns; // 12MHz
        CLK = !CLK;
    end
end

logic pll_out;
initial begin
    pll_out = 0;
    forever begin
        #21.701ns; // 23.04MHz
        pll_out = !pll_out;
    end
end
assign icebreaker.pll.PLLOUTGLOBAL = pll_out;

icebreaker
icebreaker
    (.CLK(CLK)
    ,.BTN_N(BTN_N)
    ,.RX(RX)
    ,.TX(TX)
    );

task automatic reset;
    BTN_N = 0;
    @(posedge pll_out);
    @(posedge pll_out);
    BTN_N = 1;
endtask

task automatic wait_half_prescale;
    repeat (138) begin
        @(posedge pll_out);
    end
endtask

task automatic wait_prescale;
    repeat (279) begin
        @(posedge pll_out);
    end
endtask

task automatic send_frame(input [7:0] data);
    RX = 1'b0;
    wait_half_prescale();
    wait_prescale();
    repeat (8) begin
        RX = data[0];
        data = data >> 1;
        wait_prescale();
    end
    RX = 1'b1;
    wait_half_prescale();
endtask

task automatic echo;
    // Opcode
    send_frame(8'hEC);
    // Reserved
    send_frame(8'h00);
    // Data length
    data_len = $urandom_range(2, 10);
    send_frame(data_len + 4);
    send_frame(8'h00);
    // Frames
    repeat (data_len) begin
        send_frame($urandom()[7:0]);
    end
endtask

task automatic add;
    // Opcode
    send_frame(8'hAD);
    // Reserved
    send_frame(8'h00);
    // Data length
    data_len = $urandom_range(2, 10);
    send_frame(data_len * 4 + 4);
    send_frame(8'h00);
    // Frames
    repeat (data_len) begin
        send_frame($urandom()[7:0]);
        send_frame($urandom()[7:0]);
        send_frame($urandom()[7:0]);
        send_frame(8'h00);
    end
endtask

task automatic multiply;
    // Opcode
    send_frame(8'hCA);
    // Reserved
    send_frame(8'h00);
    // Data length
    data_len = $urandom_range(2, 5);
    send_frame(data_len * 4 + 4);
    send_frame(8'h00);
    // Frames
    repeat (data_len) begin
        send_frame($urandom()[7:0]);
        send_frame($urandom()[7:0]);
        send_frame(8'h00);
        send_frame(8'h00);
    end
endtask

task automatic divide;
    // Opcode
    send_frame(8'hDE);
    // Reserved
    send_frame(8'h00);
    // Data length
    send_frame(8'h0C);
    send_frame(8'h00);
    // Dividend
    send_frame($urandom()[7:0]);
    send_frame($urandom()[7:0]);
    send_frame($urandom()[7:0]);
    send_frame($urandom()[7:0]);
    // Divisor
    send_frame($urandom()[7:0]);
    send_frame($urandom()[7:0]);
    send_frame($urandom()[7:0]);
    send_frame(8'h00);
endtask

endmodule

