#!/usr/bin/env bash
#
# Folder-based regression harness for the RASM fork.
#
# Each subdirectory of tests/cases/ is one test case:
#
#   case.asm    the source RASM assembles
#   case.conf   shell fragment; sets DESC and ARGS, and defines extract()
#   expected    the exact text the case must produce
#
# The runner assembles case.asm in a scratch directory, normalises the
# result to a small deterministic block of text (exit status + whatever
# extract() prints), and diffs that against `expected`. A case passes
# when the diff is empty.
#
# Usage:
#   ./tests/run-tests.linux.sh                  run every case
#   ./tests/run-tests.linux.sh note1            run cases whose name matches
#   RASM=/path/to/rasm ./tests/run-tests.linux.sh
#
#   --update    rewrite each selected case's `expected` from what the
#               binary actually produced. Only ever use this to record a
#               *new* case's RED baseline, never to make a failing case
#               go green -- that erases the regression.
#
# Exit status: 0 if every selected case passed, 1 otherwise.

set -uo pipefail

TESTS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname -- "$TESTS_DIR")"

# Which binary is under test. Defaults to the build in this worktree, so
# each worktree tests its own rasm rather than a stale sibling.
RASM="${RASM:-$REPO_ROOT/rasm}"

UPDATE=0
FILTER=""
for arg in "$@"; do
    case "$arg" in
        --update) UPDATE=1 ;;
        -h|--help) sed -n '2,28p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) FILTER="$arg" ;;
    esac
done

if [ ! -x "$RASM" ]; then
    echo "error: no rasm binary at $RASM" >&2
    echo "       build it with: make -f Makefile.linux prod" >&2
    echo "       or point RASM= at one" >&2
    exit 2
fi

# rasm colours its output; the escapes would otherwise land in the diff
# as invisible bytes and make every comparison fail for the wrong reason.
strip_ansi() { sed -e 's/\x1b\[[0-9;]*m//g'; }

pass=0
fail=0
failed_cases=()

for case_dir in "$TESTS_DIR"/cases/*/; do
    case_name="$(basename "$case_dir")"
    [ -n "$FILTER" ] && [[ "$case_name" != *"$FILTER"* ]] && continue
    [ -f "$case_dir/case.conf" ] || continue

    DESC=""
    ARGS=""
    unset -f extract 2>/dev/null
    # shellcheck disable=SC1090
    source "$case_dir/case.conf"

    work="$(mktemp -d)"
    cp "$case_dir/case.asm" "$work/case.asm"

    (
        cd "$work" || exit 99
        # shellcheck disable=SC2086
        "$RASM" case.asm $ARGS
    ) > "$work/raw.out" 2>&1
    rc=$?
    strip_ansi < "$work/raw.out" > "$work/out.txt"

    {
        if [ "$rc" -eq 0 ]; then echo "exit: 0"; else echo "exit: nonzero"; fi
        if declare -F extract > /dev/null; then
            ( cd "$work" && extract )
        fi
    } > "$work/actual"

    if [ "$UPDATE" -eq 1 ]; then
        cp "$work/actual" "$case_dir/expected"
        echo "UPDATED $case_name"
        rm -rf "$work"
        continue
    fi

    if diff -q "$case_dir/expected" "$work/actual" > /dev/null 2>&1; then
        echo "PASS  $case_name -- $DESC"
        pass=$((pass + 1))
    else
        echo "FAIL  $case_name -- $DESC"
        diff -u "$case_dir/expected" "$work/actual" \
            | sed -e '1,2d' -e 's/^/        /'
        fail=$((fail + 1))
        failed_cases+=("$case_name")
    fi
    rm -rf "$work"
done

echo
echo "$pass passed, $fail failed"
if [ "$fail" -gt 0 ]; then
    printf 'failed: %s\n' "${failed_cases[*]}"
    exit 1
fi
exit 0
