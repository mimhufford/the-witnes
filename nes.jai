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
    
    // initalise the window and pixel buffer
    window = Window.create_window(256 * SCALE, 240 * SCALE, "The WitNES", 100, 100);
    set_render_target(window);
    bitmap_alloc(*bitmap, 256, 240, .RGB8); // @TODO: can probably not alloc and use ppu buffer directly?
    bitmap.data.data = xx ppu.buffer.data;

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

        // print("%  %  A:% X:% Y:% P:% SP:% PPU:% CYC:%\n",
        //         formatInt(cpu.pc,  base=16, minimum_digits=4),
        //         formatInt(op,      base=16, minimum_digits=2),
        //         formatInt(cpu.acc, base=16, minimum_digits=2),
        //         formatInt(cpu.x  , base=16, minimum_digits=2),
        //         formatInt(cpu.y  , base=16, minimum_digits=2),
        //         formatInt(flags  , base=16, minimum_digits=2),
        //         formatInt(cpu.sp , base=16, minimum_digits=2),
        //         ppu.vblank,
        //         cpu.clock,
        // );

        cpu_tick(op);
        vblank := ppu_tick();
        vblank |= ppu_tick();
        vblank |= ppu_tick();

        if vblank cpu_nmi();
        if vblank render(); // @TEMP: didn't think too hard about this
        if vblank sleep_milliseconds(1); // @TEMP throttle until we have better timing
    }
    // }
}

render :: () {
    update_window_events();

    for events_this_frame {
        if it.type == .QUIT  exit(0);

        if it.type == .KEYBOARD {
            if it.key_code == {
                case .ESCAPE;      exit(0);
                case .ARROW_UP;    joypad.up     = it.key_pressed && !it.repeat;
                case .ARROW_DOWN;  joypad.down   = it.key_pressed && !it.repeat;
                case .ARROW_LEFT;  joypad.left   = it.key_pressed && !it.repeat;
                case .ARROW_RIGHT; joypad.right  = it.key_pressed && !it.repeat;
                case .ENTER;       joypad.start  = it.key_pressed && !it.repeat;
                case .BACKSPACE;   joypad.select = it.key_pressed && !it.repeat;
                case #char "Z";    joypad.a      = it.key_pressed && !it.repeat;
                case #char "X";    joypad.b      = it.key_pressed && !it.repeat;
            }
        }
    }

    texture_load_from_bitmap(*texture, *bitmap);
    set_shader_for_images(*texture);
    immediate_begin();
    immediate_quad(0, 0, 256 * SCALE, 240 * SCALE, .{1, 1, 1, 1});
    immediate_flush();
    swap_buffers(window);
}


ram    : [2048]u8;
cpu    : CPU;
ppu    : PPU;
apu    : [  32]u8;
cart   : Cartridge;
joypad : Joypad;

SCALE :: 2;
window : Window.Window_Type;
bitmap : Bitmap;
texture : Texture;

#load "cartridge.jai";
#load "cpu.jai";
#load "ppu.jai";
#load "mapper.jai";
#load "joypad.jai";

#import "Basic";
#import "Simp";
#import "Input";
Window :: #import "Window_Creation";