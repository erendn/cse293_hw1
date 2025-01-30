
`timescale 1ns/1ps
module alu_tb
    import config_pkg::*;
    import dv_pkg::*;
    ;

alu_runner alu_runner_inst();

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

    $display("Begin simulation.");
    $urandom(100);
    $timeformat(-3, 3, "ms", 0);

    $display("Reset.");
    alu_runner_inst.reset();

    $display("Begin Test:");

    for (int i = 0; i < 10; i++) begin
        $display("Sending echo operation #%d.", i);
        alu_runner_inst.echo();
    end

    // Wait to receive data back
    repeat (1000) begin
        alu_runner_inst.wait_prescale();
    end

    $display("End simulation.");
    $finish;
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
