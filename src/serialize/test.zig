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

const Fifo = std.fifo.LinearFifo(u8, .Slice);

fn write(writer: ?*const anyopaque, data: [*c]const u8) callconv(.C) c_int {
    std.debug.assert(null != writer);
    std.debug.assert(null != data);
    const w: *const Fifo.Writer = @alignCast(@ptrCast(writer));
    const d = std.mem.span(data);
    return @intCast(w.write(d) catch 0);
}

test "init" {
    var failing_allocator = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = 0 });
    const allocator = failing_allocator.allocator();
    const buffer_size = 5;
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_context_init(
        &context,
        null,
        write,
        @ptrCast(&allocator),
        @ptrCast(&alloc),
        @ptrCast(&free),
        buffer_size,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const deinit_err = con.con_serialize_context_deinit(
        &context,
        @ptrCast(&testing.allocator),
        @ptrCast(&free),
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), deinit_err);
}

test "init_null_context" {
    const buffer_size = 5;
    const init_err = con.con_serialize_context_init(
        null,
        null,
        write,
        @ptrCast(&testing.allocator),
        @ptrCast(&alloc),
        @ptrCast(&free),
        buffer_size,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

test "init_null_alloc" {
    const buffer_size = -1;
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_context_init(
        &context,
        null,
        write,
        @ptrCast(&testing.allocator),
        null,
        @ptrCast(&free),
        buffer_size,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

test "init_null_free" {
    const buffer_size = -1;
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_context_init(
        &context,
        null,
        write,
        @ptrCast(&testing.allocator),
        @ptrCast(&alloc),
        null,
        buffer_size,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

test "deinit_null_free" {
    const buffer_size = 5;
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_context_init(
        &context,
        null,
        write,
        @ptrCast(&testing.allocator),
        @ptrCast(&alloc),
        @ptrCast(&free),
        buffer_size,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const deinit_err = con.con_serialize_context_deinit(
        &context,
        @ptrCast(&testing.allocator),
        null,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), deinit_err);

    const deinit_ok = con.con_serialize_context_deinit(
        &context,
        @ptrCast(&testing.allocator),
        @ptrCast(&free),
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), deinit_ok);
}

test "init_negative_buffer" {
    const buffer_size = -1;
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_context_init(
        &context,
        null,
        write,
        @ptrCast(&testing.allocator),
        @ptrCast(&alloc),
        @ptrCast(&free),
        buffer_size,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_BUFFER), init_err);
}

test "array" {
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_context_init(
        &context,
        &fifo.writer(),
        write,
        @ptrCast(&testing.allocator),
        @ptrCast(&alloc),
        @ptrCast(&free),
        2,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    {
        const open_err = con.con_serialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

        const close_err = con.con_serialize_array_close(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

        try testing.expectEqualStrings("[]", &buffer);
    }

    const deinit_err = con.con_serialize_context_deinit(
        &context,
        @ptrCast(&testing.allocator),
        @ptrCast(&free),
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), deinit_err);
}
