// @TODO: entire file is just hacked in for now

render_init :: () {
    window = Window.create_window(256, 240, "The WitNES", 100, 100);
    set_render_target(window);

    bitmap_alloc(*bitmap, 256, 240, .RGB8);
    bitmap.data.data = xx ppu.buffer.data;
}

render :: () {
    texture_load_from_bitmap(*texture, *bitmap);
    clear_render_target(.15, .08, .08, 1);
    set_shader_for_color();
    set_shader_for_images(*texture);
    immediate_begin();
    immediate_quad(0, 0, 256, 240, .{1, 1, 1, 1});
    immediate_flush();
    swap_buffers(window);
}

#scope_file

window : Window.Window_Type;
bitmap : Bitmap;
texture : Texture;

#import "Simp";
Window :: #import "Window_Creation";