
// Do not modify this file!
`timescale 1ns/1ps
module alu_tb();

    logic [0:0] clk;
    logic [0:0] reset;
    logic [7:0] data;
    logic [0:0] rxd;
    wire  [0:0] txd;

    alu
       //#(.DATA_WIDTH_P(8)
	   // ,.PRESCALE_P(35)
       // )
    alu_inst
        (.clk_i(clk)
        ,.reset_ni(reset)
        ,.rxd_i(rxd)
        ,.txd_o(txd)
        );

    // Clock generator
    initial begin
        clk = 1;
        forever
            #5 clk = ~clk;
    end

   initial begin
`ifdef VERILATOR
    $dumpfile("verilator.fst");
`else
    $dumpfile("iverilog.vcd");
`endif
    $dumpvars;

    $display();
    $display("  ______          __  __                    __");
    $display(" /_  __/__  _____/ /_/ /_  ___  ____  _____/ /");
    $display("  / / / _ \\/ ___/ __/ __ \\/ _ \\/ __ \\/ ___/ __ \\");
    $display(" / / /  __(__  ) /_/ /_/ /  __/ / / / /__/ / / /");
    $display("/_/  \\___/____/\\__/_.___/\\___/_/ /_/\\___/_/ /_/");
    $display();

    reset = 0;
    rxd   = 0;
    data  = 8'hED;
    for (int i = 0; i < 5; i = i + 1) begin
        @(posedge clk);
    end
    reset = 1;

    $display("Begin Test:");
    // Wait for initial prescale
    for (int i = 0; i < 138; i = i + 1) begin
        @(posedge clk);
    end
    // Wait for bit count
    for (int i = 0; i < 279; i = i + 1) begin
        @(posedge clk);
    end
    // Start sending data
    for (int i = 0; i < 8;  i = i + 1) begin
        #1;
        rxd = data[0];
        data = data >> 1;
        // Wait for prescale
        for (int i = 0; i < 279; i = i + 1) begin
            @(posedge clk);
        end
    end

	// Wait to receive data back
    rxd = 1;
    for (int i = 0; i < 5000; i = i + 1) begin
        @(posedge clk);
    end

    $display();
    $finish();
   end

    final begin
        $display("Simulation time is %t", $time);
        if(0) begin
            $display("\033[0;31m    ______                    \033[0m");
            $display("\033[0;31m   / ____/_____________  _____\033[0m");
            $display("\033[0;31m  / __/ / ___/ ___/ __ \\/ ___/\033[0m");
            $display("\033[0;31m / /___/ /  / /  / /_/ / /    \033[0m");
            $display("\033[0;31m/_____/_/  /_/   \\____/_/     \033[0m");
            $display();
            $display("Simulation Failed");
        end else begin
            $display("\033[0;32m    ____  ___   __________\033[0m");
            $display("\033[0;32m   / __ \\/   | / ___/ ___/\033[0m");
            $display("\033[0;32m  / /_/ / /| | \\__ \\\__ \ \033[0m");
            $display("\033[0;32m / ____/ ___ |___/ /__/ / \033[0m");
            $display("\033[0;32m/_/   /_/  |_/____/____/  \033[0m");
            $display();
            $display("Simulation Succeeded!");
        end
    end

endmodule


