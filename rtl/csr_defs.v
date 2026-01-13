`define LCSR_BIT           14
`define LCSR_CRMD          `LCSR_BIT'h0_0_0_0
`define LCSR_PRMD          `LCSR_BIT'h0_0_0_1
`define LCSR_EUEN          `LCSR_BIT'h0_0_0_2
`define LCSR_MISC          `LCSR_BIT'h0_0_0_3  //
`define LCSR_ECTL          `LCSR_BIT'h0_0_0_4
`define LCSR_ESTAT         `LCSR_BIT'h0_0_0_5  //
`define LCSR_EPC           `LCSR_BIT'h0_0_0_6
`define LCSR_BADV          `LCSR_BIT'h0_0_0_7
`define LCSR_BADI          `LCSR_BIT'h0_0_0_8
`define LCSR_EBASE         `LCSR_BIT'h0_0_0_C
`define LCSR_INDEX         `LCSR_BIT'h0_0_1_0
`define LCSR_TLBEHI        `LCSR_BIT'h0_0_1_1
`define LCSR_TLBELO0       `LCSR_BIT'h0_0_1_2
`define LCSR_TLBELO1       `LCSR_BIT'h0_0_1_3
`define LCSR_ASID          `LCSR_BIT'h0_0_1_8
`define LCSR_PGDL          `LCSR_BIT'h0_0_1_9
`define LCSR_PGDH          `LCSR_BIT'h0_0_1_A
`define LCSR_PGD           `LCSR_BIT'h0_0_1_B
`define LCSR_PWCL          `LCSR_BIT'h0_0_1_C
`define LCSR_PWCH          `LCSR_BIT'h0_0_1_D
`define LCSR_STLBPS        `LCSR_BIT'h0_0_1_E
`define LCSR_RVACFG        `LCSR_BIT'h0_0_1_F
`define LCSR_CPUNUM        `LCSR_BIT'h0_0_2_0
`define LCSR_PRCFG1        `LCSR_BIT'h0_0_2_1
`define LCSR_PRCFG2        `LCSR_BIT'h0_0_2_2
`define LCSR_PRCFG3        `LCSR_BIT'h0_0_2_3
`define LCSR_SAVE0         `LCSR_BIT'h0_0_3_0
`define LCSR_SAVE1         `LCSR_BIT'h0_0_3_1
`define LCSR_SAVE2         `LCSR_BIT'h0_0_3_2
`define LCSR_SAVE3         `LCSR_BIT'h0_0_3_3
`define LCSR_SAVE4         `LCSR_BIT'h0_0_3_4
`define LCSR_SAVE5         `LCSR_BIT'h0_0_3_5
`define LCSR_SAVE6         `LCSR_BIT'h0_0_3_6
`define LCSR_SAVE7         `LCSR_BIT'h0_0_3_7
`define LCSR_TID           `LCSR_BIT'h0_0_4_0
`define LCSR_TCFG          `LCSR_BIT'h0_0_4_1
`define LCSR_TVAL          `LCSR_BIT'h0_0_4_2
`define LCSR_CNTC          `LCSR_BIT'h0_0_4_3
`define LCSR_TICLR         `LCSR_BIT'h0_0_4_4
`define LCSR_LLBCTL        `LCSR_BIT'h0_0_6_0
`define LCSR_IMPCTL1       `LCSR_BIT'h0_0_8_0 //
`define LCSR_IMPCTL2       `LCSR_BIT'h0_0_8_1 //
`define LCSR_TLBREBASE     `LCSR_BIT'h0_0_8_8
`define LCSR_TLBRBADV      `LCSR_BIT'h0_0_8_9
`define LCSR_TLBREPC       `LCSR_BIT'h0_0_8_A
`define LCSR_TLBRSAVE      `LCSR_BIT'h0_0_8_B
`define LCSR_TLBRELO0      `LCSR_BIT'h0_0_8_C //
`define LCSR_TLBRELO1      `LCSR_BIT'h0_0_8_D //
`define LCSR_TLBREHI       `LCSR_BIT'h0_0_8_E
`define LCSR_TLBRPRMD      `LCSR_BIT'h0_0_8_F
`define LCSR_ERRCTL        `LCSR_BIT'h0_0_9_0
`define LCSR_ERRINFO1      `LCSR_BIT'h0_0_9_1
`define LCSR_ERRINFO2      `LCSR_BIT'h0_0_9_2
`define LCSR_ERREBASE      `LCSR_BIT'h0_0_9_3
`define LCSR_ERREPC        `LCSR_BIT'h0_0_9_4
`define LCSR_ERRSAVE       `LCSR_BIT'h0_0_9_5
`define LCSR_CTAG          `LCSR_BIT'h0_0_9_8 //
`define LCSR_DMW0          `LCSR_BIT'h0_1_8_0
`define LCSR_DMW1          `LCSR_BIT'h0_1_8_1
`define LCSR_PMCFG0        `LCSR_BIT'h0_2_0_0
`define LCSR_PMCNT0        `LCSR_BIT'h0_2_0_1

`define LCSR_DBG           `LCSR_BIT'h0_5_0_0 //
`define LCSR_DEPC          `LCSR_BIT'h0_5_0_1 //
`define LCSR_DSAVE         `LCSR_BIT'h0_5_0_2 //

// self defined
`define LCSR_BSEC          `LCSR_BIT'h0_1_0_0 //


//// CSR
// CRMD 0x0_0_0
`define CRMD_WE    9
`define CRMD_DATM  8:7
`define CRMD_DATF  6:5
`define CRMD_PG    4
`define CRMD_DA    3
`define CRMD_IE    2
`define CRMD_PLV   1:0

// CRMD 0x0_0_1
`define LPRMD_PWE    3
`define LPRMD_PIE    2
`define LPRMD_PPLV   1:0


// TID 0x0_4_0
`define LTID_TID 31:0

// TCFG 0x0_4_1
`define LTCFG_EN       0
`define LTCFG_PERIODIC 1
//`define LSOC1K_TCFG_INITVAL  31:2

`define TIMER_BIT            30		

// TVAL 0x0_4_2
`define LTVAL_TIMEVAL 31:0

// CNTC 0x0_4_3
`define LCNTC_COMPENSATION 63:0

// TICLR 0x0_4_4
`define LTICLR_CLR 0


// EUEN 0x0_0_2
`define LSOC1K_EUEN_BTE    3
`define LSOC1K_EUEN_ASXE   2
`define LSOC1K_EUEN_SXE    1
`define LSOC1K_EUEN_FPE    0

// MISC 0x0_0_3
`define LSOC1K_MISC_DWPL2    18
`define LSOC1K_MISC_DWPL1    17
`define LSOC1K_MISC_DWPL0    16
`define LSOC1K_MISC_ALCL3    15
`define LSOC1K_MISC_ALCL2    14
`define LSOC1K_MISC_ALCL1    13
`define LSOC1K_MISC_ALCL0    12
`define LSOC1K_MISC_RPCNTL3  11
`define LSOC1K_MISC_RPCNTL2  10
`define LSOC1K_MISC_RPCNTL1   9
`define LSOC1K_MISC_DRDTL3    7
`define LSOC1K_MISC_DRDTL2    6
`define LSOC1K_MISC_DRDTL1    5
`define LSOC1K_MISC_VA32L3    3
`define LSOC1K_MISC_VA32L2    2
`define LSOC1K_MISC_VA32L1    1

// ECTL 0x0_0_4
`define LSOC1K_ECTL_VS  18:16
`define LSOC1K_ECTL_LIE 12:0

// ESTAT 0x0_0_5
`define LESTAT_ESUBCODE 30:22
`define LESTAT_ECODE    21:16
`define LESTAT_IS       12: 2
`define LESTAT_SIS       1: 0

// BADI 0x0_0_8
`define LSOC1K_BADI_INST 31:0

// EBASE 0x0_0_C
`ifdef LA64
`define LSOC1K_EBASE_EBASE 63:12
`elsif LA32
`define LSOC1K_EBASE_EBASE 31:6
`endif

// INDEX 0x0_1_0
`define LSOC1K_INDEX_NP    31
`define LSOC1K_INDEX_PS    29:24
`define LSOC1K_INDEX_INDEX `TLB_IDXBITS-1: 0

// ENTRYHI 0x0_1_1
`define LSOC1K_TLBEHI_VPN2 `VABITS-1:13

// csr 0x12/0x13 EntryLo0, EntryLo1
`define LSOC1K_TLBELO_RPLV         63
`define LSOC1K_TLBELO_NX           62
`define LSOC1K_TLBELO_NR           61
`ifdef GS264C_64BIT
  `define LSOC1K_TLBELO_PFN        `PABITS-1:12
`else
  `define LSOC1K_TLBELO_PFN        31:8
`endif
`define LSOC1K_TLBELO_G            6
`define LSOC1K_TLBELO_MAT          5: 4
`define LSOC1K_TLBELO_PLV          3: 2
`define LSOC1K_TLBELO_WE           1
`define LSOC1K_TLBELO_V            0

// ASID 0x0_1_8  
`define LSOC1K_ASID_ASIDBITS       23:16
`define LSOC1K_ASID_ASID            9: 0

// PGDL 0x0_1_9
`define LSOC1K_PGDL_BASE 31:12

// PGDH 0x0_1_A
`define LSOC1K_PGDH_BASE 31:12

// PGD 0x0_1_B
`define LSOC1K_PGD_BASE  31:12

// PWCL 0x0_1_C 
`define LSOC1K_PWCL_PTBASE      4: 0
`define LSOC1K_PWCL_PTWIDTH     9: 5
`define LSOC1K_PWCL_DIR1_BASE  14:10
`define LSOC1K_PWCL_DIR1_WIDTH 19:15
`define LSOC1K_PWCL_DIR2_BASE  24:20
`define LSOC1K_PWCL_DIR2_WIDTH 29:25
`define LSOC1K_PWCL_PTEWIDTH   31:30

// PWCH 0x0_1_D
`define LSOC1K_PWCH_PTBASE      4: 0
`define LSOC1K_PWCH_PTWIDTH     9: 5
`define LSOC1K_PWCH_DIR1_BASE  14:10
`define LSOC1K_PWCH_DIR1_WIDTH 19:15
`define LSOC1K_PWCH_DIR2_BASE  24:20
`define LSOC1K_PWCH_DIR2_WIDTH 29:25
`define LSOC1K_PWCH_PTEWIDTH   31:30

// FTLB PageSize 0x0_1_E
`define LSOC1K_STLBPS_PS      5: 0

// RVACFG 0x0_1_F
`define LSOC1K_RVACFG_RBITS     3: 0

// CPUNUM 0x0_2_0
`define LSOC1K_CPUNUM_COREID    8: 0

// PRCFG1 0x0_2_1
`define LSOC1K_PRCFG1_SAVENUM   3 : 0
`define LSOC1K_PRCFG1_TIMERBITS 11: 4
`define LSOC1K_PRCFG1_VSMAX     14:12

// PRCFG2 0x0_2_2

// PRCFG3 0x0_2_3
`define LSOC1K_PRCFG3_TLBTYPE     3 : 0
`define LSOC1K_PRCFG3_MTLBENTRIES 11: 4
`define LSOC1K_PRCFG3_STLBWAYS    19:12
`define LSOC1K_PRCFG3_STLBSETS    25:20

// LLBCTL 0x0_6_0
`define LSOC1K_LLBCTL_ROLLB     0
`define LSOC1K_LLBCTL_WCLLB     1
`define LSOC1K_LLBCTL_KLO       2


// TLBREBASE 0x0_8_8
`ifdef GS264C_64BIT
  `define LSOC1K_TLBREBASE_EBASE `PABITS-1:12
`else
  `define LSOC1K_TLBREBASE_EBASE 31:6
`endif

// TLBREPC 0x0_8_A
`define LSOC1K_TLBREPC_ISTLBR 0
`define LSOC1K_TLBREPC_EPC    63:2

// TLBRPRMD 0x0_8_F
`define LSOC1K_TLBRPRMD_PPLV 1:0
`define LSOC1K_TLBRPRMD_PIE  2
`define LSOC1K_TLBRPRMD_PWE  4

// ERRCTL 0x0_9_0
`define LSOC1K_ERRCTL_ISERR       0
`define LSOC1K_ERRCTL_REPAIRABLE  1
`define LSOC1K_ERRCTL_PPLV        3:2
`define LSOC1K_ERRCTL_PIE         4
`define LSOC1K_ERRCTL_PWE         6
`define LSOC1K_ERRCTL_PDA         7
`define LSOC1K_ERRCTL_PPG         8
`define LSOC1K_ERRCTL_PDATF      10:9
`define LSOC1K_ERRCTL_PDATM      12:11
`define LSOC1K_ERRCTL_CAUSE      23:16

// ERREBASE 0x0_9_3
`define LSOC1K_ERREBASE_EBASE    `PABITS-1:12

// ERREPC 0x0_9_4
`define LSOC1K_ERREPC_EPC        63:0

// DMWIN 0x1_8_0 - 0x1_8_1
`define LSOC1K_DMW_PLV0 0
`define LSOC1K_DMW_PLV1 1
`define LSOC1K_DMW_PLV2 2
`define LSOC1K_DMW_PLV3 3
`define LSOC1K_DMW_MAT  5:4
`ifdef GS264C_64BIT
  `define LSOC1K_DMW_VSEG 63:56
`else
  `define LSOC1K_DMW_PSEG 27:25
  `define LSOC1K_DMW_VSEG 31:29
`endif 

// PMCFG 0x2_0_0 + 2N
`define LSOC1K_PMCFG_EVENT  9:0
`define LSOC1K_PMCFG_PLV0   16
`define LSOC1K_PMCFG_PLV1   17
`define LSOC1K_PMCFG_PLV2   18
`define LSOC1K_PMCFG_PLV3   19
`define LSOC1K_PMCFG_IE     20

// PMCNT 0x2_0_1 + 2N
`define LSOC1K_PMCNT_COUNT  63:0


// BSEC (BOOT SECURITY) 0x1_0_0
`define LBSEC_EF       0
