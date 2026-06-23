`timescale 1ns/1ps

module sfe_channel #(
    parameter int DATA_WIDTH       = 16,
    parameter int THETA_WIDTH      = 16,
    parameter int REF_WIDTH        = DATA_WIDTH,
    parameter int LEAK_SHIFT       = 4,
    parameter int THETA_DEC_SHIFT  = 6,
    parameter int REFRACTORY_LEN   = 4,
    parameter int REFRACTORY_WIDTH = (REFRACTORY_LEN <= 1) ? 1 : $clog2(REFRACTORY_LEN + 1),
    parameter int THETA_MIN        = 16,
    parameter int THETA_MAX        = 1024,
    parameter int THETA_INIT       = 32,
    parameter bit ENABLE_ADAPTIVE  = 1'b1,
    parameter bit ENABLE_LEAKAGE   = 1'b1,
    parameter bit ENABLE_REFRACTORY = 1'b1
) (
    input  logic                         clk,
    input  logic                         rst_n,
    input  logic                         en,
    input  logic                         channel_en,
    input  logic                         cfg_enable_adaptive,
    input  logic                         cfg_enable_leakage,
    input  logic                         cfg_enable_refractory,
    input  logic                         decay_tick,
    input  logic                         cfg_load,
    input  logic        [THETA_WIDTH-1:0] cfg_theta_min,
    input  logic        [THETA_WIDTH-1:0] cfg_theta_max,
    input  logic        [THETA_WIDTH-1:0] cfg_theta_init,
    input  logic        [REFRACTORY_WIDTH-1:0] cfg_refractory_len,
    input  logic signed [DATA_WIDTH-1:0] x_in,
    output logic                         spike_up,
    output logic                         spike_down,
    output logic signed [REF_WIDTH-1:0]  v_ref_dbg,
    output logic        [THETA_WIDTH-1:0] theta_dbg
);

    localparam int DELTA_WIDTH = DATA_WIDTH + 1;
    logic signed [REF_WIDTH-1:0]       v_ref_q;
    logic        [THETA_WIDTH-1:0]     theta_q;
    logic        [REFRACTORY_WIDTH-1:0] refractory_q;

    // Pipeline: fire decision registered for one cycle to break the
    // combinational path x_in -> delta -> compare -> sat_add -> v_ref_q.
    // Stage 1 (combinational): delta, fire_up, fire_down.
    // Stage 2 (registered):    fire_up_pipe, fire_down_pipe -> state update.
    // Spike output is delayed by 1 cycle (still correct for AER protocol).
    logic signed [DELTA_WIDTH-1:0] delta;
    logic signed [DELTA_WIDTH-1:0] theta_signed;
    logic                         can_fire;
    logic                         fire_up;
    logic                         fire_down;
    logic                         fire_up_pipe;
    logic                         fire_down_pipe;
    logic [THETA_WIDTH-1:0]       theta_pipe;

    assign delta        = $signed({x_in[DATA_WIDTH-1], x_in}) -
                          $signed({v_ref_q[REF_WIDTH-1], v_ref_q});
    assign theta_signed = $signed({1'b0, theta_q});
    assign can_fire     = en && channel_en &&
                          (!cfg_enable_refractory || (refractory_q == '0));
    assign fire_up      = can_fire && (delta >= theta_signed);
    assign fire_down    = can_fire && (delta <= -theta_signed);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spike_up       <= 1'b0;
            spike_down     <= 1'b0;
            v_ref_q        <= '0;
            theta_q        <= THETA_INIT;
            refractory_q   <= '0;
            fire_up_pipe   <= 1'b0;
            fire_down_pipe <= 1'b0;
            theta_pipe     <= THETA_INIT;
        end else begin
            spike_up   <= 1'b0;
            spike_down <= 1'b0;

            // Stage 1: register fire decision for next-cycle update.
            // Gate with en && channel_en so a stale fire is not
            // replayed after a disable/enable toggle.
            fire_up_pipe   <= fire_up && en && channel_en;
            fire_down_pipe <= fire_down && en && channel_en;
            theta_pipe     <= theta_q;

            if (cfg_load) begin
                v_ref_q        <= '0;
                theta_q        <= cfg_theta_init;
                refractory_q   <= '0;
                fire_up_pipe   <= 1'b0;
                fire_down_pipe <= 1'b0;
            end else if (en && channel_en) begin
                // Stage 2: apply state updates from pipelined fire decision
                if (fire_up_pipe) begin
                    spike_up     <= 1'b1;
                    v_ref_q      <= sat_add_ref(v_ref_q, theta_pipe);
                    theta_q      <= cfg_enable_adaptive ? theta_inc(theta_q) : theta_q;
                    refractory_q <= cfg_enable_refractory ? cfg_refractory_len : '0;
                end else if (fire_down_pipe) begin
                    spike_down   <= 1'b1;
                    v_ref_q      <= sat_sub_ref(v_ref_q, theta_pipe);
                    theta_q      <= cfg_enable_adaptive ? theta_inc(theta_q) : theta_q;
                    refractory_q <= cfg_enable_refractory ? cfg_refractory_len : '0;
                end else begin
                    if (decay_tick) begin
                        v_ref_q <= cfg_enable_leakage ? leak_to_zero(v_ref_q) : v_ref_q;
                        theta_q <= cfg_enable_adaptive ? theta_dec(theta_q) : theta_q;
                    end
                    if (refractory_q != '0) begin
                        refractory_q <= refractory_q - 1'b1;
                    end
                end
            end else begin
                // Channel/en disabled: clear any pending fire so a spike is
                // not emitted when re-enabled.
                fire_up_pipe   <= 1'b0;
                fire_down_pipe <= 1'b0;
            end
        end
    end

    assign v_ref_dbg  = v_ref_q;
    assign theta_dbg  = theta_q;

    function automatic logic signed [REF_WIDTH-1:0] leak_to_zero(
        input logic signed [REF_WIDTH-1:0] value
    );
        logic signed [REF_WIDTH-1:0] leak_step;
        begin
            leak_step = value >>> LEAK_SHIFT;
            if (value == '0) begin
                leak_to_zero = '0;
            end else if (leak_step == '0) begin
                leak_to_zero = value - {{(REF_WIDTH-1){1'b0}}, 1'b1};
            end else begin
                leak_to_zero = value - leak_step;
            end
        end
    endfunction

    function automatic logic [THETA_WIDTH-1:0] theta_inc(
        input logic [THETA_WIDTH-1:0] theta
    );
        logic [THETA_WIDTH:0] grown;
        begin
            grown = {1'b0, theta} + ({1'b0, theta} >> 1);
            if (grown > cfg_theta_max) begin
                theta_inc = cfg_theta_max;
            end else begin
                theta_inc = grown[THETA_WIDTH-1:0];
            end
        end
    endfunction

    function automatic logic [THETA_WIDTH-1:0] theta_dec(
        input logic [THETA_WIDTH-1:0] theta
    );
        logic [THETA_WIDTH-1:0] dec_step;
        begin
            dec_step = theta >> THETA_DEC_SHIFT;
            if (theta <= cfg_theta_min) begin
                theta_dec = cfg_theta_min;
            end else if (dec_step == '0) begin
                theta_dec = theta - {{(THETA_WIDTH-1){1'b0}}, 1'b1};
            end else if ((theta - dec_step) < cfg_theta_min) begin
                theta_dec = cfg_theta_min;
            end else begin
                theta_dec = theta - dec_step;
            end
        end
    endfunction

    function automatic logic signed [REF_WIDTH-1:0] sat_add_ref(
        input logic signed [REF_WIDTH-1:0] value,
        input logic        [THETA_WIDTH-1:0] step
    );
        logic signed [REF_WIDTH:0] result;
        logic signed [REF_WIDTH:0] max_pos;
        begin
            result  = $signed({value[REF_WIDTH-1], value}) + $signed({1'b0, step});
            max_pos = $signed({1'b0, {(REF_WIDTH-1){1'b1}}});
            if (result > max_pos) begin
                sat_add_ref = {1'b0, {(REF_WIDTH-1){1'b1}}};
            end else begin
                sat_add_ref = result[REF_WIDTH-1:0];
            end
        end
    endfunction

    function automatic logic signed [REF_WIDTH-1:0] sat_sub_ref(
        input logic signed [REF_WIDTH-1:0] value,
        input logic        [THETA_WIDTH-1:0] step
    );
        logic signed [REF_WIDTH:0] result;
        logic signed [REF_WIDTH:0] min_neg;
        begin
            result  = $signed({value[REF_WIDTH-1], value}) - $signed({1'b0, step});
            min_neg = $signed({1'b1, {(REF_WIDTH-1){1'b0}}});
            if (result < min_neg) begin
                sat_sub_ref = {1'b1, {(REF_WIDTH-1){1'b0}}};
            end else begin
                sat_sub_ref = result[REF_WIDTH-1:0];
            end
        end
    endfunction

endmodule
