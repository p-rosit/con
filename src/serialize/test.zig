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
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);
    try testing.expectEqual(@as([*c]u8, @ptrCast(&buffer)), context.out_buffer);
    try testing.expectEqual(@as(c_int, @intCast(buffer.len)), context.out_buffer_size);
    try testing.expectEqual(0, context.current_position);
}

test "init_null_context" {
    var buffer: [5]c_char = undefined;
    const init_err = con.con_serialize_context_init(null, @ptrCast(&buffer), buffer.len);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

test "init_null_buffer" {
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_context_init(&context, null, 10);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

test "init_negative_buffer" {
    var context: con.ConSerialize = undefined;
    var buffer: [5]c_char = undefined;

    const init_err = con.con_serialize_context_init(&context, @ptrCast(&buffer), -1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_BUFFER), init_err);
}

test "current_position" {
    var context: con.ConSerialize = undefined;
    var buffer: [5]c_char = undefined;
    var curr: c_int = undefined;

    const init_err = con.con_serialize_context_init(&context, @ptrCast(&buffer), buffer.len);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);
    var pos_err = con.con_serialize_current_position(&context, &curr);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), pos_err);
    try testing.expectEqual(0, curr);

    context.current_position = 3;
    pos_err = con.con_serialize_current_position(&context, &curr);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), pos_err);
    try testing.expectEqual(3, curr);
}

test "current_position_null_out" {
    var context: con.ConSerialize = undefined;
    var buffer: [5]c_char = undefined;

    const init_err = con.con_serialize_context_init(&context, @ptrCast(&buffer), buffer.len);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);
    const pos_err = con.con_serialize_current_position(&context, null);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), pos_err);
}

test "set_buffer" {
    var context: con.ConSerialize = undefined;
    var buffer: [5]c_char = undefined;
    var new: [6]c_char = undefined;

    const init_err = con.con_serialize_context_init(&context, @ptrCast(&buffer), buffer.len);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);
    context.current_position = 1;

    const set_err = con.con_serialize_buffer_set(&context, @ptrCast(&new), new.len);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), set_err);
    try testing.expectEqual(@as([*c]u8, @ptrCast(&new)), context.out_buffer);
    try testing.expectEqual(@as(c_int, @intCast(new.len)), context.out_buffer_size);
    try testing.expectEqual(0, context.current_position);
}

test "set_null_buffer" {
    var context: con.ConSerialize = undefined;
    var buffer: [5]c_char = undefined;

    const init_err = con.con_serialize_context_init(&context, @ptrCast(&buffer), buffer.len);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const set_err = con.con_serialize_buffer_set(&context, null, 10);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), set_err);
}

test "set_negative_buffer" {
    var context: con.ConSerialize = undefined;
    var buffer: [5]c_char = undefined;
    var new: [6]c_char = undefined;

    const init_err = con.con_serialize_context_init(&context, @ptrCast(&buffer), buffer.len);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const set_err = con.con_serialize_buffer_set(&context, @ptrCast(&new), -2);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_BUFFER), set_err);
}

test "get_buffer" {
    var context: con.ConSerialize = undefined;
    var buffer: [5]c_char = undefined;

    const init_err = con.con_serialize_context_init(&context, @ptrCast(&buffer), buffer.len);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    var get_size: c_int = undefined;
    var get_buffer: [*c]c_char = undefined;
    const get_err = con.con_serialize_buffer_get(&context, @ptrCast(&get_buffer), &get_size);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), get_err);
    try testing.expectEqual(@as([*c]c_char, @ptrCast(&buffer)), get_buffer);
    try testing.expectEqual(5, get_size);
}

test "get_buffer_null_buffer_out" {
    var context: con.ConSerialize = undefined;
    var buffer: [5]c_char = undefined;

    const init_err = con.con_serialize_context_init(&context, @ptrCast(&buffer), buffer.len);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    var get_size: c_int = 2;
    const get_err = con.con_serialize_buffer_get(&context, null, &get_size);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), get_err);
    try testing.expectEqual(2, get_size);
}

test "get_buffer_null_size_out" {
    var context: con.ConSerialize = undefined;
    var buffer: [5]c_char = undefined;

    const init_err = con.con_serialize_context_init(&context, @ptrCast(&buffer), buffer.len);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    var get_buffer: [*c]c_char = 2;
    const get_err = con.con_serialize_buffer_get(&context, @ptrCast(&get_buffer), null);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), get_err);
    try testing.expectEqual(2, get_buffer);
}

test "clear_buffer" {
    var context: con.ConSerialize = undefined;
    var buffer: [5]c_char = undefined;

    const init_err = con.con_serialize_context_init(&context, @ptrCast(&buffer), buffer.len);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);
    context.current_position = 3;

    const clear_err = con.con_serialize_buffer_clear(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), clear_err);
    context.current_position = 0;
}
