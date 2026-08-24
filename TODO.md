# TODO

> **Scope:** this file tracks open work on the **RASM fork** -- assembler
> bugs and cartridge-mode gaps found from `../raycast/`, fork-local test
> harness and `tools/` additions, and the process work around staying
> upstream-mergeable (rebases, PRs to `EdouardBERGE/rasm`). Background
> on why the fork exists and the rules every change here has to satisfy
> live in `CLAUDE.md`; the canonical write-ups of the original
> cartridge-mode findings live in `../raycast/RASM-NOTES.md`.
>
> **Numbering:** sections and items are numbered hierarchically
> (`1`, `1.2`, `1.2.1`) so any point is citable ("`TODO.md` §1.2").
> There is only one TODO file here, so numbers carry no letter prefix --
> unlike `../raycast/`, which prefixes `A.`/`Z.`/`C.` to disambiguate
> between its three TODO files. If this file ever splits, the new file
> picks a prefix and items are renumbered on the move, not before.
>
> **Item numbers are never reused.** Gaps in the sequence are expected
> and mean "retired to `DONE.md`", not "renumber me".
>
> **Completed items are retired to `DONE.md`, not deleted and not kept
> here.** Top-level sections stay in this file even when all their
> current items are done -- the section is the home for the next item on
> that topic. Leave a parenthetical pointer behind where an item was, so
> a reader following a citation lands somewhere:
>
> ```markdown
> (1.4 retired to `DONE.md` §1.4.)
> ```
>
> **Retiring must not bury what is still open** (`CLAUDE.md`, same rule).
> `DONE.md` is a historical record -- nobody scans it for work. Before
> moving an item across, pull every not-done statement out of it
> ("deferred", "known limitation", "unverified", "blocked on X") into its
> own unchecked item here, with its own number; the `DONE.md` entry then
> *points* at those numbers. A partially-done item is not retired at all.
> If the leftover belongs to a different repo -- e.g. a raycast-side gap
> found while doing fork work -- file it in **that** repo's `TODO.md` and
> cite the number from here.
>
> **Status legend:** items are markdown checkboxes -- `- [ ]` pending,
> `- [x]` done but not yet retired. Inline annotations follow the
> checkbox: **🔴 \[HIGH PRIORITY]** = critical path.
> **\[repro ✓]** = a copy-pasteable `.asm` reproduction plus exact
> command line and observed output exists (`CLAUDE.md`: reproduce before
> fixing). **\[upstream]** = offered or to be offered as a PR against
> `EdouardBERGE/rasm`. **\[fork-local]** = deliberately never goes
> upstream (`tools/`, `tests/`, this file).
>
> **Reading this file:** it is short today, so read it whole. Once it
> outgrows `Read`'s 2,000-line default, add a generated section index at
> the top -- see `../raycast/tools/gen_doc_index.py` for the generator
> and `../raycast/TODO.md` for what the output looks like -- because a
> whole-file `Read` past that limit silently truncates.

---

<!-- Sections go here. First one starts at "## 1 <topic>". -->
