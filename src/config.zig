const std = @import("std");
const core = @import("core.zig");

pub inline fn testing() void {
    std.debug.print("\nhi__________\n", .{});
}
const HookFunc = fn() callconv(.Inline) void;

const Hook = struct {HookFunc, core.HookType};
pub const hooks_list = [_]Hook {

    .{testing, .Init},
    .{testing, .Init},
};
