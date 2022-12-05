`default_nettype none
`timescale 1ns / 1ps

module fifo_sim(
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire rd,
    input wire wr,

    output logic data_out,
    output logic empty,
    output logic full,
    output logic [31:0] data_count
);

    logic [7:0][2:0] buffer ;
    logic [2:0] r_ptr, w_ptr;
    logic [2:0] bit_counter;

    assign full = (w_ptr == 3 && r_ptr == 0) ? 1 : 0;
    assign empty = (w_ptr == r_ptr) ? 1 : 0;

    always_ff @(posedge clk) begin 
        if (rst) begin
            w_ptr <= 0;
            r_ptr <= 0;
            bit_counter <= 7;
            data_count <= 0;
        end else begin
            if (wr && ~full) begin
                buffer[w_ptr] <= data_in;
                w_ptr <= w_ptr + 1;
                data_count <= data_count + 8;
            end
            if (rd && ~empty) begin
                data_out <= buffer[r_ptr][bit_counter];
                data_count <= data_count - 1;
                if (bit_counter == 0) begin
                    bit_counter <= 7;
                    r_ptr <= r_ptr + 1;
                end else begin
                    bit_counter <= bit_counter - 1;
                end
            end
            
        end
    end

endmodule

`default_nettype wire