main :: () {
    // parse args
    args := get_command_line_arguments();
    if args.count < 2 { print("Usage: nes _____.nes\n"); return; }

    // load the cartridge
    ok : bool;
    cart, ok = load_cartridge(args[1]);
    if !ok { print("Could not load cartridge\n"); return; }

    // initalise the system with the default power on state
    cpu.sp = 0xFD;
    cpu.interrupt_disable = true;
    cpu.pc = read_word(0xFFFC);

    // @TEMPORARY: testing the cpu using nestest.nes
    // {
    cpu.pc = 0xC000; // nestest requires starting at 0xC000
    for 1..10 {
        op := read_byte(cpu.pc);
        print("% %\n",
                formatInt(cpu.pc, base=16, minimum_digits=4),
                formatInt(op,     base=16, minimum_digits=2),
        );
        tick(op);
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
    if address < 0x4000 return ppu[address % 0x0008];
    if address < 0x4020 return apu[address % 0x0020];
    // @TODO: use correct mapper based on current cartridge
    return mapper_read_byte(address);
}

write_byte :: (address: u16, value: u8) {
    assert(address >= 0x0000);
    assert(address <= 0xFFFF);
    if address < 0x2000 ram[address % 0x0800] = value;
    if address < 0x4000 ppu[address % 0x0008] = value;
    if address < 0x4020 apu[address % 0x0020] = value;
    // @TODO: use correct mapper based on current cartridge
    mapper_write_byte(address, value);
}

// @TODO move into mapper.jai, this is just mapper 0 for now
mapper_read_byte :: (address: u16) -> u8 {
    assert(address >= 0x8000);
    assert(cart.prg_rom.count == 16 * 1024 || cart.prg_rom.count == 32 * 1024);
    return cart.prg_rom[address % cart.prg_rom.count];
}

// @TODO move into mapper.jai, this is just mapper 0 for now
mapper_write_byte :: (address: u16, value: u8) {
    // @TODO
}

ram  : [2048]u8;
ppu  : [   8]u8;
apu  : [  32]u8;
cpu  : CPU;
cart : Cartridge;

#import "Basic";
#load "cartridge.jai";
#load "cpu.jai";