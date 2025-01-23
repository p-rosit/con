const std = @import("std");
const testing = @import("std").testing;
const con = @cImport({
    @cInclude("serialize.h");
});

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

// Section: Values -------------------------------------------------------------

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

test "number writer fail" {
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

    const num_err = con.con_serialize_number(&context, "6");
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), num_err);
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

test "string null" {
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

    const str_err = con.con_serialize_string(&context, null);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), str_err);
}

test "string first quote writer fail" {
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

    const str_err = con.con_serialize_string(&context, "-");
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), str_err);
}

test "string body writer fail" {
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

    const str_err = con.con_serialize_string(&context, "-");
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), str_err);
    try testing.expectEqualStrings("\"", &buffer);
}

test "string second quote writer fail" {
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

    const str_err = con.con_serialize_string(&context, "-");
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), str_err);
    try testing.expectEqualStrings("\"-", &buffer);
}

test "bool true" {
    var depth: [0]u8 = undefined;
    var buffer: [4]u8 = undefined;
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

    const bool_err = con.con_serialize_bool(&context, true);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), bool_err);

    try testing.expectEqualStrings("true", &buffer);
}

test "bool true writer fail" {
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

    const bool_err = con.con_serialize_bool(&context, true);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), bool_err);
}

test "bool false" {
    var depth: [0]u8 = undefined;
    var buffer: [5]u8 = undefined;
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

    const bool_err = con.con_serialize_bool(&context, false);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), bool_err);

    try testing.expectEqualStrings("false", &buffer);
}

test "bool false writer fail" {
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

    const bool_err = con.con_serialize_bool(&context, false);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), bool_err);
}

test "null" {
    var depth: [0]u8 = undefined;
    var buffer: [4]u8 = undefined;
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

    const null_err = con.con_serialize_null(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), null_err);

    try testing.expectEqualStrings("null", &buffer);
}

test "null writer fail" {
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

    const null_err = con.con_serialize_null(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), null_err);
}

// Section: Containers ---------------------------------------------------------

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

    const close_err = con.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

    try testing.expectEqualStrings("[]", &buffer);
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

test "array close writer fail" {
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

    const close_err = con.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), close_err);
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

    const close_err = con.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

    try testing.expectEqualStrings("{}", &buffer);
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

test "dict close writer fail" {
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

    const close_err = con.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), close_err);
}

// Section: Dict key -----------------------------------------------------------

test "dict key" {
    var depth: [1]u8 = undefined;
    var buffer: [7]u8 = undefined;
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

    {
        const key_err = con.con_serialize_dict_key(&context, "key");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), key_err);

        try testing.expectEqualStrings("{\"key\":", &buffer);
    }
}

test "dict key multiple" {
    var depth: [1]u8 = undefined;
    var buffer: [13]u8 = undefined;
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

    {
        const key_err = con.con_serialize_dict_key(&context, "k1");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), key_err);

        const item_err = con.con_serialize_number(&context, "1");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item_err);

        const err = con.con_serialize_dict_key(&context, "k2");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), err);

        try testing.expectEqualStrings("{\"k1\":1,\"k2\":", &buffer);
    }
}

test "dict key null" {
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

    {
        const key_err = con.con_serialize_dict_key(&context, null);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), key_err);
    }
}

test "dict key comma writer fail" {
    var depth: [1]u8 = undefined;
    var buffer: [6]u8 = undefined;
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

    {
        const key1_err = con.con_serialize_dict_key(&context, "a");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), key1_err);
        const item1_err = con.con_serialize_number(&context, "1");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item1_err);
        try testing.expectEqualStrings("{\"a\":1", &buffer);

        const key2_err = con.con_serialize_dict_key(&context, "2");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), key2_err);
    }
}

test "dict key outside dict" {
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

    const key_err = con.con_serialize_dict_key(&context, "key");
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NOT_DICT), key_err);
}

test "dict key in array" {
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

    {
        const key_err = con.con_serialize_dict_key(&context, "key");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NOT_DICT), key_err);
    }
}

test "dict key twice" {
    var depth: [1]u8 = undefined;
    var buffer: [7]u8 = undefined;
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

    {
        const key1_err = con.con_serialize_dict_key(&context, "key");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), key1_err);

        const key2_err = con.con_serialize_dict_key(&context, "key");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_VALUE), key2_err);
    }
}

test "dict number key missing" {
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

    {
        const num_err = con.con_serialize_number(&context, "2");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_KEY), num_err);
    }
}

test "dict number second key missing" {
    var depth: [1]u8 = undefined;
    var buffer: [6]u8 = undefined;
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

    {
        const key_err = con.con_serialize_dict_key(&context, "k");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), key_err);
        const item_err = con.con_serialize_number(&context, "1");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item_err);

        const num_err = con.con_serialize_number(&context, "2");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_KEY), num_err);
    }
}

test "dict string key missing" {
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

    {
        const str_err = con.con_serialize_string(&context, "2");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_KEY), str_err);
    }
}

test "dict string second key missing" {
    var depth: [1]u8 = undefined;
    var buffer: [8]u8 = undefined;
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

    {
        const key_err = con.con_serialize_dict_key(&context, "k");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), key_err);
        const item_err = con.con_serialize_string(&context, "a");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item_err);

        const str_err = con.con_serialize_string(&context, "b");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_KEY), str_err);
    }
}

test "dict array key missing" {
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

    {
        const array_err = con.con_serialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_KEY), array_err);
    }
}

test "dict array second key missing" {
    var depth: [1]u8 = undefined;
    var buffer: [6]u8 = undefined;
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

    {
        const key_err = con.con_serialize_dict_key(&context, "k");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), key_err);
        const item_err = con.con_serialize_number(&context, "1");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item_err);

        const str_err = con.con_serialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_KEY), str_err);
    }
}

test "dict dict key missing" {
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

    {
        const dict_err = con.con_serialize_dict_open(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_KEY), dict_err);
    }
}

test "dict dict second key missing" {
    var depth: [1]u8 = undefined;
    var buffer: [6]u8 = undefined;
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
    {
        const key_err = con.con_serialize_dict_key(&context, "k");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), key_err);
        const item_err = con.con_serialize_number(&context, "1");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item_err);

        const str_err = con.con_serialize_dict_open(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_KEY), str_err);
    }
}

// Section: Combinations of containers -----------------------------------------

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
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NOT_DICT), close_err);
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
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NOT_ARRAY), close_err);
}

test "array number single" {
    var depth: [1]u8 = undefined;
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

    const open_err = con.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    {
        const num_err = con.con_serialize_number(&context, "2");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), num_err);
    }

    const close_err = con.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

    try testing.expectEqualStrings("[2]", &buffer);
}

test "array number multiple" {
    var depth: [1]u8 = undefined;
    var buffer: [5]u8 = undefined;
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

    {
        const item1_err = con.con_serialize_number(&context, "6");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item1_err);

        const item2_err = con.con_serialize_number(&context, "4");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item2_err);
    }

    const close_err = con.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

    try testing.expectEqualStrings("[6,4]", &buffer);
}

test "array number comma writer fail" {
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

    {
        const item1_err = con.con_serialize_number(&context, "2");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item1_err);
        try testing.expectEqualStrings("[2", &buffer);

        const item2_err = con.con_serialize_number(&context, "3");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), item2_err);
    }
}

test "array string single" {
    var depth: [1]u8 = undefined;
    var buffer: [5]u8 = undefined;
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

    {
        const str_err = con.con_serialize_string(&context, "a");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), str_err);
    }

    const close_err = con.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

    try testing.expectEqualStrings("[\"a\"]", &buffer);
}

test "array string multiple" {
    var depth: [1]u8 = undefined;
    var buffer: [9]u8 = undefined;
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

    {
        const item1_err = con.con_serialize_string(&context, "a");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item1_err);

        const item2_err = con.con_serialize_string(&context, "b");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item2_err);
    }

    const close_err = con.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

    try testing.expectEqualStrings("[\"a\",\"b\"]", &buffer);
}

test "array string comma writer fail" {
    var depth: [1]u8 = undefined;
    var buffer: [4]u8 = undefined;
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

    {
        const item1_err = con.con_serialize_string(&context, "a");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item1_err);
        try testing.expectEqualStrings("[\"a\"", &buffer);

        const item2_err = con.con_serialize_string(&context, "b");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), item2_err);
    }
}

test "array array single" {
    var depth: [2]u8 = undefined;
    var buffer: [4]u8 = undefined;
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

    {
        const sub_open_err = con.con_serialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), sub_open_err);
        const sub_close_err = con.con_serialize_array_close(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), sub_close_err);
    }

    const close_err = con.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);
    try testing.expectEqualStrings("[[]]", &buffer);
}

test "array array multiple" {
    var depth: [2]u8 = undefined;
    var buffer: [7]u8 = undefined;
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

    {
        const sub_open_err1 = con.con_serialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), sub_open_err1);
        const sub_close_err1 = con.con_serialize_array_close(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), sub_close_err1);

        const sub_open_err2 = con.con_serialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), sub_open_err2);
        const sub_close_err2 = con.con_serialize_array_close(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), sub_close_err2);
    }

    const close_err = con.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);
    try testing.expectEqualStrings("[[],[]]", &buffer);
}

test "array array comma writer fail" {
    var depth: [2]u8 = undefined;
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

    const open_err = con.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    {
        const sub_open_err1 = con.con_serialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), sub_open_err1);
        const sub_close_err1 = con.con_serialize_array_close(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), sub_close_err1);

        try testing.expectEqualStrings("[[]", &buffer);

        const sub_open_err2 = con.con_serialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), sub_open_err2);
    }
}

test "array dict single" {
    var depth: [2]u8 = undefined;
    var buffer: [4]u8 = undefined;
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

    {
        const sub_open_err = con.con_serialize_dict_open(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), sub_open_err);
        const sub_close_err = con.con_serialize_dict_close(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), sub_close_err);
    }

    const close_err = con.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);
    try testing.expectEqualStrings("[{}]", &buffer);
}

test "array dict multiple" {
    var depth: [2]u8 = undefined;
    var buffer: [7]u8 = undefined;
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

    {
        const sub_open_err1 = con.con_serialize_dict_open(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), sub_open_err1);
        const sub_close_err1 = con.con_serialize_dict_close(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), sub_close_err1);

        const sub_open_err2 = con.con_serialize_dict_open(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), sub_open_err2);
        const sub_close_err2 = con.con_serialize_dict_close(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), sub_close_err2);
    }

    const close_err = con.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);
    try testing.expectEqualStrings("[{},{}]", &buffer);
}

test "array dict comma writer fail" {
    var depth: [2]u8 = undefined;
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

    const open_err = con.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    {
        const sub_open_err1 = con.con_serialize_dict_open(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), sub_open_err1);
        const sub_close_err1 = con.con_serialize_dict_close(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), sub_close_err1);

        try testing.expectEqualStrings("[{}", &buffer);

        const sub_open_err2 = con.con_serialize_dict_open(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), sub_open_err2);
    }
}

test "dict number single" {
    var depth: [1]u8 = undefined;
    var buffer: [7]u8 = undefined;
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

    {
        const key1_err = con.con_serialize_dict_key(&context, "a");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), key1_err);
        const item1_err = con.con_serialize_number(&context, "1");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item1_err);
    }

    const close_err = con.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

    try testing.expectEqualStrings("{\"a\":1}", &buffer);
}

test "dict string single" {
    var depth: [1]u8 = undefined;
    var buffer: [9]u8 = undefined;
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

    {
        const key_err = con.con_serialize_dict_key(&context, "a");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), key_err);
        const item_err = con.con_serialize_string(&context, "b");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item_err);
    }

    const close_err = con.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

    try testing.expectEqualStrings("{\"a\":\"b\"}", &buffer);
}

test "dict string mulitple" {
    var depth: [1]u8 = undefined;
    var buffer: [17]u8 = undefined;
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

    {
        const key1_err = con.con_serialize_dict_key(&context, "a");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), key1_err);
        const item1_err = con.con_serialize_string(&context, "b");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item1_err);

        const key2_err = con.con_serialize_dict_key(&context, "c");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), key2_err);
        const item2_err = con.con_serialize_string(&context, "d");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item2_err);
    }

    const close_err = con.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

    try testing.expectEqualStrings("{\"a\":\"b\",\"c\":\"d\"}", &buffer);
}

test "dict array single" {
    var depth: [2]u8 = undefined;
    var buffer: [8]u8 = undefined;
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

    {
        const key_err = con.con_serialize_dict_key(&context, "a");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), key_err);

        const sub_open_err = con.con_serialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), sub_open_err);
        const sub_close_err = con.con_serialize_array_close(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), sub_close_err);
    }

    const close_err = con.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

    try testing.expectEqualStrings("{\"a\":[]}", &buffer);
}

test "dict dict single" {
    var depth: [2]u8 = undefined;
    var buffer: [8]u8 = undefined;
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

    {
        const key_err = con.con_serialize_dict_key(&context, "a");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), key_err);

        const sub_open_err = con.con_serialize_dict_open(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), sub_open_err);
        const sub_close_err = con.con_serialize_dict_close(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), sub_close_err);
    }

    const close_err = con.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

    try testing.expectEqualStrings("{\"a\":{}}", &buffer);
}
