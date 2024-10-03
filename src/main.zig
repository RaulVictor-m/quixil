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
