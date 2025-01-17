const std = @import("std");
const Allocator = std.mem.Allocator;
const con = @cImport({
    @cInclude("serialize.h");
});

pub fn Serialize(Writer: type) type {
    // TODO: comptime verify type passed in is writer

    return struct {
        const Self = @This();

        allocator: Allocator,
        writer: Writer,
        inner: con.ConSerialize,

        pub fn init(w: Writer, alloc: Allocator, buffer_size: usize) !Self {
            var context = Self{
                .writer = w,
                .allocator = alloc,
                .inner = undefined,
            };
            if (buffer_size > std.math.maxInt(c_int)) {
                return error.Overflow;
            }

            const err = con.con_serialize_context_init(
                &context.inner,
                &context.writer,
                Self.writeCallback,
                @ptrCast(&alloc),
                @ptrCast(&Self.allocCallback),
                @ptrCast(&Self.freeCallback),
                @intCast(buffer_size),
            );

            Self.enum_to_error(err) catch |new_err| {
                return new_err;
            };
            return context;
        }

        pub fn deinit(self: Self) void {
            const err = con.con_serialize_context_deinit(
                @constCast(&self.inner),
                @ptrCast(&self.allocator),
                @ptrCast(&Self.freeCallback),
            );
            std.debug.assert(err == con.CON_SERIALIZE_OK);
        }

        pub fn currentPosition(self: *Self) usize {
            var current_position: c_int = undefined;
            const err = con.con_serialize_current_position(&self.inner, &current_position);
            std.debug.assert(err == con.CON_SERIALIZE_OK);
            std.debug.assert(current_position >= 0);
            return @intCast(current_position);
        }

        pub fn bufferSet(self: *Self, buffer: []u8) !void {
            if (buffer.len > std.math.maxInt(c_int)) {
                return error.Overflow;
            }

            const err = con.con_serialize_buffer_set(
                &self.inner,
                @ptrCast(buffer),
                @intCast(buffer.len),
            );
            std.debug.assert(err == con.CON_SERIALIZE_OK);
        }

        pub fn bufferGet(self: *Self) []u8 {
            var ptr: [*c]c_char = null;
            var len: c_int = 0;

            const err = con.con_serialize_buffer_get(&self.inner, @ptrCast(&ptr), &len);
            std.debug.assert(err == con.CON_SERIALIZE_OK);
            std.debug.assert(ptr != null);
            std.debug.assert(len >= 0);

            return @as(*[]u8, @ptrCast(@constCast(&.{ .ptr = ptr, .len = @as(usize, @intCast(len)) }))).*;
        }

        pub fn bufferClear(self: *Self) void {
            const err = con.con_serialize_buffer_clear(&self.inner);
            std.debug.assert(err == con.CON_SERIALIZE_OK);
        }

        pub fn arrayOpen(self: *Self) !void {
            const err = con.con_serialize_array_open(&self.inner);
            return Self.enum_to_error(err);
        }

        pub fn arrayClose(self: *Self) !void {
            const err = con.con_serialize_array_close(&self.inner);
            return Self.enum_to_error(err);
        }

        fn allocCallback(allocator: *anyopaque, size: usize) callconv(.C) [*c]u8 {
            const a = @as(*const std.mem.Allocator, @ptrCast(@alignCast(allocator)));
            const ptr = a.alignedAlloc(u8, 8, size) catch null;
            return @ptrCast(ptr);
        }

        fn freeCallback(allocator: *anyopaque, data: [*c]u8, size: usize) callconv(.C) void {
            std.debug.assert(null != data);
            const a = @as(*const std.mem.Allocator, @ptrCast(@alignCast(allocator)));
            const p = data[0..size];
            a.free(@as([]align(8) u8, @alignCast(p)));
        }

        fn writeCallback(writer: ?*const anyopaque, data: [*c]const u8) callconv(.C) c_int {
            std.debug.assert(null != writer);
            std.debug.assert(null != data);
            const w: *const Writer = @alignCast(@ptrCast(writer));
            const d = std.mem.span(data);
            return @intCast(w.write(d) catch 0);
        }

        fn enum_to_error(err: con.ConSerializeError) !void {
            switch (err) {
                con.CON_SERIALIZE_OK => return,
                con.CON_SERIALIZE_NULL => return error.Null,
                con.CON_SERIALIZE_BUFFER => return error.Buffer,
                con.CON_SERIALIZE_MEM => return error.Mem,
                else => return error.Unknown,
            }
        }
    };
}

const Fifo = std.fifo.LinearFifo(u8, .Slice);
const testing = std.testing;

test "init_failing_first_alloc" {
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var failing_allocator = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = 0 });
    const allocator = failing_allocator.allocator();

    const buffer_size = 5;
    const err = Serialize(Fifo.Writer).init(fifo.writer(), allocator, buffer_size);
    try testing.expectError(error.Mem, err);
}

test "init" {
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var failing_allocator = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = 1 });
    const allocator = failing_allocator.allocator();

    const buffer_size = 3;
    const context = try Serialize(Fifo.Writer).init(fifo.writer(), allocator, buffer_size);
    defer context.deinit();
}

test "large_buffer" {
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    const writer = fifo.writer();
    const buffer_size = @as(usize, std.math.maxInt(c_int)) + 1;
    const result = Serialize(Fifo.Writer).init(writer, testing.allocator, buffer_size);
    try testing.expectError(error.Overflow, result);
}

test "current_position" {
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    const buffer_size = 5;
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), testing.allocator, buffer_size);
    defer context.deinit();

    try testing.expectEqual(0, context.currentPosition());
}

test "get_buffer" {
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    const buffer_size = 5;
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), testing.allocator, buffer_size);
    defer context.deinit();

    const b = context.bufferGet();
    try testing.expectEqual(b.len, buffer_size);
}

test "clear_buffer" {
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    const buffer_size = 5;
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), testing.allocator, buffer_size);
    defer context.deinit();

    context.bufferClear();
    try testing.expectEqual(0, context.currentPosition());
}

test "array" {
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), testing.allocator, 2);
    defer context.deinit();

    try context.arrayOpen();
    try context.arrayClose();

    try testing.expectEqualStrings("[]", &buffer);
}
