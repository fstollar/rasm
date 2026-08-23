; {PAGE} keeps working in snapshot mode, where banks really are RAM banks
; and the Gate Array value is the right answer. Guards the fix against
; being applied too widely.
        buildsna
        bank 5
        org 0x8000
maroutine: nop
        assert {page}maroutine==0x7FC5
        assert {pageset}maroutine==0x7FC2
        assert {bank}maroutine==5
