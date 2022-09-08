PPU :: struct {
    // register bytes unpacked for convenience
    vblank : bool;  // ppustatus - 0x2002 - 0b_1000_0000

    clock  : s64;
}

ppu_read_byte :: (address: u16) -> u8 {
    using ppu;

    assert(address == 2, "@TEMPORARY, only handling 0x2002 PPUSTATUS for now");

    status := (cast(u8)vblank) << 7;

    vblank = false;

    return status;
}

ppu_write_byte :: (address: u16, value: u8) {
    // @TODO
}

ppu_tick :: (cycles: s64) {
    using ppu;

    clock += cycles;

    // @TODO: does vblank have to be set on rising and falling edges?
    //        once up and running test if this can simply be:
    //            vblank = frame_clock > vblank_edge;

    frame_clock := clock % (341 * 262);
    vblank_edge :: 341 * 241;
    if     !vblank && frame_clock >  vblank_edge then vblank = true;
    else if vblank && frame_clock <= vblank_edge then vblank = false;
}