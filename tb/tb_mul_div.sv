`timescale 1ns/10ps

module tb_mul_div;
    localparam PERIOD = 1;
    logic        clk;
    logic        rstb;
    logic [31:0] a;
    logic [31:0] b;
    logic        valid;
    logic [5:0]  cnt;
    logic [2:0]  optype;
    logic [31:0] result_mult;
    logic [31:0] result_div;
    wire         result_valid;

    always @(posedge clk or negedge rstb) begin
        if(~rstb) begin
            cnt <= 0;
        end else begin
            cnt <= cnt + 1;
        end
    end 

    initial begin
        clk = 0;
        rstb = 0;
        #(10); rstb = 1;
    end

    always @(posedge clk) begin
        if(cnt == 'h3F) begin
            valid <= 0;
            a <= $urandom_range(0,32'hffff_ffff);
            b <= $urandom_range(0,32'hffff_ffff);
            optype <= $urandom_range(0,7);
        end else begin
            valid <= 1;
        end
    end 

    wire mul_valid = valid & (optype < 6);
    wire div_valid = valid & (optype >= 6);

xrv_mult U_XRV_MULT(
    .clk(clk),
    .rstb(rstb),
    .a(a),
    .b(b),
    .mult_type(optype),
    .valid(mul_valid),

    .result(result_mult),
    .result_valid(result_valid)
);

xrv_div(
    .clk(clk),
    .rstb(rstb),
    .dividend(dividend),
    .divisor(divisor),
    .is_div_sign(is_div_sign),
    .optype(optype), //0: div; 1: rem
    .valid(valid),
    .result(result_div),
    .result_valid(result_valid)
);


endmodule
