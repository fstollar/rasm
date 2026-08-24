# DONE

Completed and resolved items retired from `TODO.md`, kept here for
historical reference. **Item numbers match the item's number in
`TODO.md` at the time it was completed** -- items are not renumbered on
arrival here, and `TODO.md` never reuses a retired number for something
else.

**Items are filed in the order they were retired, not by number.** That
means an item can end up under a section whose prefix it does not share.
Look items up by number rather than by scrolling to "the §2 section":

```
grep -n '^- \[x\] \*\*2\.3' DONE.md   # find it, then Read that range
```

**Nothing open lives only in here.** `DONE.md` is a historical record --
nobody scans it for work -- so a retired entry must not be the only place
a "deferred" / "known limitation" / "unverified" / "blocked on X"
statement exists. Those are split out into their own unchecked items in
`TODO.md` *before* the item is retired, and the entry below points at
those numbers instead of restating them. See `CLAUDE.md`, "Retiring an
Item to DONE.md Must Not Bury What Is Still Open".

**What a good entry carries:** the same number and title it had in
`TODO.md`, the date it landed, what actually changed (commit or file),
how it was verified, and -- for anything offered upstream -- the PR
number and whether it was merged. For an assembler fix, the reproduction
that motivated it is the most valuable thing to keep.

**Reading this file:** it is short today, so read it whole. Once it
outgrows `Read`'s 2,000-line default, add a generated section index at
the top -- see `../raycast/tools/gen_doc_index.py` for the generator and
`../raycast/DONE.md` for what the output looks like -- because a
whole-file `Read` past that limit returns only the head *and does not
say that it truncated*.

---

<!-- Retired items go here, newest section last. -->
