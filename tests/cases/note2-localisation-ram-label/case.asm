        buildcpr symbol
        bank 0
        org 0x0000
boot:   nop
        bank 4
        org 0x8400, 0xC000
        LOCALISATION RAM,1
staged: jp staged
