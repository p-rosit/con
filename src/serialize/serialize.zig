const std = @import("std");
const Allocator = std.mem.Allocator;
const con = @cImport({
    @cInclude("serialize.h");
});

pub const Serialize = struct {
    allocator: Allocator,
    inner: *con.ConSerialize,

    pub fn init(alloc: Allocator, buffer_size: usize) !Serialize {
        var context: Serialize = .{ .inner = undefined, .allocator = alloc };
        if (buffer_size > std.math.maxInt(c_int)) {
            return error.Overflow;
        }

        const err = con.con_serialize_context_init(
            @ptrCast(&context.inner),
            @ptrCast(@constCast(&alloc)),
            @ptrCast(&Serialize.allocCallback),
            @ptrCast(&Serialize.freeCallback),
            @intCast(buffer_size),
        );

        Serialize.enum_to_error(err) catch |new_err| {
            return new_err;
        };
        return context;
    }

    pub fn deinit(self: Serialize) void {
        con.con_serialize_context_deinit(
            self.inner,
            @ptrCast(@constCast(&self.allocator)),
            @ptrCast(&Serialize.freeCallback),
        );
    }

    pub fn currentPosition(self: *Serialize) usize {
        var current_position: c_int = undefined;
        const err = con.con_serialize_current_position(self.inner, &current_position);
        std.debug.assert(err == con.CON_SERIALIZE_OK);
        std.debug.assert(current_position >= 0);
        return @intCast(current_position);
    }

    pub fn bufferSet(self: *Serialize, buffer: []u8) !void {
        if (buffer.len > std.math.maxInt(c_int)) {
            return error.Overflow;
        }

        const err = con.con_serialize_buffer_set(
            self.inner,
            @ptrCast(buffer),
            @intCast(buffer.len),
        );
        std.debug.assert(err == con.CON_SERIALIZE_OK);
    }

    pub fn bufferGet(self: *Serialize) []u8 {
        var ptr: [*c]c_char = null;
        var len: c_int = 0;

        const err = con.con_serialize_buffer_get(self.inner, @ptrCast(&ptr), &len);
        std.debug.assert(err == con.CON_SERIALIZE_OK);
        std.debug.assert(ptr != null);
        std.debug.assert(len >= 0);

        return @as(*[]u8, @ptrCast(@constCast(&.{ .ptr = ptr, .len = @as(usize, @intCast(len)) }))).*;
    }

    pub fn bufferClear(self: *Serialize) void {
        const err = con.con_serialize_buffer_clear(self.inner);
        std.debug.assert(err == con.CON_SERIALIZE_OK);
    }

    pub fn arrayOpen(self: Serialize) !void {
        const err = con.con_serialize_array_open(self.inner);
        return Serialize.enum_to_error(err);
    }

    pub fn arrayClose(self: Serialize) !void {
        const err = con.con_serialize_array_close(self.inner);
        return Serialize.enum_to_error(err);
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

const testing = std.testing;

test "init_failing_first_alloc" {
    var failing_allocator = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = 0 });
    const allocator = failing_allocator.allocator();

    const buffer_size = 5;
    const err = Serialize.init(allocator, buffer_size);
    try testing.expectError(error.Mem, err);
}

test "init_failing_second_alloc" {
    var failing_allocator = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = 1 });
    const allocator = failing_allocator.allocator();

    const buffer_size = 5;
    const err = Serialize.init(allocator, buffer_size);
    try testing.expectError(error.Mem, err);
}

test "init" {
    var failing_allocator = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = 2 });
    const allocator = failing_allocator.allocator();

    const buffer_size = 3;
    const context = try Serialize.init(allocator, buffer_size);
    defer context.deinit();
}

test "large_buffer" {
    const buffer_size = @as(usize, std.math.maxInt(c_int)) + 1;
    const result = Serialize.init(testing.allocator, buffer_size);
    try testing.expectError(error.Overflow, result);
}

test "current_position" {
    const buffer_size = 5;
    var context = try Serialize.init(testing.allocator, buffer_size);
    defer context.deinit();

    try testing.expectEqual(0, context.currentPosition());
}

test "get_buffer" {
    const buffer_size = 5;
    var context = try Serialize.init(testing.allocator, buffer_size);
    defer context.deinit();

    const b = context.bufferGet();
    try testing.expectEqual(b.len, buffer_size);
}

test "clear_buffer" {
    const buffer_size = 5;
    var context = try Serialize.init(testing.allocator, buffer_size);
    defer context.deinit();

    context.bufferClear();
    try testing.expectEqual(0, context.currentPosition());
}

test "array" {
    const buffer_size = 2;
    var context = try Serialize.init(testing.allocator, buffer_size);
    defer context.deinit();

    try context.arrayOpen();
    try context.arrayClose();

    try testing.expectEqualStrings("[]", context.bufferGet());
}
