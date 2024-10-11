// a SIGNED multiplier applying booth encoding

module Muler (
    input signed [15:0] x,
    input signed [15:0] y,
    output reg signed [31:0] z
);

  reg signed [31:0] ans;
  reg signed [31:0] xorigin;
  reg signed [31:0] xneg;
  reg signed [31:0] xdouble;
  reg signed [31:0] xnegdouble;
  reg [15:-1] yextend;
  reg signed [4:0] i;

  always @(x, y) begin
    xorigin = {{16{x[15]}}, x};
    xneg = ~xorigin + 1;
    xdouble = xorigin << 1;
    xnegdouble = ~xdouble + 1;
    yextend = {y, 1'b0};

    ans = 0;

    for (i = 14; i >= 0; i = i - 2) begin
      if (yextend[i+1] == 1'b0 && yextend[i] == 1'b0 && yextend[i-1] == 1'b0) begin
        //+0
      end else if (yextend[i+1] == 1'b0 && yextend[i] == 1'b0 && yextend[i-1] == 1'b1) begin
        ans = ans + x;
      end else if (yextend[i+1] == 1'b0 && yextend[i] == 1'b1 && yextend[i-1] == 1'b0) begin
        ans = ans + x;
      end else if (yextend[i+1] == 1'b0 && yextend[i] == 1'b1 && yextend[i-1] == 1'b1) begin
        ans = ans + xdouble;
      end else if (yextend[i+1] == 1'b1 && yextend[i] == 1'b0 && yextend[i-1] == 1'b0) begin
        ans = ans + xnegdouble;
      end else if (yextend[i+1] == 1'b1 && yextend[i] == 1'b0 && yextend[i-1] == 1'b1) begin
        ans = ans + xneg;
      end else if (yextend[i+1] == 1'b1 && yextend[i] == 1'b1 && yextend[i-1] == 1'b0) begin
        ans = ans + xneg;
      end else if (yextend[i+1] == 1'b1 && yextend[i] == 1'b1 && yextend[i-1] == 1'b1) begin
        //+0
      end
    end
  end

  always @(x, y) begin
    #20;  // give them some time to calc
    z = ans;
  end

endmodule
