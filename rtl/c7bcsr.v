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
module c7bcsr (
   input                          clk,
   input                          resetn,
   output [31:0]                  csr_rdata,
   input  [`LCSR_BIT-1:0]         csr_raddr,
   input  [31:0]                  csr_wdata,
   input  [`LCSR_BIT-1:0]         csr_waddr,
   input  [31:0]                  csr_mask,
   input                          csr_wen,
   input                          csr_rdtimel,                     
   input                          csr_rdtimeh,                     

   output [31:0]                  csr_eentry,
   output [31:0]                  csr_era,
   output [31:0]                  csr_tlbrentry,
   input  [31:0]                  ecl_csr_badv_w,
   input                          exu_ifu_except,
   input  [5:0]                   ecl_csr_exccode_w,
   input  [8:0]                   ecl_csr_excsubcode_w, 
   input  [31:0]                  ifu_exu_pc_w,
   input                          ecl_csr_ertn_w,
   input                          lsu_csr_llb_set,
   input                          lsu_csr_llb_clr,

   output                         csr_lsu_llb,
   output                         csr_ecl_crmd_ie,
   output [1:0]                   csr_crmd_plv,
   output                         csr_crmd_da,
   output                         csr_crmd_pg,
   output [2:0]                   csr_dmw0_pseg,
   output [2:0]                   csr_dmw0_vseg,
   output [2:0]                   csr_dmw1_pseg,
   output [2:0]                   csr_dmw1_vseg,
   output                         csr_ifu_ic_en, 
   output                         csr_ifu_ic_en_pls,
   output                         csr_ecl_timer_intr,

   input                          ext_intr_sync,

   output [18:0]                  csr_tlbehi_vppn,

   output                         csr_tlbidx_ne,
   output [5:0]                   csr_tlbidx_ps,
   output                         csr_tlbidx_i_d,
   output [4:0]                   csr_tlbidx_index,

   output [19:0]                  csr_tlbelo0_ppn,
   output                         csr_tlbelo0_g,
   output [1:0]                   csr_tlbelo0_mat,
   output [1:0]                   csr_tlbelo0_plv,
   output                         csr_tlbelo0_d,
   output                         csr_tlbelo0_v,
   
   output [19:0]                  csr_tlbelo1_ppn,
   output                         csr_tlbelo1_g,
   output [1:0]                   csr_tlbelo1_mat,
   output [1:0]                   csr_tlbelo1_plv,
   output                         csr_tlbelo1_d,
   output                         csr_tlbelo1_v,

   output [9:0]                   csr_asid_asid, 

   output                         csr_tlbrefill_ctx,

   input                          tlbrd_vld_e,
   input                          tlbsrch_vld_m,

   // itlb to csr
   input  [4:0]                   itlb_csr_tlbidx_index,
   input  [18:0]                  itlb_csr_tlbehi_vppn,
   input                          itlb_csr_tlbelo_g,
   input  [5:0]                   itlb_csr_tlbidx_ps,
   input                          itlb_csr_tlbidx_e,
   input                          itlb_csr_tlbelo0_v,
   input                          itlb_csr_tlbelo0_d,
   input  [1:0]                   itlb_csr_tlbelo0_mat,
   input  [1:0]                   itlb_csr_tlbelo0_plv,
   input  [19:0]                  itlb_csr_tlbelo0_ppn,
   input                          itlb_csr_tlbelo1_v,
   input                          itlb_csr_tlbelo1_d,
   input  [1:0]                   itlb_csr_tlbelo1_mat,
   input  [1:0]                   itlb_csr_tlbelo1_plv,
   input  [19:0]                  itlb_csr_tlbelo1_ppn,
   input  [9:0]                   itlb_csr_asid_asid,

   // dtlb to csr
   input  [4:0]                   dtlb_csr_tlbidx_index,
   input  [18:0]                  dtlb_csr_tlbehi_vppn,
   input                          dtlb_csr_tlbelo_g,
   input  [5:0]                   dtlb_csr_tlbidx_ps,
   input                          dtlb_csr_tlbidx_e,
   input                          dtlb_csr_tlbelo0_v,
   input                          dtlb_csr_tlbelo0_d,
   input  [1:0]                   dtlb_csr_tlbelo0_mat,
   input  [1:0]                   dtlb_csr_tlbelo0_plv,
   input  [19:0]                  dtlb_csr_tlbelo0_ppn,
   input                          dtlb_csr_tlbelo1_v,
   input                          dtlb_csr_tlbelo1_d,
   input  [1:0]                   dtlb_csr_tlbelo1_mat,
   input  [1:0]                   dtlb_csr_tlbelo1_plv,
   input  [19:0]                  dtlb_csr_tlbelo1_ppn,
   input  [9:0]                   dtlb_csr_asid_asid
   );


   wire [31:0] csr_reg_rdata;

   wire exception;

   assign exception = exu_ifu_except; // when to store era, the timing is decided by ecl

   wire               prmd_pie;
   wire               prmd_pie_wdata;
   wire               prmd_pie_nxt;

   wire [1:0]         prmd_pplv;
   wire [1:0]         prmd_pplv_wdata;
   wire [1:0]         prmd_pplv_nxt;

   wire [`LESTAT_ECODE] estat_ecode;

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
   assign crmd_ie_mux_sel_prmdpie_l = ~ecl_csr_ertn_w;
   
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
      .en    (crmd_ie_msk_wen | exception | ecl_csr_ertn_w),
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
   assign crmd_plv_mux_sel_prmdpplv_l = ~ecl_csr_ertn_w;
  
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
      .en    (crmd_plv_msk_wen | exception | ecl_csr_ertn_w),
      .clk   (clk),
      .q     (crmd_plv));
      //.se(), .si(), .so());


   // `EXC_TLBR 6'h3f
   wire tlbrefill_ctx = estat_ecode == 6'h3f;
   wire tlbr_exception = exception & (ecl_csr_exccode_w == 6'h3f); // estat_ecode is one cycle late
   wire ertn_tlbr_excep = ecl_csr_ertn_w & tlbrefill_ctx;

   assign csr_tlbrefill_ctx = tlbrefill_ctx;

   wire pil_exception = exception & (ecl_csr_exccode_w == 6'h1); // estat_ecode is one cycle late
   wire pis_exception = exception & (ecl_csr_exccode_w == 6'h2); // estat_ecode is one cycle late
   wire pif_exception = exception & (ecl_csr_exccode_w == 6'h3); // estat_ecode is one cycle late
   wire pme_exception = exception & (ecl_csr_exccode_w == 6'h4); // estat_ecode is one cycle late
   wire ppi_exception = exception & (ecl_csr_exccode_w == 6'h7); // estat_ecode is one cycle late

   // CRMD.DA (bit[3]) and CRMD.PG (bit[4])
   // Reset: DA=1, PG=0 (direct mode)
   // On tlb_exception: forced to DA=1, PG=0
   
   wire crmd_da;
   wire crmd_pg;

   wire crmd_da_wen = csr_mask[`CRMD_DA] & crmd_wen;
   wire crmd_pg_wen = csr_mask[`CRMD_PG] & crmd_wen;
   
   // DA next value:
   // - During reset (resetn=0): force 1 (loads on first clock)
   // - TLB refill exception: 1
   // - ERTN from TLB refill: 0
   // - Normal write: csr_wdata
   //wire crmd_da_din = (~resetn)                 ? 1'b1 :
   //                   tlbr_exception            ? 1'b1 :
   //                   ertn_tlbr_excep           ? 1'b0 :
   //                   csr_wdata[`CRMD_DA];

   wire crmd_da_din = tlbr_exception            ? 1'b1 :
                      ertn_tlbr_excep           ? 1'b0 :
                      csr_wdata[`CRMD_DA];

   // Enable: write OR exception OR ERTN from TLB refill OR reset
   //wire crmd_da_en = crmd_da_wen | tlbr_exception | ertn_tlbr_excep | (~resetn);
   wire crmd_da_en = crmd_da_wen | tlbr_exception | ertn_tlbr_excep;

   //// da should be 1'b1 after reset
   //dffe_ns #(1) crmd_da_reg (
   //    .din   (crmd_da_din),
   //    //.rst_l (resetn),
   //    .en    (crmd_da_en),
   //    .clk   (clk),
   //    .q     (crmd_da)
   //);

   dffrle_rstval #(.WIDTH(1), .RST_VAL(1'b1)) crmd_da_reg (
      .clk   (clk),
      .rst_l (resetn),
      .en    (crmd_da_en),
      .din   (crmd_da_din),
      .q     (crmd_da)
   );

   // 同步复位
   //always @(posedge clk) begin
   //   if (!resetn)
   //      crmd_da <= 1'b1;
   //   else if (crmd_da_en)
   //      crmd_da <= crmd_da_din;
   //end

   // 异步复位，低有效，复位值为 1
   //always @(posedge clk or negedge resetn) begin
   //   if (!resetn)
   //      crmd_da <= 1'b1;
   //   else if (crmd_da_en)
   //      crmd_da <= crmd_da_din;
   //end
   
   // PG next value:
   // - TLB refill exception -> 0
   // - ERTN from TLB refill -> 1
   // - normal write -> csr_wdata[PG]
   wire crmd_pg_din = tlbr_exception            ? 1'b0 :
                      ertn_tlbr_excep           ? 1'b1 :
                      csr_wdata[`CRMD_PG];

   wire crmd_pg_en = crmd_pg_wen | tlbr_exception | ertn_tlbr_excep;
   
   dffrle_ns #(1) crmd_pg_reg (
       .din   (crmd_pg_din),
       .rst_l (resetn),
       .en    (crmd_pg_en),
       .clk   (clk),
       .q     (crmd_pg)
   );
   

   assign crmd = {
		 27'b0,
		 crmd_pg,
		 crmd_da,
		 crmd_ie,
		 crmd_plv
		 };

   assign csr_crmd_plv = crmd_plv;


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
   wire era_exception_wen;

   assign era_wen = (csr_waddr == `LCSR_EPC) && csr_wen;  // EPC is ERA
   assign era_wdata = (era & (~csr_mask)) | (csr_wdata & csr_mask);

   //
   // Only record the exception address ifu_exu_pc_w when it is non-zero.
   // This prevents logging exceptions that occur when the pipeline is flushed
   // and no valid instruction is present. For example, a TLBR exception that
   // installs a TLB entry with V=0 will cause a PIF exception on the
   // subsequent fetch. Since the fetch fails, the pipeline PC becomes zero;
   // capturing this exception would be incorrect and should be suppressed.
   //
   assign era_exception_wen = exception & (|ifu_exu_pc_w);

   dp_mux2es #(32) era_mux(
      .dout (era_nxt),
      .in0  (era_wdata),
      .in1  (ifu_exu_pc_w),
      .sel  (exception));

   dffrle_ns #(32) era_reg (
      .din   (era_nxt),
      .rst_l (resetn),
      //.en    (era_wen | exception),
      .en    (era_wen | era_exception_wen),
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
      .in1  (ecl_csr_badv_w),
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
   //  TLBIDX 0x10
   //  Fields:
   //    [31]    NE   (1 bit)  0=valid, 1=invalid
   //    [30]    reserved (0)
   //    [29:24] PS   (6 bits)
   //    [23:17] reserved (0)
   //    [16]    I_D  (1 bit)  0=ITLB, 1=DTLB
   //    [15:5]  reserved (0)
   //    [4:0]   INDEX (5 bits)
   //
   //  On TLBRD instruction:
   //    - NE is set to 0 if the TLB entry at INDEX is valid, else 1.
   //    - PS is set to the page size from the TLB entry.
   //    - INDEX and I_D remain unchanged.
   //
   //  On TLBSRCH instruction:
   //    - Search result index is written to INDEX.
   //    - NE is set to 0 if a match is found, else 1.
   //    - PS and I_D remain unchanged.
   //
   //  Note: TLBRD and TLBSRCH are mutually exclusive in pipeline.
   //
   
   wire [31:0] tlbidx;
   wire        tlbidx_wen;
   assign tlbidx_wen = (csr_waddr == `LCSR_TLBIDX) && csr_wen;
   
   // --------------------------------------------------------------------
   // I_D (bit 16) – writable, not affected by TLBRD/TLBSRCH
   // --------------------------------------------------------------------
   wire        tlbidx_i_d;
   wire        tlbidx_i_d_wen = csr_mask[`TLBIDX_I_D] & tlbidx_wen;
   wire        tlbidx_i_d_in = (tlbidx_i_d & ~csr_mask[`TLBIDX_I_D]) |
                               (csr_wdata[`TLBIDX_I_D] & csr_mask[`TLBIDX_I_D]);
   
   dffrle_ns #(1) tlbidx_i_d_reg (
       .din   (tlbidx_i_d_in),
       .rst_l (resetn),
       .en    (tlbidx_i_d_wen),
       .clk   (clk),
       .q     (tlbidx_i_d)
   );
   
   // --------------------------------------------------------------------
   // PS (bits 29:24) – writable via CSR, or updated by TLBRD
   // --------------------------------------------------------------------
   wire [5:0] tlbidx_ps;
   wire       tlbidx_ps_wen = |csr_mask[`TLBIDX_PS] & tlbidx_wen;
   wire [5:0] tlbidx_ps_wdata = (tlbidx_ps & ~csr_mask[`TLBIDX_PS]) |
                                 (csr_wdata[`TLBIDX_PS] & csr_mask[`TLBIDX_PS]);
   
   // TLBRD reads PS from the TLB entry (selected by I_D)
   wire [5:0] tlbrd_ps_data = tlbidx_i_d ? dtlb_csr_tlbidx_ps : itlb_csr_tlbidx_ps;
   
   wire [5:0] tlbidx_ps_in = tlbrd_vld_e ? tlbrd_ps_data : tlbidx_ps_wdata;
   wire       tlbidx_ps_en  = tlbidx_ps_wen | tlbrd_vld_e;
   
   dffrle_ns #(6) tlbidx_ps_reg (
       .din   (tlbidx_ps_in),
       .rst_l (resetn),
       .en    (tlbidx_ps_en),
       .clk   (clk),
       .q     (tlbidx_ps)
   );
   
   // --------------------------------------------------------------------
   // NE (bit 31) – writable via CSR, or updated by TLBRD/TLBSRCH
   // --------------------------------------------------------------------
   wire        tlbidx_ne;
   wire        tlbidx_ne_wen = csr_mask[`TLBIDX_NE] & tlbidx_wen;
   wire        tlbidx_ne_wdata = csr_wdata[`TLBIDX_NE] & csr_mask[`TLBIDX_NE];
   
   // Common NE data: 0 if selected TLB entry is valid, else 1
   // Works for both TLBRD (reads entry at INDEX) and TLBSRCH (uses search result)
   wire tlb_ne_data = ~(tlbidx_i_d ? dtlb_csr_tlbidx_e : itlb_csr_tlbidx_e);
   
   // Priority: TLBSRCH → TLBRD → CSR write
   wire        tlbidx_ne_in = tlbsrch_vld_m ? tlb_ne_data :
                              (tlbrd_vld_e  ? tlb_ne_data :
                              tlbidx_ne_wdata);
   wire        tlbidx_ne_en = tlbidx_ne_wen | tlbrd_vld_e | tlbsrch_vld_m;
   
   dffrle_ns #(1) tlbidx_ne_reg (
       .din   (tlbidx_ne_in),
       .rst_l (resetn),
       .en    (tlbidx_ne_en),
       .clk   (clk),
       .q     (tlbidx_ne)
   );

   // --------------------------------------------------------------------
   // INDEX (bits 4:0) – writable via CSR, or updated by TLBSRCH
   // --------------------------------------------------------------------
   wire [4:0] tlbidx_index;
   wire       tlbidx_index_wen = |csr_mask[`TLBIDX_INDEX] & tlbidx_wen;
   wire [4:0] tlbidx_index_wdata = (tlbidx_index & ~csr_mask[`TLBIDX_INDEX]) |
                                    (csr_wdata[`TLBIDX_INDEX] & csr_mask[`TLBIDX_INDEX]);
   
   // TLBSRCH writes the search result index (selected by I_D)
   wire [4:0] tlbsrch_index_data = tlbidx_i_d ? dtlb_csr_tlbidx_index : itlb_csr_tlbidx_index;
   wire [4:0] tlbidx_index_in = tlbsrch_vld_m ? tlbsrch_index_data : tlbidx_index_wdata;
   //wire       tlbidx_index_en = tlbidx_index_wen | tlbsrch_vld_m;
   //                                                 if no valid tlbentry
   //                                                 found, index remains
   wire       tlbidx_index_en = tlbidx_index_wen | (tlbsrch_vld_m & ~tlb_ne_data);
   
   dffrle_ns #(5) tlbidx_index_reg (
       .din   (tlbidx_index_in),
       .rst_l (resetn),
       .en    (tlbidx_index_en),
       .clk   (clk),
       .q     (tlbidx_index)
   );
   
   // --------------------------------------------------------------------
   // Concatenate into full 32-bit register
   // --------------------------------------------------------------------
   assign tlbidx = {
       tlbidx_ne,      // [31]
       1'b0,           // [30] reserved
       tlbidx_ps,      // [29:24]
       7'b0,           // [23:17] reserved
       tlbidx_i_d,     // [16]
       11'b0,          // [15:5] reserved
       tlbidx_index    // [4:0]
   };

   assign csr_tlbidx_ne = tlbidx_ne;
   assign csr_tlbidx_ps = tlbidx_ps;
   assign csr_tlbidx_i_d = tlbidx_i_d;
   assign csr_tlbidx_index = tlbidx_index;


   //
   //  TLBEHI 0x11
   //  Fields:
   //    [31:13] VPPN  (19 bits, virtual paired page number)
   //    [12:0]  reserved (0)
   //
   //  On TLBRD instruction:
   //    - If TLBIDX.I_D == 0: read from ITLB VPPN (if valid)
   //    - If TLBIDX.I_D == 1: read from DTLB VPPN (if valid)
   //    - If selected entry is invalid, VPPN is cleared to 0.
   //
   //  On TLB-related exceptions (tlbr, pil, pis, pif, pme, ppi):
   //    - VPPN is updated with badv[31:13] (faulting virtual address page number).
   //
   
   wire [31:0] tlbehi;
   wire        tlbehi_wen;
   assign tlbehi_wen = (csr_waddr == `LCSR_TLBEHI) && csr_wen;
   
   // ---------- VPPN (bits 31:13) ----------
   wire [18:0] tlbehi_vppn;
   wire        tlbehi_vppn_wen = |csr_mask[`TLBEHI_VPPN] & tlbehi_wen;
   
   // TLBRD read data: select ITLB or DTLB based on TLBIDX.I_D,
   // and clear if selected entry is invalid.
   wire [18:0] tlbrd_vppn_data;
   assign tlbrd_vppn_data = tlbidx_i_d ? 
                            (dtlb_csr_tlbidx_e ? dtlb_csr_tlbehi_vppn : 19'b0) :
                            (itlb_csr_tlbidx_e ? itlb_csr_tlbehi_vppn : 19'b0);
   
   wire tlbehi_exception_wr = tlbr_exception | pil_exception | pis_exception |
                               pif_exception | pme_exception | ppi_exception;

   // VPPN input: normal CSR write or TLBRD read (with invalid clearing)
   wire [18:0] tlbehi_vppn_in;
   assign tlbehi_vppn_in = tlbehi_exception_wr ? badv[31:13] :
                           tlbrd_vld_e ? tlbrd_vppn_data :
                           ((tlbehi_vppn & ~csr_mask[`TLBEHI_VPPN]) |
                            (csr_wdata[`TLBEHI_VPPN] & csr_mask[`TLBEHI_VPPN]));

   // Write enable: normal CSR write OR TLBRD instruction
   wire tlbehi_vppn_en = tlbehi_vppn_wen | tlbrd_vld_e | tlbehi_exception_wr;
   
   dffrle_ns #(19) tlbehi_vppn_reg (
       .din   (tlbehi_vppn_in),
       .rst_l (resetn),
       .en    (tlbehi_vppn_en),
       .clk   (clk),
       .q     (tlbehi_vppn)
   );
   
   // ---------- Concatenate into full 32-bit register ----------
   assign tlbehi = {
       tlbehi_vppn,   // [31:13]
       13'b0          // [12:0] reserved
   };

   assign csr_tlbehi_vppn = tlbehi_vppn;

   
   //
   //  TLBELO0 0x12
   //  Fields:
   //    [31:28] reserved (0)
   //    [27:8]  PPN  (20 bits)
   //    [7]     reserved (0)
   //    [6]     G    (1 bit)
   //    [5:4]   MAT  (2 bits)
   //    [3:2]   PLV  (2 bits)
   //    [1]     D    (1 bit)
   //    [0]     V    (1 bit)
   //
   //  On TLBRD instruction:
   //    - If TLBIDX.I_D == 0: read from ITLB
   //    - If TLBIDX.I_D == 1: read from DTLB
   //    - If selected entry invalid (V=0), all fields are cleared.
   //
   
   wire [31:0] tlbelo0;
   wire        tlbelo0_wen;
   assign tlbelo0_wen = (csr_waddr == `LCSR_TLBELO0) && csr_wen;
   
   // ---------- PPN (bits 27:8) ----------
   wire [19:0] tlbelo0_ppn;
   wire        tlbelo0_ppn_wen = |csr_mask[`TLBELO_PPN] & tlbelo0_wen;
   
   // TLBRD read data: select ITLB or DTLB based on TLBIDX.I_D,
   // and clear if selected entry is invalid.
   wire [19:0] tlbrd_tlbelo0_ppn_data;
   assign tlbrd_tlbelo0_ppn_data = tlbidx_i_d ?
                           (dtlb_csr_tlbidx_e ? dtlb_csr_tlbelo0_ppn : 20'b0) :
                           (itlb_csr_tlbidx_e ? itlb_csr_tlbelo0_ppn : 20'b0);
   
   // PPN input: normal CSR write or TLBRD read
   wire [19:0] tlbelo0_ppn_in;
   assign tlbelo0_ppn_in = tlbrd_vld_e ? tlbrd_tlbelo0_ppn_data :
                           ((tlbelo0_ppn & ~csr_mask[`TLBELO_PPN]) |
                            (csr_wdata[`TLBELO_PPN] & csr_mask[`TLBELO_PPN]));
   
   wire tlbelo0_ppn_en = tlbelo0_ppn_wen | tlbrd_vld_e;
   
   dffrle_ns #(20) tlbelo0_ppn_reg (
       .din   (tlbelo0_ppn_in),
       .rst_l (resetn),
       .en    (tlbelo0_ppn_en),
       .clk   (clk),
       .q     (tlbelo0_ppn)
   );
   
   // ---------- G (bit 6) ----------
   wire        tlbelo0_g;
   wire        tlbelo0_g_wen = csr_mask[`TLBELO_G] & tlbelo0_wen;
   
   wire        tlbrd_tlbelo0_g_data;
   assign tlbrd_tlbelo0_g_data = tlbidx_i_d ?
                         (dtlb_csr_tlbidx_e ? dtlb_csr_tlbelo_g : 1'b0) :
                         (itlb_csr_tlbidx_e ? itlb_csr_tlbelo_g : 1'b0);
   
   wire        tlbelo0_g_in;
   assign tlbelo0_g_in = tlbrd_vld_e ? tlbrd_tlbelo0_g_data :
                         ((tlbelo0_g & ~csr_mask[`TLBELO_G]) |
                          (csr_wdata[`TLBELO_G] & csr_mask[`TLBELO_G]));
   
   wire tlbelo0_g_en = tlbelo0_g_wen | tlbrd_vld_e;
   
   dffrle_ns #(1) tlbelo0_g_reg (
       .din   (tlbelo0_g_in),
       .rst_l (resetn),
       .en    (tlbelo0_g_en),
       .clk   (clk),
       .q     (tlbelo0_g)
   );
   
   // ---------- MAT (bits 5:4) ----------
   wire [1:0] tlbelo0_mat;
   wire       tlbelo0_mat_wen = |csr_mask[`TLBELO_MAT] & tlbelo0_wen;
   
   wire [1:0] tlbrd_tlbelo0_mat_data;
   assign tlbrd_tlbelo0_mat_data = tlbidx_i_d ?
                           (dtlb_csr_tlbidx_e ? dtlb_csr_tlbelo0_mat : 2'b0) :
                           (itlb_csr_tlbidx_e ? itlb_csr_tlbelo0_mat : 2'b0);
   
   wire [1:0] tlbelo0_mat_in;
   assign tlbelo0_mat_in = tlbrd_vld_e ? tlbrd_tlbelo0_mat_data :
                           ((tlbelo0_mat & ~csr_mask[`TLBELO_MAT]) |
                            (csr_wdata[`TLBELO_MAT] & csr_mask[`TLBELO_MAT]));
   
   wire tlbelo0_mat_en = tlbelo0_mat_wen | tlbrd_vld_e;
   
   dffrle_ns #(2) tlbelo0_mat_reg (
       .din   (tlbelo0_mat_in),
       .rst_l (resetn),
       .en    (tlbelo0_mat_en),
       .clk   (clk),
       .q     (tlbelo0_mat)
   );
   
   // ---------- PLV (bits 3:2) ----------
   wire [1:0] tlbelo0_plv;
   wire       tlbelo0_plv_wen = |csr_mask[`TLBELO_PLV] & tlbelo0_wen;
   
   wire [1:0] tlbrd_tlbelo0_plv_data;
   assign tlbrd_tlbelo0_plv_data = tlbidx_i_d ?
                           (dtlb_csr_tlbidx_e ? dtlb_csr_tlbelo0_plv : 2'b0) :
                           (itlb_csr_tlbidx_e ? itlb_csr_tlbelo0_plv : 2'b0);
   
   wire [1:0] tlbelo0_plv_in;
   assign tlbelo0_plv_in = tlbrd_vld_e ? tlbrd_tlbelo0_plv_data :
                           ((tlbelo0_plv & ~csr_mask[`TLBELO_PLV]) |
                            (csr_wdata[`TLBELO_PLV] & csr_mask[`TLBELO_PLV]));
   
   wire tlbelo0_plv_en = tlbelo0_plv_wen | tlbrd_vld_e;
   
   dffrle_ns #(2) tlbelo0_plv_reg (
       .din   (tlbelo0_plv_in),
       .rst_l (resetn),
       .en    (tlbelo0_plv_en),
       .clk   (clk),
       .q     (tlbelo0_plv)
   );
   
   // ---------- D (bit 1) ----------
   wire        tlbelo0_d;
   wire        tlbelo0_d_wen = csr_mask[`TLBELO_D] & tlbelo0_wen;
   
   wire        tlbrd_tlbelo0_d_data;
   assign tlbrd_tlbelo0_d_data = tlbidx_i_d ?
                         (dtlb_csr_tlbidx_e ? dtlb_csr_tlbelo0_d : 1'b0) :
                         (itlb_csr_tlbidx_e ? itlb_csr_tlbelo0_d : 1'b0);
   
   wire        tlbelo0_d_in;
   assign tlbelo0_d_in = tlbrd_vld_e ? tlbrd_tlbelo0_d_data :
                         ((tlbelo0_d & ~csr_mask[`TLBELO_D]) |
                          (csr_wdata[`TLBELO_D] & csr_mask[`TLBELO_D]));
   
   wire tlbelo0_d_en = tlbelo0_d_wen | tlbrd_vld_e;
   
   dffrle_ns #(1) tlbelo0_d_reg (
       .din   (tlbelo0_d_in),
       .rst_l (resetn),
       .en    (tlbelo0_d_en),
       .clk   (clk),
       .q     (tlbelo0_d)
   );
   
   // ---------- V (bit 0) ----------
   wire        tlbelo0_v;
   wire        tlbelo0_v_wen = csr_mask[`TLBELO_V] & tlbelo0_wen;
   
   wire        tlbrd_tlbelo0_v_data;
   assign tlbrd_tlbelo0_v_data = tlbidx_i_d ?
                         (dtlb_csr_tlbidx_e ? dtlb_csr_tlbelo0_v : 1'b0) :
                         (itlb_csr_tlbidx_e ? itlb_csr_tlbelo0_v : 1'b0);
   
   wire        tlbelo0_v_in;
   assign tlbelo0_v_in = tlbrd_vld_e ? tlbrd_tlbelo0_v_data :
                         ((tlbelo0_v & ~csr_mask[`TLBELO_V]) |
                          (csr_wdata[`TLBELO_V] & csr_mask[`TLBELO_V]));
   
   wire tlbelo0_v_en = tlbelo0_v_wen | tlbrd_vld_e;
   
   dffrle_ns #(1) tlbelo0_v_reg (
       .din   (tlbelo0_v_in),
       .rst_l (resetn),
       .en    (tlbelo0_v_en),
       .clk   (clk),
       .q     (tlbelo0_v)
   );
   
   // ---------- Concatenate into full 32-bit register ----------
   assign tlbelo0 = {
       4'b0,               // [31:28] reserved
       tlbelo0_ppn,        // [27:8]
       1'b0,               // [7] reserved
       tlbelo0_g,          // [6]
       tlbelo0_mat,        // [5:4]
       tlbelo0_plv,        // [3:2]
       tlbelo0_d,          // [1]
       tlbelo0_v           // [0]
   };

   assign csr_tlbelo0_ppn = tlbelo0_ppn;
   assign csr_tlbelo0_g = tlbelo0_g;
   assign csr_tlbelo0_mat = tlbelo0_mat;
   assign csr_tlbelo0_plv = tlbelo0_plv;
   assign csr_tlbelo0_d = tlbelo0_d;
   assign csr_tlbelo0_v = tlbelo0_v;


   //
   //  TLBELO1 0x13
   //  Fields:
   //    [31:28] reserved (0)
   //    [27:8]  PPN  (20 bits)
   //    [7]     reserved (0)
   //    [6]     G    (1 bit)
   //    [5:4]   MAT  (2 bits)
   //    [3:2]   PLV  (2 bits)
   //    [1]     D    (1 bit)
   //    [0]     V    (1 bit)
   //
   //  On TLBRD instruction:
   //    - If TLBIDX.I_D == 0: read from ITLB
   //    - If TLBIDX.I_D == 1: read from DTLB
   //    - If selected entry invalid (V=0), all fields are cleared.
   //
   
   wire [31:0] tlbelo1;
   wire        tlbelo1_wen;
   assign tlbelo1_wen = (csr_waddr == `LCSR_TLBELO1) && csr_wen;
   
   // ---------- PPN (bits 27:8) ----------
   wire [19:0] tlbelo1_ppn;
   wire        tlbelo1_ppn_wen = |csr_mask[`TLBELO_PPN] & tlbelo1_wen;
   
   // TLBRD read data: select ITLB or DTLB based on TLBIDX.I_D,
   // and clear if selected entry is invalid.
   wire [19:0] tlbrd_tlbelo1_ppn_data;
   assign tlbrd_tlbelo1_ppn_data = tlbidx_i_d ?
                           (dtlb_csr_tlbidx_e ? dtlb_csr_tlbelo1_ppn : 20'b0) :
                           (itlb_csr_tlbidx_e ? itlb_csr_tlbelo1_ppn : 20'b0);
   
   // PPN input: normal CSR write or TLBRD read
   wire [19:0] tlbelo1_ppn_in;
   assign tlbelo1_ppn_in = tlbrd_vld_e ? tlbrd_tlbelo1_ppn_data :
                           ((tlbelo1_ppn & ~csr_mask[`TLBELO_PPN]) |
                            (csr_wdata[`TLBELO_PPN] & csr_mask[`TLBELO_PPN]));
   
   wire tlbelo1_ppn_en = tlbelo1_ppn_wen | tlbrd_vld_e;
   
   dffrle_ns #(20) tlbelo1_ppn_reg (
       .din   (tlbelo1_ppn_in),
       .rst_l (resetn),
       .en    (tlbelo1_ppn_en),
       .clk   (clk),
       .q     (tlbelo1_ppn)
   );
   
   // ---------- G (bit 6) ----------
   wire        tlbelo1_g;
   wire        tlbelo1_g_wen = csr_mask[`TLBELO_G] & tlbelo1_wen;
   
   wire        tlbrd_tlbelo1_g_data;
   assign tlbrd_tlbelo1_g_data = tlbidx_i_d ?
                         (dtlb_csr_tlbidx_e ? dtlb_csr_tlbelo_g : 1'b0) :
                         (itlb_csr_tlbidx_e ? itlb_csr_tlbelo_g : 1'b0);
   
   wire        tlbelo1_g_in;
   assign tlbelo1_g_in = tlbrd_vld_e ? tlbrd_tlbelo1_g_data :
                         ((tlbelo1_g & ~csr_mask[`TLBELO_G]) |
                          (csr_wdata[`TLBELO_G] & csr_mask[`TLBELO_G]));
   
   wire tlbelo1_g_en = tlbelo1_g_wen | tlbrd_vld_e;
   
   dffrle_ns #(1) tlbelo1_g_reg (
       .din   (tlbelo1_g_in),
       .rst_l (resetn),
       .en    (tlbelo1_g_en),
       .clk   (clk),
       .q     (tlbelo1_g)
   );
   
   // ---------- MAT (bits 5:4) ----------
   wire [1:0] tlbelo1_mat;
   wire       tlbelo1_mat_wen = |csr_mask[`TLBELO_MAT] & tlbelo1_wen;
   
   wire [1:0] tlbrd_tlbelo1_mat_data;
   assign tlbrd_tlbelo1_mat_data = tlbidx_i_d ?
                           (dtlb_csr_tlbidx_e ? dtlb_csr_tlbelo1_mat : 2'b0) :
                           (itlb_csr_tlbidx_e ? itlb_csr_tlbelo1_mat : 2'b0);
   
   wire [1:0] tlbelo1_mat_in;
   assign tlbelo1_mat_in = tlbrd_vld_e ? tlbrd_tlbelo1_mat_data :
                           ((tlbelo1_mat & ~csr_mask[`TLBELO_MAT]) |
                            (csr_wdata[`TLBELO_MAT] & csr_mask[`TLBELO_MAT]));
   
   wire tlbelo1_mat_en = tlbelo1_mat_wen | tlbrd_vld_e;
   
   dffrle_ns #(2) tlbelo1_mat_reg (
       .din   (tlbelo1_mat_in),
       .rst_l (resetn),
       .en    (tlbelo1_mat_en),
       .clk   (clk),
       .q     (tlbelo1_mat)
   );
   
   // ---------- PLV (bits 3:2) ----------
   wire [1:0] tlbelo1_plv;
   wire       tlbelo1_plv_wen = |csr_mask[`TLBELO_PLV] & tlbelo1_wen;
   
   wire [1:0] tlbrd_tlbelo1_plv_data;
   assign tlbrd_tlbelo1_plv_data = tlbidx_i_d ?
                           (dtlb_csr_tlbidx_e ? dtlb_csr_tlbelo1_plv : 2'b0) :
                           (itlb_csr_tlbidx_e ? itlb_csr_tlbelo1_plv : 2'b0);
   
   wire [1:0] tlbelo1_plv_in;
   assign tlbelo1_plv_in = tlbrd_vld_e ? tlbrd_tlbelo1_plv_data :
                           ((tlbelo1_plv & ~csr_mask[`TLBELO_PLV]) |
                            (csr_wdata[`TLBELO_PLV] & csr_mask[`TLBELO_PLV]));
   
   wire tlbelo1_plv_en = tlbelo1_plv_wen | tlbrd_vld_e;
   
   dffrle_ns #(2) tlbelo1_plv_reg (
       .din   (tlbelo1_plv_in),
       .rst_l (resetn),
       .en    (tlbelo1_plv_en),
       .clk   (clk),
       .q     (tlbelo1_plv)
   );
   
   // ---------- D (bit 1) ----------
   wire        tlbelo1_d;
   wire        tlbelo1_d_wen = csr_mask[`TLBELO_D] & tlbelo1_wen;
   
   wire        tlbrd_tlbelo1_d_data;
   assign tlbrd_tlbelo1_d_data = tlbidx_i_d ?
                         (dtlb_csr_tlbidx_e ? dtlb_csr_tlbelo1_d : 1'b0) :
                         (itlb_csr_tlbidx_e ? itlb_csr_tlbelo1_d : 1'b0);
   
   wire        tlbelo1_d_in;
   assign tlbelo1_d_in = tlbrd_vld_e ? tlbrd_tlbelo1_d_data :
                         ((tlbelo1_d & ~csr_mask[`TLBELO_D]) |
                          (csr_wdata[`TLBELO_D] & csr_mask[`TLBELO_D]));
   
   wire tlbelo1_d_en = tlbelo1_d_wen | tlbrd_vld_e;
   
   dffrle_ns #(1) tlbelo1_d_reg (
       .din   (tlbelo1_d_in),
       .rst_l (resetn),
       .en    (tlbelo1_d_en),
       .clk   (clk),
       .q     (tlbelo1_d)
   );
   
   // ---------- V (bit 0) ----------
   wire        tlbelo1_v;
   wire        tlbelo1_v_wen = csr_mask[`TLBELO_V] & tlbelo1_wen;
   
   wire        tlbrd_tlbelo1_v_data;
   assign tlbrd_tlbelo1_v_data = tlbidx_i_d ?
                         (dtlb_csr_tlbidx_e ? dtlb_csr_tlbelo1_v : 1'b0) :
                         (itlb_csr_tlbidx_e ? itlb_csr_tlbelo1_v : 1'b0);
   
   wire        tlbelo1_v_in;
   assign tlbelo1_v_in = tlbrd_vld_e ? tlbrd_tlbelo1_v_data :
                         ((tlbelo1_v & ~csr_mask[`TLBELO_V]) |
                          (csr_wdata[`TLBELO_V] & csr_mask[`TLBELO_V]));
   
   wire tlbelo1_v_en = tlbelo1_v_wen | tlbrd_vld_e;
   
   dffrle_ns #(1) tlbelo1_v_reg (
       .din   (tlbelo1_v_in),
       .rst_l (resetn),
       .en    (tlbelo1_v_en),
       .clk   (clk),
       .q     (tlbelo1_v)
   );
   
   // ---------- Concatenate into full 32-bit register ----------
   assign tlbelo1 = {
       4'b0,               // [31:28] reserved
       tlbelo1_ppn,        // [27:8]
       1'b0,               // [7] reserved
       tlbelo1_g,          // [6]
       tlbelo1_mat,        // [5:4]
       tlbelo1_plv,        // [3:2]
       tlbelo1_d,          // [1]
       tlbelo1_v           // [0]
   };

   assign csr_tlbelo1_ppn = tlbelo1_ppn;
   assign csr_tlbelo1_g = tlbelo1_g;
   assign csr_tlbelo1_mat = tlbelo1_mat;
   assign csr_tlbelo1_plv = tlbelo1_plv;
   assign csr_tlbelo1_d = tlbelo1_d;
   assign csr_tlbelo1_v = tlbelo1_v;


   //
   //  ASID 0x18
   //  Fields:
   //    [31:24] reserved (0)
   //    [23:16] ASIDBits (8 bits, fixed value 10)
   //    [15:10] reserved (0)
   //    [9:0]   ASID (10 bits)
   //
   //  On TLBRD instruction:
   //    - ASID is read from ITLB or DTLB based on TLBIDX.I_D.
   //    - If the selected entry is invalid (e=0), ASID is cleared to 0.
   //    - ASIDBits is a constant and not affected by TLBRD.
   //
   
   wire [31:0] asid;
   wire        asid_wen;
   assign asid_wen = (csr_waddr == `LCSR_ASID) && csr_wen;
   
   // ---------- ASID (bits 9:0) ----------
   wire [9:0] asid_asid;
   wire       asid_asid_wen = |csr_mask[`ASID_ASID] & asid_wen;
   
   // TLBRD read data: select ITLB or DTLB based on TLBIDX.I_D,
   // and clear if selected entry is invalid.
   wire [9:0] tlbrd_asid_data;
   assign tlbrd_asid_data = tlbidx_i_d ?
                            (dtlb_csr_tlbidx_e ? dtlb_csr_asid_asid : 10'b0) :
                            (itlb_csr_tlbidx_e ? itlb_csr_asid_asid : 10'b0);
   
   // ASID input: normal CSR write or TLBRD read
   wire [9:0] asid_asid_in;
   assign asid_asid_in = tlbrd_vld_e ? tlbrd_asid_data :
                         ((asid_asid & ~csr_mask[`ASID_ASID]) |
                          (csr_wdata[`ASID_ASID] & csr_mask[`ASID_ASID]));
   
   wire asid_asid_en = asid_asid_wen | tlbrd_vld_e;
   
   dffrle_ns #(10) asid_asid_reg (
       .din   (asid_asid_in),
       .rst_l (resetn),
       .en    (asid_asid_en),
       .clk   (clk),
       .q     (asid_asid)
   );
   
   // ---------- ASIDBits (bits 23:16) - constant 10 ----------
   wire [7:0] asid_asidbits = 8'd10;
   
   // ---------- Concatenate into full 32-bit register ----------
   assign asid = {
       8'b0,               // [31:24] reserved
       asid_asidbits,      // [23:16]
       6'b0,               // [15:10] reserved
       asid_asid           // [9:0]
   };

   assign csr_asid_asid = asid_asid;

   //
   //  PGDL 0x19
   //  Fields:
   //    [31:12] BASE  (20 bits)
   //    [11:0]  reserved (0)
   //
   
   wire [31:0] pgdl;
   wire        pgdl_wen;
   assign pgdl_wen = (csr_waddr == `LCSR_PGDL) && csr_wen;
   
   // ---------- BASE (bits 31:12) ----------
   wire [19:0] pgdl_base;
   wire        pgdl_base_wen = |csr_mask[`PGDL_BASE] & pgdl_wen;
   wire [19:0] pgdl_base_in = (pgdl_base & ~csr_mask[`PGDL_BASE]) |
                              (csr_wdata[`PGDL_BASE] & csr_mask[`PGDL_BASE]);
   
   dffrle_ns #(20) pgdl_base_reg (
       .din   (pgdl_base_in),
       .rst_l (resetn),
       .en    (pgdl_base_wen),
       .clk   (clk),
       .q     (pgdl_base)
   );
   
   // ---------- Concatenate into full 32-bit register ----------
   assign pgdl = {
       pgdl_base,   // [31:12]
       12'b0        // [11:0] reserved
   };


   //
   //  PGDH 0x1a
   //  Fields:
   //    [31:12] BASE  (20 bits)
   //    [11:0]  reserved (0)
   //
   
   wire [31:0] pgdh;
   wire        pgdh_wen;
   assign pgdh_wen = (csr_waddr == `LCSR_PGDH) && csr_wen;
   
   // ---------- BASE (bits 31:12) ----------
   wire [19:0] pgdh_base;
   wire        pgdh_base_wen = |csr_mask[`PGDH_BASE] & pgdh_wen;
   wire [19:0] pgdh_base_in = (pgdh_base & ~csr_mask[`PGDH_BASE]) |
                              (csr_wdata[`PGDH_BASE] & csr_mask[`PGDH_BASE]);
   
   dffrle_ns #(20) pgdh_base_reg (
       .din   (pgdh_base_in),
       .rst_l (resetn),
       .en    (pgdh_base_wen),
       .clk   (clk),
       .q     (pgdh_base)
   );
   
   // ---------- Concatenate into full 32-bit register ----------
   assign pgdh = {
       pgdh_base,   // [31:12]
       12'b0        // [11:0] reserved
   };


   //
   //  PGD 0x1b
   //

   wire [31:0] pgd;

   assign pgd = badv[31] ? pgdh : pgdl;


   //
   //  SAVE0 0x30
   //

   wire [31:0]        save0;
   wire [31:0]        save0_nxt;
   wire               save0_wen;

   assign save0_nxt = (save0 & (~csr_mask)) | (csr_wdata & csr_mask);
   assign save0_wen = (csr_waddr == `LCSR_SAVE0) && csr_wen;

   dffrle_ns #(32) save0_reg (
      .din   (save0_nxt),
      .rst_l (resetn),
      .en    (save0_wen),
      .clk   (clk),
      .q     (save0));


   //
   //  SAVE1 0x31
   //

   wire [31:0]        save1;
   wire [31:0]        save1_nxt;
   wire               save1_wen;

   assign save1_nxt = (save1 & (~csr_mask)) | (csr_wdata & csr_mask);
   assign save1_wen = (csr_waddr == `LCSR_SAVE1) && csr_wen;

   dffrle_ns #(32) save1_reg (
      .din   (save1_nxt),
      .rst_l (resetn),
      .en    (save1_wen),
      .clk   (clk),
      .q     (save1));

   //
   //  SAVE2 0x32
   //

   wire [31:0]        save2;
   wire [31:0]        save2_nxt;
   wire               save2_wen;

   assign save2_nxt = (save2 & (~csr_mask)) | (csr_wdata & csr_mask);
   assign save2_wen = (csr_waddr == `LCSR_SAVE2) && csr_wen;

   dffrle_ns #(32) save2_reg (
      .din   (save2_nxt),
      .rst_l (resetn),
      .en    (save2_wen),
      .clk   (clk),
      .q     (save2));

   //
   //  SAVE3 0x33
   //

   wire [31:0]        save3;
   wire [31:0]        save3_nxt;
   wire               save3_wen;

   assign save3_nxt = (save3 & (~csr_mask)) | (csr_wdata & csr_mask);
   assign save3_wen = (csr_waddr == `LCSR_SAVE3) && csr_wen;

   dffrle_ns #(32) save3_reg (
      .din   (save3_nxt),
      .rst_l (resetn),
      .en    (save3_wen),
      .clk   (clk),
      .q     (save3));


   //
   // LLBCTL  0x60
   //

   wire [31:0]        llbctl;
   wire               llbctl_wen;
   
   assign llbctl_wen = (csr_waddr == `LCSR_LLBCTL) && csr_wen;

   // LLBCTL.KLO
   wire llbctl_klo;
   wire llbctl_klo_nxt;
   
   wire llbctl_klo_msk_wen = csr_mask[`LLBCTL_KLO] && llbctl_wen;
   
   wire klo_auto_clear = ecl_csr_ertn_w && llbctl_klo;
   
   assign llbctl_klo_nxt = klo_auto_clear ? 1'b0 :
                           (llbctl_klo_msk_wen ? csr_wdata[`LLBCTL_KLO] :
                            llbctl_klo);
   
   dffrl_ns #(1) llbctl_klo_reg (
      .din   (llbctl_klo_nxt),
      .rst_l (resetn),
      .clk   (clk),
      .q     (llbctl_klo)
   );

   // LLBCTL.ROLLB
   // LLBCTL.WCLLB
   
   wire llbctl_rollb; 
   wire llbctl_rollb_nxt;

   wire llbctl_wcllb_msk_wen = csr_mask[`LLBCTL_WCLLB] && llbctl_wen;

   wire rollb_clr = lsu_csr_llb_clr ||
                   (llbctl_wcllb_msk_wen && csr_wdata[`LLBCTL_WCLLB]) ||
                   (ecl_csr_ertn_w && !llbctl_klo);

   wire rollb_set = lsu_csr_llb_set;

   assign llbctl_rollb_nxt = rollb_set ? 1'b1 :
                          (rollb_clr ? 1'b0 : llbctl_rollb);

   dffrl_ns #(1) llbctl_rollb_reg (
      .din   (llbctl_rollb_nxt),
      .rst_l (resetn),
      .clk   (clk),
      .q     (llbctl_rollb));


   assign llbctl = {
	         29'b0, 
	         llbctl_klo,
		 1'b0,        // WCLLB
		 llbctl_rollb
	 };

   assign csr_lsu_llb = llbctl_rollb;


   //
   //  TLBRENTRY 0x88
   //

   wire [31:0]        tlbrentry;
   wire [31:0]        tlbrentry_nxt;
   wire               tlbrentry_wen;

   assign tlbrentry_nxt = (tlbrentry & (~csr_mask)) | (csr_wdata & csr_mask);
   assign tlbrentry_wen = (csr_waddr == `LCSR_TLBREBASE) && csr_wen; // TLBREBASE aka TLBRENTRY

   dffrle_ns #(32) tlbrentry_reg (
      .din   (tlbrentry_nxt),
      .rst_l (resetn),
      .en    (tlbrentry_wen),
      .clk   (clk),
      .q     (tlbrentry));
      //.se(), .si(), .so());

   assign csr_tlbrentry = tlbrentry;



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
   
   c7bcsr_timer u_csr_timer(
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
		     ext_intr_sync, // HWI0
                     ticlr_clr,   // TI
                     1'b0         // IPI
	             };



   // not control data, only for query, no need reset
   //  need reset, if there is no exception happened before, the estat contains x
   dffrle_ns #(6) estat_ecode_reg (
      .din   (ecl_csr_exccode_w),
      .rst_l (resetn),
      .en    (exception),             // interrupt ecode is 0, handled in ecl
      .clk   (clk),
      .q     (estat_ecode));
      //.se(), .si(), .so());


   wire [`LESTAT_ESUBCODE] estat_esubcode;

   // not control data, only for query, no need reset
   //  need reset, if there is no exception happened before, the estat contains x
   dffrle_ns #(9) estat_esubcode_reg (
      .din   (ecl_csr_excsubcode_w),
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
   
   dffrle_ns #(1) bsec_ef_reg (
      .din (bsec_ef_nxt),
      .en  (bsec_ef_msk_wen),
      .clk (clk),
      .rst_l (resetn),
      .q   (bsec_ef));
      //.se(), .si(), .so());

   
   assign bsec = {
		 31'b0,
                 bsec_ef
		 };

   //
   //  SELF DEFINED: COMPEN (COMPONENT ENABLE) 0x101
   //

   wire [31:0]        compen;
   wire               compen_wen;

   assign compen_wen = (csr_waddr == `LCSR_COMPEN) && csr_wen;

   // bit 0, icache enable
   wire              compen_ic_msk_wen;
   assign compen_ic_msk_wen = csr_mask[`LCOMPEN_IC] & compen_wen;

   wire               compen_ic;
   wire               compen_ic_wdata;
   wire               compen_ic_nxt;

   assign compen_ic_wdata = csr_wdata[`LCOMPEN_IC];
   assign compen_ic_nxt = compen_ic_wdata;
   
   dffrle_ns #(1) compen_ic_reg (
      .din (compen_ic_nxt),
      .en  (compen_ic_msk_wen),
      .clk (clk),
      .rst_l (resetn),
      .q   (compen_ic));

   
   assign compen = {
		 31'b0,
                 compen_ic
		 };


   //
   //  DMW0 0x180
   //

   wire [31:0] dmw0;
   wire dmw0_wen;
   assign dmw0_wen = (csr_waddr == `LCSR_DMW0) && csr_wen;

   wire dmw0_plv0;
   wire dmw0_plv3;
   wire [1:0] dmw0_mat;
   wire [2:0] dmw0_pseg;
   wire [2:0] dmw0_vseg;

   wire dmw0_plv0_wen = csr_mask[`LDMW_PLV0] & dmw0_wen;
   wire dmw0_plv3_wen = csr_mask[`LDMW_PLV3] & dmw0_wen;
   wire dmw0_mat_wen = |csr_mask[`LDMW_MAT] & dmw0_wen;
   wire dmw0_pseg_wen = |csr_mask[`LDMW_PSEG] & dmw0_wen;
   wire dmw0_vseg_wen = |csr_mask[`LDMW_VSEG] & dmw0_wen;


   wire dmw0_plv0_in;
   assign dmw0_plv0_in = csr_wdata[`LDMW_PLV0] & csr_mask[`LDMW_PLV0];

   dffrle_ns #(1) dmw0_plv0_reg (
      .din   (dmw0_plv0_in),
      .rst_l (resetn),
      .en    (dmw0_plv0_wen),
      .clk   (clk),
      .q     (dmw0_plv0));


   wire dmw0_plv3_in;
   assign dmw0_plv3_in = csr_wdata[`LDMW_PLV3] & csr_mask[`LDMW_PLV3];

   dffrle_ns #(1) dmw0_plv3_reg (
      .din   (dmw0_plv3_in),
      .rst_l (resetn),
      .en    (dmw0_plv3_wen),
      .clk   (clk),
      .q     (dmw0_plv3));
   

   wire [1:0] dmw0_mat_in;
   assign dmw0_mat_in = (dmw0_mat & (~csr_mask[`LDMW_MAT])) | (csr_wdata[`LDMW_MAT] & csr_mask[`LDMW_MAT]);

   dffrle_ns #(2) dmw0_mat_reg (
      .din   (dmw0_mat_in),
      .rst_l (resetn),
      .en    (dmw0_mat_wen),
      .clk   (clk),
      .q     (dmw0_mat));


   wire [2:0] dmw0_pseg_in;
   assign dmw0_pseg_in = (dmw0_pseg & (~csr_mask[`LDMW_PSEG])) | (csr_wdata[`LDMW_PSEG] & csr_mask[`LDMW_PSEG]);

   dffrle_ns #(3) dmw0_pseg_reg (
      .din   (dmw0_pseg_in),
      .rst_l (resetn),
      .en    (dmw0_pseg_wen),
      .clk   (clk),
      .q     (dmw0_pseg));


   wire [2:0] dmw0_vseg_in;
   assign dmw0_vseg_in = (dmw0_vseg & (~csr_mask[`LDMW_VSEG])) | (csr_wdata[`LDMW_VSEG] & csr_mask[`LDMW_VSEG]);

   dffrle_ns #(3) dmw0_vseg_reg (
      .din   (dmw0_vseg_in),
      .rst_l (resetn),
      .en    (dmw0_vseg_wen),
      .clk   (clk),
      .q     (dmw0_vseg));
   

   assign dmw0 = {
                 dmw0_vseg,
                 1'b0,
                 dmw0_pseg,
                 19'b0,  
                 dmw0_mat,
                 dmw0_plv3,
                 2'b0,
                 dmw0_plv0
                 };

   assign csr_dmw0_pseg = dmw0_pseg;
   assign csr_dmw0_vseg = dmw0_vseg;

   //
   //  DMW1 0x181
   //

   wire [31:0] dmw1;
   wire dmw1_wen;
   assign dmw1_wen = (csr_waddr == `LCSR_DMW1) && csr_wen;

   wire dmw1_plv0;
   wire dmw1_plv3;
   wire [1:0] dmw1_mat;
   wire [2:0] dmw1_pseg;
   wire [2:0] dmw1_vseg;

   wire dmw1_plv0_wen = csr_mask[`LDMW_PLV0] & dmw1_wen;
   wire dmw1_plv3_wen = csr_mask[`LDMW_PLV3] & dmw1_wen;
   wire dmw1_mat_wen = |csr_mask[`LDMW_MAT] & dmw1_wen;
   wire dmw1_pseg_wen = |csr_mask[`LDMW_PSEG] & dmw1_wen;
   wire dmw1_vseg_wen = |csr_mask[`LDMW_VSEG] & dmw1_wen;


   wire dmw1_plv0_in;
   assign dmw1_plv0_in = csr_wdata[`LDMW_PLV0] & csr_mask[`LDMW_PLV0];

   dffrle_ns #(1) dmw1_plv0_reg (
      .din   (dmw1_plv0_in),
      .rst_l (resetn),
      .en    (dmw1_plv0_wen),
      .clk   (clk),
      .q     (dmw1_plv0));


   wire dmw1_plv3_in;
   assign dmw1_plv3_in = csr_wdata[`LDMW_PLV3] & csr_mask[`LDMW_PLV3];

   dffrle_ns #(1) dmw1_plv3_reg (
      .din   (dmw1_plv3_in),
      .rst_l (resetn),
      .en    (dmw1_plv3_wen),
      .clk   (clk),
      .q     (dmw1_plv3));
   

   wire [1:0] dmw1_mat_in;
   assign dmw1_mat_in = (dmw1_mat & (~csr_mask[`LDMW_MAT])) | (csr_wdata[`LDMW_MAT] & csr_mask[`LDMW_MAT]);

   dffrle_ns #(2) dmw1_mat_reg (
      .din   (dmw1_mat_in),
      .rst_l (resetn),
      .en    (dmw1_mat_wen),
      .clk   (clk),
      .q     (dmw1_mat));


   wire [2:0] dmw1_pseg_in;
   assign dmw1_pseg_in = (dmw1_pseg & (~csr_mask[`LDMW_PSEG])) | (csr_wdata[`LDMW_PSEG] & csr_mask[`LDMW_PSEG]);

   dffrle_ns #(3) dmw1_pseg_reg (
      .din   (dmw1_pseg_in),
      .rst_l (resetn),
      .en    (dmw1_pseg_wen),
      .clk   (clk),
      .q     (dmw1_pseg));


   wire [2:0] dmw1_vseg_in;
   assign dmw1_vseg_in = (dmw1_vseg & (~csr_mask[`LDMW_VSEG])) | (csr_wdata[`LDMW_VSEG] & csr_mask[`LDMW_VSEG]);

   dffrle_ns #(3) dmw1_vseg_reg (
      .din   (dmw1_vseg_in),
      .rst_l (resetn),
      .en    (dmw1_vseg_wen),
      .clk   (clk),
      .q     (dmw1_vseg));
   

   assign dmw1 = {
                 dmw1_vseg,
                 1'b0,
                 dmw1_pseg,
                 19'b0,  
                 dmw1_mat,
                 dmw1_plv3,
                 2'b0,
                 dmw1_plv0
                 };
   
   assign csr_dmw1_pseg = dmw1_pseg;
   assign csr_dmw1_vseg = dmw1_vseg;


   // both rising edge and falling edge
   assign csr_ifu_ic_en_pls = ((compen_ic_nxt & ~compen_ic) | (~compen_ic_nxt & compen_ic)) & compen_ic_msk_wen; 


   assign csr_ecl_crmd_ie = crmd_ie;
   assign csr_crmd_da = crmd_da;
   assign csr_crmd_pg = crmd_pg;
   assign csr_ifu_ic_en = compen_ic;


   assign csr_reg_rdata = {32{csr_raddr == `LCSR_CRMD}}     & crmd   |
                          {32{csr_raddr == `LCSR_PRMD}}     & prmd   |
                          {32{csr_raddr == `LCSR_ESTAT}}    & estat  |
                          {32{csr_raddr == `LCSR_EPC}}      & era    |
                          {32{csr_raddr == `LCSR_BADV}}     & badv   |
                          {32{csr_raddr == `LCSR_EBASE}}    & eentry |
                          {32{csr_raddr == `LCSR_TCFG}}     & tcfg   |
                          {32{csr_raddr == `LCSR_TVAL}}     & tval   |
                          {32{csr_raddr == `LCSR_TICLR}}    & ticlr  |
                          {32{csr_raddr == `LCSR_BSEC}}     & bsec   |
                          {32{csr_raddr == `LCSR_COMPEN}}   & compen |
                          {32{csr_raddr == `LCSR_SAVE0}}    & save0  |
                          {32{csr_raddr == `LCSR_SAVE1}}    & save1  |
                          {32{csr_raddr == `LCSR_SAVE2}}    & save2  |
                          {32{csr_raddr == `LCSR_SAVE3}}    & save3  |
                          {32{csr_raddr == `LCSR_LLBCTL}}   & llbctl |
                          {32{csr_raddr == `LCSR_TLBREBASE}}& tlbrentry|
                          {32{csr_raddr == `LCSR_DMW0}}     & dmw0   |
                          {32{csr_raddr == `LCSR_DMW1}}     & dmw1   |
                          {32{csr_raddr == `LCSR_TLBIDX}}   & tlbidx |
                          {32{csr_raddr == `LCSR_TLBEHI}}   & tlbehi |
                          {32{csr_raddr == `LCSR_TLBELO0}}  & tlbelo0|
                          {32{csr_raddr == `LCSR_TLBELO1}}  & tlbelo1|
                          {32{csr_raddr == `LCSR_PGDL}}     & pgdl   |
                          {32{csr_raddr == `LCSR_PGDH}}     & pgdh   |
                          {32{csr_raddr == `LCSR_PGD}}      & pgd    |
                          {32{csr_raddr == `LCSR_ASID}}     & asid   |
                          32'b0;


   wire [63:0] counter_val;

   c7bcsr_counter u_counter(
      .clk                             (clk),
      .resetn                          (resetn),
      .counter_val                     (counter_val)
   );

   assign csr_rdata = {32{~(csr_rdtimel | csr_rdtimeh)}} & csr_reg_rdata      |
	              {32{csr_rdtimel}}                  & counter_val[31:0]  |
	              {32{csr_rdtimeh}}                  & counter_val[63:32] 
		      ;

endmodule // cpu7_csr
