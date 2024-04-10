const std = @import("std");
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

const Buffer = struct {
    name: []const u8,
    text: ArrayList(ArrayList(u8)),

    ///init the lines array with nothing inside
    pub fn init(allocator: Allocator) Buffer {
        var self: Buffer = undefined;
        self.text = ArrayList(ArrayList(u8)).initCapacity(allocator, 100) catch unreachable;
        return self;
    }

    ///init the buffer with the the context of text
    pub fn init_text(allocator: Allocator, text: []const u8) Buffer {
        var self = init(allocator);
        self.new_line_at(0);
        self.insert_slice_at(.{.x = 0, .y = 0}, text);
        return self;
    }

    pub fn init_file(allocator: Allocator, path: []const u8) Buffer {
        _ = allocator;
        _ = path;
        @panic("unimplemented");
        // return undefined;

    }

    pub fn in_bounds(self: Buffer, p: Point) bool {
        return self.text.items.len > p.y and self.text.items[p.y].items.len > p.x;
    }

    ///inserts char in position p
    ///if there is ever a new line char
    ///adds new line and moves all the text after it 
    pub fn insert_at(self: *Buffer, p: Point, value: u8) void {
        //TODO: error when p is out of bounds

        const lines = self.text.items;

        if(value == '\n') {
            const len = lines[p.y].items.len;

            const end_of_line: []u8 =  lines[p.y].items[p.x..len-1];
            self.new_line_slice_at(p.y+1, end_of_line);

            self.delete_range(.{.y = p.y, .x = p.x},
                              .{.y = p.y, .x = @as(u32, @truncate(len-2))});
            return;
        }

        lines[p.y].insert(p.x, value) catch unreachable;
    }

    ///inserts slice of text in position p
    pub fn insert_slice_at(self: *Buffer, p: Point, text: []const u8) void {
        //TODO: optimize for better slice insertion
        var cursor: Point = p;

        for(text, 0..) |chr, i| {
            if(chr == '\n'){
                //avoid creating an extra new line at the end
                if(i < text.len - 1)
                    self.insert_at(cursor, chr);
                cursor.y += 1;
                cursor.x = 0;
                continue;
            }
            self.insert_at(cursor, chr);
            cursor.x += 1;
        }
    }

    ///inserts a new line in position index
    pub fn new_line_at(self: *Buffer, index: u32) void {
        const allocator = self.text.allocator;
        var line = ArrayList(u8).initCapacity(allocator, 100) catch unreachable;
        line.append('\n') catch unreachable;

        self.text.insert(index, line) catch unreachable;
    }

    ///inserts a new line in position index and initialise it with text
    pub fn new_line_slice_at(self: *Buffer, index: u32, text: []const u8) void {
        self.new_line_at(index);
        const lines = self.text.items;
        lines[index].insertSlice(0, text) catch unreachable;
    }

    ///delete a single char in position p
    pub fn delete(self: *Buffer, p: Point) void {
        const lines = self.text.items;
        //TODO: check if it should remove the line or concat the next one in
        //TODO: add value to registers
        _ = lines[p.y].orderedRemove(p.x);
    }

    pub fn delete_range(self: *Buffer, a: Point, b: Point) void {
        //TODO: optimize for deletion of slices
        for(a.y..b.y+1) |y| {
            for(a.x..b.x+1) |_| {
                self.delete(.{ .x = @truncate(a.x), .y = @truncate(y)});
            }
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

test "buffer functions" {
    var buff: [10000]u8 = undefined;
    var allocator = std.heap.FixedBufferAllocator.init(&buff);

    const my_buf = "__1__\n" ++
                   "__2__\n" ++
                   "__3__\n" ++
                   "__4__\n" ++
                   "__5__\n" ++
                   "__6__";

    //TEST: init text
    var buf = Buffer.init_text(allocator.allocator(), my_buf);
    //TODO: do the real testing to guarantee its working

    //TEST: insert at
    buf.insert_at(.{ .x = 5, .y = 0}, 'a');
    buf.insert_at(.{ .x = 5, .y = 0}, 'a');
    buf.insert_at(.{ .x = 5, .y = 0}, 'a');
    buf.insert_at(.{ .x = 5, .y = 0}, 'b');
    // buf.insert_at(.{ .x = 9, .y = 0}, '\n');
    buf.delete(.{ .x = 5, .y = 0});
    
    buf.insert_slice_at(.{ .x = 3, .y = 0}, my_buf);

    std.debug.print("\n", .{});
    for(buf.text.items, 0..) |line, i| {
        // std.debug.print("{d})  {s}", .{i, line.items});
        _ = i;

        std.debug.print("{s}", .{line.items});
    }


}
