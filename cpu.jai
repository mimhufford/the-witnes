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
        case 0x09; // ORA
        acc   |= immediate();
        set_negative_and_zero_flags(acc);
        clock += 2;
        pc    += 2;

        case 0x05; // ORA
        acc   |= read_byte(zero_page());
        set_negative_and_zero_flags(acc);
        clock += 3;
        pc    += 2;

        case 0x15; // ORA
        acc   |= read_byte(zero_page_x());
        set_negative_and_zero_flags(acc);
        clock += 4;
        pc    += 2;

        case 0x01; // ORA
        acc   |= read_byte(indirect_zero_page_x());
        set_negative_and_zero_flags(acc);
        clock += 6;
        pc    += 2;

        case 0x11; // ORA
        acc   |= read_byte(indirect_zero_page_y(extra_cycle = true));
        set_negative_and_zero_flags(acc);
        clock += 5;
        pc    += 2;

        case 0x0D; // ORA
        acc   |= read_byte(absolute());
        set_negative_and_zero_flags(acc);
        clock += 4;
        pc    += 2;

        case 0x1D; // ORA
        acc   |= read_byte(absolute_x(extra_cycle = true));
        set_negative_and_zero_flags(acc);
        clock += 4;
        pc    += 2;

        case 0x19; // ORA
        acc   |= read_byte(absolute_y(extra_cycle = true));
        set_negative_and_zero_flags(acc);
        clock += 4;
        pc    += 2;

        case 0x29; // AND
        acc   &= immediate();
        set_negative_and_zero_flags(acc);
        clock += 2;
        pc    += 2;

        case 0x25; // AND
        acc   &= read_byte(zero_page());
        set_negative_and_zero_flags(acc);
        clock += 3;
        pc    += 2;

        case 0x35; // AND
        acc   &= read_byte(zero_page_x());
        set_negative_and_zero_flags(acc);
        clock += 4;
        pc    += 2;

        case 0x21; // AND
        acc   &= read_byte(indirect_zero_page_x());
        set_negative_and_zero_flags(acc);
        clock += 6;
        pc    += 2;

        case 0x31; // AND
        acc   &= read_byte(indirect_zero_page_y(extra_cycle = true));
        set_negative_and_zero_flags(acc);
        clock += 5;
        pc    += 2;

        case 0x2D; // AND
        acc   &= read_byte(absolute());
        set_negative_and_zero_flags(acc);
        clock += 4;
        pc    += 2;

        case 0x3D; // AND
        acc   &= read_byte(absolute_x(extra_cycle = true));
        set_negative_and_zero_flags(acc);
        clock += 4;
        pc    += 2;

        case 0x39; // AND
        acc   &= read_byte(absolute_y(extra_cycle = true));
        set_negative_and_zero_flags(acc);
        clock += 4;
        pc    += 2;

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

        case 0x4C; // JMP
        clock += 3;
        pc     = absolute();

        case 0x6C; // JMP
        clock += 5;
        pc     = indirect();

        case 0x24; // BIT
        value   := read_byte(zero_page());
        zero     = (value & acc) == 0;
        negative = value & 0b_1000_0000 != 0;
        overflow = value & 0b_0100_0000 != 0;
        clock   += 3;
        pc      += 2;

        case 0x2C; // BIT
        value   := read_byte(absolute());
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

        case 0xA1; // LDA izx
        value := read_byte(indirect_zero_page_x());
        set_negative_and_zero_flags(value);
        acc    = value;
        clock += 6;
        pc    += 2;

        case 0xA5; // LDA
        value := read_byte(zero_page());
        set_negative_and_zero_flags(value);
        acc    = value;
        clock += 3;
        pc    += 2;

        case 0xA9; // LDA
        value := immediate();
        set_negative_and_zero_flags(value);
        acc    = value;
        clock += 2;
        pc    += 2;

        case 0xAD; // LDA
        value := read_byte(absolute());
        set_negative_and_zero_flags(value);
        acc    = value;
        clock += 4;
        pc    += 3;

        case 0xB1; // LDA
        value := read_byte(indirect_zero_page_y(extra_cycle = true));
        set_negative_and_zero_flags(value);
        acc    = value;
        clock += 5;
        pc    += 2;

        case 0xB5; // LDA
        value := read_byte(zero_page_x());
        set_negative_and_zero_flags(value);
        acc    = value;
        clock += 4;
        pc    += 2;

        case 0xB9; // LDA
        value := read_byte(absolute_y(extra_cycle = true));
        set_negative_and_zero_flags(value);
        acc    = value;
        clock += 4;
        pc    += 3;
        
        case 0xBD; // LDA
        value := read_byte(absolute_x(extra_cycle = true));
        set_negative_and_zero_flags(value);
        acc    = value;
        clock += 4;
        pc    += 3;

        case 0xA2; // LDX
        value := immediate();
        set_negative_and_zero_flags(value);
        x      = value;
        clock += 2;
        pc    += 2;

        case 0xA6; // LDX
        value := read_byte(zero_page());
        set_negative_and_zero_flags(value);
        x      = value;
        clock += 3;
        pc    += 2;

        case 0xAE; // LDX
        value := read_byte(absolute());
        set_negative_and_zero_flags(value);
        x      = value;
        clock += 4;
        pc    += 3;

        case 0xB6; // LDX
        value := read_byte(zero_page_y());
        set_negative_and_zero_flags(value);
        x      = value;
        clock += 4;
        pc    += 2;

        case 0xBE; // LDX
        value := read_byte(absolute_y(extra_cycle = true));
        set_negative_and_zero_flags(value);
        x      = value;
        clock += 4;
        pc    += 3;
        
        case 0xA0; // LDY
        value := immediate();
        set_negative_and_zero_flags(value);
        y      = value;
        clock += 2;
        pc    += 2;

        case 0xA4; // LDY
        value := read_byte(zero_page());
        set_negative_and_zero_flags(value);
        y      = value;
        clock += 3;
        pc    += 2;

        case 0xAC; // LDY
        value := read_byte(absolute());
        set_negative_and_zero_flags(value);
        y      = value;
        clock += 4;
        pc    += 3;

        case 0xB4; // LDY
        value := read_byte(zero_page_x());
        set_negative_and_zero_flags(value);
        y      = value;
        clock += 4;
        pc    += 2;

        case 0xBC; // LDY
        value := read_byte(absolute_x(extra_cycle = true));
        set_negative_and_zero_flags(value);
        y      = value;
        clock += 4;
        pc    += 3;

        case 0x81; // STA
        write_byte(indirect_zero_page_x(), acc);
        clock += 6;
        pc    += 2;

        case 0x85; // STA
        write_byte(zero_page(), acc);
        clock += 3;
        pc    += 2;

        case 0x8D; // STA
        write_byte(absolute(), acc);
        clock += 4;
        pc    += 3;
        
        case 0x91; // STA
        write_byte(indirect_zero_page_y(), acc);
        clock += 6;
        pc    += 2;

        case 0x95; // STA
        write_byte(zero_page_x(), acc);
        clock += 4;
        pc    += 2;

        case 0x99; // STA
        write_byte(absolute_y(), acc);
        clock += 5;
        pc    += 3;

        case 0x9D; // STA
        write_byte(absolute_x(), acc);
        clock += 5;
        pc    += 3;

        case 0x86; // STX
        write_byte(zero_page(), x);
        clock += 3;
        pc    += 2;

        case 0x8E; // STX
        write_byte(absolute(), x);
        clock += 4;
        pc    += 3;

        case 0x96; // STX
        write_byte(zero_page_y(), x);
        clock += 4;
        pc    += 2;

        case 0x84; // STY
        write_byte(zero_page(), y);
        clock += 3;
        pc    += 2;

        case 0x8C; // STY
        write_byte(absolute(), y);
        clock += 4;
        pc    += 3;

        case 0x94; // STY
        write_byte(zero_page_x(), y);
        clock += 4;
        pc    += 2;

        case;
        assert(false, "Unhandled opcode [%]", opcode);
    }
}

#scope_file

immediate :: inline () -> u8 {
    return read_byte(cpu.pc + 1);
}

indirect :: inline () -> u16 {
    // @TODO: if first read is the last byte of a page boundary
    //        then the second byte should wrap within the page
    return read_word(read_word(cpu.pc + 1));
}

indirect_zero_page_x :: inline () -> u16 {
    return read_word(read_byte(cpu.pc + 1) + cpu.x);
}

indirect_zero_page_y :: inline (extra_cycle := false) -> u16 {
    addr := read_word(read_byte(cpu.pc + 1));
    if extra_cycle && (addr & 0xFF00) != ((addr + cpu.y) & 0xFF00) cpu.clock += 1;
    return addr + cpu.y;
}

zero_page :: inline () -> u8 {
    return read_byte(cpu.pc + 1);
}

zero_page_x :: inline () -> u8 {
    return read_byte(cpu.pc + 1) + cpu.x;
}

zero_page_y :: inline () -> u8 {
    return read_byte(cpu.pc + 1) + cpu.y;
}

absolute :: inline () -> u16 {
    return read_word(cpu.pc + 1);
}

absolute_x :: inline (extra_cycle := false) -> u16 {
    addr := read_word(cpu.pc + 1);
    if extra_cycle && (addr & 0xFF00) != ((addr + cpu.x) & 0xFF00) cpu.clock += 1;
    return addr + cpu.x;
}

absolute_y :: inline (extra_cycle := false) -> u16 {
    addr := read_word(cpu.pc + 1);
    if extra_cycle && (addr & 0xFF00) != ((addr + cpu.y) & 0xFF00) cpu.clock += 1;
    return addr + cpu.y;
}

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