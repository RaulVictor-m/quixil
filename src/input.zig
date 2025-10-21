const core = @import("core.zig");
const config = @import("config.zig");
const std = @import("std");
const term = @cImport(@cInclude("termbox.h"));
const platform = @import("termbox_plat.zig");

pub const hooks_list = [_]core.Hook {
    .{get_input, .Tick},
};

pub const Mod = enum {
    None,
    Alt,
    Ctrl,
};

pub const KeyBindFunc = fn(anytype) void;
pub const Param = struct {
    type,
    *const anyopaque,
};

/// given a value it will make a keybindParam back(internal use)
pub fn param(p: anytype) Param {
    comptime var res: Param = undefined;
    res[0] = @TypeOf(&p);
    res[1] = @ptrCast(&@as(@TypeOf(p), p));
    return res;
}

pub const KeyPress = struct {
    Mod,                      //1
    u8,                       //2
};

pub const KeyBind = struct {
    core.Mode,                //0
    Mod,                      //1
    u8,                       //2
    KeyBindFunc,              //3
    ?Param,
};

fn get(
    bind: KeyBind,
    field: enum {Mode, Mod, Char, Func, Param}
) @TypeOf(bind[@intFromEnum(field)]) {
        return bind[@intFromEnum(field)];
    }

fn get_input() void {
    const input = platform.get_input();
    if(input) |i| {
        const index = get_index(core.api.get_mode(), i[0], i[1]);
        input_action(index);
    } else |_| {}
}

fn input_action(index: u16) void {
    @setEvalBranchQuota(200000);
    switch(index) {
        inline 0...KeyBindTable.len - 1 => |i| {

            if(KeyBindTable[i][1]) |P|{
                // KeyBindTable[i][0](@as(P[0], @ptrCast(@alignCast(P[1]))).*);
                @call(.always_inline, KeyBindTable[i][0], .{@as(P[0], @ptrCast(@alignCast(P[1]))).*});
            }else {
                // KeyBindTable[i][0](.{});
                @call(.always_inline, KeyBindTable[i][0], .{.{}});
            }
        },
        else => unreachable,
    }
}

fn generic_func(_ : anytype) void{
    // unreachable;
}

fn get_index(mode: core.Mode, mod: Mod, key: u32) u16 {
    const mode_i: u16 = @intFromEnum(mode);
    const mod_i: u16 = @intFromEnum(mod);
    const key_i: u16 = @truncate(key);

    return (mode_i << 10) | (mod_i << 8) | key_i;
}

const KeyBindTable = table;
const table = blk: {
    @setEvalBranchQuota(10000);
    const TableNode = struct{
        KeyBindFunc,
        ?Param,
    };

    var result: [4096]TableNode = [_]TableNode{ .{generic_func, null}}**4096;

    //config insert
    const insert = get_index(.Insert, .None, 0);

    for (config.keys) |k| {
        const index = get_index(get(k, .Mode), get(k, .Mod), get(k, .Char));
        if(result[index][0] == generic_func){
            result[index][0] = get(k, .Func);
            result[index][1] = get(k, .Param);
        } else {
            @compileError("Two definitions of the same keybind");
        }
    }

    for (insert..insert+0xff) |i| {
        if(result[i][0] == generic_func){
            result[i][0] = core.api.insert;
            result[i][1] = param(@as(u8, @truncate(i)));
        }
    }

    break :blk result;
};

