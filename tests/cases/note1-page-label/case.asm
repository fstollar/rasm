; {PAGE} on a label in a numbered cartridge bank.
; RASM answers with a Gate Array RAM-banking value (0x7FC5), which pages
; RAM, not the cartridge ROM page the label lives in. Must be refused.
        buildcpr symbol
        bank 0
        org 0x0000
        ld bc,{page}b5
        bank 5
        org 0xC000
b5:     nop
