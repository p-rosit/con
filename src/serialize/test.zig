const std = @import("std");
const testing = @import("std").testing;
const con = @cImport({
    @cInclude("serialize.h");
});

test "zig_bindings" {
    _ = @import("serialize.zig");
}

fn alloc(allocator: *const anyopaque, size: usize) callconv(.C) [*c]u8 {
    const a = @as(*const std.mem.Allocator, @alignCast(@ptrCast(allocator)));
    const ptr = a.alignedAlloc(u8, 8, size) catch null;
    return @ptrCast(ptr);
}

fn free(allocator: *const anyopaque, data: [*c]u8, size: usize) callconv(.C) void {
    std.debug.assert(null != data);
    const a = @as(*const std.mem.Allocator, @alignCast(@ptrCast(allocator)));
    const p = data[0..size];
    a.free(@as([]align(8) u8, @alignCast(p)));
}

test "init_failing_first_alloc" {
    var failing_allocator = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = 0 });
    const allocator = failing_allocator.allocator();
    const buffer_size = 5;
    var context: *con.ConSerialize = undefined;

    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        @ptrCast(&allocator),
        @ptrCast(&alloc),
        @ptrCast(&free),
        buffer_size,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_MEM), init_err);
}

test "init_failing_second_alloc" {
    var failing_allocator = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = 1 });
    const allocator = failing_allocator.allocator();
    const buffer_size = 5;
    var context: *con.ConSerialize = undefined;

    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        @ptrCast(&allocator),
        @ptrCast(&alloc),
        @ptrCast(&free),
        buffer_size,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_MEM), init_err);
}

test "init" {
    var failing_allocator = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = 2 });
    const allocator = failing_allocator.allocator();
    const buffer_size = 5;
    var context: *con.ConSerialize = @ptrFromInt(1);

    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        @ptrCast(&allocator),
        @ptrCast(&alloc),
        @ptrCast(&free),
        buffer_size,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);
    try testing.expect(context != @as(*con.ConSerialize, @ptrFromInt(1)));

    const deinit_err = con.con_serialize_context_deinit(
        context,
        @ptrCast(&testing.allocator),
        @ptrCast(&free),
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), deinit_err);
}

test "init_null_context" {
    const buffer_size = 5;
    const init_err = con.con_serialize_context_init(
        null,
        @ptrCast(&testing.allocator),
        @ptrCast(&alloc),
        @ptrCast(&free),
        buffer_size,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

test "init_null_alloc" {
    const buffer_size = -1;
    var context: *con.ConSerialize = undefined;

    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        @ptrCast(&testing.allocator),
        null,
        @ptrCast(&free),
        buffer_size,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

test "init_null_free" {
    const buffer_size = -1;
    var context: *con.ConSerialize = undefined;

    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        @ptrCast(&testing.allocator),
        @ptrCast(&alloc),
        null,
        buffer_size,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

test "deinit_null_free" {
    const buffer_size = 5;
    var context: *con.ConSerialize = undefined;

    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        @ptrCast(&testing.allocator),
        @ptrCast(&alloc),
        @ptrCast(&free),
        buffer_size,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const deinit_err = con.con_serialize_context_deinit(
        context,
        @ptrCast(&testing.allocator),
        null,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), deinit_err);

    const deinit_ok = con.con_serialize_context_deinit(
        context,
        @ptrCast(&testing.allocator),
        @ptrCast(&free),
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), deinit_ok);
}

test "init_negative_buffer" {
    const buffer_size = -1;
    var context: *con.ConSerialize = undefined;

    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        @ptrCast(&testing.allocator),
        @ptrCast(&alloc),
        @ptrCast(&free),
        buffer_size,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_BUFFER), init_err);
}

test "current_position" {
    const buffer_size = 5;
    var context: *con.ConSerialize = undefined;

    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        @ptrCast(&testing.allocator),
        @ptrCast(&alloc),
        @ptrCast(&free),
        buffer_size,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    {
        var curr: c_int = undefined;
        const pos_err = con.con_serialize_current_position(context, &curr);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), pos_err);
        try testing.expectEqual(0, curr);
    }

    const deinit_err = con.con_serialize_context_deinit(
        context,
        @ptrCast(&testing.allocator),
        @ptrCast(&free),
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), deinit_err);
}

test "current_position_null_out" {
    const buffer_size = 5;
    var context: *con.ConSerialize = undefined;

    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        @ptrCast(&testing.allocator),
        @ptrCast(&alloc),
        @ptrCast(&free),
        buffer_size,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    {
        const pos_err = con.con_serialize_current_position(context, null);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), pos_err);
    }

    const deinit_err = con.con_serialize_context_deinit(
        context,
        @ptrCast(&testing.allocator),
        @ptrCast(&free),
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), deinit_err);
}

test "get_buffer" {
    const buffer_size = 5;
    var context: *con.ConSerialize = undefined;

    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        @ptrCast(&testing.allocator),
        @ptrCast(&alloc),
        @ptrCast(&free),
        buffer_size,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    {
        var get_size: c_int = undefined;
        var get_buffer: [*c]c_char = 1;
        const get_err = con.con_serialize_buffer_get(context, @ptrCast(&get_buffer), &get_size);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), get_err);
        try testing.expect(get_buffer != null);
        try testing.expect(get_buffer != 1);
        try testing.expectEqual(5, get_size);
    }

    const deinit_err = con.con_serialize_context_deinit(
        context,
        @ptrCast(&testing.allocator),
        @ptrCast(&free),
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), deinit_err);
}

test "get_buffer_null_buffer_out" {
    const buffer_size = 5;
    var context: *con.ConSerialize = undefined;

    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        @ptrCast(&testing.allocator),
        @ptrCast(&alloc),
        @ptrCast(&free),
        buffer_size,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    {
        var get_size: c_int = 2;
        const get_err = con.con_serialize_buffer_get(context, null, &get_size);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), get_err);
        try testing.expectEqual(2, get_size);
    }

    const deinit_err = con.con_serialize_context_deinit(
        context,
        @ptrCast(&testing.allocator),
        @ptrCast(&free),
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), deinit_err);
}

test "get_buffer_null_size_out" {
    const buffer_size = 5;
    var context: *con.ConSerialize = undefined;

    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        @ptrCast(&testing.allocator),
        @ptrCast(&alloc),
        @ptrCast(&free),
        buffer_size,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    {
        var get_buffer: [*c]c_char = 2;
        const get_err = con.con_serialize_buffer_get(context, @ptrCast(&get_buffer), null);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), get_err);
        try testing.expectEqual(2, get_buffer);
    }

    const deinit_err = con.con_serialize_context_deinit(
        context,
        @ptrCast(&testing.allocator),
        @ptrCast(&free),
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), deinit_err);
}

test "clear_buffer" {
    const buffer_size = 3;
    var context: *con.ConSerialize = undefined;

    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        @ptrCast(&testing.allocator),
        @ptrCast(&alloc),
        @ptrCast(&free),
        buffer_size,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    {
        const clear_err = con.con_serialize_buffer_clear(context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), clear_err);

        var curr: c_int = undefined;
        const pos_err = con.con_serialize_current_position(context, &curr);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), pos_err);
        try testing.expectEqual(0, curr);
    }

    const deinit_err = con.con_serialize_context_deinit(
        context,
        @ptrCast(&testing.allocator),
        @ptrCast(&free),
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), deinit_err);
}

test "array" {
    const buffer_size = 2;
    var context: *con.ConSerialize = undefined;

    const init_err = con.con_serialize_context_init(
        @ptrCast(&context),
        @ptrCast(&testing.allocator),
        @ptrCast(&alloc),
        @ptrCast(&free),
        buffer_size,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    {
        const open_err = con.con_serialize_array_open(context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

        const close_err = con.con_serialize_array_close(context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

        var get_size: c_int = undefined;
        var get_buffer: [*c]c_char = undefined;
        const get_err = con.con_serialize_buffer_get(context, @ptrCast(&get_buffer), &get_size);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), get_err);

        const b = get_buffer[0..@intCast(get_size)];
        try testing.expectEqualStrings("[]", @ptrCast(b));
    }

    const deinit_err = con.con_serialize_context_deinit(
        context,
        @ptrCast(&testing.allocator),
        @ptrCast(&free),
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), deinit_err);
}
