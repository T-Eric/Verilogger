module Add (
    input [31:0] a,
    input [31:0] b,
    output reg [31:0] sum
);

  wire cm, cout;
  wire [31:0] ans;

  CLA16 adderLow (
      .a(a[15:0]),
      .b(b[15:0]),
      .cin(1'b0),
      .sum(ans[15:0]),
      .cout(cm)
  );

  CLA16 adderHigh (
      .a(a[31:16]),
      .b(b[31:16]),
      .cin(cm),
      .sum(ans[31:16]),
      .cout(cout)
  );

  always @(*) begin
    sum <= ans;
  end

endmodule

module CLA16 (
    input [15:0] a,
    input [15:0] b,
    input cin,
    output [15:0] sum,
    output cout
);

  wire c4, c8, c12;

  CLA4 adder0 (
      .a(a[3:0]),
      .b(b[3:0]),
      .cin(cin),
      .sum(sum[3:0]),
      .cout(c4)
  );

  CLA4 adder1 (
      .a(a[7:4]),
      .b(b[7:4]),
      .cin(c4),
      .sum(sum[7:4]),
      .cout(c8)
  );

  CLA4 adder2 (
      .a(a[11:8]),
      .b(b[11:8]),
      .cin(c8),
      .sum(sum[11:8]),
      .cout(c12)
  );

  CLA4 adder3 (
      .a(a[15:12]),
      .b(b[15:12]),
      .cin(c12),
      .sum(sum[15:12]),
      .cout(cout)
  );

endmodule

module CLA4 (
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] sum,
    output cout
);

  wire [4:0] c;
  wire [3:0] g;
  wire [3:0] p;

  assign g = a & b;
  assign p = a ^ b;
  assign c[0] = cin;
  assign cout = c[4];

  assign c[1] = g[0] | (p[0] & c[0]);
  assign c[2] = g[1] | (p[1] & (g[0] | (p[0] & c[0])));
  assign c[3] = g[2] | (p[2] & (g[1] | (p[1] & (g[0] | (p[0] & c[0])))));
  assign c[4] = g[3] | (p[3] & (g[2] | (p[2] & (g[1] | (p[1] & (g[0] | (p[0] & c[0])))))));

  genvar i;
  generate
    for (i = 0; i < 4; i = i + 1) begin : sum_block
      assign sum[i] = p[i] ^ c[i];
    end
  endgenerate

endmodule
