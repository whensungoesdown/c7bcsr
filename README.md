# c7bcsr — Control and Status Registers of cpu7b

c7bcsr holds the privileged state of the cpu7b LA32R core: current and
previous mode (CRMD/PRMD), exception state (ESTAT/ERA/BADV/EENTRY), the TLB
interface registers (TLBIDX/TLBEHI/TLBELO0/1/ASID/PGD*/TLBRENTRY), the
direct-mapped windows (DMW0/1), the timer (TCFG/TVAL/TICLR), the 64-bit
stable counter (RDTIMEL/RDTIMEH), LLBCTL, SAVE0-3 and two
implementation-specific registers (BSEC, COMPEN).

It is instantiated once, as `u_csr` in `c7bexu` (`c7bexu/rtl/c7bexu.v:738`).
Reads are combinational from `csr_raddr`. Writes and hardware updates take
effect on the clock edge at the end of the cycle in which they are enabled.

```
   EXU D: csr_raddr_d, rdtimel/h_d ------------> read mux ----------> csr_rdata_d
                                                    ^   ^
   EXU M: csr_waddr/wdata/mask/wen_m ---+           |   +-- c7bcsr_counter (64-bit)
                                        v           |
   EXU W: exc_vld_w, exc_code_w,   +---------------------------------------+
          exc_badv_w, pc_w ------->| CRMD PRMD ESTAT ERA BADV EENTRY       |--> eentry / tlbrentry / era
          ertn_vld_w ------------->| TLBIDX TLBEHI TLBELO0/1 ASID PGD*     |--> csr_tlb*, csr_asid  (ITLB/DTLB)
          last_inst_ertn --------->| TLBRENTRY DMW0/1 SAVE0-3 LLBCTL       |--> crmd_plv/da/pg, dmw*_seg
   EXU E/M: tlbrd_vld_e,           | BSEC COMPEN                           |--> csr_lsu_llb, csr_ifu_ic_en*
          tlbsrch_vld_m ---------->| TCFG -> c7bcsr_timer -> TVAL, TICLR   |--> csr_ecl_timer_intr --> pic
   itlb_csr_* / dtlb_csr_* ------->|                                       |
   ext_intr_sync, lsu_csr_llb_* -->+---------------------------------------+
```

## Files

| File | Module | Purpose |
|---|---|---|
| `rtl/c7bcsr.v` | `c7bcsr` | Top: all CSRs, exception/ERTN updates, TLB result capture, read mux |
| `rtl/c7bcsr_timer.v` | `c7bcsr_timer` | Down-counting timer, one-shot or periodic, `intr` output |
| `rtl/c7bcsr_counter.v` | `c7bcsr_counter` | 64-bit free-running counter for RDTIMEL/RDTIMEH |
| `rtl/csr_defs.v` | | CSR addresses (`LCSR_*`), field positions, `TIMER_BIT` = 30 |
| `flist/c7bcsr.flist` | | File list |

Flip-flops and muxes come from `models/swrvr_clib.v` and `models/swrvr_dlib.v`.

## CSR access timing

| Stage | Where | What happens |
|---|---|---|
| D | `csr_raddr_d` | CSR read; `csr_rdata` is captured as `csr_rdata_d`. With `csr_rdtimel_d` / `csr_rdtimeh_d` the counter low/high word is returned instead (`c7bcsr.v:1876-1878`). |
| E | `csr_wdata_e`, `csr_mask_e` | `csr_wdata_e = rs2_data_byp_e`; `csr_mask_e = csr_xchg_e ? rs1_data_byp_e : 32'hFFFFFFFF` (`c7bexu.v:734-735`). |
| M | `csr_*_m` | Write port active (`csr_wen_m`); the register updates at the end of M. The old value (`csr_rdata_m`) goes to `rd_data_m` (`c7bexu.v:927`). |

For most fields the next value is
`(old & ~csr_mask) | (csr_wdata & csr_mask)`, enabled when the address
matches and at least one mask bit of the field is set. Fields that differ
are noted in the register table.

The CSR stall is in `c7bexu_ecl`:

```verilog
csr_stall_in  = csr_vld_e;
csr_stall_ifu = csr_vld_e | csr_stall_q;   // CSR instr in E, and one cycle more
stall_ifu     = lsu_stall_ifu | csr_stall_ifu | div_stall_ifu | tlb_stall_ifu;
```

It works around the missing CSR bypass (`c7bexu_ecl.v:64-81,121`). It blocks
the IFU only; the CSR instruction itself continues (`c7bexu.v:1452-1453`).
`csr_wen_m` is a plain register of `csr_wen_e`, not qualified by `flush` or
an exception in W (`c7bexu.v:1480-1488`).

### Timeline: CSRWR / CSRXCHG

```
cycle          t      t+1    t+2    t+3
stage          D      E      M      W
csr_raddr      CSR    -      -      -
csr_rdata_d    old    -      -      -
csr_vld_e      0      1      0      0
csr_stall_q    0      0      1      0
stall_ifu      0      1      1      0
csr_wen_m      0      0      1      0
CSR value      old    old    old    new
rd_data_m      -      -      old    -
```

- t: the old value is read.
- t+1: write data and mask are taken from the bypassed operands.
- t+2: write enable in M; the new value is stored at the end of the cycle.
- t+3: the new value is readable.

## Register table

Unlisted addresses read 0 (`c7bcsr.v:1838-1865`) and ignore writes. Reset
value is 0 unless stated.

| Addr | Name | Implemented fields | Reset | Behaviour |
|---|---|---|---|---|
| 0x0 | CRMD | PLV[1:0], IE[2], DA[3], PG[4] | 0x8 (DA=1, `c7bcsr.v:279`) | PLV/IE are loaded with `csr_wdata` when any mask bit of the field is set; the 2-bit PLV has no per-bit merge (`c7bcsr.v:189,195`). DA/PG: per-bit mask. Exception: PLV=0, IE=0. ERTN: PLV/IE from PRMD. TLBR: DA=1, PG=0. ERTN in refill context: DA=0, PG=1. DATF/DATM/WE read 0. |
| 0x1 | PRMD | PPLV[1:0], PIE[2] | 0 | Loaded with `csr_wdata` when the field mask is non-zero (`c7bcsr.v:342-376`). Exception: PPLV<=CRMD.PLV, PIE<=CRMD.IE. No PWE. |
| 0x4 | ECFG | LIE[12:0] | LIE = 0x18 | Masked write. LIE bit n enables ESTAT.IS bit n: bit 3 timer, bit 4 external interrupt. Exported as `csr_ecfg_lie` and applied in `c7bexu` before `pic`. Reset enables TI and HWI0 (the LA32R manual specifies 0) so software that never writes ECFG still gets interrupts. VS[18:16] reads 0. |
| 0x5 | ESTAT | SIS[1:0], IS[12:2], Ecode[21:16], EsubCode[30:22] | 0 | Only SIS is writable. IS is read-only. Ecode/EsubCode are loaded on every exception (`c7bcsr.v:1547-1565`), not changed by ERTN. |
| 0x6 | ERA | [31:0] | 0 | Masked write. Loaded on exception (see ERA workaround). |
| 0x7 | BADV | [31:0] | 0 | Masked write. Loaded with `ecl_csr_badv_w` on every exception, including ones that do not define BADV (`c7bcsr.v:469`). |
| 0xC | EENTRY | [31:0] | 0 | Masked write of all 32 bits; the low bits are not read-only (`c7bcsr.v:490`). |
| 0x10 | TLBIDX | INDEX[4:0], I_D[16], PS[29:24], NE[31] | 0 | Masked write per field. I_D is non-standard: 0 = ITLB, 1 = DTLB for TLBRD/TLBSRCH. |
| 0x11 | TLBEHI | VPPN[31:13] | 0 | Masked write. Updated by TLBRD and by TLB exceptions. |
| 0x12 | TLBELO0 | V[0], D[1], PLV[3:2], MAT[5:4], G[6], PPN[27:8] | 0 | Masked write per field; loaded by TLBRD. |
| 0x13 | TLBELO1 | as TLBELO0 | 0 | As TLBELO0. |
| 0x18 | ASID | ASID[9:0], ASIDBITS[23:16] = 10 | 0x000A0000 | Masked write of ASID; loaded by TLBRD. ASIDBITS is a constant. |
| 0x19 | PGDL | BASE[31:12] | 0 | Masked write. Not exported. |
| 0x1A | PGDH | BASE[31:12] | 0 | Masked write. Not exported. |
| 0x1B | PGD | [31:12] | - | Read-only: `BADV[31] ? PGDH : PGDL` (`c7bcsr.v:1206`). |
| 0x30-0x33 | SAVE0-3 | [31:0] | 0 | Masked write. |
| 0x41 | TCFG | En[0], Periodic[1], InitVal | 0 | En/Periodic loaded with `csr_wdata` when the bit's mask is set. InitVal takes only `csr_wdata[29:2]` (`c7bcsr.v:1423-1424`), so TCFG[31:30] read 0. Every TCFG write re-initialises the timer. |
| 0x42 | TVAL | [31:0] | 0 | Read-only, current `timeval`. |
| 0x44 | TICLR | CLR[0] | - | Reads 0. Writing 1 clears the timer pending bit. |
| 0x60 | LLBCTL | ROLLB[0], WCLLB[1], KLO[2] | 0 | WCLLB reads 0; writing 1 clears ROLLB. KLO masked write. |
| 0x88 | TLBRENTRY | [31:0] | 0 | Masked write of all 32 bits. |
| 0x100 | BSEC | EF[0] | 0 | Implementation-specific. `nxt = wdata | ef`: once set, only reset clears it (`c7bcsr.v:1597`). Not exported. |
| 0x101 | COMPEN | IC[0] | 0 | Implementation-specific I-cache enable (`csr_ifu_ic_en`). `csr_ifu_ic_en_pls` pulses in the write cycle when IC toggles (`c7bcsr.v:1829`). |
| 0x180 | DMW0 | PLV0[0], PLV3[3], MAT[5:4], PSEG[27:25], VSEG[31:29] | 0 | Masked write per field. Only PSEG/VSEG are exported. |
| 0x181 | DMW1 | as DMW0 | 0 | As DMW0. |

Not implemented (read 0, write ignored): EUEN (0x2), CPUID
(0x20), TID (0x40), CNTC (0x43), TLBRBADV/TLBRERA/TLBRSAVE/TLBRELO*/TLBREHI/
TLBRPRMD (0x89-0x8F), and the other addresses in `csr_defs.v` not listed
above.

## Exception entry

`exu_csr_except_w` (= `exc_vld_w`) is the exception strobe. In that cycle:

| Register | New value | Source |
|---|---|---|
| CRMD.PLV, CRMD.IE | 0, 0 | `c7bcsr.v:168-225` |
| PRMD.PPLV, PRMD.PIE | old CRMD.PLV, CRMD.IE | `c7bcsr.v:346-378` |
| ESTAT.Ecode / EsubCode | `ecl_csr_exccode_w` / `ecl_csr_excsubcode_w` | `c7bcsr.v:1547-1565` |
| ERA | `pc_w != 0 ? pc_w : early_pc_w`, only if `~exu_csr_last_inst_ertn` | `c7bcsr.v:412-445` |
| BADV | `ecl_csr_badv_w` | `c7bcsr.v:465-476` |
| TLBEHI.VPPN | `ecl_csr_badv_w[31:13]` for Ecode TLBR (0x3F), PIL (0x1), PIS (0x2), PIF (0x3), PME (0x4), PPI (0x7) | `c7bcsr.v:668-681` |
| CRMD.DA, CRMD.PG | 1, 0 (TLBR only) | `c7bcsr.v:262-311` |

The vector is selected in `c7bexu`:
`exu_ifu_isr_addr = (exc_code_w == 6'h3f) ? csr_tlbrentry : csr_eentry`
(`c7bexu.v:947`).

TLB refill context: `csr_tlbrefill_ctx = (ESTAT.Ecode == 6'h3F)`
(`c7bcsr.v:230`). Ecode is registered, so the context becomes 1 one cycle
after the TLBR exception; updates needed in the exception cycle use
`tlbr_exception_w`, decoded from `ecl_csr_exccode_w` (`c7bcsr.v:231`). The
context stays 1 until the next exception, because ERTN does not change
Ecode. It goes to the ITLB/DTLB (`c7bexu.v:563,875`); for example, TLBFILL
writes E=1 in refill context (`c7bifu/rtl/c7bifu.v:433`).

TLBR uses the same PRMD, ERA and BADV as other exceptions; the TLBR save
registers are not implemented.

### ERA workaround

`pc_w` is a plain register of `pc_m` (`c7bexu.v:1172-1176`). When the
exception arrives with a "fake" `vld_e` whose `pc_e` is 0, `pc_w` is 0 when
`exu_csr_except_w` is set (comment `c7bcsr.v:414-421`). Two measures:

- `early_pc_w` stores the last non-zero `pc_w`, and ERA takes it when
  `pc_w == 0` (`c7bcsr.v:423-436`).
- `era_exception_wen = exu_csr_except_w & ~exu_csr_last_inst_ertn`
  (`c7bcsr.v:412`). `exu_csr_last_inst_ertn` registers `ertn_vld_e` whenever
  a valid, non-exception instruction is in E (`c7bexu.v:1540-1545`). An
  exception right after an ERTN (for example a PIF on the ERTN target,
  comment `c7bcsr.v:404-410`) therefore leaves ERA at the ERTN target. All
  other exception fields are still updated.

The RTL marks this as a workaround: "TO FIX this, exc_vld_e should come
alone" (`c7bcsr.v:419`).

CRMD.PLV/IE use `dp_mux3ds` with one-cold selects (`crmd_wen`,
`exu_csr_except_w`, `ecl_csr_ertn_w`). If two are active in the same cycle
the output is X (`models/swrvr_dlib.v:239-243`).

### Timeline: exception entry

Exception carried by the instruction in D at t-1 (IFU exception or
interrupt).

```
cycle              t      t+1    t+2    t+3
exc_vld_e          1      0      0      0
exc_vld_m          0      1      0      0      (LSU ls2/ls3 exceptions merge here)
exc_vld_w          0      0      1      0
exu_ifu_except     0      0      1      0      isr_addr = TLBR ? TLBRENTRY : EENTRY
CRMD.PLV/IE        old    old    old    0/0
PRMD               old    old    old    old CRMD.PLV/IE
ESTAT.Ecode        old    old    old    exc_code_w
ERA / BADV         old    old    old    pc_w (or early_pc_w) / badv_w
TLBEHI (TLB exc)   old    old    old    badv_w[31:13]
DA/PG (TLBR)       old    old    old    1/0
csr_tlbrefill_ctx  old    old    old    Ecode == 0x3F
```

- t+2: `exc_vld_w` updates the CSRs and redirects the IFU.
- t+3: the new values are visible; `csr_tlbrefill_ctx` follows the new Ecode.

## ERTN

In the cycle of `ecl_csr_ertn_w` (= `ertn_vld_w`):

- CRMD.PLV <= PRMD.PPLV, CRMD.IE <= PRMD.PIE (`c7bcsr.v:168-225`).
- If `tlbrefill_ctx`: CRMD.DA <= 0, CRMD.PG <= 1 (`ertn_tlbr_excep`,
  `c7bcsr.v:232,262-311`).
- LLBCTL: KLO=1 clears KLO and keeps ROLLB; KLO=0 clears ROLLB
  (`c7bcsr.v:1298-1326`).
- The return address is `csr_era` (`exu_ifu_ert_addr`, `c7bexu.v:950`),
  also for TLBR.

### Timeline: ERTN

```
cycle                  t      t+1    t+2    t+3    t+4
stage                  D      E      M      W
ertn_vld_e             0      1      0      0      0
ertn_vld_m             0      0      1      0      0
ertn_vld_w             0      0      0      1      0
exu_ifu_ertn           0      0      0      1      0      ert_addr = ERA
exu_csr_last_inst_ertn x      x      1      1      1      (until the next non-exception instr in E)
CRMD.PLV/IE            old    old    old    old    PRMD.PPLV/PIE
CRMD.DA/PG (refill)    old    old    old    old    0/1
LLBCTL                 old    old    old    old    KLO ? KLO=0 : ROLLB=0
```

`ertn_vld_e/m/w` are part of `flush` (`c7bexu.v:966`).

## TLB-related CSRs

The core has a separate ITLB and DTLB. TLBIDX.I_D selects whose outputs
(`itlb_csr_*` or `dtlb_csr_*`) are captured.

TLBRD (`tlbrd_vld_e`, `c7bexu.v:888`), captured at the end of E:

- `e = I_D ? dtlb_csr_tlbidx_e : itlb_csr_tlbidx_e`.
- TLBIDX.NE <= ~e. TLBIDX.PS <= selected PS (not cleared when e=0).
- TLBEHI.VPPN, TLBELO0/1 (G from `*_tlbelo_g` for both) and ASID.ASID <=
  selected values, or 0 when e=0 (`c7bcsr.v:664-666,729-1105`).
- INDEX and I_D unchanged.

TLBSRCH (`tlbsrch_vld_m`, one cycle after `tlbsrch_vld_e`,
`c7bexu.v:894-898`):

- TLBIDX.NE <= ~e of the selected TLB.
- TLBIDX.INDEX <= selected index only on a hit; kept on a miss
  (`c7bcsr.v:609`).

| Field | Priority |
|---|---|
| TLBIDX.NE | TLBSRCH > TLBRD > CSR write (`c7bcsr.v:582-584`) |
| TLBEHI.VPPN | exception > TLBRD > CSR write (`c7bcsr.v:675-678`) |
| other TLB fields | TLBRD > CSR write |

All TLBIDX, TLBEHI, TLBELO0/1 and ASID fields are exported to the ITLB/DTLB.

## Timer (TCFG / TVAL / TICLR)

```verilog
init        = tcfg_wen;                                    // every TCFG write
en          = tcfg_en_msk_wen ? tcfg_en_nxt : tcfg_en;     // write data in write cycle
timeval_nxt = (init & en) | (intr & periodic) ? {initval, 2'b0} : timeval - 1;
                                                           // timeval updates only when en
intr        = ~(|timeval) & en & ~init;
```

(`c7bcsr_timer.v:35-45`, `c7bcsr.v:1446-1455`). `timeval` is 32 bits. In
one-shot mode it wraps from 0 to 0xFFFFFFFF and keeps counting down while
En=1.

The pending bit `ticlr_clr` (`c7bcsr.v:1489-1497`) is set by `intr` and
cleared by a TICLR write with bit 0 = 1; set wins if both happen in one
cycle. It is ESTAT.IS TI and drives `csr_ecl_timer_intr` without IE gating
(`c7bcsr.v:1502`). In `c7bexu`, `csr_timer_intr & csr_crmd_ie & csr_ecfg_lie[3]` goes to the
`pic`, which raises `intr_pulse` while a valid instruction is in D; that
instruction is then sent down as an exception with code 0x00
(`c7bexu.v:1004,1045-1051`, `pic.v:52-71`). The `pic` does not trigger again
until `ertn_vld_w`.

### Timeline: timer interrupt

TCFG written in M at cycle t with En=1, CRMD.IE=1, N = InitVal << 2, a valid
instruction in D at t+N+2.

```
cycle          t     t+1   ..  t+N   t+N+1  t+N+2   t+N+3  t+N+4  t+N+5  t+N+6
csr_wen_m      1     0         0     0      0       0      0      0      0
timeval        x     N     ..  1     0      N/FFFFFFFF ..
intr           0     0         0     1      0       0      0      0      0
ticlr_clr      0     0         0     0      1       1      1      1      1
intr_pulse     0     0         0     0      1       0      0      0      0
exc_vld_e      0     0         0     0      0       1      0      0      0
exc_vld_m      0     0         0     0      0       0      1      0      0
exc_vld_w      0     0         0     0      0       0      0      1      0
CRMD.IE        1     1         1     1      1       1      1      1      0
```

- t: `init` loads `{initval, 2'b0}` at the end of the write cycle; `intr`
  is masked by `~init`.
- t+N+1: `timeval` = 0, `intr` = 1; periodic reloads N, one-shot wraps.
- t+N+2: ESTAT.IS TI = 1; `pic` pulses and the D instruction becomes an
  interrupt exception.
- t+N+5: exception entry; t+N+6: CRMD.IE = 0, ESTAT.Ecode = 0.
- The handler must write TICLR.CLR = 1, otherwise `ticlr_clr` stays 1.

If no valid instruction is in D at t+N+2, `intr_pulse` waits (`pic.v:52`).

## Counter (RDTIMEL / RDTIMEH)

`c7bcsr_counter` is 64 bits, reset to 0, +1 every clock
(`c7bcsr_counter.v:9-16`). With `csr_rdtimel` / `csr_rdtimeh` in D,
`csr_rdata` returns `counter_val[31:0]` / `[63:32]`. There is no TID, so no
counter ID is returned.

## LLBCTL

| Event | ROLLB | KLO |
|---|---|---|
| `lsu_csr_llb_set` | 1 (highest priority) | - |
| `lsu_csr_llb_clr` | 0 | - |
| write WCLLB = 1 | 0 | - |
| ERTN, KLO = 0 | 0 | - |
| ERTN, KLO = 1 | kept | 0 (over a KLO write) |
| write KLO | - | `csr_wdata[2]` |

`csr_lsu_llb = ROLLB` (`c7bcsr.v:1287-1342`).

## DMW0 / DMW1

Each window stores PLV0, PLV3, MAT, PSEG and VSEG at the LA32R positions
(`c7bcsr.v:1723-1732,1813-1822`). Only `csr_dmw{0,1}_pseg` and
`csr_dmw{0,1}_vseg` are outputs (`c7bcsr.v:41-44`); PLV0/PLV3/MAT have no
effect outside the CSR file.

## Interrupt status (ESTAT.IS)

`estat_is[12:2] = {1'b0, 7'b0, ext_intr_sync, ticlr_clr, 1'b0}`
(`c7bcsr.v:1535-1541`):

| ESTAT bit | Content |
|---|---|
| 12, 11:5, 2 | 0 |
| 4 | `ext_intr_sync`, 2-flop synchronised external interrupt level (`c7bexu.v:280-287`), labelled HWI0 |
| 3 | timer pending `ticlr_clr`, labelled TI |

LA32R places HWI0 at ESTAT[2] and TI at ESTAT[11]; this RTL uses [4] and
[3]. ESTAT.SIS is stored and readable but not connected to interrupt logic.

## Interface summary

| Signal | Dir | Description |
|---|---|---|
| `csr_raddr` / `csr_rdata` | in / out | Read port (D), from `csr_raddr_d`, to `csr_rdata_d` |
| `csr_rdtimel` / `csr_rdtimeh` | in | Return counter low/high word |
| `csr_waddr` / `csr_wdata` / `csr_mask` / `csr_wen` | in | Write port (M) |
| `csr_eentry` / `csr_tlbrentry` / `csr_era` | out | Exception, TLB refill and return addresses |
| `exu_csr_except_w` | in | Exception strobe (`exc_vld_w`) |
| `ecl_csr_exccode_w` / `ecl_csr_excsubcode_w` / `ecl_csr_badv_w` | in | Ecode, EsubCode, bad address (W) |
| `ifu_exu_pc_w` | in | PC for ERA (`pc_w`) |
| `ecl_csr_ertn_w` | in | ERTN strobe (`ertn_vld_w`) |
| `exu_csr_last_inst_ertn` | in | Suppress ERA update right after ERTN |
| `lsu_csr_llb_set` / `lsu_csr_llb_clr` / `csr_lsu_llb` | in / out | LL/SC bit |
| `csr_ecl_crmd_ie` | out | CRMD.IE, interrupt gating |
| `csr_crmd_plv` / `csr_crmd_da` / `csr_crmd_pg` | out | Privilege level and translation mode |
| `csr_dmw{0,1}_pseg` / `csr_dmw{0,1}_vseg` | out | DMW segments |
| `csr_ifu_ic_en` / `csr_ifu_ic_en_pls` | out | COMPEN.IC and toggle pulse |
| `csr_ecl_timer_intr` | out | Timer interrupt pending |
| `ext_intr_sync` | in | Synchronised external interrupt (ESTAT.IS) |
| `csr_tlbehi_vppn`, `csr_tlbidx_*`, `csr_tlbelo{0,1}_*`, `csr_asid_asid` | out | TLB CSR fields to ITLB/DTLB |
| `csr_tlbrefill_ctx` | out | ESTAT.Ecode == 0x3F |
| `tlbrd_vld_e` / `tlbsrch_vld_m` | in | TLBRD in E / TLBSRCH result valid |
| `itlb_csr_*` / `dtlb_csr_*` | in | TLBRD/TLBSRCH results (index, vppn, g, ps, e, elo0/1, asid) |
