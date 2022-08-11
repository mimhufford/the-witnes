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

ram : [2048]u8;
ppu : [   8]u8;
apu : [  32]u8;
cpu : CPU;

#import "Basic";
#load "cartridge.jai";
#load "cpu.jai";