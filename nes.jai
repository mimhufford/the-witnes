main :: () {
    // parse args
    args := get_command_line_arguments();
    if args.count < 2 { print("Usage: nes _____.nes\n"); return; }

    // load the cartridge
    ok : bool;
    cart, ok = load_cartridge(args[1]);
    if !ok { print("Could not load cartridge\n"); return; }

    // initalise the system with the default power on state
    cpu_reset();

    // @TEMPORARY: testing the ppu using nestest.nes
    // {
    while true {
        op := read_byte(cpu.pc);

        flags : u8 = ((cast(u8)cpu.negative)          << 7) |
                     ((cast(u8)cpu.overflow)          << 6) |
                     ((cast(u8)1)                     << 5) |
                     ((cast(u8)cpu.decimal)           << 3) |
                     ((cast(u8)cpu.interrupt_disable) << 2) |
                     ((cast(u8)cpu.zero)              << 1) |
                     ((cast(u8)cpu.carry)             << 0);

        print("%  %  A:% X:% Y:% P:% SP:% PPU:% CYC:%\n",
                formatInt(cpu.pc,  base=16, minimum_digits=4),
                formatInt(op,      base=16, minimum_digits=2),
                formatInt(cpu.acc, base=16, minimum_digits=2),
                formatInt(cpu.x  , base=16, minimum_digits=2),
                formatInt(cpu.y  , base=16, minimum_digits=2),
                formatInt(flags  , base=16, minimum_digits=2),
                formatInt(cpu.sp , base=16, minimum_digits=2),
                ppu.vblank,
                cpu.clock,
        );

        cycles := cpu_tick(op);
        vblank := ppu_tick(cycles * 3);

        if vblank cpu_nmi();
    }
    // }
}

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

ram  : [2048]u8;
cpu  : CPU;
ppu  : PPU;
apu  : [  32]u8;
cart : Cartridge;

#import "Basic";
#load "cartridge.jai";
#load "cpu.jai";
#load "ppu.jai";