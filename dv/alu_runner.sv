
module alu_runner;

logic [0:0] clk_i;
logic [0:0] reset_ni;
logic [0:0] rxd;
wire  [0:0] txd;

// Test variables
integer data_len;

localparam realtime ClockPeriod = 5ms;

initial begin
    clk_i = 0;
    forever begin
        #(ClockPeriod / 2);
        clk_i = ~clk_i;
    end
end

alu
alu_inst
    (.clk_i(clk_i)
    ,.reset_ni(reset_ni)
    ,.rxd_i(rxd)
    ,.txd_o(txd)
    );

task automatic reset;
    reset_ni = 0;
    @(posedge clk_i);
    @(posedge clk_i);
    reset_ni = 1;
endtask

task automatic wait_half_prescale;
    repeat (138) begin
        @(posedge clk_i);
    end
endtask

task automatic wait_prescale;
    repeat (279) begin
        @(posedge clk_i);
    end
endtask

task automatic send_frame(input [7:0] data);
    rxd = 1'b0;
    wait_half_prescale();
    wait_prescale();
    repeat (8) begin
        rxd = data[0];
        data = data >> 1;
        wait_prescale();
    end
    rxd = 1'b1;
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

