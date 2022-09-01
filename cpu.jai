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

tick :: (opcode: u8) {
    using cpu;

    if opcode == {
        case 0x09; ORA(2, 2, immediate());
        case 0x05; ORA(3, 2, zero_page());
        case 0x15; ORA(4, 2, zero_page_x());
        case 0x01; ORA(6, 2, indirect_zero_page_x());
        case 0x11; ORA(5, 2, indirect_zero_page_y(extra_cycle = true));
        case 0x0D; ORA(4, 3, absolute());
        case 0x19; ORA(4, 3, absolute_y(extra_cycle = true));
        case 0x1D; ORA(4, 3, absolute_x(extra_cycle = true));

        case 0x29; AND(2, 2, immediate());
        case 0x25; AND(3, 2, zero_page());
        case 0x35; AND(4, 2, zero_page_x());
        case 0x21; AND(6, 2, indirect_zero_page_x());
        case 0x31; AND(5, 2, indirect_zero_page_y(extra_cycle = true));
        case 0x2D; AND(4, 3, absolute());
        case 0x3D; AND(4, 3, absolute_x(extra_cycle = true));
        case 0x39; AND(4, 3, absolute_y(extra_cycle = true));

        case 0x49; EOR(2, 2, immediate());
        case 0x45; EOR(3, 2, zero_page());
        case 0x55; EOR(4, 2, zero_page_x());
        case 0x41; EOR(6, 2, indirect_zero_page_x());
        case 0x51; EOR(5, 2, indirect_zero_page_y(extra_cycle = true));
        case 0x4D; EOR(4, 3, absolute());
        case 0x5D; EOR(4, 3, absolute_x(extra_cycle = true));
        case 0x59; EOR(4, 3, absolute_y(extra_cycle = true));

        case 0x69; ADC(2, 2, immediate());
        case 0x65; ADC(3, 2, zero_page());
        case 0x75; ADC(4, 2, zero_page_x());
        case 0x61; ADC(6, 2, indirect_zero_page_x());
        case 0x71; ADC(5, 2, indirect_zero_page_y(extra_cycle = true));
        case 0x6D; ADC(4, 3, absolute());
        case 0x7D; ADC(4, 3, absolute_x(extra_cycle = true));
        case 0x79; ADC(4, 3, absolute_y(extra_cycle = true));

        case 0xEB; SBC(2, 2, immediate());
        case 0xE9; SBC(2, 2, immediate());
        case 0xE5; SBC(3, 2, zero_page());
        case 0xF5; SBC(4, 2, zero_page_x());
        case 0xE1; SBC(6, 2, indirect_zero_page_x());
        case 0xF1; SBC(5, 2, indirect_zero_page_y(extra_cycle = true));
        case 0xED; SBC(4, 3, absolute());
        case 0xFD; SBC(4, 3, absolute_x(extra_cycle = true));
        case 0xF9; SBC(4, 3, absolute_y(extra_cycle = true));

        case 0xC9; compare(2, 2, acc, immediate());                               // CMP
        case 0xC5; compare(3, 2, acc, zero_page());                               // CMP
        case 0xD5; compare(4, 2, acc, zero_page_x());                             // CMP
        case 0xC1; compare(6, 2, acc, indirect_zero_page_x());                    // CMP
        case 0xD1; compare(6, 2, acc, indirect_zero_page_y(extra_cycle = true));  // CMP
        case 0xCD; compare(4, 3, acc, absolute());                                // CMP
        case 0xDD; compare(4, 3, acc, absolute_x(extra_cycle = true));            // CMP
        case 0xD9; compare(4, 3, acc, absolute_y(extra_cycle = true));            // CMP

        case 0xE0; compare(2, 2, x, immediate()); // CPX
        case 0xE4; compare(3, 2, x, zero_page()); // CPX
        case 0xEC; compare(4, 3, x, absolute());  // CPX

        case 0xC0; compare(2, 2, y, immediate()); // CPY
        case 0xC4; compare(3, 2, y, zero_page()); // CPY
        case 0xCC; compare(4, 3, y, absolute());  // CPY

        case 0xC6; DEC(5, 2, zero_page());
        case 0xD6; DEC(6, 2, zero_page_x());
        case 0xCE; DEC(6, 3, absolute());
        case 0xDE; DEC(7, 3, absolute_x());

        case 0xC7; DCP(5, 2, zero_page());
        case 0xD7; DCP(6, 2, zero_page_x());
        case 0xC3; DCP(8, 2, indirect_zero_page_x());
        case 0xD3; DCP(8, 2, indirect_zero_page_y());
        case 0xCF; DCP(6, 3, absolute());
        case 0xDF; DCP(7, 3, absolute_x());
        case 0xDB; DCP(7, 3, absolute_y());

        case 0xE6; INC(5, 2, zero_page());
        case 0xF6; INC(6, 2, zero_page_x());
        case 0xEE; INC(6, 3, absolute());
        case 0xFE; INC(7, 3, absolute_x());

        case 0xE7; ISC(5, 2, zero_page());
        case 0xF7; ISC(6, 2, zero_page_x());
        case 0xE3; ISC(8, 2, indirect_zero_page_x());
        case 0xF3; ISC(8, 2, indirect_zero_page_y());
        case 0xEF; ISC(6, 3, absolute());
        case 0xFF; ISC(7, 3, absolute_x());
        case 0xFB; ISC(7, 3, absolute_y());

        case 0xA9; LDA(2, 2, immediate());
        case 0xA5; LDA(3, 2, zero_page());
        case 0xB5; LDA(4, 2, zero_page_x());
        case 0xA1; LDA(6, 2, indirect_zero_page_x());
        case 0xB1; LDA(5, 2, indirect_zero_page_y(extra_cycle = true));
        case 0xAD; LDA(4, 3, absolute());
        case 0xBD; LDA(4, 3, absolute_x(extra_cycle = true));
        case 0xB9; LDA(4, 3, absolute_y(extra_cycle = true));

        case 0xAB; LAX(2, 2, immediate());
        case 0xA7; LAX(3, 2, zero_page());
        case 0xB7; LAX(4, 2, zero_page_y());
        case 0xA3; LAX(6, 2, indirect_zero_page_x());
        case 0xB3; LAX(5, 2, indirect_zero_page_y(extra_cycle = true));
        case 0xAF; LAX(4, 3, absolute());
        case 0xBF; LAX(4, 3, absolute_y(extra_cycle = true));

        case 0xA2; LDX(2, 2, immediate());
        case 0xA6; LDX(3, 2, zero_page());
        case 0xB6; LDX(4, 2, zero_page_y());
        case 0xAE; LDX(4, 3, absolute());
        case 0xBE; LDX(4, 3, absolute_y(extra_cycle = true));
        
        case 0xA0; LDY(2, 2, immediate());
        case 0xA4; LDY(3, 2, zero_page());
        case 0xB4; LDY(4, 2, zero_page_x());
        case 0xAC; LDY(4, 3, absolute());
        case 0xBC; LDY(4, 3, absolute_x(extra_cycle = true));

        case 0x85; store(3, 2, acc, zero_page());             // STA
        case 0x95; store(4, 2, acc, zero_page_x());           // STA
        case 0x81; store(6, 2, acc, indirect_zero_page_x());  // STA
        case 0x91; store(6, 2, acc, indirect_zero_page_y());  // STA
        case 0x8D; store(4, 3, acc, absolute());              // STA
        case 0x99; store(5, 3, acc, absolute_y());            // STA
        case 0x9D; store(5, 3, acc, absolute_x());            // STA

        case 0x86; store(3, 2, x, zero_page());     // STX
        case 0x96; store(4, 2, x, zero_page_y());   // STX
        case 0x8E; store(4, 3, x, absolute());      // STX

        case 0x84; store(3, 2, y, zero_page());     // STY
        case 0x94; store(4, 2, y, zero_page_x());   // STY
        case 0x8C; store(4, 3, y, absolute());      // STY

        case 0x87; store(3, 2, acc & x, zero_page());             // SAX
        case 0x97; store(4, 2, acc & x, zero_page_y());           // SAX
        case 0x83; store(6, 2, acc & x, indirect_zero_page_x());  // SAX
        case 0x8F; store(4, 3, acc & x, absolute());              // SAX

        case 0x10; branch_relative(!negative);  // BPL
        case 0x30; branch_relative( negative);  // BMI
        case 0x50; branch_relative(!overflow);  // BVC
        case 0x70; branch_relative( overflow);  // BVS
        case 0x90; branch_relative(!carry);     // BCC
        case 0xB0; branch_relative( carry);     // BCS
        case 0xD0; branch_relative(!zero);      // BNE
        case 0xF0; branch_relative( zero);      // BEQ

        case 0xE8; increment(*x);  // INX
        case 0xC8; increment(*y);  // INY
        case 0xCA; decrement(*x);  // DEX
        case 0x88; decrement(*y);  // DEY

        case 0x0A; ASL(2, 1);
        case 0x06; ASL(5, 2, zero_page());
        case 0x16; ASL(6, 2, zero_page_x());
        case 0x0E; ASL(6, 3, absolute());
        case 0x1E; ASL(7, 3, absolute_x());

        case 0x07; SLO(5, 2, zero_page());
        case 0x17; SLO(6, 2, zero_page_x());
        case 0x03; SLO(8, 2, indirect_zero_page_x());
        case 0x13; SLO(8, 2, indirect_zero_page_y());
        case 0x0F; SLO(6, 3, absolute());
        case 0x1F; SLO(7, 3, absolute_x());
        case 0x1B; SLO(7, 3, absolute_y());

        case 0x2A; ROL(2, 1);
        case 0x26; ROL(5, 2, zero_page());
        case 0x36; ROL(6, 2, zero_page_x());
        case 0x2E; ROL(6, 3, absolute());
        case 0x3E; ROL(7, 3, absolute_x());

        case 0x27; RLA(5, 2, zero_page());
        case 0x37; RLA(6, 2, zero_page_x());
        case 0x23; RLA(8, 2, indirect_zero_page_x());
        case 0x33; RLA(8, 2, indirect_zero_page_y());
        case 0x2F; RLA(6, 3, absolute());
        case 0x3F; RLA(7, 3, absolute_x());
        case 0x3B; RLA(7, 3, absolute_y());

        case 0x6A; ROR(2, 1);
        case 0x66; ROR(5, 2, zero_page());
        case 0x76; ROR(6, 2, zero_page_x());
        case 0x6E; ROR(6, 3, absolute());
        case 0x7E; ROR(7, 3, absolute_x());

        case 0x4A; LSR(2, 1);
        case 0x46; LSR(5, 2, zero_page());
        case 0x56; LSR(6, 2, zero_page_x());
        case 0x4E; LSR(6, 3, absolute());
        case 0x5E; LSR(7, 3, absolute_x());

        case 0x47; SRE(5, 2, zero_page());
        case 0x57; SRE(6, 2, zero_page_x());
        case 0x43; SRE(8, 2, indirect_zero_page_x());
        case 0x53; SRE(8, 2, indirect_zero_page_y());
        case 0x4F; SRE(6, 2, absolute());
        case 0x5F; SRE(7, 2, absolute_x());
        case 0x5B; SRE(7, 2, absolute_y());

        case 0x4C; JMP(3, absolute());
        case 0x6C; JMP(5, indirect());

        case 0x24; BIT(3, 2, zero_page());
        case 0x2C; BIT(4, 3, absolute());

        case 0x18; set_flag(*carry,             false);  // CLC
        case 0x38; set_flag(*carry,             true);   // SEC
        case 0xD8; set_flag(*decimal,           false);  // CLD
        case 0xF8; set_flag(*decimal,           true);   // SED
        case 0x58; set_flag(*interrupt_disable, false);  // CLI
        case 0x78; set_flag(*interrupt_disable, true);   // SEI
        case 0xB8; set_flag(*overflow,          false);  // CLV

        case 0x1A; NOP(1);
        case 0x3A; NOP(1);
        case 0x5A; NOP(1);
        case 0x7A; NOP(1);
        case 0xDA; NOP(1);
        case 0xEA; NOP(1);
        case 0xFA; NOP(1);
        case 0x04; NOP(2);
        case 0x14; NOP(2);
        case 0x34; NOP(2);
        case 0x44; NOP(2);
        case 0x54; NOP(2);
        case 0x64; NOP(2);
        case 0x74; NOP(2);
        case 0x80; NOP(2);
        case 0xD4; NOP(2);
        case 0xF4; NOP(2);
        case 0x0C; NOP(3);
        case 0x1C; NOP(3);
        case 0x3C; NOP(3);
        case 0x5C; NOP(3);
        case 0x7C; NOP(3);
        case 0xDC; NOP(3);
        case 0xFC; NOP(3);

        case 0xAA; transfer(acc, *x, set_flags = true);   // TAX
        case 0x8A; transfer(x, *acc, set_flags = true);   // TXA
        case 0xA8; transfer(acc, *y, set_flags = true);   // TAY
        case 0x98; transfer(y, *acc, set_flags = true);   // TYA
        case 0xBA; transfer(sp, *x,  set_flags = true);   // TSX
        case 0x9A; transfer(x, *sp,  set_flags = false);  // TXS

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
        pc     = (cast(u16)pull_stack()) | ((cast(u16)pull_stack()) << 8);

        case 0x20; // JSR
        push_stack(cast(u8)(((pc + 2) >> 8) & 0xFF));
        push_stack(cast(u8)(((pc + 2) >> 0) & 0xFF));
        clock += 6;
        pc     = read_word(pc + 1);

        case 0x60; // RTS
        clock += 6;
        pc     = (cast(u16)pull_stack()) | ((cast(u16)pull_stack()) << 8);
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

        case; assert(false, "Unhandled opcode [%]", formatInt(opcode, base=16));
    }
}

#scope_file

immediate :: inline () -> u16 {
    return cpu.pc + 1;
}

indirect :: inline () -> u16 {
    addr := read_word(cpu.pc + 1);
    return (cast(u16)read_byte((addr & 0xFF00) | ((addr + 1) & 0x00FF))) << 8 | read_byte(addr);
}

indirect_zero_page_x :: inline () -> u16 {
    return read_word(read_byte(cpu.pc + 1) + cpu.x);
}

indirect_zero_page_y :: inline (extra_cycle := false) -> u16 {
    addr := read_word(read_byte(cpu.pc + 1));
    if extra_cycle && (addr & 0xFF00) != ((addr + cpu.y) & 0xFF00) cpu.clock += 1;
    return addr + cpu.y;
}

zero_page :: inline () -> u16 {
    return read_byte(cpu.pc + 1);
}

zero_page_x :: inline () -> u16 {
    return read_byte(cpu.pc + 1) + cpu.x;
}

zero_page_y :: inline () -> u16 {
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
        cpu.pc = cast,no_check(u16)(cast,no_check(s16)(cpu.pc + 2) + cast,no_check(s8) read_byte(cpu.pc + 1));
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
    flags := ((cast(u8)cpu.negative)          << 7) |
             ((cast(u8)cpu.overflow)          << 6) |
             ((cast(u8)bit_5)                 << 5) |
             ((cast(u8)bit_4)                 << 4) |
             ((cast(u8)cpu.decimal)           << 3) |
             ((cast(u8)cpu.interrupt_disable) << 2) |
             ((cast(u8)cpu.zero)              << 1) |
             ((cast(u8)cpu.carry)             << 0);
    push_stack(flags);
}

ORA :: inline (cycles: s64, bytes: u16, location: u16) {
    cpu.acc   |= read_byte(location);
    cpu.clock += cycles;
    cpu.pc    += bytes;
    set_negative_and_zero_flags(cpu.acc);
}

AND :: inline (cycles: s64, bytes: u16, location: u16) {
    cpu.acc   &= read_byte(location);
    cpu.clock += cycles;
    cpu.pc    += bytes;
    set_negative_and_zero_flags(cpu.acc);
}

EOR :: inline (cycles: s64, bytes: u16, location: u16) {
    cpu.acc   ^= read_byte(location);
    cpu.clock += cycles;
    cpu.pc    += bytes;
    set_negative_and_zero_flags(cpu.acc);
}

ADC :: inline (cycles: s64, bytes: u16, location: u16) {
    value   : u16 = read_byte(location);
    sum     : u16 = cast(u16)cpu.acc + value + cast(u16)cpu.carry;
    cpu.carry     = sum & 0x0100 != 0;
    cpu.overflow  = (cpu.acc ^ sum) & (value ^ sum) & 0x80 != 0;
    cpu.acc       = cast(u8)(sum & 0xFF);
    cpu.clock    += cycles;
    cpu.pc       += bytes;
    set_negative_and_zero_flags(cpu.acc);
}

SBC :: inline (cycles: s64, bytes: u16, location: u16) {
    value   : u16 = read_byte(location);
    sum     : u16 = cast(u16)cpu.acc - value - cast(u16)!cpu.carry;
    cpu.carry     = sum & 0x0100 == 0;
    cpu.overflow  = (cpu.acc ^ sum) & (~value ^ sum) & 0x80 != 0;
    cpu.acc       = cast(u8)(sum & 0xFF);
    cpu.clock    += cycles;
    cpu.pc       += bytes;
    set_negative_and_zero_flags(cpu.acc);
}

DEC :: inline (cycles: s64, bytes: u16, location: u16) {
    cpu.clock += cycles;
    cpu.pc    += bytes;
    value     := read_byte(location) - 1;
    write_byte(location, value);
    set_negative_and_zero_flags(value);
}

DCP :: inline (cycles: s64, bytes: u16, location: u16) {
    DEC(0, 0, location);
    compare(cycles, bytes, cpu.acc, location);
}

INC :: inline (cycles: s64, bytes: u16, location: u16) {
    cpu.clock += cycles;
    cpu.pc    += bytes;
    value     := read_byte(location) + 1;
    write_byte(location, value);
    set_negative_and_zero_flags(value);
}

ISC :: inline (cycles: s64, bytes: u16, location: u16) {
    INC(0, 0, location);
    SBC(cycles, bytes, location);
}

LDA :: inline (cycles: s64, bytes: u16, location: u16) {
    cpu.acc    = read_byte(location);
    cpu.clock += cycles;
    cpu.pc    += bytes;
    set_negative_and_zero_flags(cpu.acc);
}

LAX :: inline (cycles: s64, bytes: u16, location: u16) {
    cpu.acc    = read_byte(location);
    cpu.x      = cpu.acc;
    cpu.clock += cycles;
    cpu.pc    += bytes;
    set_negative_and_zero_flags(cpu.acc);
}

LDX :: inline (cycles: s64, bytes: u16, location: u16) {
    cpu.x      = read_byte(location);
    cpu.clock += cycles;
    cpu.pc    += bytes;
    set_negative_and_zero_flags(cpu.x);
}

LDY :: inline (cycles: s64, bytes: u16, location: u16) {
    cpu.y      = read_byte(location);
    cpu.clock += cycles;
    cpu.pc    += bytes;
    set_negative_and_zero_flags(cpu.y);
}

store :: (cycles: s64, bytes: u16, value: u8, location: u16) {
    write_byte(location, value);
    cpu.clock += cycles;
    cpu.pc    += bytes;
}

BIT :: inline (cycles: s64, bytes: u16, location: u16) {
    value       := read_byte(location);
    cpu.zero     = (value & cpu.acc) == 0;
    cpu.negative = value & 0b_1000_0000 != 0;
    cpu.overflow = value & 0b_0100_0000 != 0;
    cpu.clock   += cycles;
    cpu.pc      += bytes;
}

JMP :: inline (cycles: s64, location: u16) {
    cpu.clock += cycles;
    cpu.pc     = location;
}

NOP :: inline (bytes: u16) {
    // @TODO: clock based on type of NOP
    cpu.clock += 2;
    cpu.pc    += bytes;
}

ASL :: inline (cycles: s64, bytes: u16) {
    cpu.clock += cycles;
    cpu.pc    += bytes;
    cpu.carry  = cpu.acc & 0x80 != 0;
    cpu.acc  <<= 1;
    set_negative_and_zero_flags(cpu.acc);
}

ASL :: inline (cycles: s64, bytes: u16, location: u16) {
    cpu.clock += cycles;
    cpu.pc    += bytes;
    value     := read_byte(location);
    cpu.carry  = value & 0x80 != 0;
    value    <<= 1;
    write_byte(location, value);
    set_negative_and_zero_flags(value);
}

SLO :: inline (cycles: s64, bytes: u16, location: u16) {
    ASL(0, 0, location);
    ORA(cycles, bytes, location);
}

LSR :: inline (cycles: s64, bytes: u16) {
    cpu.clock += cycles;
    cpu.pc    += bytes;
    cpu.carry  = cpu.acc & 0x1 != 0;
    cpu.acc  >>= 1;
    set_negative_and_zero_flags(cpu.acc);
}

LSR :: inline (cycles: s64, bytes: u16, location: u16) {
    cpu.clock += cycles;
    cpu.pc    += bytes;
    value     := read_byte(location);
    cpu.carry  = value & 0x1 != 0;
    value    >>= 1;
    write_byte(location, value);
    set_negative_and_zero_flags(value);
}

SRE :: inline (cycles: s64, bytes: u16, location: u16) {
    LSR(0, 0, location);
    EOR(cycles, bytes, location);
}

ROL :: inline (cycles: s64, bytes: u16) {
    cpu.clock += cycles;
    cpu.pc    += bytes;
    pre_carry := cpu.carry;
    cpu.carry  = cpu.acc & 0x80 != 0;
    cpu.acc  <<= 1;
    cpu.acc   |= cast(u8)pre_carry;
    set_negative_and_zero_flags(cpu.acc);
}

ROL :: inline (cycles: s64, bytes: u16, location: u16) {
    cpu.clock += cycles;
    cpu.pc    += bytes;
    pre_carry := cpu.carry;
    value     := read_byte(location);
    cpu.carry  = value & 0x80 != 0;
    value    <<= 1;
    value     |= cast(u8)pre_carry;
    write_byte(location, value);
    set_negative_and_zero_flags(value);
}

RLA :: inline (cycles: s64, bytes: u16, location: u16) {
    ROL(0, 0, location);
    AND(cycles, bytes, location);
}

ROR :: inline (cycles: s64, bytes: u16) {
    cpu.clock += cycles;
    cpu.pc    += bytes;
    pre_carry := cpu.carry;
    cpu.carry  = cpu.acc & 0x1 != 0;
    cpu.acc  >>= 1;
    cpu.acc   |= (cast(u8)pre_carry) << 7;
    set_negative_and_zero_flags(cpu.acc);
}

ROR :: inline (cycles: s64, bytes: u16, location: u16) {
    cpu.clock += cycles;
    cpu.pc    += bytes;
    pre_carry := cpu.carry;
    value     := read_byte(location);
    cpu.carry  = value & 0x1 != 0;
    value    >>= 1;
    value     |= (cast(u8)pre_carry) << 7;
    write_byte(location, value);
    set_negative_and_zero_flags(value);
}

decrement :: inline (reg: *u8) {
    cpu.clock += 2;
    cpu.pc    += 1;
    <<reg     -= 1;
    set_negative_and_zero_flags(<<reg);
}

increment :: inline (reg: *u8) {
    cpu.clock += 2;
    cpu.pc    += 1;
    <<reg     += 1;
    set_negative_and_zero_flags(<<reg);
}

set_flag :: inline (flag: *bool, value: bool) {
    cpu.clock += 2;
    cpu.pc    += 1;
    <<flag     = value;
}

transfer :: inline (src: u8, dest: *u8, set_flags: bool) {
    cpu.clock += 2;
    cpu.pc    += 1;
    <<dest     = src;
    if set_flags then set_negative_and_zero_flags(src);
}

compare :: inline (cycles: s64, bytes: u16, src: u8, location: u16) {
    value       := read_byte(location);
    cpu.clock   += cycles;
    cpu.pc      += bytes;
    cpu.negative = src != value;
    cpu.carry    = src >= value;
    cpu.zero     = src == value;
}