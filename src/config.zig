const std = @import("std");
const term = @cImport(@cInclude("termbox.h"));
const core = @import("core.zig");
const client = @import("client.zig");

pub inline fn testing() void {
    core.api.insert(100);
    // core.api.insert(@as(u8, @intCast('a')));
}

pub const hooks_list = [_]core.Hook {
    .{testing, .Init},
    .{testing, .Init},
} ++
    client.hooks_list
;

const Mod     = client.Mod;
const KeyBind = client.KeyBind;
const Move    = api.Move;
const api     = core.api;
const param   = client.param;

pub const keys = [_]KeyBind{
    .{.Selection, .Alt , 'a', api.insert, param('a')},
    .{.Selection, .None, 'd', api.delete, null},
    .{.Selection, .None, 'l', api.move  , param(Move.LLeft)},
    .{.Selection, .None, 'h', api.move  , param(Move.LRight)},
    .{.Selection, .None, 'Q', quit      , null},
};

inline fn quit(_ : anytype) void {
    std.process.exit(0);
}
