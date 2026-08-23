; {PAGESET} has the same problem as {PAGE} and the same fix.
        buildcpr symbol
        bank 0
        org 0x0000
        ld bc,{pageset}b5
        bank 5
        org 0xC000
b5:     nop
