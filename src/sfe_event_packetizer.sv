`timescale 1ns/1ps

module sfe_event_packetizer #(
    parameter int NUM_CHANNELS = 32,
    parameter int CH_WIDTH = (NUM_CHANNELS <= 1) ? 1 : $clog2(NUM_CHANNELS),
    parameter int TIMESTAMP_WIDTH = 32,
    parameter int FIFO_DEPTH = 16,
    parameter int PENDING_COUNT_WIDTH = 2,
    parameter int FIFO_COUNT_WIDTH = (FIFO_DEPTH <= 1) ? 1 : $clog2(FIFO_DEPTH + 1)
) (
    input  logic                         clk,
    input  logic                         rst_n,
    input  logic                         en,
    input  logic                         event_ready,
    input  logic [NUM_CHANNELS-1:0]      spike_up,
    input  logic [NUM_CHANNELS-1:0]      spike_down,
    output logic                         event_valid,
    output logic [CH_WIDTH-1:0]          event_channel,
    output logic                         event_direction,
    output logic [TIMESTAMP_WIDTH-1:0]   event_timestamp,
    output logic [NUM_CHANNELS-1:0]      pending_mask,
    output logic                         fifo_full,
    output logic                         fifo_overflow,
    output logic                         pending_overflow,
    output logic [FIFO_COUNT_WIDTH-1:0]  fifo_level
);

    localparam logic DIR_DOWN = 1'b0;
    localparam logic DIR_UP   = 1'b1;

    logic [TIMESTAMP_WIDTH-1:0] timestamp_q;
    logic [CH_WIDTH-1:0] channel_fifo [0:FIFO_DEPTH-1];
    logic direction_fifo [0:FIFO_DEPTH-1];
    logic [TIMESTAMP_WIDTH-1:0] timestamp_fifo [0:FIFO_DEPTH-1];
    logic [FIFO_COUNT_WIDTH-1:0] count_q;
    logic [FIFO_COUNT_WIDTH-1:0] wr_ptr_q;
    logic [FIFO_COUNT_WIDTH-1:0] rd_ptr_q;
    logic [PENDING_COUNT_WIDTH-1:0] pending_up_count_q [0:NUM_CHANNELS-1];
    logic [PENDING_COUNT_WIDTH-1:0] pending_down_count_q [0:NUM_CHANNELS-1];

    logic [NUM_CHANNELS-1:0] candidate_up;
    logic [NUM_CHANNELS-1:0] candidate_down;
    logic found;
    logic [CH_WIDTH-1:0] selected_channel;
    logic selected_direction;
    logic do_push;
    logic do_pop;

    integer i;
    integer up_next;
    integer down_next;

    localparam int PENDING_COUNT_MAX = (1 << PENDING_COUNT_WIDTH) - 1;

    assign fifo_full = (count_q == FIFO_DEPTH);
    assign event_valid = (count_q != '0);
    assign event_channel = channel_fifo[rd_ptr_q];
    assign event_direction = direction_fifo[rd_ptr_q];
    assign event_timestamp = timestamp_fifo[rd_ptr_q];
    assign fifo_level = count_q;
    assign do_pop = event_valid && event_ready;
    assign do_push = found && (!fifo_full || do_pop);

    always_comb begin
        pending_mask = '0;
        candidate_up = '0;
        candidate_down = '0;
        for (i = 0; i < NUM_CHANNELS; i = i + 1) begin
            pending_mask[i] = (pending_up_count_q[i] != '0) || (pending_down_count_q[i] != '0);
            candidate_up[i] = (pending_up_count_q[i] != '0) || (en && spike_up[i]);
            candidate_down[i] = (pending_down_count_q[i] != '0) || (en && spike_down[i]);
        end
    end

    always_comb begin
        found = 1'b0;
        selected_channel = '0;
        selected_direction = DIR_DOWN;

        for (i = 0; i < NUM_CHANNELS; i = i + 1) begin
            if (!found && candidate_up[i]) begin
                found = 1'b1;
                selected_channel = i;
                selected_direction = DIR_UP;
            end else if (!found && candidate_down[i]) begin
                found = 1'b1;
                selected_channel = i;
                selected_direction = DIR_DOWN;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timestamp_q   <= '0;
            fifo_overflow <= 1'b0;
            pending_overflow <= 1'b0;
            count_q       <= '0;
            wr_ptr_q      <= '0;
            rd_ptr_q      <= '0;
            for (i = 0; i < NUM_CHANNELS; i = i + 1) begin
                pending_up_count_q[i] <= '0;
                pending_down_count_q[i] <= '0;
            end
        end else begin
            fifo_overflow <= 1'b0;
            pending_overflow <= 1'b0;

            if (en) begin
                timestamp_q <= timestamp_q + 1'b1;
            end

            if (found && fifo_full && !do_pop) begin
                fifo_overflow <= 1'b1;
            end

            for (i = 0; i < NUM_CHANNELS; i = i + 1) begin
                up_next = pending_up_count_q[i] + ((en && spike_up[i]) ? 1 : 0);
                down_next = pending_down_count_q[i] + ((en && spike_down[i]) ? 1 : 0);

                if (do_push && selected_channel == i && selected_direction == DIR_UP && up_next != 0) begin
                    up_next = up_next - 1;
                end
                if (do_push && selected_channel == i && selected_direction == DIR_DOWN && down_next != 0) begin
                    down_next = down_next - 1;
                end

                if (up_next > PENDING_COUNT_MAX) begin
                    pending_up_count_q[i] <= '1;
                    pending_overflow <= 1'b1;
                end else begin
                    pending_up_count_q[i] <= up_next[PENDING_COUNT_WIDTH-1:0];
                end

                if (down_next > PENDING_COUNT_MAX) begin
                    pending_down_count_q[i] <= '1;
                    pending_overflow <= 1'b1;
                end else begin
                    pending_down_count_q[i] <= down_next[PENDING_COUNT_WIDTH-1:0];
                end
            end

            if (do_push) begin
                channel_fifo[wr_ptr_q] <= selected_channel;
                direction_fifo[wr_ptr_q] <= selected_direction;
                timestamp_fifo[wr_ptr_q] <= timestamp_q;

                if (wr_ptr_q == (FIFO_DEPTH - 1)) begin
                    wr_ptr_q <= '0;
                end else begin
                    wr_ptr_q <= wr_ptr_q + 1'b1;
                end
            end

            if (do_pop) begin
                if (rd_ptr_q == (FIFO_DEPTH - 1)) begin
                    rd_ptr_q <= '0;
                end else begin
                    rd_ptr_q <= rd_ptr_q + 1'b1;
                end
            end

            case ({do_push, do_pop})
                2'b10: count_q <= count_q + 1'b1;
                2'b01: count_q <= count_q - 1'b1;
                default: count_q <= count_q;
            endcase
        end
    end

endmodule
