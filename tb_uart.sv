`timescale 1ns/1ps

module tb_uart;
    localparam int CLK_HZ=10_000_000;
    localparam int BAUD=9600;
    localparam time TCLK = 1000000000/CLK_HZ; // ns

    logic clk=0, rst_n=0;
    always #(TCLK/2) clk = ~clk;

    logic tx, rx;
    logic [7:0] tx_data, rx_data;
    logic tx_valid, tx_ready, rx_valid;
    logic rx_ready=1;

    uart_tx #(.CLK_HZ(CLK_HZ),.BAUD(BAUD)) dut_tx(
        .clk, .rst_n, .tx_data, .tx_valid, .tx_ready, .tx
    );
    uart_rx #(.CLK_HZ(CLK_HZ),.BAUD(BAUD)) dut_rx(
        .clk, .rst_n, .rx, .rx_data, .rx_valid, .rx_ready
    );

    assign rx = tx; // loopback

    initial begin
        // clean init
        tx_data  = 8'h00;
        tx_valid = 0;
        rst_n    = 0;

        $dumpfile("dump.vcd");
        $dumpvars(0,tb_uart);

        // reset
        #(10*TCLK); rst_n=1;

        // let everything settle
        #(100*TCLK);
        wait(tx_ready);

        // SEND then IMMEDIATELY WAIT FOR RX (so we don't miss pulses)
        send_byte(8'h55);  wait_rx(8'h55);
        send_byte(8'hA3);  wait_rx(8'hA3);
        send_byte(8'h00);  wait_rx(8'h00);
        send_byte(8'hFF);  wait_rx(8'hFF);

        #(10000*TCLK);
        $display("PASS ✅ UART loopback works");
        $finish;
    end

    // Send a byte: make data stable, pulse tx_valid, return quickly
    task send_byte(input [7:0] b);
        begin
            wait(tx_ready);
            tx_data = b;          // blocking
            @(posedge clk);
            tx_valid = 1;         // pulse valid for 1 clk
            @(posedge clk);
            tx_valid = 0;
        end
    endtask

    // Wait for a received byte, then sample rx_data NEXT clk
    task wait_rx(input [7:0] b);
        begin
            wait(rx_valid);
            @(posedge clk); // allow rx_data to settle (NBA)
            $display("RX got %h at time %0t", rx_data, $time);
            if (rx_data !== b) begin
                $display("FAIL ❌ exp=%h got=%h", b, rx_data);
                $finish;
            end
        end
    endtask
endmodule
