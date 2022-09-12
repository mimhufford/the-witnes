PPU :: struct {
    base_nametable_address   : u16;   // ppuctrl   - 0x2000 - 0b_0000_0011
    vram_address_increment   : u8;    // ppuctrl   - 0x2000 - 0b_0000_0100
    sprite_table_address     : u16;   // ppuctrl   - 0x2000 - 0b_0000_1000
    background_table_address : u16;   // ppuctrl   - 0x2000 - 0b_0001_0000
    big_sprites              : bool;  // ppuctrl   - 0x2000 - 0b_0010_0000
    generate_interrupt       : bool;  // ppuctrl   - 0x2000 - 0b_1000_0000

    greyscale                : bool;  // ppumask   - 0x2001 - 0b_0000_0001
    background_left_column   : bool;  // ppumask   - 0x2001 - 0b_0000_0010
    sprite_left_column       : bool;  // ppumask   - 0x2001 - 0b_0000_0100
    show_background          : bool;  // ppumask   - 0x2001 - 0b_0000_1000
    show_sprites             : bool;  // ppumask   - 0x2001 - 0b_0001_0000
    emphasise_red            : bool;  // ppumask   - 0x2001 - 0b_0010_0000
    emphasise_green          : bool;  // ppumask   - 0x2001 - 0b_0100_0000
    emphasise_blue           : bool;  // ppumask   - 0x2001 - 0b_1000_0000

    vblank                   : bool;  // ppustatus - 0x2002 - 0b_1000_0000
    sprite_0_hit             : bool;  // ppustatus - 0x2002 - 0b_0100_0000
    sprite_overflow          : bool;  // ppustatus - 0x2002 - 0b_0010_0000

    oam_address              : u8;    // oamaddr   - 0x2003 - 0b_1111_1111
    oam_data                 : u8;    // oamdata   - 0x2004 - 0b_1111_1111

    clock  : s64;
}

ppu_read_byte :: (address: u16) -> u8 {
    using ppu;

    if address == 2 {
        status := (cast(u8)vblank)          << 7 |
                  (cast(u8)sprite_0_hit)    << 6;
                  (cast(u8)sprite_overflow) << 5;
        vblank = false;
        return status;
    } else if address == 4 {
        return oam_data;
    } else {
        assert(false, "Only handling 0x2002 PPUSTATUS for now");
        return 0;
    }
}

ppu_write_byte :: (address: u16, value: u8) {
    using ppu;

    if address == 0 {
        base_nametable_address   = cast(u16)0x2000 + (cast(u16)value & 0b11) * 0x400;
        vram_address_increment   = 1 + ((value & 0b_0000_0100) >> 2) * 31;
        sprite_table_address     = (cast(u16)value & 0b_0000_1000) * 0x1000;
        background_table_address = (cast(u16)value & 0b_0001_0000) * 0x1000;
        big_sprites              = (value & 0b_0010_0000) > 0;
        generate_interrupt       = (value & 0b_1000_0000) > 0;
    }
    else if address == 1 {
        greyscale                = (value & 0b_0000_0001) > 0;
        background_left_column   = (value & 0b_0000_0010) > 0;
        sprite_left_column       = (value & 0b_0000_0100) > 0;
        show_background          = (value & 0b_0000_1000) > 0;
        show_sprites             = (value & 0b_0001_0000) > 0;
        emphasise_red            = (value & 0b_0010_0000) > 0;
        emphasise_green          = (value & 0b_0100_0000) > 0;
        emphasise_blue           = (value & 0b_1000_0000) > 0;
    } else if address == 3 {
        oam_address              = value;
    } else if address == 4 {
        oam_data                 = value;
    }
}

ppu_tick :: (cycles: s64) -> (vblank_interrupt: bool) {
    using ppu;

    clock += cycles;

    // @TODO: does vblank have to be set on rising and falling edges?
    //        once up and running test if this can simply be:
    //            vblank = frame_clock > vblank_edge;

    // @TODO: sprite_0_hit
    // @TODO: sprite_overflow

    vblank_before := vblank;

    frame_clock := clock % (341 * 262);
    vblank_edge :: 341 * 241;
    if     !vblank && frame_clock >  vblank_edge then vblank = true;
    else if vblank && frame_clock <= vblank_edge then vblank = false;

    return generate_interrupt && !vblank_before && vblank;
}