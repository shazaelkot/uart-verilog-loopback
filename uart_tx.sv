module uart_tx #(
    parameter int CLK_HZ = 50_000_000,
    parameter int BAUD   = 115200
)(
    input  logic clk, rst_n,
    input  logic [7:0] tx_data,
    input  logic tx_valid,
    output logic tx_ready,
    output logic tx
);
    logic baud_tick, half_tick;
    baud_gen #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) u_baud(
        .clk, .rst_n, .baud_tick, .half_tick
    );

    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t st;

    logic [7:0] shreg;
    int bit_i;

    assign tx_ready = (st == IDLE);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st <= IDLE;
            tx <= 1'b1;   // idle high
            shreg <= 0;
            bit_i <= 0;
        end else begin
            // While idle, accept tx_valid on ANY clock
            if (st == IDLE) begin
                tx <= 1'b1;
                if (tx_valid) begin
                    shreg <= tx_data;  // latch immediately
                    bit_i <= 0;
                    st <= START;
                end
            end
            // Advance bits only on baud_tick
            else if (baud_tick) begin
                case (st)
                    START: begin
                        tx <= 1'b0;   // start bit
                        st <= DATA;
                    end

                    DATA: begin
                        tx <= shreg[bit_i]; // LSB first
                        if (bit_i == 7) st <= STOP;
                        else bit_i <= bit_i + 1;
                    end

                    STOP: begin
                        tx <= 1'b1;   // stop bit
                        st <= IDLE;
                    end
                endcase
            end
        end
    end
endmodule
