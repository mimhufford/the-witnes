main :: () {
    // parse args
    args := get_command_line_arguments();
    if args.count < 2 { print("Usage: nes _____.nes\n"); return; }

    // load the cartridge
    cartridge, ok := load_cartridge(args[1]);
    if !ok { print("Could not load cartridge\n"); return; }

    // initalise the system with the default power on state
    cpu.sp = 0xFD;
    cpu.interrupt_disable = true;
    cpu.pc = read_word(0xFFFC);

    print("%\n", cartridge);
    print("%\n", cpu);
}

tick :: (opcode: u8) {
    using cpu;

    set_negative_and_zero_flags :: () #expand {
        negative = `value & 0b10000000 != 0;
        zero     = `value == 0;
    }

    if opcode == {
        case 0xA1; // LDA izx
        value := read_byte(read_byte(pc + 1) + x);
        set_negative_and_zero_flags();
        acc    = value;
        clock += 6;
        pc    += 2;

        case 0xA5; // LDA zp
        value := read_byte(read_byte(pc + 1));
        set_negative_and_zero_flags();
        acc    = value;
        clock += 3;
        pc    += 2;

        case 0xA9; // LDA imm
        value := read_byte(pc + 1);
        set_negative_and_zero_flags();
        acc    = value;
        clock += 2;
        pc    += 2;

        case;
        assert(false, "Unhandled opcode [%]", opcode);
    }
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
    if address < 0x4020 return apu[address % 0x4000];
    // @TODO: cartridge space, prg rom, prg ram, and mapper
    return 0;
}

write_byte :: (address: u16, value: u8) {
    assert(address >= 0x0000);
    assert(address <= 0xFFFF);
    if address < 0x2000 ram[address % 0x0800] = value;
    if address < 0x4000 ppu[address % 0x0008] = value;
    if address < 0x4020 apu[address % 0x4000] = value;
    // @TODO: cartridge space, prg rom, prg ram, and mapper
}

ram : [2048]u8;
ppu : [   8]u8;
apu : [  32]u8;
cpu : struct {
    acc : u8;  // accumulator
    x   : u8;  // indexes
    y   : u8;  // indexes
    pc  : u16; // program counter
    sp  : u8;  // stack pointer

    // status register byte unpacked for convenience
    carry             : bool;
    zero              : bool;
    interrupt_disable : bool;
    decimal           : bool;
    // @TODO: b : 2 bits
    overflow          : bool;
    negative          : bool;
    
    clock : u64; // how many cycles the CPU has performed
}

#import "Basic";
#load "cartridge.jai";