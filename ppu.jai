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
    ppu_scroll               : u16;   // ppuscroll - 0x2005 - 0b_1111_1111
    ppu_address              : u16;   // ppuaddr   - 0x2006 - 0b_1111_1111

    vram_page_0000 : []u8;
    vram_page_1000 : []u8;
    vram   : [8 * 1024]u8;
    oam    : [256]u8;

    clock  : s64;
}

ppu_init :: (chr_rom: []u8) {
    ppu.base_nametable_address = 0x2000;
    ppu.vram_address_increment = 1;
    // @TODO: this is a it gross, can it all just be vram?
    // @TODO: this currently assumes there is only 1 page of chr_rom data
    ppu.vram_page_0000.data = chr_rom.data;
    ppu.vram_page_1000.data = chr_rom.data;
    ppu.vram_page_0000.count = 8 * 1024;
    ppu.vram_page_1000.count = 8 * 1024;
}

ppu_read_byte :: (address: u16) -> u8 {
    using ppu;

    if address == 2 {
        // PPUSTATUS
        status := ((cast(u8)vblank)          << 7) |
                  ((cast(u8)sprite_0_hit)    << 6) |
                  ((cast(u8)sprite_overflow) << 5);
        vblank      = false;
        ppu_address = 0;
        return status;
    } else if address == 4 {
        // OAMDATA
        return oam_data;
    } else if address == 7 {
        // PPUDATA
        value := vram[ppu_address - 0x2000];
        ppu_address += vram_address_increment;
        return value;
    } else {
        assert(false, "Only handling 0x2002 PPUSTATUS for now");
        return 0;
    }
}

ppu_write_byte :: (address: u16, value: u8) {
    using ppu;

    if address == 0 {
        // PPUCTRL
        base_nametable_address   = cast(u16)0x2000 + (cast(u16)value & 0b11) * 0x400;
        vram_address_increment   = 1 + ((value & 0b_0000_0100) >> 2) * 31;
        sprite_table_address     = (cast(u16)value & 0b_0000_1000) * 0x1000;
        background_table_address = (cast(u16)value & 0b_0001_0000) * 0x1000;
        big_sprites              = (value & 0b_0010_0000) > 0;
        generate_interrupt       = (value & 0b_1000_0000) > 0;
    }
    else if address == 1 {
        // PPUMASK
        greyscale                = (value & 0b_0000_0001) > 0;
        background_left_column   = (value & 0b_0000_0010) > 0;
        sprite_left_column       = (value & 0b_0000_0100) > 0;
        show_background          = (value & 0b_0000_1000) > 0;
        show_sprites             = (value & 0b_0001_0000) > 0;
        emphasise_red            = (value & 0b_0010_0000) > 0;
        emphasise_green          = (value & 0b_0100_0000) > 0;
        emphasise_blue           = (value & 0b_1000_0000) > 0;
    } else if address == 3 {
        // OAMADDR
        oam_address              = value;
    } else if address == 4 {
        // OAMDATA
        oam_data                 = value;
    } else if address == 5 {
        // @TODO: PPUSCROLL
    } else if address == 6 {
        // PPUADDR
        ppu_address <<= 8;
        ppu_address += cast(u16) value;
    } else if address == 7 {
        // PPUDATA
        // @TODO: mirroring
        vram[ppu_address - 0x2000] = value;
        ppu_address += vram_address_increment;
    } else {
        assert(false, "Unhandled ppu_write address: %", address);
    }
}

ppu_tick :: () -> (vblank_interrupt: bool) {
    using ppu;

    horizontal_pixel := clock % 341;
    vertical_pixel   := clock / 341;

    if vertical_pixel < 240 && horizontal_pixel < 256 {
        horizontal_tile := horizontal_pixel % 32;
        verticle_tile := vertical_pixel / 8;

        nametable_entry := vram[base_nametable_address - 0x2000 + (verticle_tile * 32) + horizontal_tile];
        print("%", nametable_entry);
    }

    // @TODO: does vblank have to be set on rising and falling edges?
    //        once up and running test if this can simply be:
    //            vblank = frame > vblank_edge;

    // @TODO: sprite_0_hit
    // @TODO: sprite_overflow

    vblank_before := vblank;

    frame := clock % (341 * 262);
    vblank_edge :: 341 * 241;
    if     !vblank && frame >  vblank_edge then vblank = true;
    else if vblank && frame <= vblank_edge then vblank = false;

    clock += 1;

    return generate_interrupt && !vblank_before && vblank;
}