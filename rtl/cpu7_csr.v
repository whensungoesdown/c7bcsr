`include "../defines.vh"
`include "csr_defs.v"

/////
//
//  All the exceptions are handled at _e stage, including ale, illinstr, badaddr
//
//  For example, illegal instruction exception happens at _d stage. Handle different types of exception
//  at different stages make things more complicated. Should choose between pc_d and pc_e to store.
//  And exception happened at _e has a higher priority, becasue it is from the elderly instruction.
//   
//
module cpu7_csr(
   input                          clk,
   input                          resetn,
   output [31:0]                  csr_rdata,
   input  [`LCSR_BIT-1:0]         csr_raddr,
   input  [31:0]                  csr_wdata,
   input  [`LCSR_BIT-1:0]         csr_waddr,
   input  [31:0]                  csr_mask,
   input                          csr_wen,

   output [31:0]                  csr_eentry,
   output [31:0]                  csr_era,
   input  [31:0]                  ecl_csr_badv_e,
   input                          exu_ifu_except,
   input  [5:0]                   ecl_csr_exccode_e,
   input  [31:0]                  ifu_exu_pc_e,
   input                          ecl_csr_ertn_e,

   output                         csr_ecl_crmd_ie,
   output                         csr_ecl_timer_intr,

   input                          ext_intr
   );


   wire exception;

   assign exception = exu_ifu_except; // when to store era, the timing is decided by ecl

   wire               prmd_pie;
   wire               prmd_pie_wdata;
   wire               prmd_pie_nxt;

   wire [1:0]         prmd_pplv;
   wire [1:0]         prmd_pplv_wdata;
   wire [1:0]         prmd_pplv_nxt;


   //
   //  CRMD 0x0
   //
   
   wire [31:0]        crmd;
   wire               crmd_wen;
   assign crmd_wen = (csr_waddr == `LCSR_CRMD) && csr_wen;


   wire               crmd_ie_msk_wen;
   assign crmd_ie_msk_wen = csr_mask[`CRMD_IE] & crmd_wen;

   
   wire               crmd_ie;
   wire               crmd_ie_wdata;
   wire               crmd_ie_nxt;

   assign crmd_ie_wdata = csr_wdata[`CRMD_IE];

//   dp_mux2es #(1) crmd_ie_mux(
//      .dout (crmd_ie_nxt),
//      .in0  (crmd_ie_wdata),
//      .in1  (1'b0),
//      .sel  (exception));

   wire crmd_ie_mux_sel_wdata_l;
   wire crmd_ie_mux_sel_zero_l;
   wire crmd_ie_mux_sel_prmdpie_l;
   
   assign crmd_ie_mux_sel_wdata_l = ~crmd_wen;
   assign crmd_ie_mux_sel_zero_l = ~exception;
   assign crmd_ie_mux_sel_prmdpie_l = ~ecl_csr_ertn_e;
   
   dp_mux3ds #(1) crmd_ie_mux(
      .dout   (crmd_ie_nxt),
      .in0    (crmd_ie_wdata),
      .in1    (1'b0),
      .in2    (prmd_pie),
      .sel0_l (crmd_ie_mux_sel_wdata_l),
      .sel1_l (crmd_ie_mux_sel_zero_l),
      .sel2_l (crmd_ie_mux_sel_prmdpie_l));
         
   dffrle_ns #(1) crmd_ie_reg (
      .din   (crmd_ie_nxt),
      .rst_l (resetn),
      .en    (crmd_ie_msk_wen | exception | ecl_csr_ertn_e),
      .clk   (clk),
      .q     (crmd_ie));
      //.se(), .si(), .so());
   

   // CRMD.plv

   wire               crmd_plv_msk_wen;
   assign crmd_plv_msk_wen = |csr_mask[`CRMD_PLV] & crmd_wen; // plv 2bits
   
   wire [1:0]         crmd_plv;
   wire [1:0]         crmd_plv_wdata;
   wire [1:0]         crmd_plv_nxt;

   assign crmd_plv_wdata = csr_wdata[`CRMD_PLV];

//   dp_mux2es #(2) crmd_plv_mux(
//      .dout (crmd_plv_nxt),
//      .in0  (crmd_plv_wdata),
//      .in1  (2'b0),
//      .sel  (exception));

   wire crmd_plv_mux_sel_wdata_l;
   wire crmd_plv_mux_sel_zero_l;
   wire crmd_plv_mux_sel_prmdpplv_l;

   assign crmd_plv_mux_sel_wdata_l = ~crmd_wen;
   assign crmd_plv_mux_sel_zero_l = ~exception;
   assign crmd_plv_mux_sel_prmdpplv_l = ~ecl_csr_ertn_e;
  
   dp_mux3ds #(2) crmd_plv_mux(
      .dout   (crmd_plv_nxt),
      .in0    (crmd_plv_wdata),
      .in1    (2'b0),
      .in2    (prmd_pplv),
      .sel0_l (crmd_plv_mux_sel_wdata_l),
      .sel1_l (crmd_plv_mux_sel_zero_l),
      .sel2_l (crmd_plv_mux_sel_prmdpplv_l));
   
   dffrle_ns #(2) crmd_plv_reg (
      .din   (crmd_plv_nxt),
      .rst_l (resetn),
      .en    (crmd_plv_msk_wen | exception | ecl_csr_ertn_e),
      .clk   (clk),
      .q     (crmd_plv));
      //.se(), .si(), .so());

   
   assign crmd = {
		 29'b0,
		 crmd_ie,
		 crmd_plv
		 };


   //
   //  PRMD 0x1
   //

   wire [31:0]        prmd;
   wire               prmd_wen;
   assign prmd_wen = (csr_waddr == `LCSR_PRMD) && csr_wen;

   wire               prmd_pie_msk_wen;
   assign prmd_pie_msk_wen = csr_mask[`LPRMD_PIE] & prmd_wen;

   assign prmd_pie_wdata = csr_wdata[`LPRMD_PIE];

   dp_mux2es #(1) prmd_pie_mux(
      .dout (prmd_pie_nxt),
      .in0  (prmd_pie_wdata),
      .in1  (crmd_ie),
      .sel  (exception));
   
   dffrle_ns #(1) prmd_pie_reg (
      .din   (prmd_pie_nxt),
      .rst_l (resetn),
      .en    (prmd_pie_msk_wen | exception),
      .clk   (clk),
      .q     (prmd_pie));
      //.se(), .si(), .so());



   wire prmd_pplv_msk_wen;
   assign prmd_pplv_msk_wen = |csr_mask[`LPRMD_PPLV] & prmd_wen;

   assign prmd_pplv_wdata = csr_wdata[`LPRMD_PPLV];

   dp_mux2es #(2) prmd_pplv_mux(
      .dout (prmd_pplv_nxt),
      .in0  (prmd_pplv_wdata),
      .in1  (crmd_plv),
      .sel  (exception));

   dffrle_ns #(2) prmd_pplv_reg (
      .din   (prmd_pplv_nxt),
      .rst_l (resetn),
      .en    (prmd_pplv_msk_wen | exception),
      .clk   (clk),
      .q     (prmd_pplv));
      //.se(), .si(), .so());
   

   assign prmd = {
		 29'b0,
                 prmd_pie,
                 prmd_pplv
		 };



   //
   //  ERA 0x6
   //

   wire [31:0]        era;
   wire [31:0]        era_wdata;
   wire [31:0]        era_nxt;
   wire               era_wen;

   assign era_wen = (csr_waddr == `LCSR_EPC) && csr_wen;  // EPC is ERA

   assign era_wdata = (era & (~csr_mask)) | (csr_wdata & csr_mask);

   dp_mux2es #(32) era_mux(
      .dout (era_nxt),
      .in0  (era_wdata),
      .in1  (ifu_exu_pc_e),
      .sel  (exception));

   dffrle_ns #(32) era_reg (
      .din   (era_nxt),
      .rst_l (resetn),
      .en    (era_wen | exception),
      .clk   (clk),
      .q     (era));
      //.se(), .si(), .so());
   
   assign csr_era = era;


   //
   // BADV 0x7
   //

   wire [31:0]        badv;
   wire [31:0]        badv_wdata;
   wire [31:0]        badv_nxt;
   wire               badv_wen;

   assign badv_wen = (csr_waddr == `LCSR_BADV) && csr_wen;

   assign badv_wdata = (badv & (~csr_mask)) | (csr_wdata & csr_mask);


   dp_mux2es #(32) badv_mux(
      .dout (badv_nxt),
      .in0  (badv_wdata),
      .in1  (ecl_csr_badv_e),
      .sel  (exception));  // illinst does not set BADV, later consider this. code review 

   dffrle_ns #(32) badv_reg (
      .din   (badv_nxt),
      .rst_l (resetn),
      .en    (badv_wen | exception),
      .clk   (clk),
      .q     (badv));
      //.se(), .si(), .so());
   


   //
   //  EENTRY 0xc
   //

   wire [31:0]        eentry;
   wire [31:0]        eentry_nxt;
   wire               eentry_wen;

   //assign eentry_nxt = csr_wdata;
   assign eentry_nxt = (eentry & (~csr_mask)) | (csr_wdata & csr_mask);
   assign eentry_wen = (csr_waddr == `LCSR_EBASE) && csr_wen; // EBASE is EENTRY

   dffrle_ns #(32) eentry_reg (
      .din   (eentry_nxt),
      .rst_l (resetn),
      .en    (eentry_wen),
      .clk   (clk),
      .q     (eentry));
      //.se(), .si(), .so());

   assign csr_eentry = eentry;


   //
   // TCFG  0x41
   //

   wire [31:0]        tcfg;
   wire               tcfg_wen;
   
   assign tcfg_wen = (csr_waddr == `LCSR_TCFG) && csr_wen;



   // TCFG.EN
   

   wire               tcfg_en_msk_wen;
   assign tcfg_en_msk_wen = csr_mask[`LTCFG_EN] && tcfg_wen;

   wire               tcfg_en; 
   wire               tcfg_en_nxt;

   assign tcfg_en_nxt = csr_wdata[`LTCFG_EN];

   dffrle_ns #(1) tcfg_en_reg (
      .din   (tcfg_en_nxt),
      .rst_l (resetn),
      .en    (tcfg_en_msk_wen),
      .clk   (clk),
      .q     (tcfg_en));
      //.se(), .si(), .so());


   // TCFG.PERIODIC
   wire               tcfg_periodic_msk_wen;
   assign tcfg_periodic_msk_wen = csr_mask[`LTCFG_PERIODIC] && tcfg_wen;

   wire               tcfg_periodic; 
   wire               tcfg_periodic_nxt;

   assign tcfg_periodic_nxt = csr_wdata[`LTCFG_PERIODIC];

   dffrle_ns #(1) tcfg_periodic_reg (
      .din   (tcfg_periodic_nxt),
      .rst_l (resetn),
      .en    (tcfg_periodic_msk_wen),
      .clk   (clk),
      .q     (tcfg_periodic));
      //.se(), .si(), .so());


   // TCFG.INITVAL
  
   wire [`TIMER_BIT-1:0]          tcfg_initval;
   wire [`TIMER_BIT-1:0]          tcfg_initval_nxt;
   wire                           tcfg_initval_msk_wen;
   
   assign tcfg_initval_msk_wen = (|csr_mask[`TIMER_BIT-1:2]) && tcfg_wen;
   assign tcfg_initval_nxt = (tcfg_initval & (~csr_mask[`TIMER_BIT-1:2])) | (csr_wdata[`TIMER_BIT-1:2] & csr_mask[`TIMER_BIT-1:2]);

   dffrle_ns #(`TIMER_BIT) tcfg_initval_reg (
      .din   (tcfg_initval_nxt),
      .rst_l (resetn),
      .en    (tcfg_initval_msk_wen),
      .clk   (clk),
      .q     (tcfg_initval));
      //.se(), .si(), .so());


   assign tcfg = {
	         //32-`TIMER_BIT-2'b0,
	         tcfg_initval,
		 tcfg_periodic,
		 tcfg_en
		 };


   wire timer_intr;
   wire [`TIMER_BIT+2-1:0] timeval;
   
   cpu7_csr_timer u_csr_timer(
      .clk                             (clk),
      .resetn                          (resetn),
      .init                            (tcfg_wen), // every tcfg write consider an init
      .en                              (tcfg_en_msk_wen ? tcfg_en_nxt : tcfg_en),  // write data not latched yet
      .periodic                        (tcfg_periodic_msk_wen ? tcfg_periodic_nxt : tcfg_periodic),
      .initval                         (tcfg_initval_msk_wen ? tcfg_initval_nxt : tcfg_initval),
      .timeval                         (timeval),
      .intr                            (timer_intr)
   );



   //
   // TVAL  0x42
   //

   wire [31:0]        tval;

   assign tval = {
                 //32-`TIMER_BIT'b0,
	         timeval
	         };
	         

   //
   // TICLR  0x44
   //

   wire [31:0]        ticlr;
   wire               ticlr_wen;

   assign ticlr = 32'b0; // manual says ticlr always read out all 0
   assign ticlr_wen = (csr_waddr == `LCSR_TICLR) && csr_wen;   

   wire               ticlr_clr;
   wire               ticlr_clr_nxt;
   wire               ticlr_clr_en;

   wire clear_timer;

   assign clear_timer = csr_wdata[`LTICLR_CLR] & csr_mask[`LTICLR_CLR] &  ticlr_wen;

   assign ticlr_clr_nxt = timer_intr | (~clear_timer);
   assign ticlr_clr_en = timer_intr | clear_timer;

   dffre_ns #(1) ticlr_clr_reg (
      .din (ticlr_clr_nxt),
      .en  (ticlr_clr_en),
      .clk (clk),
      .rst (~resetn),
      .q   (ticlr_clr));
      //.se(), .si(), .so());


   //assign csr_ecl_timer_intr = ticlr_clr & crmd_ie;
   assign csr_ecl_timer_intr = ticlr_clr;



   //
   // ESTAT 0x5
   //
   
   wire [31:0] estat;
   wire               estat_wen;
   assign estat_wen = (csr_waddr == `LCSR_ESTAT) && csr_wen;

   wire               estat_sis_msk_wen;
   assign estat_sis_msk_wen = |csr_mask[`LESTAT_SIS] & estat_wen;

   // 1:0
   wire [`LESTAT_SIS] estat_sis_wdata;
   wire [`LESTAT_SIS] estat_sis_nxt;
   wire [`LESTAT_SIS] estat_sis;

   assign estat_sis_wdata = csr_wdata[`LESTAT_SIS];
   assign estat_sis_nxt = (estat_sis & (~csr_mask[`LESTAT_SIS])) | (estat_sis_wdata & csr_mask[`LESTAT_SIS]);

   dffrle_ns #(2) estat_sis_reg (
      .din   (estat_sis_nxt),
      .rst_l (resetn),
      .en    (estat_sis_msk_wen),
      .clk   (clk),
      .q     (estat_sis));
      //.se(), .si(), .so());


   wire [`LESTAT_IS] estat_is;
   assign estat_is = {
                     1'b0,        // ??
                     7'b0,        // HWI1~HWI7
		     ext_intr,    // HWI0
                     ticlr_clr,   // TI
                     1'b0         // IPI
	             };


   wire [`LESTAT_ECODE] estat_ecode;

   // not control data, only for query, no need reset
   //  need reset, if there is no exception happened before, the estat contains x
   dffrle_ns #(6) estat_ecode_reg (
      .din   (ecl_csr_exccode_e),
      .rst_l (resetn),
      .en    (exception),             // interrupt ecode is 0, handled in ecl
      .clk   (clk),
      .q     (estat_ecode));
      //.se(), .si(), .so());


   wire [`LESTAT_ESUBCODE] estat_esubcode;

   // not control data, only for query, no need reset
   //  need reset, if there is no exception happened before, the estat contains x
   dffrle_ns #(9) estat_esubcode_reg (
      .din   (9'b0),
      .rst_l (resetn),
      .en    (exception), 
      .clk   (clk),
      .q     (estat_esubcode));
      //.se(), .si(), .so());

   assign estat = {
                  1'b0, // reserved
                  estat_esubcode,
		  estat_ecode,
		  3'b0, // reserved
		  estat_is,
		  estat_sis
                  };


   //
   //  SELF DEFINED: BSEC (BOOT SECURITY) 0x100
   //

   wire [31:0]        bsec;
   wire [31:0]        bsec_nxt;
   wire               bsec_wen;

   assign bsec_wen = (csr_waddr == `LCSR_BSEC) && csr_wen;

   // bit 0, eeprom flush
   wire              bsec_ef_msk_wen;
   assign bsec_ef_msk_wen = csr_mask[`LBSEC_EF] & bsec_wen;

   wire               bsec_ef;
   wire               bsec_ef_wdata;
   wire               bsec_ef_nxt;

   assign bsec_ef_wdata = csr_wdata[`LBSEC_EF];
   assign bsec_ef_nxt = bsec_ef_wdata | bsec_ef;
   
   dffre_ns #(1) bsec_ef_reg (
      .din (bsec_ef_nxt),
      .en  (bsec_ef_msk_wen),
      .clk (clk),
      .rst (~resetn),
      .q   (bsec_ef));
      //.se(), .si(), .so());

   
   assign bsec = {
		 31'b0,
                 bsec_ef
		 };

   
   assign csr_ecl_crmd_ie = crmd_ie;

   
   assign csr_rdata = {32{csr_raddr == `LCSR_CRMD}}  & crmd   |
		      {32{csr_raddr == `LCSR_PRMD}}  & prmd   |
		      {32{csr_raddr == `LCSR_ESTAT}} & estat  |
		      {32{csr_raddr == `LCSR_EPC}}   & era    |
		      {32{csr_raddr == `LCSR_BADV}}  & badv   |
		      {32{csr_raddr == `LCSR_EBASE}} & eentry |
		      {32{csr_raddr == `LCSR_TCFG}}  & tcfg   |
		      {32{csr_raddr == `LCSR_TVAL}}  & tval   |
		      {32{csr_raddr == `LCSR_TICLR}} & ticlr  |
		      {32{csr_raddr == `LCSR_BSEC}}  & bsec   |
		      32'b0;

endmodule // cpu7_csr
