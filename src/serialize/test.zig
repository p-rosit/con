const std = @import("std");
const testing = @import("std").testing;
const con = @cImport({
    @cInclude("serialize.h");
});

test "zig_bindings" {
    _ = @import("serialize.zig");
}

fn alloc(allocator: *anyopaque, size: usize) callconv(.C) [*c]u8 {
    const a = @as(*const std.mem.Allocator, @alignCast(@ptrCast(allocator)));
    const ptr = a.alignedAlloc(u8, 8, size) catch null;
    return @ptrCast(ptr);
}

fn free(allocator: *anyopaque, data: [*c]u8, size: usize) callconv(.C) void {
    std.debug.assert(null != data);
    const a = @as(*const std.mem.Allocator, @alignCast(@ptrCast(allocator)));
    const p = data[0..size];
    a.free(@as([]align(8) u8, @alignCast(p)));
}

test "init" {
    var context: *con.ConSerialize = undefined;
    var buffer: [5]c_char = undefined;

    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        @ptrCast(&buffer),
        buffer.len,
        @ptrCast(@constCast(&testing.allocator)),
        @ptrCast(&alloc),
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);
    defer con.con_serialize_context_deinit(
        context,
        @ptrCast(@constCast(&testing.allocator)),
        @ptrCast(&free),
    );
}

test "init_failing_alloc" {
    var context: *con.ConSerialize = undefined;
    var buffer: [4]c_char = undefined;

    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        @ptrCast(&buffer),
        buffer.len,
        @ptrCast(@constCast(&testing.failing_allocator)),
        @ptrCast(&alloc),
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_MEM), init_err);
}

test "init_null_context" {
    var buffer: [5]c_char = undefined;
    const init_err = con.con_serialize_context_init(
        null,
        @ptrCast(&buffer),
        buffer.len,
        @ptrCast(@constCast(&testing.allocator)),
        @ptrCast(&alloc),
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

test "init_null_buffer" {
    var context: *con.ConSerialize = undefined;
    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        null,
        10,
        @ptrCast(@constCast(&testing.allocator)),
        @ptrCast(&alloc),
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

test "init_negative_buffer" {
    var context: *con.ConSerialize = undefined;
    var buffer: [5]c_char = undefined;

    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        @ptrCast(&buffer),
        -1,
        @ptrCast(@constCast(&testing.allocator)),
        @ptrCast(&alloc),
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_BUFFER), init_err);
}

test "current_position" {
    var context: *con.ConSerialize = undefined;
    var buffer: [5]c_char = undefined;

    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        @ptrCast(&buffer),
        buffer.len,
        @ptrCast(@constCast(&testing.allocator)),
        @ptrCast(&alloc),
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);
    defer con.con_serialize_context_deinit(
        context,
        @ptrCast(@constCast(&testing.allocator)),
        @ptrCast(&free),
    );

    var curr: c_int = undefined;
    const pos_err = con.con_serialize_current_position(context, &curr);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), pos_err);
    try testing.expectEqual(0, curr);
}

test "current_position_null_out" {
    var context: *con.ConSerialize = undefined;
    var buffer: [5]c_char = undefined;

    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        @ptrCast(&buffer),
        buffer.len,
        @ptrCast(@constCast(&testing.allocator)),
        @ptrCast(&alloc),
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);
    defer con.con_serialize_context_deinit(
        context,
        @ptrCast(@constCast(&testing.allocator)),
        @ptrCast(&free),
    );
    const pos_err = con.con_serialize_current_position(context, null);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), pos_err);
}

test "get_buffer" {
    var context: *con.ConSerialize = undefined;
    var buffer: [5]c_char = undefined;

    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        @ptrCast(&buffer),
        buffer.len,
        @ptrCast(@constCast(&testing.allocator)),
        @ptrCast(&alloc),
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);
    defer con.con_serialize_context_deinit(
        context,
        @ptrCast(@constCast(&testing.allocator)),
        @ptrCast(&free),
    );

    var get_size: c_int = undefined;
    var get_buffer: [*c]c_char = undefined;
    const get_err = con.con_serialize_buffer_get(context, @ptrCast(&get_buffer), &get_size);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), get_err);
    try testing.expectEqual(@as([*c]c_char, @ptrCast(&buffer)), get_buffer);
    try testing.expectEqual(5, get_size);
}

test "get_buffer_null_buffer_out" {
    var context: *con.ConSerialize = undefined;
    var buffer: [5]c_char = undefined;

    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        @ptrCast(&buffer),
        buffer.len,
        @ptrCast(@constCast(&testing.allocator)),
        @ptrCast(&alloc),
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);
    defer con.con_serialize_context_deinit(
        context,
        @ptrCast(@constCast(&testing.allocator)),
        @ptrCast(&free),
    );

    var get_size: c_int = 2;
    const get_err = con.con_serialize_buffer_get(context, null, &get_size);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), get_err);
    try testing.expectEqual(2, get_size);
}

test "get_buffer_null_size_out" {
    var context: *con.ConSerialize = undefined;
    var buffer: [5]c_char = undefined;

    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        @ptrCast(&buffer),
        buffer.len,
        @ptrCast(@constCast(&testing.allocator)),
        @ptrCast(&alloc),
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);
    defer con.con_serialize_context_deinit(
        context,
        @ptrCast(@constCast(&testing.allocator)),
        @ptrCast(&free),
    );

    var get_buffer: [*c]c_char = 2;
    const get_err = con.con_serialize_buffer_get(context, @ptrCast(&get_buffer), null);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), get_err);
    try testing.expectEqual(2, get_buffer);
}

test "clear_buffer" {
    var context: *con.ConSerialize = undefined;
    var buffer: [5]c_char = undefined;

    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        @ptrCast(&buffer),
        buffer.len,
        @ptrCast(@constCast(&testing.allocator)),
        @ptrCast(&alloc),
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);
    defer con.con_serialize_context_deinit(
        context,
        @ptrCast(@constCast(&testing.allocator)),
        @ptrCast(&free),
    );

    const clear_err = con.con_serialize_buffer_clear(context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), clear_err);

    var curr: c_int = undefined;
    const pos_err = con.con_serialize_current_position(context, &curr);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), pos_err);
    try testing.expectEqual(0, curr);
}

test "array" {
    var context: *con.ConSerialize = undefined;
    var buffer: [2]c_char = undefined;

    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        @ptrCast(&buffer),
        buffer.len,
        @ptrCast(@constCast(&testing.allocator)),
        @ptrCast(&alloc),
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);
    defer con.con_serialize_context_deinit(
        context,
        @ptrCast(@constCast(&testing.allocator)),
        @ptrCast(&free),
    );

    const open_err = con.con_serialize_array_open(context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    const close_err = con.con_serialize_array_close(context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

    try testing.expectEqualStrings("[]", @ptrCast(&buffer));
}
