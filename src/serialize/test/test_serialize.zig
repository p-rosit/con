const testing = @import("std").testing;
const lib = @import("../../internal.zig").lib;

test "context init" {
    var writer: lib.ConWriterString = undefined;
    var depth: [0]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        0,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
}

test "context init null" {
    var writer: lib.ConWriterString = undefined;
    var depth: [0]u8 = undefined;

    const init_err = lib.con_serialize_init(
        null,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_NULL), init_err);
}

test "context depth null, length positive" {
    var writer: lib.ConWriterString = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        null,
        1,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_NULL), init_err);
}

test "context depth null, length zero" {
    var writer: lib.ConWriterString = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        null,
        0,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
}

test "context depth negative" {
    var writer: lib.ConWriterString = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        @ptrFromInt(1),
        -1,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_BUFFER), init_err);
}

// Section: Values -------------------------------------------------------------

test "number int-like" {
    var buffer: [1]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const num_err = lib.con_serialize_number(&context, "2", 1);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), num_err);
}

test "number float-like" {
    var buffer: [2]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const num_err = lib.con_serialize_number(&context, ".3", 2);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), num_err);
}

test "number scientific-like" {
    var buffer: [3]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const num_err = lib.con_serialize_number(&context, "2e4", 3);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), num_err);
}

test "number null" {
    var buffer: [0]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const num_err = lib.con_serialize_number(&context, null, 0);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_NULL), num_err);
}

test "number writer fail" {
    var buffer: [0]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const num_err = lib.con_serialize_number(&context, "6", 1);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_WRITER), num_err);
}

test "number empty" {
    var buffer: [0]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const num_err = lib.con_serialize_number(&context, "", 0);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_NOT_NUMBER), num_err);
}

test "string" {
    var buffer: [3]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const str_err = lib.con_serialize_string(&context, "-", 1);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), str_err);
}

test "string null" {
    var buffer: [0]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const str_err = lib.con_serialize_string(&context, null, 0);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_NULL), str_err);
}

test "string first quote writer fail" {
    var buffer: [0]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const str_err = lib.con_serialize_string(&context, "-", 1);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_WRITER), str_err);
}

test "string body writer fail" {
    var buffer: [1]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const str_err = lib.con_serialize_string(&context, "-", 1);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_WRITER), str_err);
    try testing.expectEqualStrings("\"", &buffer);
}

test "string second quote writer fail" {
    var buffer: [2]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const str_err = lib.con_serialize_string(&context, "-", 1);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_WRITER), str_err);
    try testing.expectEqualStrings("\"-", &buffer);
}

test "bool true" {
    var buffer: [4]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const bool_err = lib.con_serialize_bool(&context, true);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), bool_err);

    try testing.expectEqualStrings("true", &buffer);
}

test "bool true writer fail" {
    var buffer: [0]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const bool_err = lib.con_serialize_bool(&context, true);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_WRITER), bool_err);
}

test "bool false" {
    var buffer: [5]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const bool_err = lib.con_serialize_bool(&context, false);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), bool_err);

    try testing.expectEqualStrings("false", &buffer);
}

test "bool false writer fail" {
    var buffer: [0]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const bool_err = lib.con_serialize_bool(&context, false);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_WRITER), bool_err);
}

test "null" {
    var buffer: [4]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var context: lib.ConSerialize = undefined;
    var depth: [0]u8 = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const null_err = lib.con_serialize_null(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), null_err);

    try testing.expectEqualStrings("null", &buffer);
}

test "null writer fail" {
    var buffer: [0]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const null_err = lib.con_serialize_null(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_WRITER), null_err);
}

// Section: Containers ---------------------------------------------------------

test "array open" {
    var buffer: [1]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    try testing.expectEqualStrings("[", &buffer);
}

test "array open too many" {
    var buffer: [1]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_TOO_DEEP), open_err);
}

test "array nested open too many" {
    var buffer: [2]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const num_err = lib.con_serialize_number(&context, "1", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), num_err);
        try testing.expectEqualStrings("[1", &buffer);

        const err = lib.con_serialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_TOO_DEEP), err);
    }
}

test "array open writer fail" {
    var buffer: [0]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_WRITER), open_err);
}

test "array close" {
    var buffer: [2]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    const close_err = lib.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);

    try testing.expectEqualStrings("[]", &buffer);
}

test "array close too many" {
    var buffer: [1]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const close_err = lib.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_CLOSED_TOO_MANY), close_err);
}

test "array close writer fail" {
    var buffer: [1]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);
    try testing.expectEqualStrings("[", &buffer);

    const close_err = lib.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_WRITER), close_err);
}

test "dict open" {
    var buffer: [1]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    try testing.expectEqualStrings("{", &buffer);
}

test "dict open too many" {
    var buffer: [1]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_TOO_DEEP), open_err);
}

test "dict nested open too many" {
    var buffer: [2]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const num_err = lib.con_serialize_number(&context, "1", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), num_err);
        try testing.expectEqualStrings("[1", &buffer);

        const err = lib.con_serialize_dict_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_TOO_DEEP), err);
    }
}

test "dict open writer fail" {
    var buffer: [0]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_WRITER), open_err);
}

test "dict close" {
    var buffer: [2]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    const close_err = lib.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);

    try testing.expectEqualStrings("{}", &buffer);
}

test "dict close too many" {
    var buffer: [1]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const close_err = lib.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_CLOSED_TOO_MANY), close_err);
}

test "dict close writer fail" {
    var buffer: [1]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);
    try testing.expectEqualStrings("{", &buffer);

    const close_err = lib.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_WRITER), close_err);
}

// Section: Dict key -----------------------------------------------------------

test "dict key" {
    var buffer: [7]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const key_err = lib.con_serialize_dict_key(&context, "key", 3);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key_err);

        try testing.expectEqualStrings("{\"key\":", &buffer);
    }
}

test "dict key multiple" {
    var buffer: [13]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const key_err = lib.con_serialize_dict_key(&context, "k1", 2);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key_err);

        const item_err = lib.con_serialize_number(&context, "1", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), item_err);

        const err = lib.con_serialize_dict_key(&context, "k2", 2);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err);

        try testing.expectEqualStrings("{\"k1\":1,\"k2\":", &buffer);
    }
}

test "dict key null" {
    var buffer: [1]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);
    try testing.expectEqualStrings("{", &buffer);

    {
        const key_err = lib.con_serialize_dict_key(&context, null, 0);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_NULL), key_err);
    }
}

test "dict key first quote writer fail" {
    var buffer: [1]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const key_err = lib.con_serialize_dict_key(&context, "k", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_WRITER), key_err);
        try testing.expectEqualStrings("{", &buffer);
    }
}

test "dict key body writer fail" {
    var buffer: [2]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const key_err = lib.con_serialize_dict_key(&context, "k", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_WRITER), key_err);
        try testing.expectEqualStrings("{\"", &buffer);
    }
}

test "dict key second quote writer fail" {
    var buffer: [3]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const key_err = lib.con_serialize_dict_key(&context, "k", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_WRITER), key_err);
        try testing.expectEqualStrings("{\"k", &buffer);
    }
}

test "dict key colon writer fail" {
    var buffer: [4]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const key_err = lib.con_serialize_dict_key(&context, "k", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_WRITER), key_err);
        try testing.expectEqualStrings("{\"k\"", &buffer);
    }
}

test "dict key comma writer fail" {
    var buffer: [6]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const key1_err = lib.con_serialize_dict_key(&context, "a", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key1_err);
        const item1_err = lib.con_serialize_number(&context, "1", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), item1_err);
        try testing.expectEqualStrings("{\"a\":1", &buffer);

        const key2_err = lib.con_serialize_dict_key(&context, "2", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_WRITER), key2_err);
    }
}

test "dict key outside dict" {
    var buffer: [0]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const key_err = lib.con_serialize_dict_key(&context, "key", 3);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_NOT_DICT), key_err);
}

test "dict key in array" {
    var buffer: [1]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const key_err = lib.con_serialize_dict_key(&context, "key", 3);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_NOT_DICT), key_err);
    }
}

test "dict key twice" {
    var buffer: [7]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const key1_err = lib.con_serialize_dict_key(&context, "key", 3);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key1_err);

        const key2_err = lib.con_serialize_dict_key(&context, "key", 3);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_VALUE), key2_err);
    }
}

test "dict number key missing" {
    var buffer: [1]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const num_err = lib.con_serialize_number(&context, "2", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_KEY), num_err);
    }
}

test "dict number second key missing" {
    var buffer: [6]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const key_err = lib.con_serialize_dict_key(&context, "k", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key_err);
        const item_err = lib.con_serialize_number(&context, "1", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), item_err);

        const num_err = lib.con_serialize_number(&context, "2", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_KEY), num_err);
    }
}

test "dict string key missing" {
    var buffer: [1]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const str_err = lib.con_serialize_string(&context, "2", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_KEY), str_err);
    }
}

test "dict string second key missing" {
    var buffer: [8]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const key_err = lib.con_serialize_dict_key(&context, "k", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key_err);
        const item_err = lib.con_serialize_string(&context, "a", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), item_err);

        const str_err = lib.con_serialize_string(&context, "b", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_KEY), str_err);
    }
}

test "dict array key missing" {
    var buffer: [1]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [2]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const array_err = lib.con_serialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_KEY), array_err);
    }
}

test "dict array second key missing" {
    var buffer: [6]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [2]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const key_err = lib.con_serialize_dict_key(&context, "k", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key_err);
        const item_err = lib.con_serialize_number(&context, "1", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), item_err);

        const str_err = lib.con_serialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_KEY), str_err);
    }
}

test "dict dict key missing" {
    var buffer: [1]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [2]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const dict_err = lib.con_serialize_dict_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_KEY), dict_err);
    }
}

test "dict dict second key missing" {
    var buffer: [6]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [2]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);

    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);
    {
        const key_err = lib.con_serialize_dict_key(&context, "k", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key_err);
        const item_err = lib.con_serialize_number(&context, "1", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), item_err);

        const str_err = lib.con_serialize_dict_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_KEY), str_err);
    }
}

// Section: Combinations of containers -----------------------------------------

test "array open -> dict close" {
    var buffer: [2]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    const close_err = lib.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_NOT_DICT), close_err);
}

test "dict open -> array close" {
    var buffer: [2]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    const close_err = lib.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_NOT_ARRAY), close_err);
}

test "array number single" {
    var buffer: [3]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const num_err = lib.con_serialize_number(&context, "2", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), num_err);
    }

    const close_err = lib.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);

    try testing.expectEqualStrings("[2]", &buffer);
}

test "array number multiple" {
    var buffer: [5]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const item1_err = lib.con_serialize_number(&context, "6", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), item1_err);

        const item2_err = lib.con_serialize_number(&context, "4", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), item2_err);
    }

    const close_err = lib.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);

    try testing.expectEqualStrings("[6,4]", &buffer);
}

test "array number comma writer fail" {
    var buffer: [2]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const item1_err = lib.con_serialize_number(&context, "2", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), item1_err);
        try testing.expectEqualStrings("[2", &buffer);

        const item2_err = lib.con_serialize_number(&context, "3", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_WRITER), item2_err);
    }
}

test "array string single" {
    var buffer: [5]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const str_err = lib.con_serialize_string(&context, "a", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), str_err);
    }

    const close_err = lib.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);

    try testing.expectEqualStrings("[\"a\"]", &buffer);
}

test "array string multiple" {
    var buffer: [9]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const item1_err = lib.con_serialize_string(&context, "a", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), item1_err);

        const item2_err = lib.con_serialize_string(&context, "b", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), item2_err);
    }

    const close_err = lib.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);

    try testing.expectEqualStrings("[\"a\",\"b\"]", &buffer);
}

test "array string comma writer fail" {
    var buffer: [4]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const item1_err = lib.con_serialize_string(&context, "a", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), item1_err);
        try testing.expectEqualStrings("[\"a\"", &buffer);

        const item2_err = lib.con_serialize_string(&context, "b", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_WRITER), item2_err);
    }
}

test "array bool single" {
    var buffer: [6]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const str_err = lib.con_serialize_bool(&context, true);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), str_err);
    }

    const close_err = lib.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);

    try testing.expectEqualStrings("[true]", &buffer);
}

test "array bool multiple" {
    var buffer: [12]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const item1_err = lib.con_serialize_bool(&context, false);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), item1_err);

        const item2_err = lib.con_serialize_bool(&context, true);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), item2_err);
    }

    const close_err = lib.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);

    try testing.expectEqualStrings("[false,true]", &buffer);
}

test "array bool comma writer fail" {
    var buffer: [5]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const item1_err = lib.con_serialize_bool(&context, true);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), item1_err);
        try testing.expectEqualStrings("[true", &buffer);

        const item2_err = lib.con_serialize_bool(&context, true);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_WRITER), item2_err);
    }
}

test "array null single" {
    var buffer: [6]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const str_err = lib.con_serialize_null(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), str_err);
    }

    const close_err = lib.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);

    try testing.expectEqualStrings("[null]", &buffer);
}

test "array null multiple" {
    var buffer: [11]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const item1_err = lib.con_serialize_null(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), item1_err);

        const item2_err = lib.con_serialize_null(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), item2_err);
    }

    const close_err = lib.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);

    try testing.expectEqualStrings("[null,null]", &buffer);
}

test "array null comma writer fail" {
    var buffer: [5]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const item1_err = lib.con_serialize_null(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), item1_err);
        try testing.expectEqualStrings("[null", &buffer);

        const item2_err = lib.con_serialize_null(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_WRITER), item2_err);
    }
}

test "array array single" {
    var buffer: [4]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [2]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const sub_open_err = lib.con_serialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), sub_open_err);
        const sub_close_err = lib.con_serialize_array_close(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), sub_close_err);
    }

    const close_err = lib.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);
    try testing.expectEqualStrings("[[]]", &buffer);
}

test "array array multiple" {
    var buffer: [7]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [2]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const sub_open_err1 = lib.con_serialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), sub_open_err1);
        const sub_close_err1 = lib.con_serialize_array_close(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), sub_close_err1);

        const sub_open_err2 = lib.con_serialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), sub_open_err2);
        const sub_close_err2 = lib.con_serialize_array_close(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), sub_close_err2);
    }

    const close_err = lib.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);
    try testing.expectEqualStrings("[[],[]]", &buffer);
}

test "array array comma writer fail" {
    var buffer: [3]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [2]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const sub_open_err1 = lib.con_serialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), sub_open_err1);
        const sub_close_err1 = lib.con_serialize_array_close(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), sub_close_err1);

        try testing.expectEqualStrings("[[]", &buffer);

        const sub_open_err2 = lib.con_serialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_WRITER), sub_open_err2);
    }
}

test "array dict single" {
    var buffer: [4]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [2]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const sub_open_err = lib.con_serialize_dict_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), sub_open_err);
        const sub_close_err = lib.con_serialize_dict_close(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), sub_close_err);
    }

    const close_err = lib.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);
    try testing.expectEqualStrings("[{}]", &buffer);
}

test "array dict multiple" {
    var buffer: [7]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [2]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const sub_open_err1 = lib.con_serialize_dict_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), sub_open_err1);
        const sub_close_err1 = lib.con_serialize_dict_close(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), sub_close_err1);

        const sub_open_err2 = lib.con_serialize_dict_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), sub_open_err2);
        const sub_close_err2 = lib.con_serialize_dict_close(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), sub_close_err2);
    }

    const close_err = lib.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);
    try testing.expectEqualStrings("[{},{}]", &buffer);
}

test "array dict comma writer fail" {
    var buffer: [3]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [2]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const sub_open_err1 = lib.con_serialize_dict_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), sub_open_err1);
        const sub_close_err1 = lib.con_serialize_dict_close(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), sub_close_err1);

        try testing.expectEqualStrings("[{}", &buffer);

        const sub_open_err2 = lib.con_serialize_dict_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_WRITER), sub_open_err2);
    }
}

test "dict number single" {
    var buffer: [7]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const key1_err = lib.con_serialize_dict_key(&context, "a", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key1_err);
        const item1_err = lib.con_serialize_number(&context, "1", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), item1_err);
    }

    const close_err = lib.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);

    try testing.expectEqualStrings("{\"a\":1}", &buffer);
}

test "dict string single" {
    var buffer: [9]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const key_err = lib.con_serialize_dict_key(&context, "a", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key_err);
        const item_err = lib.con_serialize_string(&context, "b", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), item_err);
    }

    const close_err = lib.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);

    try testing.expectEqualStrings("{\"a\":\"b\"}", &buffer);
}

test "dict bool true single" {
    var buffer: [10]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const key_err = lib.con_serialize_dict_key(&context, "a", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key_err);
        const item_err = lib.con_serialize_bool(&context, true);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), item_err);
    }

    const close_err = lib.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);

    try testing.expectEqualStrings("{\"a\":true}", &buffer);
}

test "dict bool false single" {
    var buffer: [11]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const key_err = lib.con_serialize_dict_key(&context, "a", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key_err);
        const item_err = lib.con_serialize_bool(&context, false);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), item_err);
    }

    const close_err = lib.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);

    try testing.expectEqualStrings("{\"a\":false}", &buffer);
}

test "dict null single" {
    var buffer: [10]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const key_err = lib.con_serialize_dict_key(&context, "a", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key_err);
        const item_err = lib.con_serialize_null(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), item_err);
    }

    const close_err = lib.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);

    try testing.expectEqualStrings("{\"a\":null}", &buffer);
}

test "dict array single" {
    var buffer: [8]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [2]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const key_err = lib.con_serialize_dict_key(&context, "a", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key_err);

        const sub_open_err = lib.con_serialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), sub_open_err);
        const sub_close_err = lib.con_serialize_array_close(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), sub_close_err);
    }

    const close_err = lib.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);

    try testing.expectEqualStrings("{\"a\":[]}", &buffer);
}

test "dict dict single" {
    var buffer: [8]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [2]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const key_err = lib.con_serialize_dict_key(&context, "a", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key_err);

        const sub_open_err = lib.con_serialize_dict_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), sub_open_err);
        const sub_close_err = lib.con_serialize_dict_close(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), sub_close_err);
    }

    const close_err = lib.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);

    try testing.expectEqualStrings("{\"a\":{}}", &buffer);
}

// Section: Completed ----------------------------------------------------------

test "number complete" {
    var buffer: [2]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);
    const close_err = lib.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);

    try testing.expectEqualStrings("[]", &buffer);

    const err = lib.con_serialize_number(&context, "1", 1);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_COMPLETE), err);
}

test "string complete" {
    var buffer: [2]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);
    const close_err = lib.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);

    try testing.expectEqualStrings("{}", &buffer);

    const err = lib.con_serialize_string(&context, "1", 1);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_COMPLETE), err);
}

test "bool complete" {
    var buffer: [1]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const complete_err = lib.con_serialize_number(&context, "1", 1);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), complete_err);

    try testing.expectEqualStrings("1", &buffer);

    const err = lib.con_serialize_bool(&context, true);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_COMPLETE), err);
}

test "null complete" {
    var buffer: [3]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const str_err = lib.con_serialize_string(&context, "1", 1);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), str_err);

    try testing.expectEqualStrings("\"1\"", &buffer);

    const err = lib.con_serialize_null(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_COMPLETE), err);
}

test "array complete" {
    var buffer: [4]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const bool_err = lib.con_serialize_bool(&context, true);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), bool_err);

    try testing.expectEqualStrings("true", &buffer);

    const err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_COMPLETE), err);
}

test "dict complete" {
    var buffer: [4]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const null_err = lib.con_serialize_null(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), null_err);

    try testing.expectEqualStrings("null", &buffer);

    const err = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_COMPLETE), err);
}

// Section: Integration test ---------------------------------------------------

test "nested structures" {
    var buffer: [55]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var depth: [3]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_string_interface(&writer),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err1 = lib.con_serialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err1);

    {
        const key_err2 = lib.con_serialize_dict_key(&context, "a", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key_err2);
        const open_err2 = lib.con_serialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err2);
        {
            const str_err4 = lib.con_serialize_string(&context, "hello", 5);
            try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), str_err4);

            const open_err5 = lib.con_serialize_dict_open(&context);
            try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err5);
            {
                const key_err6 = lib.con_serialize_dict_key(&context, "a.a", 3);
                try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key_err6);
                const null_err6 = lib.con_serialize_null(&context);
                try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), null_err6);

                const key_err7 = lib.con_serialize_dict_key(&context, "a.b", 3);
                try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key_err7);
                const bool_err7 = lib.con_serialize_bool(&context, true);
                try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), bool_err7);
            }
            const close_err5 = lib.con_serialize_dict_close(&context);
            try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err5);
        }
        const close_err2 = lib.con_serialize_array_close(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err2);

        const key_err3 = lib.con_serialize_dict_key(&context, "b", 1);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key_err3);
        const open_err3 = lib.con_serialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err3);
        {
            const num_err8 = lib.con_serialize_number(&context, "234", 3);
            try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), num_err8);

            const bool_err9 = lib.con_serialize_bool(&context, false);
            try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), bool_err9);
        }
        const close_err3 = lib.con_serialize_array_close(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err3);
    }

    const close_err1 = lib.con_serialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err1);

    try testing.expectEqualStrings("{\"a\":[\"hello\",{\"a.a\":null,\"a.b\":true}],\"b\":[234,false]}", &buffer);
}

test "indent writer" {
    var buffer: [119]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const writer_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), writer_err);

    var indent: lib.ConWriterIndent = undefined;
    const indent_err = lib.con_writer_indent_init(
        &indent,
        lib.con_writer_string_interface(&writer),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), indent_err);

    var depth: [3]u8 = undefined;
    var context: lib.ConSerialize = undefined;
    const init_err = lib.con_serialize_init(
        &context,
        lib.con_writer_indent_interface(&indent),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_serialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const open_dict_err = lib.con_serialize_dict_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_dict_err);

        {
            const key1_err = lib.con_serialize_dict_key(&context, "key1", 4);
            try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key1_err);
            const empty_open_array_err = lib.con_serialize_array_open(&context);
            try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), empty_open_array_err);
            const empty_close_array_err = lib.con_serialize_array_close(&context);
            try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), empty_close_array_err);

            const key2_err = lib.con_serialize_dict_key(&context, "key2", 4);
            try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key2_err);
            const empty_open_dict_err = lib.con_serialize_dict_open(&context);
            try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), empty_open_dict_err);
            const empty_close_dict_err = lib.con_serialize_dict_close(&context);
            try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), empty_close_dict_err);

            const key3_err = lib.con_serialize_dict_key(&context, "key3", 4);
            try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key3_err);
            const bool_err = lib.con_serialize_bool(&context, true);
            try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), bool_err);
        }

        const close_dict_err = lib.con_serialize_dict_close(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_dict_err);

        const num_err = lib.con_serialize_number(&context, "123", 3);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), num_err);

        const str_err = lib.con_serialize_string(&context, "string", 6);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), str_err);

        const no_indent_err = lib.con_serialize_string(&context, "\\\"[2, 3] {\\\"m\\\":1,\\\"n\\\":2}", 26);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), no_indent_err);

        const null_err = lib.con_serialize_null(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), null_err);
    }

    const close_err = lib.con_serialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);

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
