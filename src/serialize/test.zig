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

test "set_buffer" {
    var context: con.ConSerialize = undefined;
    var buffer: [5]c_char = undefined;
    var new: [6]c_char = undefined;

    const init_err = con.con_serialize_context_init(&context, @ptrCast(&buffer), buffer.len);
    try testing.expectEqual(init_err, con.CON_SERIALIZE_OK);
    context.current_position = 1;

    const set_err = con.con_serialize_buffer_set(&context, @ptrCast(&new), new.len);
    try testing.expectEqual(set_err, con.CON_SERIALIZE_OK);
    try testing.expectEqual(context.out_buffer, @as([*c]u8, @ptrCast(&new)));
    try testing.expectEqual(context.out_buffer_size, @as(c_int, @intCast(new.len)));
    try testing.expectEqual(context.current_position, 0);
}

test "set_null_buffer" {
    var context: con.ConSerialize = undefined;
    var buffer: [5]c_char = undefined;

    const init_err = con.con_serialize_context_init(&context, @ptrCast(&buffer), buffer.len);
    try testing.expectEqual(init_err, con.CON_SERIALIZE_OK);

    const set_err = con.con_serialize_buffer_set(&context, null, 10);
    try testing.expectEqual(set_err, con.CON_SERIALIZE_NULL);
}

test "set_negative_buffer" {
    var context: con.ConSerialize = undefined;
    var buffer: [5]c_char = undefined;
    var new: [6]c_char = undefined;

    const init_err = con.con_serialize_context_init(&context, @ptrCast(&buffer), buffer.len);
    try testing.expectEqual(init_err, con.CON_SERIALIZE_OK);

    const set_err = con.con_serialize_buffer_set(&context, @ptrCast(&new), -2);
    try testing.expectEqual(set_err, con.CON_SERIALIZE_BUFFER);
}
