const testing = @import("std").testing;
const con = @cImport({
    @cInclude("serialize.h");
    @cInclude("serialize_writer.h");
});

test "context init" {
    var depth: [0]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(null, con.con_serialize_writer_string_write),
        &depth,
        0,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);
}

test "context depth null, length positive" {
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(null, con.con_serialize_writer_string_write),
        null,
        1,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

test "context depth null, length zero" {
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(null, con.con_serialize_writer_string_write),
        null,
        0,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);
}

test "context depth negative" {
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(null, con.con_serialize_writer_string_write),
        @ptrFromInt(1),
        -1,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_BUFFER), init_err);
}

test "context init null" {
    var depth: [0]u8 = undefined;

    const init_err = con.con_serialize_init(
        null,
        con.con_writer(null, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

// Section: Values -------------------------------------------------------------

test "number int-like" {
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const num_err = con.con_serialize_number(&context, "2");
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), num_err);
}

test "number float-like" {
    var buffer: [2:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const num_err = con.con_serialize_number(&context, ".3");
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), num_err);
}

test "number scientific-like" {
    var buffer: [3:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const num_err = con.con_serialize_number(&context, "2e4");
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), num_err);
}

test "number null" {
    var buffer: [0:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const num_err = con.con_serialize_number(&context, null);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), num_err);
}

test "number writer fail" {
    var buffer: [0:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const num_err = con.con_serialize_number(&context, "6");
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), num_err);
}

test "number empty" {
    var buffer: [0:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const num_err = con.con_serialize_number(&context, "");
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NOT_NUMBER), num_err);
}

test "string" {
    var buffer: [3:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const str_err = con.con_serialize_string(&context, "-");
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), str_err);
}

test "string null" {
    var buffer: [0:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const str_err = con.con_serialize_string(&context, null);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), str_err);
}

test "string first quote writer fail" {
    var buffer: [0:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const str_err = con.con_serialize_string(&context, "-");
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), str_err);
}

test "string body writer fail" {
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const str_err = con.con_serialize_string(&context, "-");
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), str_err);
    try testing.expectEqualStrings("\"", &buffer);
}

test "string second quote writer fail" {
    var buffer: [2:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const str_err = con.con_serialize_string(&context, "-");
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), str_err);
    try testing.expectEqualStrings("\"-", &buffer);
}

test "bool true" {
    var buffer: [4:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const bool_err = con.con_serialize_bool(&context, true);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), bool_err);

    try testing.expectEqualStrings("true", &buffer);
}

test "bool true writer fail" {
    var buffer: [0:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const bool_err = con.con_serialize_bool(&context, true);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), bool_err);
}

test "bool false" {
    var buffer: [5:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const bool_err = con.con_serialize_bool(&context, false);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), bool_err);

    try testing.expectEqualStrings("false", &buffer);
}

test "bool false writer fail" {
    var buffer: [0:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const bool_err = con.con_serialize_bool(&context, false);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), bool_err);
}

test "null" {
    var buffer: [4:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var context: con.ConSerialize = undefined;
    var depth: [0]u8 = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const null_err = con.con_serialize_null(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), null_err);

    try testing.expectEqualStrings("null", &buffer);
}

test "null writer fail" {
    var buffer: [0:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const null_err = con.con_serialize_null(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), null_err);
}

// Section: Containers ---------------------------------------------------------

test "array open" {
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    try testing.expectEqualStrings("[", &buffer);
}

test "array open too many" {
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_TOO_DEEP), open_err);
}

test "array nested open too many" {
    var buffer: [2:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    {
        const num_err = con.con_serialize_number(&context, "1");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), num_err);
        try testing.expectEqualStrings("[1", &buffer);

        const err = con.con_serialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_TOO_DEEP), err);
    }
}

test "array open writer fail" {
    var buffer: [0:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), open_err);
}

test "array close" {
    var buffer: [2:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const close_err = con.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_CLOSED_TOO_MANY), close_err);
}

test "array close writer fail" {
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    try testing.expectEqualStrings("{", &buffer);
}

test "dict open too many" {
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_TOO_DEEP), open_err);
}

test "dict nested open too many" {
    var buffer: [2:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    {
        const num_err = con.con_serialize_number(&context, "1");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), num_err);
        try testing.expectEqualStrings("[1", &buffer);

        const err = con.con_serialize_dict_open(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_TOO_DEEP), err);
    }
}

test "dict open writer fail" {
    var buffer: [0:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), open_err);
}

test "dict close" {
    var buffer: [2:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const close_err = con.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_CLOSED_TOO_MANY), close_err);
}

test "dict close writer fail" {
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [7:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [13:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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

test "dict key first quote writer fail" {
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    {
        const key_err = con.con_serialize_dict_key(&context, "k");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), key_err);
        try testing.expectEqualStrings("{", &buffer);
    }
}

test "dict key body writer fail" {
    var buffer: [2:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    {
        const key_err = con.con_serialize_dict_key(&context, "k");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), key_err);
        try testing.expectEqualStrings("{\"", &buffer);
    }
}

test "dict key second quote writer fail" {
    var buffer: [3:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    {
        const key_err = con.con_serialize_dict_key(&context, "k");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), key_err);
        try testing.expectEqualStrings("{\"k", &buffer);
    }
}

test "dict key colon writer fail" {
    var buffer: [4:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    {
        const key_err = con.con_serialize_dict_key(&context, "k");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), key_err);
        try testing.expectEqualStrings("{\"k\"", &buffer);
    }
}

test "dict key comma writer fail" {
    var buffer: [6:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [0:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const key_err = con.con_serialize_dict_key(&context, "key");
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NOT_DICT), key_err);
}

test "dict key in array" {
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [7:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [6:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [8:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [2]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [6:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [2]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [2]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [6:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [2]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [2:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [2:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [3:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [5:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [2:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [5:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [9:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [4:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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

test "array bool single" {
    var buffer: [6:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    {
        const str_err = con.con_serialize_bool(&context, true);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), str_err);
    }

    const close_err = con.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

    try testing.expectEqualStrings("[true]", &buffer);
}

test "array bool multiple" {
    var buffer: [12:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    {
        const item1_err = con.con_serialize_bool(&context, false);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item1_err);

        const item2_err = con.con_serialize_bool(&context, true);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item2_err);
    }

    const close_err = con.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

    try testing.expectEqualStrings("[false,true]", &buffer);
}

test "array bool comma writer fail" {
    var buffer: [5:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    {
        const item1_err = con.con_serialize_bool(&context, true);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item1_err);
        try testing.expectEqualStrings("[true", &buffer);

        const item2_err = con.con_serialize_bool(&context, true);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), item2_err);
    }
}

test "array null single" {
    var buffer: [6:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    {
        const str_err = con.con_serialize_null(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), str_err);
    }

    const close_err = con.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

    try testing.expectEqualStrings("[null]", &buffer);
}

test "array null multiple" {
    var buffer: [11:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    {
        const item1_err = con.con_serialize_null(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item1_err);

        const item2_err = con.con_serialize_null(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item2_err);
    }

    const close_err = con.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

    try testing.expectEqualStrings("[null,null]", &buffer);
}

test "array null comma writer fail" {
    var buffer: [5:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    {
        const item1_err = con.con_serialize_null(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item1_err);
        try testing.expectEqualStrings("[null", &buffer);

        const item2_err = con.con_serialize_null(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_WRITER), item2_err);
    }
}

test "array array single" {
    var buffer: [4:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [2]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [7:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [2]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [3:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [2]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [4:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [2]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [7:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [2]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [3:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [2]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [7:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [9:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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

test "dict bool true single" {
    var buffer: [10:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    {
        const key_err = con.con_serialize_dict_key(&context, "a");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), key_err);
        const item_err = con.con_serialize_bool(&context, true);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item_err);
    }

    const close_err = con.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

    try testing.expectEqualStrings("{\"a\":true}", &buffer);
}

test "dict bool false single" {
    var buffer: [11:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    {
        const key_err = con.con_serialize_dict_key(&context, "a");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), key_err);
        const item_err = con.con_serialize_bool(&context, false);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item_err);
    }

    const close_err = con.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

    try testing.expectEqualStrings("{\"a\":false}", &buffer);
}

test "dict null single" {
    var buffer: [10:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    {
        const key_err = con.con_serialize_dict_key(&context, "a");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), key_err);
        const item_err = con.con_serialize_null(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), item_err);
    }

    const close_err = con.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

    try testing.expectEqualStrings("{\"a\":null}", &buffer);
}

test "dict array single" {
    var buffer: [8:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [2]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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
    var buffer: [8:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [2]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
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

// Section: Completed ----------------------------------------------------------

test "number complete" {
    var buffer: [2:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);
    const close_err = con.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

    try testing.expectEqualStrings("[]", &buffer);

    const err = con.con_serialize_number(&context, "1");
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_COMPLETE), err);
}

test "string complete" {
    var buffer: [2:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);
    const close_err = con.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

    try testing.expectEqualStrings("{}", &buffer);

    const err = con.con_serialize_string(&context, "1");
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_COMPLETE), err);
}

test "bool complete" {
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const complete_err = con.con_serialize_number(&context, "1");
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), complete_err);

    try testing.expectEqualStrings("1", &buffer);

    const err = con.con_serialize_bool(&context, true);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_COMPLETE), err);
}

test "null complete" {
    var buffer: [3:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const str_err = con.con_serialize_string(&context, "1");
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), str_err);

    try testing.expectEqualStrings("\"1\"", &buffer);

    const err = con.con_serialize_null(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_COMPLETE), err);
}

test "array complete" {
    var buffer: [4:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const bool_err = con.con_serialize_bool(&context, true);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), bool_err);

    try testing.expectEqualStrings("true", &buffer);

    const err = con.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_COMPLETE), err);
}

test "dict complete" {
    var buffer: [4:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const null_err = con.con_serialize_null(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), null_err);

    try testing.expectEqualStrings("null", &buffer);

    const err = con.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_COMPLETE), err);
}

// Section: Integration test ---------------------------------------------------

test "nested structures" {
    var buffer: [55:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var depth: [3]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&writer, con.con_serialize_writer_string_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err1 = con.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err1);

    {
        const key_err2 = con.con_serialize_dict_key(&context, "a");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), key_err2);
        const open_err2 = con.con_serialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err2);
        {
            const str_err4 = con.con_serialize_string(&context, "hello");
            try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), str_err4);

            const open_err5 = con.con_serialize_dict_open(&context);
            try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err5);
            {
                const key_err6 = con.con_serialize_dict_key(&context, "a.a");
                try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), key_err6);
                const null_err6 = con.con_serialize_null(&context);
                try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), null_err6);

                const key_err7 = con.con_serialize_dict_key(&context, "a.b");
                try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), key_err7);
                const bool_err7 = con.con_serialize_bool(&context, true);
                try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), bool_err7);
            }
            const close_err5 = con.con_serialize_dict_close(&context);
            try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err5);
        }
        const close_err2 = con.con_serialize_array_close(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err2);

        const key_err3 = con.con_serialize_dict_key(&context, "b");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), key_err3);
        const open_err3 = con.con_serialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err3);
        {
            const num_err8 = con.con_serialize_number(&context, "234");
            try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), num_err8);

            const bool_err9 = con.con_serialize_bool(&context, false);
            try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), bool_err9);
        }
        const close_err3 = con.con_serialize_array_close(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err3);
    }

    const close_err1 = con.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err1);

    try testing.expectEqualStrings("{\"a\":[\"hello\",{\"a.a\":null,\"a.b\":true}],\"b\":[234,false]}", &buffer);
}

test "indent writer" {
    var buffer: [119:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const writer_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), writer_err);

    var indent: con.ConWriterIndent = undefined;
    const indent_err = con.con_serialize_writer_indent(&indent, con.con_writer(&writer, con.con_serialize_writer_string_write));
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), indent_err);

    var depth: [3]u8 = undefined;
    var context: con.ConSerialize = undefined;
    const init_err = con.con_serialize_init(
        &context,
        con.con_writer(&indent, con.con_serialize_writer_indent_write),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const open_err = con.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_err);

    {
        const open_dict_err = con.con_serialize_dict_open(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), open_dict_err);

        {
            const key1_err = con.con_serialize_dict_key(&context, "key1");
            try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), key1_err);
            const empty_open_array_err = con.con_serialize_array_open(&context);
            try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), empty_open_array_err);
            const empty_close_array_err = con.con_serialize_array_close(&context);
            try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), empty_close_array_err);

            const key2_err = con.con_serialize_dict_key(&context, "key2");
            try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), key2_err);
            const empty_open_dict_err = con.con_serialize_dict_open(&context);
            try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), empty_open_dict_err);
            const empty_close_dict_err = con.con_serialize_dict_close(&context);
            try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), empty_close_dict_err);

            const key3_err = con.con_serialize_dict_key(&context, "key3");
            try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), key3_err);
            const bool_err = con.con_serialize_bool(&context, true);
            try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), bool_err);
        }

        const close_dict_err = con.con_serialize_dict_close(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_dict_err);

        const num_err = con.con_serialize_number(&context, "123");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), num_err);

        const str_err = con.con_serialize_string(&context, "string");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), str_err);

        const no_indent_err = con.con_serialize_string(&context, "\\\"[2, 3] {\\\"m\\\":1,\\\"n\\\":2}");
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), no_indent_err);

        const null_err = con.con_serialize_null(&context);
        try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), null_err);
    }

    const close_err = con.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), close_err);

    try testing.expectEqualStrings(
        \\[
        \\  {
        \\    "key1": [],
        \\    "key2": {},
        \\    "key3": true
        \\  },
        \\  123,
        \\  "string",
        \\  "\"[2, 3] {\"m\":1,\"n\":2}",
        \\  null
        \\]
    ,
        &buffer,
    );
}
