# RASM observations -- questions for the author

Two behaviours observed while building a CPC Plus cartridge project with
RASM. Both are cases where RASM accepts input silently and produces
something that looks right but is not usable, so they may be bugs, may be
missing cartridge-mode support, or may be intended behaviour we have
misread. Written up as self-contained reproductions so they can be
checked without our project.

**Environment**

- RASM v3.2.7 (build 16/08/2026) -- "Atlas", upstream commit `b222469`.
  Both notes were first written against v3.2.5 (build 01/06/2026) and
  re-checked against v3.2.7 on 2026-08-23: both still reproduce, with
  output unchanged between the two versions. Note 1 emits the same five
  operands listed below; note 2's three variants produce byte-identical
  `.cpr` files (md5 `c740d5ff4f49fe8fa449f439fcff5acc`), so
  `LOCALISATION` in a numbered bank affects no output path at all.
- Linux x86-64
- Target: Amstrad CPC Plus / GX4000 cartridge (`.cpr`), `BUILDCPR`
  cartridge mode with numbered banks throughout

**Status**

Both notes are open as far as upstream is concerned -- nothing has been
reported or offered to the author yet. Both have a candidate fix in our
fork (`../rasm/`, `https://github.com/fstollar/rasm`), each developed on
its own branch with a folder-based regression case per behaviour, and
each also published as a single commit based on `upstream/master`:

| Note | Fix branch | PR-shaped branch | What it changes |
|---|---|---|---|
| 1 | `fix/page-buildcpr` | `pr/page-buildcpr` | `{PAGE}`/`{PAGESET}` raise an error in cartridge mode instead of silently emitting a RAM-banking value. Covered by four new entries in RASM's own `-autotest` suite. |
| 2 | `fix/localisation-numbered-bank` | `pr/localisation-numbered-bank` | The cartridge label and breakpoint export honours `LOCALISATION` for a numbered bank, as the snapshot path already did. |

The branches are local to that checkout so far -- not pushed, not merged,
no upstream PR.

Each note below is a complete, copy-pasteable source plus the exact
command and the observed output.

---

## Note 1: `{PAGE}` under `BUILDCPR` returns a RAM-expansion config

### Summary

In cartridge mode, `{PAGE}` returns Gate Array **RAM banking**
configuration values (`&7Fxx`, `%11bbbccc`). For a cartridge those values
are not usable: they page RAM, not the cartridge ROM page the label lives
in. RASM emits them with no warning.

### Reproduction

```asm
        buildcpr symbol
        bank 0
        org 0x0000
        ld bc,{page}b1
        ld bc,{page}b5
        ld bc,{page}b7
        ld bc,{page}b8
        ld bc,{page}b31
        ld a,{bank}b5
        bank 1
        org 0xC000
b1:     nop
        bank 5
        org 0xC000
b5:     nop
        bank 7
        org 0xC000
b7:     nop
        bank 8
        org 0xC000
b8:     nop
        bank 31
        org 0xC000
b31:    nop
```

```
rasm p.asm -oc p.cpr -void
```

### Observed

Assembles cleanly, no warning. The emitted operands are:

| Label in bank | `{page}` operand | Bit pattern |
|---|---|---|
| 1 | `0x7FC0` | `%11 000 000` |
| 5 | `0x7FC5` | `%11 000 101` |
| 7 | `0x7FC7` | `%11 000 111` |
| 8 | `0x7FCC` | `%11 001 100` |
| 31 | `0x7FF7` | `%11 110 111` |

`{bank}b5` correctly yields `5`.

### Why those values do not work for a cartridge

On CPC Plus hardware there are two ways to page cartridge ROM, and
`%11xxxxxx` on `&7Fxx` is neither:

- **Upper ROM** (`#C000-#FFFF`) is selected through the `&DFxx` port, not
  `&7Fxx` at all.
- **Lower ROM** (`#0000`/`#4000`/`#8000`) is selected through RMR2, which
  *is* on `&7Fxx` but is a different register, selected by **D7=1, D6=0,
  D5=1** (`%101xxxxx`), with the ROM page number in D2-D0. The values
  above have **D6=1**, which selects the Gate Array's RAM configuration
  function instead.

So the emitted value targets the right port for RMR2 but the wrong
register, and at runtime it reconfigures RAM rather than connecting the
named cartridge ROM page. The failure is silent: no crash, just wrong
memory mapped, which is expensive to debug.

The values look consistent with `{PAGE}` computing a RAM page
configuration from the bank index -- which is exactly right in
`BUILDSNA` mode, where banks *are* RAM banks. Our reading is that
`{PAGE}` is a snapshot-mode feature that has no meaningful answer in
cartridge mode.

### Question

Is `{PAGE}` intended to be meaningful under `BUILDCPR`?

- If not, would a warning or error when `{PAGE}`/`{PAGESET}` is used in
  cartridge mode be reasonable? That would turn a silent wrong-mapping
  bug into a build failure.
- If it is intended to be usable, we have misunderstood what the returned
  value is for, and a clarifying line in the documentation would help --
  the wiki text ("the 16-bit value to send to the Gate Array to connect
  the correct memory page") reads as though it applies to cartridge banks
  too.

We are using `{BANK}` instead, which works correctly for our purposes.

---

## Note 2: `LOCALISATION` appears to have no effect in a numbered bank

### Summary

`LOCALISATION RAM,<n>` / `LOCALISATION ROM,<n>` inside a numbered
`BANK <n>` in cartridge mode changes nothing in the exported debug data
-- neither the `-rasm` text export nor the binary `REMU` chunk in the
`.cpr`. It is accepted without warning.

This matters for code that is assembled inside a cartridge ROM bank but
copied to RAM at boot and executed from there. Such code's labels are
exported as ROM labels at the ROM bank, so an emulator resolves
breakpoints and symbols against an address the code never executes at.

### Reproduction

Three variants of the same source, differing only in the marked line:

```asm
        buildcpr symbol
        bank 0
        org 0x0000
boot:   nop
        bank 4
        org 0x8400, 0xC000
        ; <-- variant: nothing / LOCALISATION RAM,1 / LOCALISATION ROM,7
staged: jp staged
```

```
rasm t.asm -oc t.cpr -rasm t -void
```

Bank 4 uses the two-argument `ORG` deliberately: the bytes are stored at
`#C000` in the ROM page, but the code is copied to RAM at `#8400` and
runs there, so `#8400` is the address a debugger should show.

### Observed

Identical output in all three variants, in both export paths:

| Variant | `-rasm` text export | `REMU` chunk in `.cpr` |
|---|---|---|
| (no `LOCALISATION`) | `romlabel STAGED 33792 4` | `romlabel STAGED 33792 4` |
| `LOCALISATION RAM,1` | `romlabel STAGED 33792 4` | `romlabel STAGED 33792 4` |
| `LOCALISATION ROM,7` | `romlabel STAGED 33792 4` | `romlabel STAGED 33792 4` |

(33792 = `0x8400`, the logical address, which is correct. The `romlabel`
record type and the bank number `4` are what we expected `LOCALISATION`
to change.)

### Contrast: `LABEL LOCAL` does take effect

In the same setup, `LABEL LOCAL` / `LABEL GLOBAL` does change the export:

```asm
        buildcpr symbol
        bank 0
        org 0
b0:     nop
        bank 4
        org 0x8400,0xC000
        LABEL LOCAL
loc_lbl:  nop
        LABEL GLOBAL
glob_lbl: nop
```

produces

```
label LOC_LBL 33792 0
romlabel GLOB_LBL 33793 4
```

so `LABEL LOCAL` gives us the RAM-label form we want. That is a usable
workaround, which is why this is a question rather than a blocker.

### Where this happens in the source

`rasm.c` (master as of this writing), in `_internal_export_REMU`. The
label export path:

```c
if (!ae->forcesnapshot) {                        /* cartridge mode */
    if (ae->label[i].ibank<256) {
        lbankn=ae->label[i].ibank;
        isrom=1;                                 /* localisation never consulted */
    } else {
        lbankn=-1;
        isrom=0;
        for (m=0;m<ae->imemory_localisation;m++)
            if (ae->memory_localisation[m].physical==ae->label[i].ibank) {
                lbankn=ae->memory_localisation[m].logical;
                isrom =ae->memory_localisation[m].rom;
                break;
            }
    }
} else {                                         /* snapshot mode */
    if (ae->label[i].ibank<260) {
        lbankn=ae->label[i].ibank;
        isrom=0;
        for (m=0;m<ae->imemory_localisation;m++)  /* consulted for numbered banks */
            if (ae->memory_localisation[m].physical==ae->label[i].ibank) { ... }
    }
```

A numbered cartridge bank has `ibank < 256`, so it takes the first branch,
which hardcodes `isrom=1` and uses the raw bank number without ever
looking at `memory_localisation`. The table is consulted only in the
`else` branch -- `ibank >= 256`, i.e. the temporary spaces opened by a
parameterless `BANK`.

`__LOCALISATION` itself records the entry correctly
(`mloc.physical=ae->activebank`), so the information is captured and then
not used on this path.

The breakpoint export immediately above has the same structure, so
execute breakpoints inside a relocated block are exported as `rombrk` in
the ROM bank for the same reason.

What stands out is the asymmetry: in **snapshot** mode the lookup *is*
performed for numbered banks (`ibank < 260`), but in **cartridge** mode
it is skipped for them. That is what makes this look like an oversight
rather than a deliberate restriction.

### Question

Is `LOCALISATION` intended to work inside a numbered `BANK` in cartridge
mode?

The wiki wording ("When assembling single files or from temporary spaces
(using BANK without memory specificity), you can assign the current
temporary space a precise location for the emulator") suggests it is
temporary-space-only by design -- but then the snapshot path would not
need the lookup for numbered banks either, and it has it.

- If cartridge mode should behave like snapshot mode here, adding the
  same lookup to the `ibank < 256` branch would be the fix.
- If it is genuinely temporary-space-only, a warning when `LOCALISATION`
  is used where it cannot take effect would prevent the
  misunderstanding. We had written `LOCALISATION RAM,0` into our boot
  sequence believing it was taking effect, and it silently was not.

---

## Not a problem -- recorded because it was useful

Two behaviours we relied on, both working exactly as documented, noted
here only so the report is not purely negative:

- **`ASSERT {BANK}label == N` works and fails the build** with exit code
  255. We use this to machine-check that every routine and table is
  assembled into the cartridge ROM page it is declared to live in, which
  makes a whole class of placement drift impossible. This is genuinely
  useful and we found it by experiment rather than from the manual.
- **`ORG <logical>,<physical>`** cleanly expresses ROM-stored,
  RAM-executed code: `jp` encodes the logical address while the bytes are
  written at the physical one. That is exactly the separation we needed.

  *Local tooling note, not a RASM issue -- recorded here because this is
  where someone will look before editing such an `org`.* Our own placement
  checker (`tools/gen_placement.py`) used to parse `org` arguments as
  numeric literals only, so `org 0xB000, SOME_EQU` -- valid RASM -- was
  invisible to it: the section was never registered and the copied-to-RAM
  extent check silently stopped covering that blob. C.4.44 fixed both
  halves: an argument the checker cannot resolve is now an error naming
  the file and line, and `NAME equ <literal>` is resolved across the
  layout and everything it includes. So a symbolic org is fine now --
  `rom_layout.asm` writes `org 0xB000, M3_COMPUTE_BLOB_PHYS` and the
  address is defined once, in `placement.asm`, where the boot LDIR also
  reads it. The symbol must still be **defined before the `org` in RASM's
  own reading order** (`placement.asm` is included at the top of
  `rom_layout.asm`, before any `bank`); the checker itself is order-
  independent. Measured 2026-08-19, not assumed: moving that `include`
  to just after the `org` that uses the symbol makes RASM fail the
  build with 2 errors, and restoring it builds clean again.
