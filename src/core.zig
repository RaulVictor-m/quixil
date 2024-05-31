const std = @import("std");
const testing = std.testing;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const Point = struct {
    x: u32,
    y: u32,
};

const Selection = struct {
    begin: u32,
    end: u32,
    facing: enum {
        Back,
        Front,
    },
};

const Text = struct {
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
    pub fn insert_at(self: *Text, p: Point, value: u8) !void {
        if(!self.in_bounds(p)) return error.PointOutOfBounds;
        const lines = self.data.items;

        if(value == '\n') {
            const len = lines[p.y].items.len;

            if(len < 2 or p.x > len - 2) {
                try self.new_line_at(p.y+1);
                return;
            }

            const end_of_line: []u8 =  lines[p.y].items[p.x..len-1];
            try self.new_line_slice_at(p.y+1, end_of_line);

            try self.delete_range(.{.y = p.y, .x = p.x},
                              .{.y = p.y, .x = @as(u32, @truncate(len-2))});
            return;
        }

        try lines[p.y].insert(p.x, value);
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

                try self.insert_at(cursor, chr);
                cursor.y += 1;
                cursor.x = 0;
                continue;
            }
            try self.insert_at(cursor, chr);
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
    pub fn delete_range(self: *Text, a: Point, b: Point) !void {
        //TODO: optimize for range deletions
        if(b.y < a.y) return;
        if(b.y == a.y){
            if(b.x < a.x) return;

            for(a.x..b.x+1) |_| {
                try self.delete(a);
            }
            return;
        }

        for((a.y+1)..b.y) |_| {
            self.delete_line(a.y+1);
        }

        const len = (self.data.items[a.y].items.len) - a.x + b.x;
        for(0..len+1) |_| {
            try self.delete(a);
        }

    }

};
const Buffer = struct {
    name: []const u8,
    text: Text,

    ///inits a new empty buffer
    pub fn init(allocator: Allocator) !Buffer {
        var self: Buffer = undefined;
        self.name = "*new*";
        self.text = try Text.init_text(allocator, "");
        return self;
    }

    ///inits a new buffer with the contentx of text
    pub fn init_text(allocator: Allocator, text: []const u8) !Buffer {
        var self: Buffer = undefined;
        self.name = "*new*";
        self.text = try Text.init_text(allocator, text);
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

        return self;
    }

    pub fn deinit(self: *Buffer) void {
        self.text.deinit();
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

const Registers = struct {
    r_a: *void,
};

const Editor = struct {
    buffers: ArrayList(Buffer),
    current_buf: u32,
    regs: Registers,
    mode: enum{
        Selection,
        Insert,
        Command,
        User,
    },
};

var g_editor = undefined;

pub const default_api = struct {
    pub inline fn delete() void {
        @panic("unimplemented");
    }

    ///insert a char at the begining of every selection
    pub inline fn insert(char: u8) void {
        _ = char;
        @panic("unimplemented");
    }

    ///appends a char at the end of every selection
    pub inline fn append(char: u8) void {
        _ = char;
        @panic("unimplemented");
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
};

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

        try text.insert_at(.{.x=0,.y=0}, 'a');
        try text.insert_at(.{.x=1,.y=0}, 'b');
        try text.insert_at(.{.x=2,.y=0}, 'c');

        const lines = text.data.items;
        try testing.expectEqual(@as(usize, 1), lines.len);
        try testing.expectEqualStrings("abc\n", lines[0].items);
    }

    // inserting new line char
    {
        var text = try Text.init_text(testing.allocator, "abcdefghij");
        defer text.deinit();

        const lines = &text.data.items;
        try text.insert_at(.{.x=1,.y=0}, '\n');
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
        try text.insert_at(.{.x = line_len-1,.y=0}, '\n');

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
