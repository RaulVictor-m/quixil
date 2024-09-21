const core = @import("core.zig");
const config = @import("config.zig");
const std = @import("std");
const term = @cImport(@cInclude("termbox.h"));

pub const hooks_list = [_]core.Hook {
    .{init, .Init},
    .{draw, .Tick},
    .{get_input, .Tick},
};

pub const Mod = enum {
    Alt,
    Ctrl,
    None,
};

pub const KeyBindFunc = fn(anytype) callconv(.Inline) void;

pub const Param = struct {
    type,
    *const anyopaque,
};

pub inline fn param(p: anytype) Param {
    comptime var res: Param = undefined;
    res[0] = @TypeOf(p);
    res[1] = &@as(res[0], p);
    return res;
}

pub const KeyBind = struct {
    core.Mode,                //0
    Mod,                      //1
    u8,                       //2
    KeyBindFunc,              //3
    ?Param = null,
};

inline fn get(
    bind: KeyBind,
    field: enum {Mode, Mod, Char, Func, Param}
) @TypeOf(bind[@intFromEnum(field)]) {
        return bind[@intFromEnum(field)];
    }


inline fn init() void {
    _ = term.tb_init();
}

inline fn draw() void {
    draw_buf();
    draw_selections();
}

inline fn draw_buf() void {
    const buf = core.api.c_buf();
    _ = term.tb_clear();

    for(0..core.api.c_buf().lines_size()) |y| {
        _ = term.tb_printf(0, @intCast(y), term.TB_GREEN, 0, "%-.*s", buf.line_size(y)-1, buf.get_line(y).ptr);

    }
    _ = term.tb_present();
}

inline fn draw_selections() void {
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

inline fn get_input() void {
    var ev: term.tb_event = undefined;
    const input = term.tb_peek_event(&ev, 100);


    if(input == term.TB_ERR_NO_EVENT) return;
    if(ev.@"type" != term.TB_EVENT_KEY) return;

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

    const index = get_index(core.api.get_mode(), mod, key);
    input_action(index);
}

inline fn input_action(index: u16) void {
    @setEvalBranchQuota(10000);
    switch(index) {
        inline 0...KeyBindTable.len - 1 => |i| {
            if(KeyBindTable[i][1]) |P|{
                KeyBindTable[i][0](@as(*const P[0], @ptrCast(P[1])).*);
            }else {
                KeyBindTable[i][0](.{});
            }
        },
        else => unreachable,
    }
}

inline fn generic_func(_ : anytype) void{
    // unreachable;
}

inline fn get_index(mode: core.Mode, mod: Mod, key: u32) u16 {
    const mode_i: u16 = @intFromEnum(mode);
    const mod_i: u16 = @intFromEnum(mod);
    const key_i: u16 = @truncate(key);

    return (mode_i << 10) | (mod_i << 8) | key_i;
}

const KeyBindTable = blk: {

    const TableNode = struct{
        KeyBindFunc,
        ?Param,
    };
    var result: [4096]TableNode = [_]TableNode{ .{generic_func, null}}**4096;

    for (config.keys) |k| {
        const index = get_index(get(k, .Mode), get(k, .Mod), get(k, .Char));
        result[index][0] = get(k, .Func);
        result[index][1] = get(k, .Param);
    }
    break :blk result;
};

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
'M'               ,//0x0d   enter
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

