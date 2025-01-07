const testing = @import("std").testing;
const con = @cImport({
    @cInclude("serialize.h");
});

test "zig_bindings" {
    _ = @import("serialize.zig");
}

test "init" {
    var context: con.ConSerialize = undefined;
    var buffer: [5]c_char = undefined;

    const init_err = con.con_serialize_context_init(&context, @ptrCast(&buffer), buffer.len);
    try testing.expectEqual(init_err, con.CON_SERIALIZE_OK);
    try testing.expectEqual(context.out_buffer, @as([*c]u8, @ptrCast(&buffer)));
    try testing.expectEqual(context.out_buffer_size, @as(c_int, @intCast(buffer.len)));
    try testing.expectEqual(context.current_position, 0);
}

test "init_null_context" {
    var buffer: [5]c_char = undefined;
    const init_err = con.con_serialize_context_init(null, @ptrCast(&buffer), buffer.len);
    try testing.expectEqual(init_err, con.CON_SERIALIZE_NULL);
}

test "init_null_buffer" {
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_context_init(&context, null, 10);
    try testing.expectEqual(init_err, con.CON_SERIALIZE_NULL);
}

test "init_negative_buffer" {
    var context: con.ConSerialize = undefined;
    var buffer: [5]c_char = undefined;

    const init_err = con.con_serialize_context_init(&context, @ptrCast(&buffer), -1);
    try testing.expectEqual(init_err, con.CON_SERIALIZE_BUFFER);
}
