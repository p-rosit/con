const std = @import("std");
const con = @cImport({
    @cInclude("serialize.h");
});

pub const Serialize = struct {
    inner: con.ConSerialize,

    pub fn init(buffer: []c_char) !Serialize {
        var context: Serialize = undefined;
        if (buffer.len > std.math.maxInt(c_int)) {
            return error.Overflow;
        }

        const err = con.con_serialize_context_init(
            @ptrCast(&context.inner),
            @ptrCast(buffer),
            @intCast(buffer.len),
        );
        std.debug.assert(err == con.CON_SERIALIZE_OK);

        return context;
    }

    pub fn currentPosition(self: *Serialize) c_int {
        var current_position: c_int = undefined;
        const err = con.con_serialize_current_position(&self.inner, &current_position);
        std.debug.assert(err == con.CON_SERIALIZE_OK);
        return current_position;
    }

    pub fn bufferSet(self: *Serialize, buffer: []c_char) !void {
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

    pub fn bufferGet(self: *Serialize) []c_char {
        var ptr: [*c]c_char = undefined;
        var len: c_int = undefined;

        const err = con.con_serialize_buffer_get(&self.inner, @ptrCast(&ptr), &len);
        std.debug.assert(err == con.CON_SERIALIZE_OK);
        std.debug.assert(ptr != null);
        std.debug.assert(len >= 0);

        return @as(*[]c_char, @ptrCast(@constCast(&.{ .ptr = ptr, .len = len }))).*;
    }

    pub fn bufferClear(self: *Serialize) void {
        const err = con.con_serialize_buffer_clear(&self.inner);
        std.debug.assert(err == con.CON_SERIALIZE_OK);
    }

    fn enum_to_error(err: con.ConSerializeError) !void {
        switch (err) {
            con.CON_SERIALIZE_OK => return,
            con.CON_SERIALIZE_NULL => return error.Null,
            con.CON_SERIALIZE_BUFFER => return error.Buffer,
        }
    }
};

const testing = std.testing;

test "init" {
    var buffer: [5]c_char = undefined;
    const context = try Serialize.init(&buffer);
    try testing.expectEqual(context.inner.out_buffer, @as([*c]u8, @ptrCast(&buffer)));
    try testing.expectEqual(context.inner.out_buffer_size, @as(c_int, @intCast(buffer.len)));
    try testing.expectEqual(context.inner.current_position, 0);
}

// test "large_buffer" {
//     const buffer = try testing.allocator.alloc(c_char, std.math.maxInt(c_int) + 1);
//     defer testing.allocator.free(buffer);
//
//     const result = Serialize.init(buffer);
//     try testing.expectError(error.Overflow, result);
// }

test "current_position" {
    var buffer: [2]c_char = undefined;
    var context = try Serialize.init(&buffer);
    try testing.expectEqual(context.currentPosition(), 0);

    context.inner.current_position = 2;
    try testing.expectEqual(context.currentPosition(), 2);
}

test "set_buffer" {
    var buffer: [5]c_char = undefined;
    var new: [5]c_char = undefined;

    var context = try Serialize.init(&buffer);
    context.inner.current_position = 1;

    try context.bufferSet(&new);
    try testing.expectEqual(context.inner.out_buffer, @as([*c]u8, @ptrCast(&new)));
    try testing.expectEqual(context.inner.out_buffer_size, @as(c_int, @intCast(new.len)));
    try testing.expectEqual(context.inner.current_position, 0);
}

// test "set_large_buffer" {
//     var buffer: [5]c_char = undefined;
//     const new = try testing.allocator.alloc(c_char, std.math.maxInt(c_int) + 1);
//     defer testing.allocator.free(new);
//
//     var context = try Serialize.init(&buffer);
//     const result = context.bufferSet(new);
//     try testing.expectError(error.Overflow, result);
// }

test "get_buffer" {
    var buffer: [5]c_char = undefined;

    var context = try Serialize.init(&buffer);
    const b = context.bufferGet();
    try testing.expectEqual(&buffer, b);
}

test "clear_buffer" {
    var buffer: [5]c_char = undefined;
    var context = try Serialize.init(&buffer);
    context.inner.current_position = 3;

    context.bufferClear();
    try testing.expectEqual(context.inner.current_position, 0);
}
