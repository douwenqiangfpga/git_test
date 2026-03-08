module led (
    input  wire i_clk,    // 100MHz
    input  wire i_rst_n,  // 低有效复位
    output reg  o_led     // LED输出
);

    // 100MHz 时钟下，0.5秒计数值 = 100_000_000 * 0.5 = 50_000_000
    // 计数范围 0 ~ 49_999_999，需要 26 bit（2^26 = 67,108,864）
    localparam integer CNT_MAX = 50_000_000 - 1;

    reg [25:0] cnt;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            cnt   <= 26'd0;
            o_led <= 1'b0;
        end else begin
            if (cnt == CNT_MAX) begin
                cnt   <= 26'd0;
                o_led <= ~o_led;   // 每0.5秒翻转一次 -> 完整周期1秒
            end else begin
                cnt <= cnt + 26'd1;
            end
        end
    end

endmodule