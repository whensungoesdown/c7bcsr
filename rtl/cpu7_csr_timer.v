`include "../defines.vh"

module cpu7_csr_timer (
   input                          clk,
   input                          resetn,
   input                          init,
   input                          en,
   input                          periodic,
   input  [`TIMER_BIT-1:0]        initval,
   output [`TIMER_BIT+2-1:0]      timeval,
   output                         intr
   );

   wire [`TIMER_BIT+2-1:0] timeval_nxt;

   assign timeval_nxt = (init & en) | (intr & periodic) ? {initval,2'b0} : timeval - 1'b1; 

   dffrle_ns #(`TIMER_BIT+2) timeval_reg (
      .din   (timeval_nxt),
      .rst_l (resetn),
      .en    (en),
      .clk   (clk),
      .q     (timeval));
      //.se(), .si(), .so());

   assign intr = ~(|timeval) & en & (~init);  // ~init , not go off right at writting tcfg

endmodule
