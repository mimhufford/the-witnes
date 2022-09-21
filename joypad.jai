Joypad :: struct {
    a      : bool;
    b      : bool;
    select : bool;
    start  : bool;
    up     : bool;
    down   : bool;
    left   : bool;
    right  : bool;

    data   : u8;
}

joypad_poll :: () {
    using joypad;
    data = ((cast(u8)right)  << 7) |
           ((cast(u8)left)   << 6) |
           ((cast(u8)down)   << 5) |
           ((cast(u8)up)     << 4) |
           ((cast(u8)start)  << 3) |
           ((cast(u8)select) << 2) |
           ((cast(u8)b)      << 1) |
           ((cast(u8)a)      << 0);
}

joypad_read :: () -> u8 {
    using joypad;
    state := data & 1;
    data >>= 1;
    return state;
}