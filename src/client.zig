const core = @import("core.zig");
const config = @import("config.zig");
const std = @import("std");
const term = @cImport(@cInclude("termbox.h"));
const platform = @import("termbox_plat.zig");
const input = @import("input.zig");

pub const hooks_list = [_]core.Hook {
    .{init, .Init},
    .{draw, .Tick},
    }
    ++ input.hooks_list;

fn init() void {
    platform.init();
}

fn draw() void {
    draw_buf();
    draw_selections();
}

fn draw_buf() void {
    const buf = core.api.c_buf();
    _ = term.tb_clear();

    for(0..core.api.c_buf().lines_size()) |y| {
        _ = term.tb_printf(0, @intCast(y), term.TB_GREEN, 0, "%-.*s", buf.line_size(y)-1, buf.get_line(y).ptr);

    }
    _ = term.tb_present();
}

fn draw_selections() void {
    const buf = core.api.c_buf();

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
