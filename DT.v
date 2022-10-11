module DT(
 input    clk, 
 input   reset,
 output reg  done ,
 output reg  sti_rd ,
 output reg  [9:0] sti_addr ,
 input  [15:0] sti_di,
 output reg  res_wr ,
 output reg  res_rd ,
 output reg  [13:0] res_addr ,
 output reg  [7:0] res_do,
 input  [7:0] res_di
 );

reg [3:0] count;//15-0(forward)//0-15(backward)
reg [3:0] ns;//state = 0~12

parameter idle = 4'b0000;//0
parameter forward = 4'b0001;//1
parameter NW = 4'b0010;//2
parameter N = 4'b0011;//3
parameter NE = 4'b0100;//4
parameter W = 4'b0101;//5
parameter backward = 4'b0110;//6
parameter SE = 4'b0111;//7
parameter S = 4'b1000;//8
parameter SW = 4'b1001;//9
parameter E = 4'b1010;//10
parameter write = 4'b1011;//11
parameter finish = 4'b1100;//12

always @(posedge clk or negedge reset) begin //count
  if(!reset)
    count <= 14;
  else if(sti_addr == 1023 && count == 0)
    count <= 1;
  else case(ns)
    forward:
      count <= count - 1;
    backward:
      count <= count + 1;
    default:
      count <= count; 
  endcase
end

always @(posedge clk) begin //state
  if(!reset)
    ns <= idle;
  else begin
    case(ns)
      idle:begin//0
        if(reset)
          ns <= forward;
        else
          ns <= idle;
        end
      forward:begin//1
        if(sti_addr == 1023 && count == 0)
          ns <= backward;
        else if(sti_di[count])
          ns <= NW;
        else if(!sti_di[count])
          ns <= forward;
        else
          ns <= NW;
        end
      NW:begin//2
        ns <= N;
      end
      N:begin//3
        ns <= NE;
      end
      NE:begin//4
        ns <= W;
      end
      W:begin//5
        if(sti_addr == 1023 && count == 0)
          ns <= backward;
        else
          ns <= forward;
      end
      backward:begin//6
        if(sti_di[count])
          ns <= SE;
        else if(count == 14 && sti_addr == 8)
          ns <= finish;
        else if(!sti_di[count])
          ns <= backward;
        else
          ns <= SE;
      end
      SE:begin//7
        ns <= S;
      end
      S:begin//8
        ns <= SW;
      end
      SW:begin//9
        ns <= E;
      end
      E:begin//10
        ns <= write;
      end
      write:begin//11
        if(count == 14 && sti_addr == 8)
          ns <= finish;
        else
          ns <= backward;
      end
      default:
        ns <= idle;
    endcase
  end
end

always @(posedge clk or negedge reset) begin //sti_addr
  if(!reset)
    sti_addr <= 0;
  else if(sti_addr == 1023 && ns == forward)
    sti_addr <= 1023;
  else if(ns == forward && count == 0)
    sti_addr <= sti_addr + 1;
  else if(ns == backward && count == 15)
    sti_addr <= sti_addr - 1;
  else
    sti_addr <= sti_addr;
end

always @(posedge clk or negedge reset) begin //sti_rd
  if(!reset)
    sti_rd <= 0;
  else if(ns == forward)
    sti_rd <= 1;
  else
    sti_rd <= 1;
end

always @(posedge clk or negedge reset) begin //res_addr
  if(!reset)
    res_addr <= 0;
  else if(sti_di[count] && ns == forward)
    res_addr <= res_addr - 128;
  else if(sti_di[count] && ns == backward)
    res_addr <= res_addr + 128;
  else case(ns)
    NW:
      res_addr <= res_addr + 1;
    N:
      res_addr <= res_addr + 1;
    NE:
      res_addr <= res_addr + 126;
    W:
      res_addr <= res_addr + 1;
    forward:
      res_addr <= res_addr + 1;
    SE:
      res_addr <= res_addr - 1;
    S:
      res_addr <= res_addr - 1;
    SW:
      res_addr <= res_addr - 126;
    E:
      res_addr <= res_addr - 1;
    backward:
      res_addr <= res_addr - 1;
    default:
      res_addr <= res_addr;
  endcase
end


always @(posedge clk or negedge reset) begin //res_wr
  if(!reset)
    res_wr <= 0;
  else if(ns == forward && !sti_di[count])
    res_wr <= 1;
  else case(ns) 
    W:
      res_wr <= 1;
    write:
      res_wr <= 1;
    default:
      res_wr <= 0;
  endcase
end

always @(posedge clk or negedge reset) begin //res_rd
  if(!reset)
    res_rd <= 0;
  else if(sti_di[count])
    res_rd <= 1;
  else
    res_rd <= 1;
end

always @(posedge clk or negedge reset) begin //res_do
  if(!reset)
    res_do <= 0;
  else if(!sti_di[count] && ns == forward)
    res_do <= 0;
  else case(ns)
    NW:
      res_do <= res_di;
    N:
      res_do <= (res_di < res_do ? res_di : res_do);
    NE:
      res_do <= (res_di < res_do ? res_di : res_do);
    W:
      res_do <= (res_di < res_do ? res_di + 1 : res_do + 1);
    SE:
      res_do <= res_di;
    S:
      res_do <= ((res_di < res_do) ? res_di : res_do);
    SW:
      res_do <= ((res_di < res_do) ? res_di : res_do);
    E:
      res_do <= ((res_di < res_do) ? res_di : res_do);
    write:
      res_do <= ((res_di < (res_do + 1)) ? res_di : res_do + 1);
    default:
      res_do <= res_do;
  endcase 
end

always @(posedge clk or negedge reset) begin
  if(!reset)
    done <= 0;
  else if(ns == finish)
    done <= 1;
  else
    done <= 0;
end

endmodule
