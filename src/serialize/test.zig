const std = @import("std");
const testing = @import("std").testing;
const con = @cImport({
    @cInclude("serialize.h");
});

const con_dict = 1;
const con_array = 2;

test "zig bindings" {
    _ = @import("serialize.zig");
}

const Fifo = std.fifo.LinearFifo(u8, .Slice);

fn write(writer: ?*const anyopaque, data: [*c]const u8) callconv(.C) c_int {
    std.debug.assert(null != writer);
    std.debug.assert(null != data);
    const w: *const Fifo.Writer = @alignCast(@ptrCast(writer));
    const d = std.mem.span(data);
    return @intCast(w.write(d) catch 0);
}

test "context init" {
    var depth: [0]u8 = undefined;
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_init(
        &context,
        null,
        write,
        &depth,
        0,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);
}

test "context depth null, length positive" {
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_init(
        &context,
        null,
        write,
        null,
        1,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

test "context depth null, length zero" {
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_init(
        &context,
        null,
        write,
        null,
        0,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);
}

test "context depth negative" {
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_init(
        &context,
        null,
        write,
        @ptrFromInt(1),
        -1,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_BUFFER), init_err);
}

test "context init null" {
    var depth: [0]u8 = undefined;

    const init_err = con.con_serialize_init(
        null,
        null,
        write,
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

test "array open" {
    var depth: [1]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_init(
        &context,
        &fifo.writer(),
        write,
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    try testing.expectEqualStrings("[", &buffer);
}

test "array open too many" {
    var depth: [0]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_init(
        &context,
        &fifo.writer(),
        write,
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_TOO_DEEP), open_err);
}

test "array open writer fail" {
    var depth: [1]u8 = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_init(
        &context,
        &fifo.writer(),
        write,
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), open_err);
}

test "array close" {
    var depth: [1]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_init(
        &context,
        &fifo.writer(),
        write,
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    context.depth = 1;
    context.depth_buffer[0] = con_array;
    const close_err = con.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

    try testing.expectEqualStrings("]", &buffer);
}

test "array close writer fail" {
    var depth: [1]u8 = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_init(
        &context,
        &fifo.writer(),
        write,
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    context.depth = 1;
    context.depth_buffer[0] = con_array;
    const close_err = con.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), close_err);
}

test "array close too many" {
    var depth: [1]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_init(
        &context,
        &fifo.writer(),
        write,
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const close_err = con.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_CLOSED_TOO_MANY), close_err);
}

test "dict open" {
    var depth: [1]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_init(
        &context,
        &fifo.writer(),
        write,
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    try testing.expectEqualStrings("{", &buffer);
}

test "dict open too many" {
    var depth: [0]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_init(
        &context,
        &fifo.writer(),
        write,
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_TOO_DEEP), open_err);
}

test "dict open writer fail" {
    var depth: [1]u8 = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_init(
        &context,
        &fifo.writer(),
        write,
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), open_err);
}

test "dict close" {
    var depth: [1]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_init(
        &context,
        &fifo.writer(),
        write,
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    context.depth = 1;
    context.depth_buffer[0] = con_dict;
    const close_err = con.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

    try testing.expectEqualStrings("}", &buffer);
}

test "dict close writer fail" {
    var depth: [1]u8 = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_init(
        &context,
        &fifo.writer(),
        write,
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    context.depth = 1;
    context.depth_buffer[0] = con_dict;
    const close_err = con.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), close_err);
}

test "dict close too many" {
    var depth: [1]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_init(
        &context,
        &fifo.writer(),
        write,
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const close_err = con.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_CLOSED_TOO_MANY), close_err);
}

test "array open -> dict close" {
    var depth: [1]u8 = undefined;
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_init(
        &context,
        &fifo.writer(),
        write,
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    const close_err = con.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_CLOSED_WRONG), close_err);
}

test "dict open -> array close" {
    var depth: [1]u8 = undefined;
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_init(
        &context,
        &fifo.writer(),
        write,
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    const close_err = con.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_CLOSED_WRONG), close_err);
}

test "number int-like" {
    var depth: [0]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_init(
        &context,
        &fifo.writer(),
        write,
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const num_err = con.con_serialize_number(&context, "2");
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), num_err);
}

test "number float-like" {
    var depth: [0]u8 = undefined;
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_init(
        &context,
        &fifo.writer(),
        write,
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const num_err = con.con_serialize_number(&context, ".3");
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), num_err);
}

test "number scientific-like" {
    var depth: [0]u8 = undefined;
    var buffer: [3]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_init(
        &context,
        &fifo.writer(),
        write,
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const num_err = con.con_serialize_number(&context, "2e4");
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), num_err);
}

test "number write fail" {
    var depth: [0]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_init(
        &context,
        &fifo.writer(),
        write,
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const num_err = con.con_serialize_number(&context, "65");
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), num_err);
}

test "number null" {
    var depth: [0]u8 = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_init(
        &context,
        &fifo.writer(),
        write,
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const num_err = con.con_serialize_number(&context, null);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), num_err);
}

test "string" {
    var depth: [0]u8 = undefined;
    var buffer: [3]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context: con.ConSerialize = undefined;

    const init_err = con.con_serialize_init(
        &context,
        &fifo.writer(),
        write,
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const str_err = con.con_serialize_string(&context, "-");
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), str_err);
}
