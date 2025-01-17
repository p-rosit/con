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
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_context_init(
        &context,
        null,
        write,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);
}

test "init_null_context" {
    const init_err = con.con_serialize_context_init(
        null,
        null,
        write,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

test "array" {
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_context_init(
        &context,
        &fifo.writer(),
        write,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    {
        const open_err = con.con_serialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

        const close_err = con.con_serialize_array_close(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

        try testing.expectEqualStrings("[]", &buffer);
    }
}
