; {BANK} is the correct thing to use in cartridge mode and already works.
; It must keep working -- it is the migration path out of {PAGE}.
; The asserts sit at the end because a {BANK}-prefixed forward reference
; is not resolvable at the point the ASSERT is evaluated.
        buildcpr symbol
        bank 0
        org 0x0000
        ld a,{bank}b5
        bank 5
        org 0xC000
b5:     nop
        assert {bank}b5==5
