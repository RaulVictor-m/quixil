const std = @import("std");
const term = @cImport(@cInclude("termbox.h"));
const core = @import("core.zig");
const client = @import("client.zig");

pub fn testing() void {
    // core.api.insert(100);
    core.api.insert(@as(u8, @intCast('a')));
}

pub const hooks_list = [_]core.Hook {
    .{testing, .Init},
    .{testing, .Init},
} ++
    client.hooks_list
;

const Mod     = client.Mod;
const Mode    = core.Mode;
const KeyBind = client.KeyBind;
const Move    = api.Move;
const api     = core.api;
const param   = client.param;

fn k(a: anytype) KeyBind {
    _ = a;
    return undefined;
}

// fn move_end(_: anytype) void {
//     api.Move(
// }
pub const keys = [_]KeyBind{
    .{.Selection, .None, 'i', api.change_mode, param(Mode.Insert)},
    .{.Selection, .None, 'd', api.delete, null},

     //moves
    .{.Selection, .None, 'l', api.move         , param(Move.LLeft)},
    // .{.Selection, .Alt,  'L', move_end , null},
    .{.Selection, .None, 'h', api.move         , param(Move.LRight)},
    .{.Selection, .None, 'L', api.move_extend  , param(Move.LLeft)},
    .{.Selection, .None, 'H', api.move_extend  , param(Move.LRight)},
    .{.Selection, .None, 'e', eduardo          , param("eduardo")},

    .{.Selection, .Alt , 'Q', quit      , null},
    .{.Insert   , .Alt , 'Q', quit      , null},

    .{.Insert, .None, 27, api.change_mode, param(Mode.Selection)},
};

fn eduardo(p: anytype) void{
    for (p) |a| {
        api.insert(a);
    }
}


fn quit(_ : anytype) void {
    std.process.exit(0);
}
