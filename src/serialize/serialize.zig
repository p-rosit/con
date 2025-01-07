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

test "large_buffer" {
    const buffer = try testing.allocator.alloc(c_char, std.math.maxInt(c_int) + 1);
    defer testing.allocator.free(buffer);

    const result = Serialize.init(buffer);
    try testing.expectError(error.Overflow, result);
}
