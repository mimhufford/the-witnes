read_word :: (address: u16) -> u16 {
    result : u16;
    result += (cast(u16)read_byte(address + 1)) << 8;
    result += (cast(u16)read_byte(address + 0)) << 0;
    return result;
}

read_byte :: (address: u16) -> u8 {
    assert(address >= 0x0000);
    assert(address <= 0xFFFF);
    if address < 0x2000 return ram[address % 0x0800];
    if address < 0x4000 return ppu_read_byte(address % 0x0008);
    if address < 0x4020 return apu[address % 0x0020];
    return mapper_read_byte(address);
    // @TODO: use correct mapper based on current cartridge
}

write_byte :: (address: u16, value: u8) {
    assert(address >= 0x0000);
    assert(address <= 0xFFFF);
    if      address < 0x2000 ram[address % 0x0800] = value;
    else if address < 0x4000 ppu_write_byte(address % 0x0008, value);
    else if address < 0x4020 apu[address % 0x0020] = value;
    else mapper_write_byte(address, value);
    // @TODO: use correct mapper based on current cartridge
}

// @TODO move into mapper.jai, this is just mapper 0 for now
mapper_read_byte :: (address: u16) -> u8 {
    assert(address >= 0x8000);
    assert(cart.prg_rom.count == 16 * 1024 || cart.prg_rom.count == 32 * 1024);
    return cart.prg_rom[address % cart.prg_rom.count];
}

// @TODO move into mapper.jai, this is just mapper 0 for now
mapper_write_byte :: (address: u16, value: u8) {
    assert(false);
}