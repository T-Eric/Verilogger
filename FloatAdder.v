module FloatAdder (
    input clk,
    input rst,
    input [31:0] x,
    input [31:0] y,
    output reg [31:0] z,
    output reg [1:0] overflow
);
  // overflow: 00-no overflow, 01: overflow, 10: underflow, 11: abnormal input

  reg [31:0] ans;
  reg [24:0] mx, my, mz;  // Significand(Mantissa)
  reg [7:0] ex, ey, ez;  // Exponent
  reg sx, sy, sz;  //Sign

  reg [2:0] state, nextState;
  parameter init=3'b000,zeroCheck=3'b001,alignExp=3'b010,addSig=3'b011,normSig=3'b100,over=3'b101;

  always @(posedge clk) begin
    if (!rst) begin
      state <= init;
    end else begin
      state <= nextState;
    end
  end

  always @(state, nextState, ex, ey, ez, mx, my, mz) begin
    case (state)
      init: begin
        ex <= x[30:23];
        ey <= y[30:23];
        mx <= {2'b01, x[22:0]};
        my <= {2'b01, y[22:0]};
        sx <= x[31];
        sy <= y[31];

        /*
        排除两个情况：
        1. Exp=255, 此时或者是+-inf或者是Nan，不能计算
        2. Exp=0 && Sig!=0, 非规格化数
        */
        if (ex == 8'd255 || ey == 8'd255) begin
          overflow <= 2'b11;
          nextState <= over;
          {sz, ez, mz} <= 32'b1;
        end else if ((ex == 8'd0 && mx != 23'b0) || (ey == 8'd0 && my != 23'b0)) begin
          overflow <= 2'b11;
          nextState <= over;
          {sz, ez, mz} <= 32'hffffffff;
        end else begin
          nextState <= zeroCheck;
        end
      end

      zeroCheck: begin
        // check whether any between x and y is zero
        if (mx[22:0] == 23'b0 && ex == 8'b0) begin
          {sz, ez, mz} <= {sy, ey, my};
          nextState <= over;
        end else if (my[22:0] == 23'b0 && ey == 8'b0) begin
          {sz, ez, mz} <= {sx, ex, mx};
          nextState <= over;
        end else begin
          nextState <= alignExp;
        end
      end

      alignExp: begin
        // align the exponents, round the significand,
        if (ex == ey) begin
          nextState <= addSig;
        end else begin
          if (ex > ey) begin
            ey <= ey + 1'b1;
            my[23:0] <= {1'b0, my[23:1]};
            // if my==0 y<<x, we can just let z=x
            if (my == 25'b0) begin
              mz <= mx;
              ez <= ex;
              sz <= sx;
              nextState <= over;
            end else begin
              nextState <= alignExp;
            end
          end else begin
            ex <= ex + 1'b1;
            mx[23:0] <= {1'b0, mx[23:1]};
            if (mx == 25'b0) begin
              mz <= my;
              ez <= ey;
              sz <= sy;
              nextState <= over;
            end else begin
              nextState <= alignExp;
            end
          end
        end
      end

      addSig: begin
        // ex=ey
        ez <= ex;
        if (sx ^ sy == 1'b0) begin
          sz <= sx;
          mz <= mx + my;
        end else begin
          if (mx > my) begin
            sz <= sx;
            mz <= mx - my;
          end else begin
            sz <= sy;
            mz <= my - mx;
          end
        end
        if (mz[23:0] == 24'b0) nextState <= over;
        else nextState <= normSig;
      end

      normSig: begin
        // 规格化处理
        // mz必须是01+22位的状态，否则并未规格化，23位就是小数点后的位
        if (mz[24] == 1'b1) begin
          //有进位或借位，右移
          mz <= {1'b0, mz[24:1]};
          ez <= ez + 1'b1;
          nextState <= over;
        end else begin
          if (mz[23] == 1'b0) begin
            mz <= {mz[23:0], 1'b0};
            ez <= ez - 1'b1;
            nextState <= normSig;
          end else begin
            nextState <= over;
          end
        end
      end

      over: begin
        z <= {sz, ez, mz[22:0]};
        // overflow?
        if (ez == 8'd255) begin
          overflow <= 2'b01;
        end else if (ez == 8'd0 && mz[22:0] != 23'b0) begin
          overflow <= 2'b10;
        end else begin
          overflow <= 2'b00;
        end
      end

      default: begin
        nextState <= init;
      end
    endcase
  end
endmodule
