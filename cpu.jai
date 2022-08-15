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
    
    clock : s64; // how many cycles the CPU has performed
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
        case 0x10; // BPL
        branch_relative(!negative);

        case 0x30; // BMI
        branch_relative(negative);

        case 0x50; // BVC
        branch_relative(!overflow);

        case 0x70; // BVS
        branch_relative(overflow);

        case 0x90; // BCC
        branch_relative(!carry);

        case 0xB0; // BCS
        branch_relative(carry);

        case 0xD0; // BNE
        branch_relative(!zero);

        case 0xE0; // BEQ
        branch_relative(zero);

        case 0x00; // BRK
        push_stack(cast(u8)((pc + 1) >> 8));
        push_stack(cast(u8)((pc + 1) >> 0));
        push_flags(1, 1);
        interrupt_disable = true;
        clock += 7;
        pc     = read_word(0xFFFE);

        case 0x40; // RTI
        pull_flags();
        clock += 6;
        pc     = pull_stack() << 0;
        pc    |= pull_stack() << 8;

        case 0x20; // JSR
        push_stack(cast(u8)((pc + 2) >> 8));
        push_stack(cast(u8)((pc + 2) >> 0));
        clock += 6;
        pc     = read_word(pc + 1);

        case 0x60; // RTS
        clock += 6;
        pc     = pull_stack() << 0;
        pc    |= pull_stack() << 8;
        pc    += 1;

        case 0x4C; // JMP abs
        clock += 3;
        pc     = read_word(pc + 1);

        case 0x6C; // JMP ind
        clock += 5;
        pc     = read_word(read_word(pc + 1));
        // @TODO: if first read is the last byte of a page boundary
        //        then the second byte should wrap within the page

        case 0x24; // BIT zp
        value   := read_byte(read_byte(pc + 1));
        zero     = (value & acc) == 0;
        negative = value & 0b_1000_0000 != 0;
        overflow = value & 0b_0100_0000 != 0;
        clock   += 3;
        pc      += 2;

        case 0x2C; // BIT abs
        value   := read_byte(read_word(pc + 1));
        zero     = (value & acc) == 0;
        negative = value & 0b_1000_0000 != 0;
        overflow = value & 0b_0100_0000 != 0;
        clock   += 4;
        pc      += 3;

        case 0x18; // CLC
        carry = false;
        clock += 2;
        pc    += 1;

        case 0x38; // SEC
        carry = true;
        clock += 2;
        pc    += 1;

        case 0xD8; // CLD
        decimal = false;
        clock += 2;
        pc    += 1;

        case 0xF8; // SED
        decimal = true;
        clock += 2;
        pc    += 1;

        case 0x58; // CLI
        interrupt_disable = false;
        clock += 2;
        pc    += 1;

        case 0x78; // SEI
        interrupt_disable = true;
        clock += 2;
        pc    += 1;

        case 0xB8; // CLV
        overflow = false;
        clock += 2;
        pc    += 1;

        case 0xEA; // NOP
        clock += 2;
        pc    += 1;

        case 0xAA; // TAX
        x = acc;
        set_negative_and_zero_flags(acc);
        clock += 2;
        pc    += 1;

        case 0x8A; // TXA
        acc = x;
        set_negative_and_zero_flags(x);
        clock += 2;
        pc    += 1;

        case 0xA8; // TAY
        y = acc;
        set_negative_and_zero_flags(acc);
        clock += 2;
        pc    += 1;

        case 0x98; // TYA
        acc = y;
        set_negative_and_zero_flags(y);
        clock += 2;
        pc    += 1;

        case 0xBA; // TSX
        x = sp;
        set_negative_and_zero_flags(sp);
        clock += 2;
        pc    += 1;

        case 0x9A; // TXS
        sp = x;
        clock += 2;
        pc    += 1;

        case 0x68; // PLA
        acc = pull_stack();
        set_negative_and_zero_flags(acc);
        clock += 4;
        pc    += 1;

        case 0x48; // PHA
        push_stack(acc);
        clock += 3;
        pc    += 1;

        case 0x28; // PLP
        flags := pull_stack();
        negative          = flags & 0b_1000_0000 > 0;
        overflow          = flags & 0b_0100_0000 > 0;
        decimal           = flags & 0b_0000_1000 > 0;
        interrupt_disable = flags & 0b_0000_0100 > 0;
        zero              = flags & 0b_0000_0010 > 0;
        carry             = flags & 0b_0000_0001 > 0;
        clock += 4;
        pc    += 1;

        case 0x08; // PHP
        push_flags(1, 1);
        clock += 3;
        pc    += 1;

        //
        // LDA
        //

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

        //
        // LDX
        //

        case 0xA2; // LDX imm
        value := read_byte(pc + 1);
        set_negative_and_zero_flags(value);
        x      = value;
        clock += 2;
        pc    += 2;

        case 0xA6; // LDX zp
        value := read_byte(read_byte(pc + 1));
        set_negative_and_zero_flags(value);
        x      = value;
        clock += 3;
        pc    += 2;

        case 0xAE; // LDX abs
        value := read_byte(read_word(pc + 1));
        set_negative_and_zero_flags(value);
        x      = value;
        clock += 4;
        pc    += 3;

        case 0xB6; // LDX zpy
        value := read_byte(read_byte(pc + 1) + y);
        set_negative_and_zero_flags(value);
        x      = value;
        clock += 4;
        pc    += 2;

        case 0xBE; // LDX aby
        addr  := read_word(pc + 1);
        value := read_byte(addr + y);
        set_negative_and_zero_flags(value);
        x      = value;
        clock += ifx (addr & 0xFF00) != ((addr + y) & 0xFF00) then 5 else 4;
        pc    += 3;
        
        //
        // LDY
        //

        case 0xA0; // LDY imm
        value := read_byte(pc + 1);
        set_negative_and_zero_flags(value);
        y      = value;
        clock += 2;
        pc    += 2;

        case 0xA4; // LDY zp
        value := read_byte(read_byte(pc + 1));
        set_negative_and_zero_flags(value);
        y      = value;
        clock += 3;
        pc    += 2;

        case 0xAC; // LDY abs
        value := read_byte(read_word(pc + 1));
        set_negative_and_zero_flags(value);
        y      = value;
        clock += 4;
        pc    += 3;

        case 0xB4; // LDY zpx
        value := read_byte(read_byte(pc + 1) + x);
        set_negative_and_zero_flags(value);
        y      = value;
        clock += 4;
        pc    += 2;

        case 0xBC; // LDY abx
        addr  := read_word(pc + 1);
        value := read_byte(addr + x);
        set_negative_and_zero_flags(value);
        y      = value;
        clock += ifx (addr & 0xFF00) != ((addr + x) & 0xFF00) then 5 else 4;
        pc    += 3;

        //
        // STA
        //

        case 0x81; // STA izx
        write_byte(read_word(read_byte(pc + 1) + x), acc);
        clock += 6;
        pc    += 2;

        case 0x85; // STA zp
        write_byte(read_byte(pc + 1), acc);
        clock += 3;
        pc    += 2;

        case 0x8D; // STA abs
        write_byte(read_word(pc + 1), acc);
        clock += 4;
        pc    += 3;
        
        case 0x91; // STA izy
        write_byte(read_word(read_byte(pc + 1)) + y, acc);
        clock += 6;
        pc    += 2;

        case 0x95; // STA zpx
        write_byte(read_byte(pc + 1) + x, acc);
        clock += 4;
        pc    += 2;

        case 0x99; // STA aby
        write_byte(read_word(pc + 1) + y, acc);
        clock += 5;
        pc    += 3;

        case 0x9D; // STA abx
        write_byte(read_word(pc + 1) + x, acc);
        clock += 5;
        pc    += 3;

        //
        // STX
        //

        case 0x86; // STX zp
        write_byte(read_byte(pc + 1), x);
        clock += 3;
        pc    += 2;

        case 0x8E; // STX abs
        write_byte(read_word(pc + 1), x);
        clock += 4;
        pc    += 3;

        case 0x96; // STX zpy
        write_byte(read_byte(pc + 1) + y, x);
        clock += 4;
        pc    += 2;

        //
        // STY
        //

        case 0x84; // STY zp
        write_byte(read_byte(pc + 1), y);
        clock += 3;
        pc    += 2;

        case 0x8C; // STY abs
        write_byte(read_word(pc + 1), y);
        clock += 4;
        pc    += 3;

        case 0x94; // STY zpx
        write_byte(read_byte(pc + 1) + x, y);
        clock += 4;
        pc    += 2;

        case;
        assert(false, "Unhandled opcode [%]", opcode);
    }
}

#scope_file

branch_relative :: inline (condition: bool) {
    cpu.clock += 2;
    if condition {
        addr := cpu.pc;
        cpu.pc = cast(u16)(cast(s16)cpu.pc + cast(s8)(read_byte(cpu.pc + 1)));
        cpu.clock += ifx (addr & 0xFF00) != (cpu.pc & 0xFF00) then 2 else 1;
    } else {
        cpu.pc += 2;
    }
}

set_negative_and_zero_flags :: inline (value: u8) {
    cpu.negative = value & 0b10000000 != 0;
    cpu.zero     = value == 0;
}

pull_stack :: inline () -> u8 {
    cpu.sp += 1;
    result := read_byte(cast(u16)0x100 | cpu.sp);
    return result;
}

push_stack :: inline (value: u8) {
    write_byte(cast(u16)0x100 | cpu.sp, value);
    cpu.sp -= 1;
}

pull_flags :: inline () {
    flags := pull_stack();
    cpu.negative          = flags & (1 << 7) != 0;
    cpu.overflow          = flags & (1 << 6) != 0;
    cpu.decimal           = flags & (1 << 3) != 0;
    cpu.interrupt_disable = flags & (1 << 2) != 0;
    cpu.zero              = flags & (1 << 1) != 0;
    cpu.carry             = flags & (1 << 0) != 0;
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