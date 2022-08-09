Cartridge :: struct {
    prg_rom_size : u32;
    chr_rom_size : u32;
    mirroring    : enum { Horizontal; Vertical; };
    battery      : bool;
    mapper       : u16;
    sub_mapper   : u8;
}

load_cartridge :: (filename: string) -> Cartridge, bool {
    using result : Cartridge;

    data := read_entire_file(filename);

    if data.count < 16 return .{}, false;

    magic : string;
    magic.count = 3;
    magic.data = data.data;
    if magic != "NES" return .{}, false;

    prg_rom_size = (((data[9] & 0b00001111) << 4) | data[4]) * 16;
    chr_rom_size = (((data[9] & 0b11110000) << 0) | data[5]) *  8;

    if data[6] & 0b00000001 > 0 mirroring = .Vertical;

    battery = data[6] & 0b00000010 > 0;

    mapper = ((data[8] & 0b00001111) << 8) | (data[7] & 0b11110000) | (data[6] >> 4);

    sub_mapper = data[8] >> 4;

    return result, true;
}

#scope_file

#import "File";