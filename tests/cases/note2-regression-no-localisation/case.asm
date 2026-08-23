; No LOCALISATION: a numbered cartridge bank's labels stay ROM labels at
; their own bank number. This is the default the fix must NOT disturb --
; the cartridge branch defaults isrom=1 where the snapshot branch
; defaults isrom=0, and copying the snapshot branch wholesale would flip
; every cartridge label to a RAM label.
        buildcpr symbol
        bank 0
        org 0x0000
boot:   nop
        bank 4
        org 0x8400, 0xC000
staged: jp staged
