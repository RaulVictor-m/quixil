const std = @import("std");
const term = @cImport(@cInclude("termbox.h"));
const core = @import("core.zig");
const client = @import("client.zig");
const Point = core.Point;
const KeyPress = client.KeyPress;
const Mod = client.Mod;

const Color = enum(c_int){
    Blue = term.TB_BLUE,
    Green = term.TB_GREEN,
    Yellow = term.TB_YELLOW,
    Red = term.TB_RED,
    Black = term.TB_BLACK,
};

pub fn init() void {
    _ = term.tb_init();
}

pub fn draw_str(buf: []const u8, x: u32, y: u32, fg_col: Color, bg_col: Color) void {
    _ = term.tb_printf(
            @intCast(x), @intCast(y),
            fg_col, bg_col, "%-.*s",
            buf.len-1, buf.ptr
        );
}

pub fn clear_buf(bg_col: Color) void {
    _ = term.tb_clear(bg_col);
}

pub fn clear_line(y: u32, fg_col: Color, bg_col: Color) void {
    _ = term.tb_print(0, @intCast(y), fg_col, bg_col, "");
}

pub fn get_input() !KeyPress{
    var ev: term.tb_event = undefined;
    const input = term.tb_peek_event(&ev, 100);


    if(input == term.TB_ERR_NO_EVENT) return error.NoInput;
    if(ev.@"type" != term.TB_EVENT_KEY) return error.NoInputKey;

    var mod: Mod = .None;
    var key: u8 = undefined;

    if(ev.key == term.TB_KEY_ESC) {

        const sec_input = term.tb_peek_event(&ev, 1);
        if(sec_input == term.TB_ERR_NO_EVENT) {
            key = 27; // ascii for ESC
        } else {
            mod = .Alt;
            key = @truncate(ev.ch);
        }

    } else {

        if(ev.ch == 0) {
            if(ev.key <= 0x20) { //ctrl keys
                if( ev.key == 0x8 or ev.key == 0x9 or
                    ev.key == 0xd or ev.key == 0x1b or
                    ev.key == 0x1f ) {
                    key = @truncate(ev.key);
                } else {
                    mod = .Ctrl;
                    key = CTRL_TABLE[ev.key];
                }
            }
        } else {
            key = @truncate(ev.ch);
        }
    }
    return .{mod, key};
}

const CTRL_TABLE = [_]u8 {
'~'               ,//0x00
'2'               ,//0x00
'A'               ,//0x01
'B'               ,//0x02
'C'               ,//0x03
'D'               ,//0x04
'E'               ,//0x05
'F'               ,//0x06
'G'               ,//0x07
'H'               ,//0x08   backspace
'I'               ,//0x09   tab
'J'               ,//0x0a
'K'               ,//0x0b
'L'               ,//0x0c
'\n'               ,//0x0d   ctrl-m /return
'N'               ,//0x0e
'O'               ,//0x0f
'P'               ,//0x10
'Q'               ,//0x11
'R'               ,//0x12
'S'               ,//0x13
'T'               ,//0x14
'U'               ,//0x15
'V'               ,//0x16
'W'               ,//0x17
'X'               ,//0x18
'Y'               ,//0x19
'Z'               ,//0x1a
'['               ,//0x1b   esc
'\\'              ,//0x1c
']'               ,//0x1d
'6'               ,//0x1e
'/'               ,//0x1f   _
' '               ,//0x20
8                 ,//0x7f   backspace
};
