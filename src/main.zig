const std = @import("std");
const term = @cImport(@cInclude("termbox.h"));
const core = @import("core.zig");
const allocator = std.heap.page_allocator;

fn draw_buf() void{
    const buf = core.api.c_buf();
    _ = term.tb_clear();

    for(0..core.api.c_buf().lines_size()) |y| {
        _ = term.tb_printf(0, @intCast(y), term.TB_GREEN, 0, "%-.*s", buf.line_size(y)-1, buf.get_line(y).ptr);

    }
    for(buf.sels.items) |s| {

        var s_bx: u32 = s.begin.x;
        for(s.begin.y..s.end.y+1) |s_y| {

            if(s_y == s.end.y) {
                for(s_bx..s.end.x+1) |s_x| {
                _ = term.tb_set_cell(@intCast(s_x), @intCast(s_y), @intCast(buf.get_c(s_y,s_x)),
                term.TB_GREEN, term.TB_WHITE);
                }
            } else {
                for(s_bx..buf.line_size(s_y)) |s_x| {
                _ = term.tb_set_cell(@intCast(s_x), @intCast(s_y), @intCast(buf.get_c(s_y,s_x)),
                term.TB_GREEN, term.TB_WHITE);
                }
            s_bx = 0;
            }
        }
    }
    _ = term.tb_present();
}

pub fn main() !void {
    const text = "I really need this to work\n" ++
                 "We are going to test out how to it goes\n";


    core.g_editor.buffers = std.ArrayList(core.Buffer).init(allocator);
    try core.g_editor.buffers.append(try core.Buffer.init_text(allocator, text));

    _ = term.tb_init();

    draw_buf();

    var ev: term.tb_event = undefined;
    while(true) {
        _ = term.tb_poll_event(&ev);

        if(ev.@"type" != term.TB_EVENT_KEY) continue;

        switch(@as(u8, @intCast(ev.ch))) {
            'd' => core.api.delete(),
            'l' => core.api.move(.LLeft),
            'h' => core.api.move(.LRight),
            'L' => core.api.move_extend(.LLeft),
            'H' => core.api.move_extend(.LRight),
            'Q' => {
                _ = term.tb_shutdown();
                break;
            },
            else => continue,
        }
        draw_buf();

    }
    core.api.c_buf().print_buffer();

}

// pub fn main() !void {

    // var ev: term.tb_event = undefined;
//     var y: c_int = 0;

//     _ = term.tb_init();

//     _ = term.tb_printf(0, y, term.TB_GREEN, 0, "hello from termbox");
//     y += 1;
//     _ = term.tb_printf(0, y, 0, 0, "width=%d height=%d", term.tb_width(), term.tb_height());
//     y += 1;
//     _ = term.tb_printf(0, y, 0, 0, "press any key...");
//     y += 1;
//     _ = term.tb_present();

//     _ = term.tb_poll_event(&ev);

//     y += 1;
//     _ = term.tb_printf(0, y, 0, 0, "event type=%d key=%d ch=%c", ev.@"type", ev.key, ev.ch);
//     y += 1;
//     _ = term.tb_printf(0, y, 0, 0, "press any key to quit...");
//     y += 1;
//     _ = term.tb_present();

//     _ = term.tb_poll_event(&ev);
//     _ = term.tb_shutdown();
// }


