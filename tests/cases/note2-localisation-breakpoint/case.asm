; The breakpoint export has the same ibank<256 shortcut as the label
; export, so a breakpoint in a relocated block is exported against the
; ROM bank too.
        buildcpr symbol
        bank 0
        org 0x0000
boot:   nop
        bank 4
        org 0x8400, 0xC000
        LOCALISATION RAM,1
staged: breakpoint
        jp staged
