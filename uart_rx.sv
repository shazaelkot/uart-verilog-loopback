module uart_rx #(
    parameter int CLK_HZ = 50_000_000,
    parameter int BAUD   = 115200
)(
    input  logic clk, rst_n,
    input  logic rx,
    output logic [7:0] rx_data,
    output logic rx_valid,
    input  logic rx_ready
);
    localparam int DIV      = CLK_HZ / BAUD;
    localparam int HALF_DIV = DIV / 2;

    // 2-FF synchronizer for real-world robustness
    logic rx_ff1, rx_ff2;
    logic rx_s;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_ff1 <= 1'b1;
            rx_ff2 <= 1'b1;
        end else begin
            rx_ff1 <= rx;
            rx_ff2 <= rx_ff1;
        end
    end
    assign rx_s = rx_ff2;

    typedef enum logic [1:0] {RX_IDLE, RX_START, RX_DATA, RX_STOP} rx_state_t;
    rx_state_t st;

    int bit_i;
    int sample_cnt;          // local counter aligned to start bit
    logic [7:0] shreg;
    logic valid_hold;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st <= RX_IDLE;
            bit_i <= 0;
            sample_cnt <= 0;
            shreg <= 0;
            valid_hold <= 0;
            rx_data <= 8'h00;
        end else begin
            // make rx_valid a pulse when rx_ready=1
            if (valid_hold && rx_ready) valid_hold <= 0;

            case (st)
                RX_IDLE: begin
                    if (!rx_s) begin
                        // start detected -> wait HALF bit to sample mid start
                        sample_cnt <= HALF_DIV;
                        st <= RX_START;
                    end
                end

                RX_START: begin
                    if (sample_cnt == 0) begin
                        // sample mid-start
                        if (!rx_s) begin
                            bit_i <= 0;
                            sample_cnt <= DIV;   // wait 1 full bit to sample data0
                            st <= RX_DATA;
                        end else begin
                            st <= RX_IDLE;       // false start
                        end
                    end else begin
                        sample_cnt <= sample_cnt - 1;
                    end
                end

                RX_DATA: begin
                    if (sample_cnt == 0) begin
                        shreg[bit_i] <= rx_s;    // sample mid-bit
                        if (bit_i == 7) begin
                            sample_cnt <= DIV;   // wait to sample stop
                            st <= RX_STOP;
                        end else begin
                            bit_i <= bit_i + 1;
                            sample_cnt <= DIV;   // wait next data bit
                        end
                    end else begin
                        sample_cnt <= sample_cnt - 1;
                    end
                end

                RX_STOP: begin
                    if (sample_cnt == 0) begin
                        if (rx_s) begin          // stop should be high
                            rx_data <= shreg;
                            valid_hold <= 1;
                        end
                        st <= RX_IDLE;
                    end else begin
                        sample_cnt <= sample_cnt - 1;
                    end
                end
            endcase
        end
    end

    assign rx_valid = valid_hold;
endmodule
