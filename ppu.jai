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

    vram   : [16 * 1024]u8;
    oam    : [256]u8;

    buffer : [256 * 240]Pixel;

    clock  : s64;
}

Pixel :: struct {
    r : u8;
    g : u8;
    b : u8;
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
        value := vram[ppu_address];
        ppu_address += vram_address_increment;
        return value;
    } else {
        assert(false, "Tried to read from address %", address);
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
        vram[ppu_address] = value;
        ppu_address += vram_address_increment;
    } else {
        assert(false, "Unhandled ppu_write address: %", address);
    }
}

ppu_tick :: () -> (vblank_interrupt: bool) {
    using ppu;

    frame := clock % (341 * 262);
    row   := cast(u16)(frame / 341);
    col   := cast(u16)(frame % 341);

    if row < 240 {
        // VISIBLE SCANELINES
        if col == 0 {
        } else if col <= 256 {
            // step 1: fetch the tile
            col_tile := (col - 1) / 8;
            row_tile := row / 8;
            nametable_entry := vram[0x2000 + row_tile * 32 + col_tile];

            // step 2: fetch the attributes
            col_attr := col_tile / 4;
            row_attr := row_tile / 4;
            attr := vram[0x23C0 + row_attr * 8 + col_attr];

            col_box_pos := (col_tile % 4) / 2;
            row_box_pos := (row_tile % 4) / 2;
            colour_bits := (attr >> ((col_box_pos * 2) + (row_box_pos * 4))) & 0x3;

            // step 3 & 4:
            // @TODO: just going straight to chr_rom here, should this be mapped somehow?
            plane_0 := cart.chr_rom[nametable_entry * 16 + row % 8];
            plane_1 := cart.chr_rom[nametable_entry * 16 + row % 8 + 8];

            plane_0_bit := (plane_0 >> ((col-1) % 8)) & 1;
            plane_1_bit := (plane_1 >> ((col-1) % 8)) & 1;

            // step 5:
            palette_entry := plane_0_bit + (plane_1_bit * 2) + (colour_bits * 4);

            buffer[row * 256 + col - 1] = .{};

            if palette_entry > 0 && palette_entry < 16 {
                palette := vram[0x3F00 + palette_entry];
                buffer[row * 256 + col - 1] = colour_palette[palette];
            }

        } else if col <= 320 {

        } else if col <= 336 {

        } else if col <= 340 {

        }
    } else if row == 241 {
        // POST-RENDER SCANLINE
        // if col == 0 print("post-render ");
    } else if row < 261 {
        // V-BLANK
        // if col == 0 print("vblank ");
        if row == 242 && col == 1 vblank = true;
        else vblank = false; // @TEMP - using this so I can trigger a render on vblank for now
    } else if row == 261 {
        // PRE-RENDER SCANLINE
        // if col == 0 print("pre-render ");
        if col == 1 {
            vblank = false;
            sprite_0_hit = false;
        }

    } else {
        assert(false);
    }

    clock += 1;

    // @TODO: sprite_0_hit
    // @TODO: sprite_overflow
    return generate_interrupt && vblank;
}

#scope_file

colour_palette :: Pixel.[
    .{ 101, 101, 101 },
    .{   0,  45, 105 },
    .{  19,  31, 127 },
    .{  69,  19, 124 },
    .{  96,  11,  98 },
    .{ 115,  10,  55 },
    .{ 113,  15,   7 },
    .{  90,  26,   0 },
    .{  52,  40,   0 },
    .{  11,  52,   0 },
    .{   0,  60,   0 },
    .{   0,  61,  16 },
    .{   0,  56,  64 },
    .{   0,   0,   0 },
    .{   0,   0,   0 },
    .{   0,   0,   0 },
    .{ 174, 174, 174 },
    .{  15,  99, 179 },
    .{  64,  81, 208 },
    .{ 120,  65, 204 },
    .{ 167,  54, 169 },
    .{ 192,  52, 112 },
    .{ 189,  60,  48 },
    .{ 159,  74,   0 },
    .{ 109,  92,   0 },
    .{  54, 109,   0 },
    .{   7, 119,   4 },
    .{   0, 121,  61 },
    .{   0, 114, 125 },
    .{   0,   0,   0 },
    .{   0,   0,   0 },
    .{   0,   0,   0 },
    .{ 254, 254, 255 },
    .{  93, 179, 255 },
    .{ 143, 161, 255 },
    .{ 200, 144, 255 },
    .{ 247, 133, 250 },
    .{ 255, 131, 192 },
    .{ 255, 139, 127 },
    .{ 239, 154,  73 },
    .{ 189, 172,  44 },
    .{ 133, 188,  47 },
    .{  85, 199,  83 },
    .{  60, 201, 140 },
    .{  62, 194, 205 },
    .{  78,  78,  78 },
    .{   0,   0,   0 },
    .{   0,   0,   0 },
    .{ 254, 254, 255 },
    .{ 188, 223, 255 },
    .{ 209, 216, 255 },
    .{ 232, 209, 255 },
    .{ 251, 205, 253 },
    .{ 255, 204, 229 },
    .{ 255, 207, 202 },
    .{ 248, 213, 180 },
    .{ 228, 220, 168 },
    .{ 204, 227, 169 },
    .{ 185, 232, 184 },
    .{ 174, 232, 208 },
    .{ 175, 229, 234 },
    .{ 182, 182, 182 },
    .{   0,   0,   0 },
    .{   0,   0,   0 },
];