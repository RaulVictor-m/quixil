//'┴'
const std = @import("std");
const term = @cImport(@cInclude("termbox.h"));
const core = @import("core.zig");
const allocator = std.heap.page_allocator;



pub fn main() !void {

    core.api.init(allocator);
    defer core.api.deinit(.{});

    while(true) {
        core.api.tick(.{});
    }

}

// pub fn main() !void {

//     var ev: term.tb_event = undefined;
//     const y: c_int = 0;

//     _ = term.tb_init();
//     // _ = term.tb_set_input_mode(term.TB_INPUT_ALT);

//     while(true){
//         // TB_ERR_NO_EVENT
//         const code = term.tb_peek_event(&ev, 100);
//         if(code == term.TB_ERR_NO_EVENT) continue;

//         _ = term.tb_clear();
//         if(ev.key == 27) {
//             const code2 = term.tb_peek_event(&ev, 1);
//             if(code2 == term.TB_ERR_NO_EVENT) {
//                 _ = term.tb_printf(0, y, 0, 0, "ESC"++"┴");
//                 std.debug.print("isso e {d}\n", .{'┴'});

//             }else {
//                 _ = term.tb_printf(0, y, 0, 0, "ALT");
//             }

//         }else {
//             if(ev.ch == 'Q') {
//                 break;
//             }
//             _ = term.tb_printf(0, y, 0, 0, "event type=%d key=%d ch=%d", ev.@"type", ev.key, ev.ch);
//         }


//         _ = term.tb_present();
//     }
    // _ = term.tb_shutdown();
// }


