`timescale 1ns/1ps

module spwm_deadtime_insert #(
    parameter integer DEADTIME_CYC = 50
)(
    input  wire i_clk,
    input  wire i_rst_n,
    input  wire i_en,
    input  wire i_pwm_in,

    output reg  o_pwm_h,
    output reg  o_pwm_l
);

    localparam [1:0]
        ST_IDLE      = 2'd0,
        ST_WAIT_H_ON = 2'd1,
        ST_WAIT_L_ON = 2'd2;

    reg [1:0] state;
    reg [31:0] dead_cnt;

    wire req_h = i_pwm_in;     // 原始PWM高 -> 上臂导通请求
    wire req_l = ~i_pwm_in;    // 原始PWM低 -> 下臂导通请求

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state   <= ST_IDLE;
            dead_cnt<= 32'd0;
            o_pwm_h <= 1'b0;
            o_pwm_l <= 1'b0;
        end else if (!i_en) begin
            state   <= ST_IDLE;
            dead_cnt<= 32'd0;
            o_pwm_h <= 1'b0;
            o_pwm_l <= 1'b0;
        end else begin
            case (state)
                ST_IDLE: begin
                    // 稳态保持：只允许单边开通
                    if (req_h) begin
                        if (o_pwm_l) begin
                            // 需要从L切到H：先关L，进入死区
                            o_pwm_l  <= 1'b0;
                            o_pwm_h  <= 1'b0;
                            dead_cnt <= 32'd0;
                            state    <= ST_WAIT_H_ON;
                        end else if (!o_pwm_h) begin
                            // 当前都关，直接开H（上电初始允许直接开，若你要更严可也加死区）
                            o_pwm_h <= 1'b1;
                            o_pwm_l <= 1'b0;
                        end else begin
                            // 已经是H开
                            o_pwm_h <= 1'b1;
                            o_pwm_l <= 1'b0;
                        end
                    end else begin
                        // req_l
                        if (o_pwm_h) begin
                            // 需要从H切到L：先关H，进入死区
                            o_pwm_h  <= 1'b0;
                            o_pwm_l  <= 1'b0;
                            dead_cnt <= 32'd0;
                            state    <= ST_WAIT_L_ON;
                        end else if (!o_pwm_l) begin
                            // 当前都关，直接开L
                            o_pwm_l <= 1'b1;
                            o_pwm_h <= 1'b0;
                        end else begin
                            // 已经是L开
                            o_pwm_l <= 1'b1;
                            o_pwm_h <= 1'b0;
                        end
                    end
                end

                ST_WAIT_H_ON: begin
                    o_pwm_h <= 1'b0;
                    o_pwm_l <= 1'b0;
                    if (dead_cnt >= (DEADTIME_CYC-1)) begin
                        // 死区结束，如果请求还在，开H；否则按当前请求走
                        if (req_h) begin
                            o_pwm_h <= 1'b1;
                            o_pwm_l <= 1'b0;
                        end else begin
                            o_pwm_h <= 1'b0;
                            o_pwm_l <= 1'b1;
                        end
                        state <= ST_IDLE;
                    end else begin
                        dead_cnt <= dead_cnt + 1'b1;
                    end
                end

                ST_WAIT_L_ON: begin
                    o_pwm_h <= 1'b0;
                    o_pwm_l <= 1'b0;
                    if (dead_cnt >= (DEADTIME_CYC-1)) begin
                        if (req_l) begin
                            o_pwm_h <= 1'b0;
                            o_pwm_l <= 1'b1;
                        end else begin
                            o_pwm_h <= 1'b1;
                            o_pwm_l <= 1'b0;
                        end
                        state <= ST_IDLE;
                    end else begin
                        dead_cnt <= dead_cnt + 1'b1;
                    end
                end

                default: begin
                    state   <= ST_IDLE;
                    dead_cnt<= 32'd0;
                    o_pwm_h <= 1'b0;
                    o_pwm_l <= 1'b0;
                end
            endcase
        end
    end

endmodule