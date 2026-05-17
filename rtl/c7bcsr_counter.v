module c7bcsr_counter (
   input               clk,
   input               resetn,
   output [63:0]       counter_val
   );

   wire [63:0] next_val;

   assign next_val = counter_val + 64'b1;

   dffrl_ns #(64) counter_reg (
       .clk   (clk),
       .rst_l (resetn),
       .din   (next_val),
       .q     (counter_val)
   );

endmodule

