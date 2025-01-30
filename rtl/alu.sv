
module alu
   #(parameter PRESCALE_P = 35
    )
    (input   [0:0]    clk_i
    ,input   [0:0] reset_ni
    ,input   [0:0]    rxd_i
    ,output  [0:0]    txd_o
    );

// UART-R interface
wire  [7:0] r_data_w;
wire  [0:0] r_valid_w;
logic [0:0] r_ready_r;
// UART-T interface
logic [7:0] t_data_r;
logic [0:0] t_valid_r;
wire  [0:0] t_ready_w;

uart_rx
   #(.DATA_WIDTH(8)
    )
uart_rx_inst
    (.clk(clk_i)
    ,.rst(~reset_ni)
    ,.m_axis_tdata(r_data_w)
    ,.m_axis_tvalid(r_valid_w)
    ,.m_axis_tready(r_ready_r)
    ,.rxd(rxd_i)
    ,.prescale(PRESCALE_P)
    );

uart_tx
   #(.DATA_WIDTH(8)
    )
uart_tx_inst
    (.clk(clk_i)
    ,.rst(~reset_ni)
    ,.s_axis_tdata(t_data_r)
    ,.s_axis_tvalid(t_valid_r)
    ,.s_axis_tready(t_ready_w)
    ,.txd(txd_o)
    ,.prescale(PRESCALE_P)
    );

// 32-bit integer multiplier interface
logic  [0:0] mul_valid_r;
wire   [0:0] mul_ready_w;
logic [31:0] mul_op_a_r;
logic [31:0] mul_op_b_r;
//logic  [0:0] mul_high_part_r;
wire   [0:0] mul_valid_w;
wire  [31:0] mul_result_w;
logic  [0:0] mul_ready_r;

bsg_imul_iterative
   #(.width_p(32)
    )
multiplier_inst
    (.clk_i(clk_i)
    ,.reset_i(~reset_ni)
    ,.v_i(mul_valid_r)
    ,.ready_and_o(mul_ready_w)
    ,.opA_i(mul_op_a_r)
    ,.signed_opA_i(1'b1)
    ,.opB_i(mul_op_b_r)
    ,.signed_opB_i(1'b1)
    ,.gets_high_part_i(1'b0)
    ,.v_o(mul_valid_w)
    ,.result_o(mul_result_w)
    ,.yumi_i(mul_ready_r)
    );

// 32-bit integer divider interface
logic  [0:0] div_valid_r;
wire   [0:0] div_ready_w;
logic [31:0] div_op_a_r;
logic [31:0] div_op_b_r;
wire   [0:0] div_valid_w;
wire  [31:0] div_result_quo_w;
wire  [31:0] div_result_rem_w;
logic  [0:0] div_ready_r;

bsg_idiv_iterative
   #(.width_p(32)
    )
divider_inst
    (.clk_i(clk_i)
    ,.reset_i(~reset_ni)
    ,.v_i(div_valid_r)
    ,.ready_and_o(div_ready_w)
    ,.dividend_i(div_op_a_r)
    ,.divisor_i(div_op_b_r)
    ,.signed_div_i(1'b0)
    ,.v_o(div_valid_w)
    ,.quotient_o(div_result_quo_w)
    ,.remainder_o(div_result_rem_w)
    ,.yumi_i(div_ready_r)
    );

// State machine
enum logic [4:0] {RECEIVE  = 5'b00001
                 ,ECHO     = 5'b00010
                 ,ADD      = 5'b00100
                 ,MULTIPLY = 5'b01000
                 ,DIVIDE   = 5'b10000
                 } state_q, state_d;
// Operation
logic [31:0] operation_q, operation_d;  // {len_msb, len_lsb, reserved, opcode}
logic [31:0] operand_a_q, operand_a_d; // Two operands for use
logic [31:0] operand_b_q, operand_b_d;
logic [15:0] frame_cnt_q, frame_cnt_d;
logic  [1:0] word_byte_q, word_byte_d;
logic  [0:0] wait_q, wait_d;
logic  [0:0] done_q, done_d;
logic  [0:0] flag_q, flag_d;
logic  [2:0] buffer_stt_q, buffer_stt_d;
logic  [2:0] buffer_end_q, buffer_end_d;
logic  [7:0] buffer_q [0:7];
logic  [7:0] buffer_d [0:7];

always_ff @(posedge clk_i) begin
    if (reset_ni) begin
        state_q          <= state_d;
        operation_q      <= operation_d;
        operand_a_q      <= operand_a_d;
        operand_b_q      <= operand_b_d;
        frame_cnt_q      <= frame_cnt_d;
        word_byte_q      <= word_byte_d;
        wait_q           <= wait_d;
        done_q           <= done_d;
        flag_q           <= flag_d;
        buffer_stt_q     <= buffer_stt_d;
        buffer_end_q     <= buffer_end_d;
        for (int i = 0; i < 8; i++) begin
            buffer_q[i]  <= buffer_d[i];
        end
    end else begin
        state_q          <= RECEIVE;
        operation_q      <= 32'h00000000;
        operand_a_q      <= 32'h00000000;
        operand_b_q      <= 32'h00000000;
        frame_cnt_q      <= 16'h0000;
        word_byte_q      <= 2'b00;
        wait_q           <= 1'b0;
        done_q           <= 1'b0;
        flag_q           <= 1'b0;
        buffer_stt_q     <= 3'b00;
        buffer_end_q     <= 3'b00;
        for (int i = 0; i < 8; i++) begin
            buffer_q[i]  <= 8'h00;
        end
    end
end

always_comb begin
    // Operation
    state_d          = state_q;
    operation_d      = operation_q;
    operand_a_d      = operand_a_q;
    operand_b_d      = operand_b_q;
    frame_cnt_d      = frame_cnt_q;
    word_byte_d      = word_byte_q;
    wait_d           = wait_q;
    done_d           = done_q;
    flag_d           = flag_q;
    buffer_stt_d     = buffer_stt_q;
    buffer_end_d     = buffer_end_q;
    for (int i = 0; i < 8; i++) begin
        buffer_d[i] = buffer_q[i];
    end
    // UART
    r_ready_r        = 1'b0;
    t_valid_r        = 1'b0;
    t_data_r         = 8'h00;
    // Multiplier
    mul_valid_r      = 1'b0;
    mul_op_a_r       = 32'h0000000;
    mul_op_b_r       = 32'h0000000;
    mul_ready_r      = 1'b0;
    // Divider
    div_valid_r      = 1'b0;
    div_op_a_r       = 32'h00000000;
    div_op_b_r       = 32'h00000000;
    div_ready_r      = 1'b0;
    // Buffer runs outside the FSM
    if (buffer_stt_q != buffer_end_q && t_ready_w) begin
        t_valid_r    = 1'b1;
        t_data_r     = buffer_q[buffer_stt_q];
        buffer_stt_d = buffer_stt_q + 1;
    end
    case (state_q)
        RECEIVE: begin
            r_ready_r = 1'b1;
            if (r_valid_w) begin
                // Receive all operation bytes one-by-one
                operation_d[word_byte_q*8+:8] = r_data_w;
                word_byte_d = word_byte_q + 1;
                if (word_byte_q == 2'b11) begin
                    frame_cnt_d = 16'h0004;
                    operand_a_d = 32'h00000000;
                    operand_b_d = 32'h00000000;
                    case (operation_q[7:0])
                        8'hEC: begin
                            state_d = ECHO;
                        end
                        8'hAD: begin
                            state_d = ADD;
                        end
                        8'hCA: begin
                            operand_a_d = 32'h00000001;
                            state_d     = MULTIPLY;
                        end
                        8'hDE: begin
                            state_d = DIVIDE;
                        end
                        default: begin
                            state_d = RECEIVE;
                        end
                    endcase
                end
            end
        end
        ECHO: begin
            r_ready_r = 1'b1;
            if (r_valid_w) begin
                frame_cnt_d  = frame_cnt_q + 1;
                buffer_end_d = buffer_end_q + 1;
                buffer_d[buffer_end_q] = r_data_w;
            end
            if (frame_cnt_q == operation_q[31:16]) begin
                state_d = RECEIVE;
            end
        end
        ADD: begin
            if (frame_cnt_q == operation_q[31:16]) begin
                r_ready_r = 1'b0;
                if (buffer_end_q + 1 != buffer_stt_q) begin
                    buffer_d[buffer_end_q] = operand_a_q[word_byte_q*8+:8];
                    buffer_end_d = buffer_end_q + 1;
                    word_byte_d  = word_byte_q + 1;
                    if (word_byte_q == 2'b11) begin
                        state_d  = RECEIVE;
                    end
                end
            end else if (r_valid_w) begin
                r_ready_r = 1'b1;
                operand_b_d[word_byte_q*8+:8] = r_data_w;
                word_byte_d = word_byte_q + 1;
                frame_cnt_d = frame_cnt_q + 1;
                if (word_byte_q == 2'b11) begin
                    operand_a_d = operand_a_q + {r_data_w, operand_b_q[23:0]};
                end
            end
        end
        MULTIPLY: begin
            r_ready_r = 1'b1;
            if (r_valid_w) begin
                operand_b_d[word_byte_q*8+:8] = r_data_w;
                frame_cnt_d = frame_cnt_q + 1;
                if (word_byte_q < 2'b11) begin
                    word_byte_d = word_byte_q + 1;
                end else begin
                    wait_d = 1'b1;
                end
            end
            if (word_byte_q == 2'b11 && wait_q) begin
                r_ready_r       = 1'b0;
                if (mul_ready_w) begin
                    mul_valid_r = 1'b1;
                    mul_op_a_r  = operand_a_q;
                    mul_op_b_r  = operand_b_q;
                end
                if (mul_valid_w) begin
                    mul_ready_r = 1'b1;
                    operand_a_d = mul_result_w;
                    wait_d      = 1'b0;
                    word_byte_d  = word_byte_q + 1;
                    if (frame_cnt_q == operation_q[31:16]) begin
                        done_d  = 1'b1;
                    end else begin
                        done_d  = 1'b0;
                    end
                end
            end
            if (frame_cnt_q == operation_q[31:16] && done_q) begin
                r_ready_r = 1'b0;
                if (buffer_end_q + 1 != buffer_stt_q) begin
                    buffer_d[buffer_end_q] = operand_a_q[word_byte_q*8+:8];
                    buffer_end_d = buffer_end_q + 1;
                    word_byte_d  = word_byte_q + 1;
                    if (word_byte_q == 2'b11) begin
                        wait_d   = 1'b0;
                        done_d   = 1'b0;
                        state_d  = RECEIVE;
                    end
                end
            end
        end
        DIVIDE: begin
            r_ready_r = 1'b1;
            if (r_valid_w) begin
                word_byte_d = word_byte_q + 1;
                if (flag_q) begin
                    operand_b_d[word_byte_q*8+:8] = r_data_w;
                    if (word_byte_q == 2'b11) begin
                        flag_d = 1'b0;
                        wait_d = 1'b1;
                    end
                end else begin
                    operand_a_d[word_byte_q*8+:8] = r_data_w;
                    if (word_byte_q == 2'b11) begin
                        flag_d = 1'b1;
                    end
                end
                frame_cnt_d = frame_cnt_q + 1;
            end
            if (wait_q) begin
                r_ready_r       = 1'b0;
                if (div_ready_w) begin
                    div_valid_r = 1'b1;
                    div_op_a_r  = operand_a_q;
                    div_op_b_r  = operand_b_q;
                end
                if (div_valid_w) begin
                    div_ready_r = 1'b1;
                    operand_a_d = div_result_quo_w;
                    operand_b_d = div_result_rem_w;
                    wait_d      = 1'b0;
                    done_d      = 1'b1;
                end
            end
            if (done_q) begin
                r_ready_r = 1'b0;
                if (buffer_end_q + 1 != buffer_stt_q) begin
                    buffer_end_d = buffer_end_q + 1;
                    if (flag_q) begin
                        buffer_d[buffer_end_q] = operand_b_q[word_byte_q*8+:8];
                    end else begin
                        buffer_d[buffer_end_q] = operand_a_q[word_byte_q*8+:8];
                    end
                    word_byte_d  = word_byte_q + 1;
                    if (word_byte_q == 2'b11) begin
                        flag_d   = ~flag_q;
                        if (flag_q) begin
                            done_d   = 1'b0;
                            state_d  = RECEIVE;
                        end
                    end
                end
            end
        end
        default: begin
        end
    endcase
end

endmodule

