module baud_gen #(
    parameter int CLK_HZ = 50_000_000,
    parameter int BAUD   = 115200
)(
    input  logic clk, rst_n,
    output logic baud_tick,
    output logic half_tick
);
    localparam int DIV      = CLK_HZ / BAUD;
    localparam int HALF_DIV = DIV / 2;

    int cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0;
            baud_tick <= 0;
            half_tick <= 0;
        end else begin
            baud_tick <= 0;
            half_tick <= 0;

            if (cnt == DIV-1) begin
                cnt <= 0;
                baud_tick <= 1;
            end else begin
                cnt <= cnt + 1;
                if (cnt == HALF_DIV-1) half_tick <= 1;
            end
        end
    end
endmodule
