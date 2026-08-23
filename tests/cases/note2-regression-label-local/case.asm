; LABEL LOCAL already produces the RAM-label form and is the documented
; workaround; it must keep behaving exactly as before.
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
