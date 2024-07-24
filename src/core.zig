const std = @import("std");
const testing = std.testing;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub const Point = struct {
    x: u32,
    y: u32,
};

pub const Selection = struct {
    begin: Point,
    end: Point,
    facing: enum {
        Back,
        Front,
    },
};

pub const Registers = struct {
    r_a: *void,
};

pub const Editor = struct {
    buffers: ArrayList(Buffer),
    current_buf: u32 = 0,
    regs: Registers = undefined,
    mode: enum{
        Selection,
        Insert,
        Command,
        User,
    } = .Selection,
};

pub var g_editor: Editor = .{ .buffers = undefined };

pub const api = default_api;
pub const default_api = struct {
    ///returns the editors current buffer
    pub inline fn c_buf() *Buffer {
        return &g_editor.buffers.items[g_editor.current_buf];
    }

    ///deletes de entire selection
    pub inline fn delete() void {
        const buf = &g_editor.buffers.items[g_editor.current_buf];

        for(buf.sels.items) |*sel| {
            const p = buf.text.delete_range(sel.begin, sel.end) catch @panic("API: panic on delete");

            sel.end = p;
            sel.begin = p;
        }
    }

    ///insert a char at the begining of every selection
    pub inline fn insert(char: u8) void {
        const buf = &g_editor.buffers.items[g_editor.current_buf];

        for(buf.sels.items) |*sel| {
            const p = buf.text.insert_at(sel.begin, char) catch @panic("API: panic on insert");

            const y = p.y - sel.begin.y;
            const x = p.x - sel.begin.x;

            sel.begin.y = p.y;
            sel.begin.x = p.x;

            sel.end.y += y;

            if(sel.begin.y == sel.end.y) {
                sel.end.x += x;
            }
        }
    }

    ///appends a char at the end of every selection
    pub inline fn append(char: u8) void {
        const buf = &g_editor.buffers.items[g_editor.current_buf];

        for(buf.sels.items) |*sel| {
            if (sel.end.x == (buf.text.data.items[sel.end.y].items.len - 1)){
                sel.end.y += 1;
                sel.end.x += 0;

                if(!buf.text.in_bounds(sel.end)) {
                    buf.text.new_line_at(sel.end.y);
                }
                _ = buf.text.insert_at(sel.end, char) catch @panic("API: panic on append");
            } else {
                sel.end.x += 1;
                _ = buf.text.insert_at(sel.end, char) catch @panic("API: panic on append");
            }

            if(char == '\n'){
                sel.end.y += 1;
                sel.end.x += 0;
            }

        }
    }

    pub inline fn yank() void {
        @panic("unimplemented");

    }

    pub inline fn paste() void {
        @panic("unimplemented");

    }

    pub inline fn paste_a() void {
        @panic("unimplemented");

    }

    pub inline fn paste_i() void {
        @panic("unimplemented");

    }

    pub inline fn sel_split_lines() void {
        @panic("unimplemented");

    }

    pub inline fn sel_split_two() void {
        @panic("unimplemented");

    }

    pub inline fn move(mov: enum {Up, Down, LLeft, LRight, WLeft, WRight, }) void {
        const buf = &g_editor.buffers.items[g_editor.current_buf];

        switch(mov) {
            .Up     => @panic("mov Up  unimplemented"),
            .Down   => @panic("mov Down  unimplemented"),
            .LLeft  => {
                for(buf.sels.items) |*sel| {
                    var p = if(sel.facing == .Front) sel.end else sel.begin;

                    p.x += 1;
                    if(p.x == buf.text.data.items[p.y].items.len) {
                        if(p.y == buf.text.data.items.len-1) {
                            p.x -= 1;
                        } else {
                            p.y += 1;
                            p.x = 0;
                        }
                    }
                    sel.begin = p;
                    sel.end = p;
                    sel.facing = .Front;
                }
            },
            .LRight => {
                for(buf.sels.items) |*sel| {
                    var p = if(sel.facing == .Front) sel.end else sel.begin;

                    if(p.x == 0) {
                        if(p.y != 0) {
                            p.x = @as(u32, @truncate(buf.text.data.items[p.y-1].items.len - 1));
                            p.y -=1;
                        }
                    }else {
                        p.x -= 1;
                    }
                    sel.begin = p;
                    sel.end = p;
                    sel.facing = .Back;
                }
            },
            .WLeft  => @panic("mov WLeft  unimplemented"),
            .WRight => @panic("mov WRight  unimplemented"),
        }
    }

    pub inline fn move_extend(mov: enum {Up, Down, LLeft, LRight, WLeft, WRight, }) void {
        const buf = &g_editor.buffers.items[g_editor.current_buf];

        switch(mov) {
            .Up     => @panic("mov Up  unimplemented"),
            .Down   => @panic("mov Down  unimplemented"),
            .LLeft  => {
                for(buf.sels.items) |*sel| {
                    const eq = sel.end.x == sel.begin.x and sel.end.y == sel.begin.y;
                    const p = if(sel.facing == .Front) &sel.end else blk: {
                        if(eq) {
                            sel.facing = .Front;
                            break : blk &sel.end;
                        }
                        break : blk &sel.begin;
                    };

                    if(p.x == buf.text.data.items[p.y].items.len-1) {
                        if(p.y != buf.text.data.items.len-1) {
                            p.y += 1;
                            p.x = 0;
                        }
                    } else {
                        p.x += 1;
                    }
                }
            },
            .LRight => {
                for(buf.sels.items) |*sel| {
                    const eq = sel.end.x == sel.begin.x and sel.end.y == sel.begin.y;
                    const p = if(sel.facing == .Back) &sel.begin else blk: {
                        if(eq) {
                            sel.facing = .Back;
                            break : blk &sel.begin;
                        }
                        break : blk &sel.end;
                    };

                    if(p.x == 0) {
                        if(p.y != 0) {
                            p.x = @as(u32, @truncate(buf.text.data.items[p.y-1].items.len - 1));
                            p.y -=1;
                        }
                    }else {
                        p.x -= 1;
                    }
                }
            },
            .WLeft  => @panic("mov WLeft  unimplemented"),
            .WRight => @panic("mov WRight  unimplemented"),
        }
    }
};
pub const Text = struct {
    data: ArrayList(ArrayList(u8)),

    ///init the lines array with nothing inside
    fn init(allocator: Allocator) !Text {
        var self: Text = undefined;
        self.data = try ArrayList(ArrayList(u8)).initCapacity(allocator, 100);
        return self;
    }

    ///init the buffer with the the context of text
    pub fn init_text(allocator: Allocator, text: []const u8) !Text {
        var self = try init(allocator);

        try self.new_line_at(0);
        try self.insert_slice_at(.{.x = 0, .y = 0}, text);

        return self;
    }

    pub fn deinit(self: *Text) void {
        for(self.data.items, 0..) |_, y| {
            self.data.items[y].deinit();
        }
        self.data.deinit();
    }

    fn in_bounds(self: Text, p: Point) bool {
        return self.data.items.len > p.y and self.data.items[p.y].items.len > p.x;
    }

    ///inserts char in position p
    ///if there is ever a new line char
    ///adds new line and moves all the text after it 
    ///returns a point to the char imediately after the inserted char
    pub fn insert_at(self: *Text, p: Point, value: u8) !Point {
        if(!self.in_bounds(p)) return error.PointOutOfBounds;
        const lines = self.data.items;
        var res: Point = p;

        if(value == '\n') {
            const len = lines[p.y].items.len;

            res.y += 1;
            if(len < 2 or p.x > len - 2) {
                try self.new_line_at(p.y+1);
                return res;
            }

            const end_of_line: []u8 =  lines[p.y].items[p.x..len-1];
            try self.new_line_slice_at(p.y+1, end_of_line);

            _ = try self.delete_range(.{.y = p.y, .x = p.x},
                              .{.y = p.y, .x = @as(u32, @truncate(len-2))});
            return res;
        }

        try lines[p.y].insert(p.x, value);

        res.x += 1;
        return res;
    }

    ///inserts slice of text in position p
    pub fn insert_slice_at(self: *Text, p: Point, text: []const u8) !void {
        //TODO: optimize for better slice insertion
        var cursor: Point = p;

        for(text, 0..) |chr, i| {
            if(chr == '\n'){

                const lines = self.data.items;
                //avoid creating an extra new line at the end
                if(
                i == text.len - 1
                and cursor.y == lines.len - 1
                and cursor.x == lines[cursor.y].items.len - 1) break;

                _ = try self.insert_at(cursor, chr);
                cursor.y += 1;
                cursor.x = 0;
                continue;
            }
            _ = try self.insert_at(cursor, chr);
            cursor.x += 1;
        }
    }

    ///inserts a new line in position index
    pub fn new_line_at(self: *Text, index: u32) !void {
        const allocator = self.data.allocator;
        var line = try ArrayList(u8).initCapacity(allocator, 100);
        try line.append('\n');

        try self.data.insert(index, line);
    }

    ///inserts a new line in position index and initialise it with text
    ///new line chars are invalid for this function
    pub fn new_line_slice_at(self: *Text, index: u32, text: []const u8) !void {
        try self.new_line_at(index);
        const lines = self.data.items;
        try lines[index].insertSlice(0, text);
    }

    ///joins the line at y with the next one
    pub fn join_line_at(self: *Text, y: u32) !void {
        if(y == self.data.items.len - 1) return;

        _ = self.data.items[y].pop();

        const next_line = self.data.items[y+1].items;
        try self.data.items[y].appendSlice(next_line);

        self.delete_line(y+1);
    }

    ///delete a single char in position p
    ///and joins or deletes lines when you delete its last char
    pub fn delete(self: *Text, p: Point) !void {
        const lines = self.data.items;

        if(lines[p.y].items.len == 1) {
            self.delete_line(p.y);
            return;
        }
        if(p.x == lines[p.y].items.len - 1) {
            try self.join_line_at(p.y);
            return;
        }

        //TODO: add value to registers
        _ = lines[p.y].orderedRemove(p.x);
    }

    ///properly deletes a line in position y and deallocate its memory
    ///created for internal use of the text struct - PREFER DELETE
    pub fn delete_line(self: *Text, y: u32) void {
        self.data.items[y].deinit();
        _ = self.data.orderedRemove(y);
    }

    ///it just deletes from point a to point b inclusevely
    ///returns the point of the char imediately before the last deleted char
    pub fn delete_range(self: *Text, a: Point, b: Point) !Point {
        //TODO: optimize for range deletions
        if(b.y < a.y) return error.InvalidRange;
        if(b.y == a.y){
            if(b.x < a.x) return error.InvalidRange;

            for(a.x..b.x+1) |_| {
                try self.delete(a);
            }

            return a;
        }

        for((a.y+1)..b.y) |_| {
            self.delete_line(a.y+1);
        }

        const len = (self.data.items[a.y].items.len) - a.x + b.x;
        for(0..len+1) |_| {
            try self.delete(a);
        }

        if(self.in_bounds(a)) return a;
        var res = a;
        res.y -= 1;
        return res;
    }

};
pub const Buffer = struct {
    name: []const u8,
    sels: ArrayList(Selection), // sels have to be always sorted
    text: Text,

    ///inits a new empty buffer
    pub fn init(allocator: Allocator) !Buffer {
        //init text
        var self: Buffer = undefined;
        self.name = "*new*";
        self.text = try Text.init_text(allocator, "");

        //init sels
        self.sels = try ArrayList(Selection).initCapacity(allocator, 10);
        _ = try self.sels.append(.{ .begin = .{.x = 0, .y = 0}, .end = .{.x = 0, .y = 0}, .facing = .Front});
        return self;
    }

    ///inits a new buffer with the contentx of text
    pub fn init_text(allocator: Allocator, text: []const u8) !Buffer {
        //init text
        var self: Buffer = undefined;
        self.name = "*new*";
        self.text = try Text.init_text(allocator, text);

        //init sels
        self.sels = try ArrayList(Selection).initCapacity(allocator, 10);
        _ = try self.sels.append(.{ .begin = .{.x = 0, .y = 0}, .end = .{.x = 0, .y = 0}, .facing = .Front});
        return self;
    }

    //given a file name it open a buffer with that file as content
    //if there is no file with that name just opens an empty buffer
    pub fn init_file(allocator: Allocator, path: []const u8) !Buffer {
        var self: Buffer = undefined;
        var file = std.fs.cwd().openFile(path, .{})
            catch return try init(allocator);

        self.text = try Text.init(allocator);
        self.name = path;

        var buf_reader = std.io.bufferedReader(file.reader());
        const reader = buf_reader.reader();

        var line = std.ArrayList(u8).init(allocator);
        defer line.deinit();

        const writer = line.writer();
        var line_no: usize = 1;
        while (reader.streamUntilDelimiter(writer, '\n', null)) : (line_no += 1) {
            defer line.clearRetainingCapacity();

            try self.text.new_line_slice_at(@truncate(line_no - 1), line.items);

        } else |err| switch (err) {
            error.EndOfStream => {}, // Continue on        defer file.close();
            else => unreachable,
        }

        //init sels
        self.sels = try ArrayList(Selection).initCapacity(allocator, 10);
        _ = try self.sels.append(.{ .begin = .{.x = 0, .y = 0}, .end = .{.x = 0, .y = 0}, .facing = .Front});
        return self;
    }

    pub fn deinit(self: *Buffer) void {
        self.sels.deinit();
        self.text.deinit();
    }

    // ///////////////////////////////////////
    // Text data wrapper
    // ///////////////////////////////////////
    pub inline fn lines_size(self: Buffer) usize {
        return self.text.data.items.len;
    }

    pub inline fn line_size(self: Buffer, line: usize) usize {
        return self.text.data.items[line].items.len;
    }

    pub inline fn get_line(self: Buffer, line: usize) []const u8{
        return self.text.data.items[line].items;
    }

    pub inline fn get_c(self: Buffer, line: usize, row: usize) u8{
        return self.text.data.items[line].items[row];
    }

    /// will print the entire buffer and the line number
    /// for debuging purposes
    pub fn print_buffer(self: Buffer) void {
        std.debug.print("\n", .{});
        for(self.text.data.items, 0..) |line, i| {
            std.debug.print("{d: >4}| {s}", .{i, line.items});
        }
    }
};


// ///////////////////////////////////////////////////////////////////////////
// testing text data struct
// ///////////////////////////////////////////////////////////////////////////

test "core.Text/init_text" {
    {
        var text = try Text.init_text(testing.allocator, "");
        defer text.deinit();

        const lines = text.data.items;
        try testing.expectEqual(@as(usize, 1), lines.len);
        try testing.expectEqual(@as(usize, 1), lines[0].items.len);
        try testing.expectEqual(@as(u8, '\n'), lines[0].items[0]);
    }

    {
        const lines = [_][]const u8{"__1__\n",
                                    "__2__\n",
                                    "__3__\n",
                                    "__4__\n",
                                    "__5__\n",
                                    "__6__\n"};
        // saving lines in a single slice
        const buf_slice = comptime blk: {
            var buf: []const u8 = "";
            for(lines) |line| {
                buf = buf ++ line;
            }
            const res = buf;
            break :blk res;
        };

        var text = try Text.init_text(testing.allocator, buf_slice);
        defer text.deinit();

        // testing to see if every line was initialized correctly
        for(text.data.items, lines) |line, line_sample| {
            try testing.expectEqualStrings(line_sample, line.items);
        }
    }
}

test "core.Text/insert_at" {
    // inserting normal chars
    {
        var text = try Text.init_text(testing.allocator, "");
        defer text.deinit();

        _ = try text.insert_at(.{.x=0,.y=0}, 'a');
        _ = try text.insert_at(.{.x=1,.y=0}, 'b');
        _ = try text.insert_at(.{.x=2,.y=0}, 'c');

        const lines = text.data.items;
        try testing.expectEqual(@as(usize, 1), lines.len);
        try testing.expectEqualStrings("abc\n", lines[0].items);
    }

    // inserting new line char
    {
        var text = try Text.init_text(testing.allocator, "abcdefghij");
        defer text.deinit();

        const lines = &text.data.items;
        _ = try text.insert_at(.{.x=1,.y=0}, '\n');
        try testing.expectEqual(@as(usize, 2), lines.len);

        const sample_lines = @as([2][]const u8, .{
                                            "a\n",
                                            "bcdefghij\n"
        });

        for(lines.*, sample_lines) |line, line_sample| {
            try testing.expectEqualStrings(line_sample, line.items);
        }
    }

    // new line char at the end of the line
    {
        var text = try Text.init_text(testing.allocator, "abcdefghij");
        defer text.deinit();

        const lines = &text.data.items;
        const line_len: u32 = @truncate(lines.*[0].items.len);
        _ = try text.insert_at(.{.x = line_len-1,.y=0}, '\n');

        try testing.expectEqual(@as(usize, 2), lines.len);

        const sample_lines = @as([2][]const u8, .{
                                            "abcdefghij\n",
                                            "\n",
        });

        for(lines.*, sample_lines) |line, line_sample| {
            try testing.expectEqualStrings(line_sample, line.items);
        }
    }

}
test "core.Text/insert_slice_at" {
    // inserting normal chars
    {
        var text = try Text.init_text(testing.allocator, "");
        defer text.deinit();

        try text.insert_slice_at(.{.x=0,.y=0}, "abc");

        const lines = text.data.items;
        try testing.expectEqual(@as(usize, 1), lines.len);

                        //lines always end with a \n no exceptions
        try testing.expectEqualStrings("abc\n", lines[0].items);
    }

    //inserting new lines int the slices
    {
        var text = try Text.init_text(testing.allocator, "abcdefghij");
        defer text.deinit();

        try text.insert_slice_at(.{.x=0,.y=0}, "1:\n");

        //new line is ignored when its is appended at the last line
        try text.insert_slice_at(.{.x=10,.y=1}, "1:\n");
        const lines = text.data.items;

        try testing.expectEqual(@as(usize, 2), lines.len);

        const sample_lines = @as([2][]const u8, .{
                                            "1:\n",
                                            "abcdefghij1:\n",

        });

        for(lines, sample_lines) |line, line_sample| {
            try testing.expectEqualStrings(line_sample, line.items);
        }
    }

}

test "core.Text/new_line_at" {
    {
        var text = try Text.init_text(testing.allocator, "__1__\n__2__\n");
        defer text.deinit();

        try text.new_line_at(1);
        try text.new_line_at(0);

        const lines = [_][]const u8{ "\n",
                                     "__1__\n",
                                     "\n",
                                     "__2__\n"};

        try testing.expectEqual(@as(usize, 4), text.data.items.len);

        // testing to see if every line was initialized correctly
        for(text.data.items, lines) |line, line_sample| {
            try testing.expectEqualStrings(line_sample, line.items);
        }
    }
}

test "core.Text/new_line_slice_at" {
    {
        var text = try Text.init_text(testing.allocator, "__1__\n__2__\n");
        defer text.deinit();

        try text.new_line_slice_at(1, "going to 2");

        const lines = [_][]const u8{ "__1__\n",
                                     "going to 2\n",
                                     "__2__\n"};

        try testing.expectEqual(@as(usize, 3), text.data.items.len);

        // testing to see if every line was initialized correctly
        for(text.data.items, lines) |line, line_sample| {
            try testing.expectEqualStrings(line_sample, line.items);
        }
    }
}

test "core.Text/join_line_at" {
    {
        var text = try Text.init_text(testing.allocator, "__1__\n__2__\n");
        defer text.deinit();

        try text.join_line_at(0);

        const lines = [_][]const u8{ "__1____2__\n",};

        try testing.expectEqual(@as(usize, 1), text.data.items.len);

        // testing to see if every line was initialized correctly
        for(text.data.items, lines) |line, line_sample| {
            try testing.expectEqualStrings(line_sample, line.items);
        }
    }

}
