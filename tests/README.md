# Test harness

Folder-based regression tests for this RASM fork. Fork-local -- **keep
`tests/` out of any upstream PR** (see `CLAUDE.md`, "This Fork Stays
Upstream-Mergeable"). Fixes offered upstream carry their coverage as
entries in RASM's own `-autotest` suite instead; this directory is where
the fix is *developed*.

Source of truth for the reproductions: `../raycast/RASM-NOTES.md`. When a
note is answered or a behaviour changes, update **that** file; the
`RASM-NOTES.md` at this repo's root is a byte-identical snapshot of it
for readers of the fork, re-copied rather than edited in place.

## 1. Running

```sh
make -f Makefile.linux prod        # produces ./rasm
./tests/run-tests.linux.sh         # all cases
./tests/run-tests.linux.sh note2   # cases whose name contains "note2"
RASM=/path/to/other/rasm ./tests/run-tests.linux.sh
```

Exit status is 0 only if every selected case passed. `RASM` defaults to
`./rasm` in the same tree as `tests/`, so a worktree tests its own build
rather than a sibling's.

## 2. Writing a case

One directory per case under `cases/`, named `<note>-<behaviour>`:

| File | Purpose |
|---|---|
| `case.asm` | the source RASM assembles. Comment *why* the case exists. |
| `case.conf` | shell fragment: `DESC`, `ARGS` (rasm's command line after the source name), and optionally `extract()` |
| `expected` | the exact text the case must produce |

The runner assembles `case.asm` in a scratch directory, strips rasm's
ANSI colour escapes, and builds the actual result as:

```
exit: 0            <- or "exit: nonzero"
<whatever extract() prints, run inside the scratch directory>
```

`extract()` is what keeps a case honest: it pulls the one thing under
test out of the output. Two shapes cover everything here --
`cat out.rasm` for a symbol/breakpoint export, and a `grep -oE` for one
expected diagnostic. A case with no `extract()` asserts on exit status
alone, which is the right shape when the source carries its own
`assert` directives.

## 3. The workflow this exists for

Test first, and **watch it fail before writing any C**:

1. Add the case with the `expected` you want RASM to produce.
2. Run the harness. The case must fail, and the diff must show the
   *current wrong* behaviour -- not a typo, not a harness error.
3. Fix `rasm.c`, rebuild, run again.
4. Every other case must still pass.

`--update` rewrites `expected` from what the binary actually produced.
Use it **only** to record a brand-new case's baseline before you know
the exact text, never to make a failing case go green -- that silently
deletes the regression the case existed to catch.

## 4. Regression cases are load-bearing

Cases named `*-regression-*` pass before the fix and must still pass
after it. They exist because both fixes are one-line-ish changes in
shared code paths that are easy to over-apply:

- `note1-regression-page-buildsna` -- `{PAGE}`/`{PAGESET}` are correct in
  snapshot mode, where banks really are RAM banks. The cartridge guard
  must key on `ae->forcecpr` and nothing wider.
- `note1-regression-bank-buildcpr` -- `{BANK}` is the migration path the
  new error message points users at; it has to keep working.
- `note2-regression-no-localisation` -- the cartridge label-export branch
  defaults `isrom=1`, the snapshot branch defaults `isrom=0`. Copying the
  snapshot branch wholesale would flip **every** cartridge label from
  `romlabel` to `label`. This case is the only thing guarding that
  default.
- `note2-regression-label-local` -- `LABEL LOCAL` already produces the
  RAM-label form and is the documented workaround; unchanged.

## 5. Known-failing upstream baseline

`./rasm -autotest` (RASM's own built-in suite, run from a scratch
directory with `minilib.h` copied in) does **not** pass cleanly on
upstream `b222469` before any of our changes:

- Autotest 058 -- `limit 70000,EXTENDED`
- Autotest 329 -- `crunching lzDataTest with ZX0 ret=-1 len=0`, which
  stops the run

264 `OK` lines, exit 255. Compare against that, not against zero
failures, when checking that a change added no new autotest breakage.

## 6. Two things the note 1 guard depends on

Both were checked against `rasm.c`, not assumed:

- **`ae->forcecpr` is the only correct predicate.** `BANKSET` defaults to
  `forcesnapshot` (`rasm.c:19080`), which is why upstream's own
  `AUTOTEST_PAGETAG`/`PAGETAG2` keep passing. `buildsna CPR` sets a
  *separate* flag `ae->snacpr` and never `forcecpr`, so a snapshot packed
  into a `.cpr` is untouched by the guard.
- **A bare `BANK n` with no build directive implies cartridge mode**
  (`rasm.c:18941`: "using BANK without build mode will select cartridge
  output as default"). So `{PAGE}` errors there too, without any
  `buildcpr` in the source. That is intended -- the output really is a
  cartridge -- but it is the one case where the new error appears in a
  source that never names `buildcpr`.

One diagnostic is emitted per offending reference, not one per assembly
pass -- verified for all four note 1 cases. This matters because rasm's
`MaxError` aborts the run with a different, misleading message once the
error count is exceeded.
