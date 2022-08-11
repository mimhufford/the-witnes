CPU :: struct {
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
    // b_flag         : 0b00;
    overflow          : bool;
    negative          : bool;
    
    clock : u64; // how many cycles the CPU has performed
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
    // @TODO: cartridge space, prg rom, prg ram, and mapper
    return 0;
}

write_byte :: (address: u16, value: u8) {
    assert(address >= 0x0000);
    assert(address <= 0xFFFF);
    if address < 0x2000 ram[address % 0x0800] = value;
    if address < 0x4000 ppu[address % 0x0008] = value;
    if address < 0x4020 apu[address % 0x0020] = value;
    // @TODO: cartridge space, prg rom, prg ram, and mapper
}

tick :: (opcode: u8) {
    using cpu;

    if opcode == {
        case 0x00; // BRK
        push_stack(cast(u8)(pc >> 8));
        push_stack(cast(u8)(pc >> 0));
        interrupt_disable = true;
        push_flags(1, 1);
        clock += 7;
        pc     = read_word(0xFFFE);

        case 0x48; // PHA
        write_byte(cast(u16)0x100 | sp, acc);
        sp    -= 1;
        clock += 3;
        pc    += 1;

        case 0xA1; // LDA izx
        value := read_byte(read_word(read_byte(pc + 1) + x));
        set_negative_and_zero_flags(value);
        acc    = value;
        clock += 6;
        pc    += 2;

        case 0xA5; // LDA zp
        value := read_byte(read_byte(pc + 1));
        set_negative_and_zero_flags(value);
        acc    = value;
        clock += 3;
        pc    += 2;

        case 0xA9; // LDA imm
        value := read_byte(pc + 1);
        set_negative_and_zero_flags(value);
        acc    = value;
        clock += 2;
        pc    += 2;

        case 0xAD; // LDA abs
        value := read_byte(read_word(pc + 1));
        set_negative_and_zero_flags(value);
        acc    = value;
        clock += 4;
        pc    += 3;

        case 0xB1; // LDA izy
        addr  := read_word(read_byte(pc + 1));
        value := read_byte(addr + y);
        set_negative_and_zero_flags(value);
        acc    = value;
        clock += ifx (addr & 0xFF00) != ((addr + y) & 0xFF00) then 6 else 5;
        pc    += 2;

        case 0xB5; // LDA zpx
        value := read_byte(read_byte(pc + 1) + x);
        set_negative_and_zero_flags(value);
        acc    = value;
        clock += 4;
        pc    += 2;

        case 0xB9; // LDA aby
        addr  := read_word(pc + 1);
        value := read_byte(addr + y);
        set_negative_and_zero_flags(value);
        acc    = value;
        clock += ifx (addr & 0xFF00) != ((addr + y) & 0xFF00) then 5 else 4;
        pc    += 3;
        
        case 0xBD; // LDA abx
        addr  := read_word(pc + 1);
        value := read_byte(addr + x);
        set_negative_and_zero_flags(value);
        acc    = value;
        clock += ifx (addr & 0xFF00) != ((addr + x) & 0xFF00) then 5 else 4;
        pc    += 3;

        case;
        assert(false, "Unhandled opcode [%]", opcode);
    }
}

#scope_file

set_negative_and_zero_flags :: inline (value: u8) {
    cpu.negative = value & 0b10000000 != 0;
    cpu.zero     = value == 0;
}

push_stack :: inline (value: u8) {
    write_byte(cast(u16)0x100 | cpu.sp, value);
    cpu.sp -= 1;
}

push_flags :: inline (bit_5: u8, bit_4: u8) {
    flags := (cast(u8)cpu.negative)          << 7 |
             (cast(u8)cpu.overflow)          << 6 |
             (cast(u8)bit_5)                 << 5 |
             (cast(u8)bit_4)                 << 4 |
             (cast(u8)cpu.decimal)           << 3 |
             (cast(u8)cpu.interrupt_disable) << 2 |
             (cast(u8)cpu.zero)              << 1 |
             (cast(u8)cpu.carry)             << 0;
    push_stack(flags);
}