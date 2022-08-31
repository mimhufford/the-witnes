Cartridge :: struct {
    mirroring    : enum { Horizontal; Vertical; };
    battery      : bool;
    mapper       : u16;
    sub_mapper   : u8;
    prg_rom      : []u8;
    chr_rom      : []u8;
}

load_cartridge :: (filename: string) -> Cartridge, bool {
    using result : Cartridge;

    data := read_entire_file(filename);

    if data.count < 16 return .{}, false;

    magic : string;
    magic.count = 3;
    magic.data = data.data;
    if magic != "NES" return .{}, false;

    if data[6] & 0b00000001 > 0 mirroring = .Vertical;
    battery = data[6] & 0b00000010 > 0;
    mapper = ((data[8] & 0b00001111) << 8) | (data[7] & 0b11110000) | (data[6] >> 4);
    sub_mapper = data[8] >> 4;

    prg_rom.count = (((data[9] & 0b00001111) << 4) | data[4]) * 16 * 1024;
    chr_rom.count = (((data[9] & 0b11110000) << 0) | data[5]) *  8 * 1024;
    if data.count < 16 + prg_rom.count + chr_rom.count return .{}, false;

    prg_rom.data = alloc(prg_rom.count);
    chr_rom.data = alloc(chr_rom.count);
    memcpy(prg_rom.data, data.data + 16                , prg_rom.count);
    memcpy(chr_rom.data, data.data + 16 + prg_rom.count, chr_rom.count);

    return result, true;
}

#scope_file

#import "File";