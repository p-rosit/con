const testing = @import("std").testing;
const lib = @import("../../internal.zig").lib;

test "context init" {
    var reader: lib.ConReaderString = undefined;
    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        0,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
}

test "context init null" {
    var reader: lib.ConReaderString = undefined;
    var depth: [0]u8 = undefined;
    const init_err = lib.con_deserialize_init(
        null,
        lib.con_reader_string_interface(&reader),
        &depth,
        0,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_NULL), init_err);
}

test "context depth null, length positive" {
    var reader: lib.ConReaderString = undefined;
    const init_err = lib.con_deserialize_init(
        null,
        lib.con_reader_string_interface(&reader),
        null,
        1,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_NULL), init_err);
}

test "context depth null, length zero" {
    var reader: lib.ConReaderString = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        null,
        0,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
}

test "context depth negative" {
    var reader: lib.ConReaderString = undefined;
    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        -1,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_BUFFER), init_err);
}

// Section: Next ---------------------------------------------------------------

test "next empty" {
    const data = "  \n\t ";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        0,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    var etype: lib.ConDeserializeType = undefined;
    const err1 = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_READER), err1);

    const err2 = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_READER), err2);
}

test "next error" {
    const data = "";
    var r: lib.ConReaderString = undefined;
    const i1_err = lib.con_reader_string_init(&r, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i1_err);

    var reader: lib.ConReaderFail = undefined;
    const i2_err = lib.con_reader_fail_init(
        &reader,
        lib.con_reader_string_interface(&r),
        0,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i2_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_fail_interface(&reader),
        &depth,
        0,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    var etype: lib.ConDeserializeType = undefined;
    const err1 = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_READER), err1);

    const err2 = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_READER), err2);
}

test "next number" {
    const data = " 1";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        0,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    var etype: lib.ConDeserializeType = undefined;
    const err1 = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err1);
    try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_NUMBER), etype);

    const err2 = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err2);
    try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_NUMBER), etype);
}

test "next string" {
    const data = " \"abc\"";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        0,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    var etype: lib.ConDeserializeType = undefined;
    const err1 = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err1);
    try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_STRING), etype);

    const err2 = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err2);
    try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_STRING), etype);
}

test "next bool true" {
    const data = "  true";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        0,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    var etype: lib.ConDeserializeType = undefined;
    const err1 = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err1);
    try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_BOOL), etype);

    const err2 = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err2);
    try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_BOOL), etype);
}

test "next bool false" {
    const data = "\tfalse";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        0,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    var etype: lib.ConDeserializeType = undefined;
    const err1 = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err1);
    try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_BOOL), etype);

    const err2 = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err2);
    try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_BOOL), etype);
}

test "next null" {
    const data = "null";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        0,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    var etype: lib.ConDeserializeType = undefined;
    const err1 = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err1);
    try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_NULL), etype);

    const err2 = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err2);
    try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_NULL), etype);
}

test "next array open" {
    const data = "[";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        0,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    var etype: lib.ConDeserializeType = undefined;
    const err1 = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err1);
    try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_ARRAY_OPEN), etype);

    const err2 = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err2);
    try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_ARRAY_OPEN), etype);
}

test "next array close" {
    const data = "[]";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    var etype: lib.ConDeserializeType = undefined;
    const err1 = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err1);
    try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_ARRAY_CLOSE), etype);

    const err2 = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err2);
    try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_ARRAY_CLOSE), etype);
}

test "next array first" {
    const data = "[true]";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        var etype: lib.ConDeserializeType = undefined;
        const err1 = lib.con_deserialize_next(&context, &etype);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err1);
        try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_BOOL), etype);

        const err2 = lib.con_deserialize_next(&context, &etype);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err2);
        try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_BOOL), etype);
    }
}

test "next array second" {
    const data = "[null, 0.0]";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        const null_err = lib.con_deserialize_null(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), null_err);

        var etype: lib.ConDeserializeType = undefined;
        const err1 = lib.con_deserialize_next(&context, &etype);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err1);
        try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_NUMBER), etype);

        const err2 = lib.con_deserialize_next(&context, &etype);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err2);
        try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_NUMBER), etype);
    }
}

test "next dict open" {
    const data = "{";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        0,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    var etype: lib.ConDeserializeType = undefined;
    const err1 = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err1);
    try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_DICT_OPEN), etype);

    const err2 = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err2);
    try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_DICT_OPEN), etype);
}

test "next dict close" {
    const data = "{}";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    var etype: lib.ConDeserializeType = undefined;
    const err1 = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err1);
    try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_DICT_CLOSE), etype);

    const err2 = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err2);
    try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_DICT_CLOSE), etype);
}

test "next dict key" {
    const data = "{\"k\":";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    var etype: lib.ConDeserializeType = undefined;
    const err1 = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err1);
    try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_DICT_KEY), etype);

    const err2 = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err2);
    try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_DICT_KEY), etype);
}

test "next dict first" {
    const data = "{\"k\":\"a\"";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        var buffer: [1]u8 = undefined;
        var writer: lib.ConWriterString = undefined;
        const iw_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw_err);

        const key_err = lib.con_deserialize_dict_key(&context, lib.con_writer_string_interface(&writer));
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key_err);
        try testing.expectEqualStrings("k", &buffer);

        var etype: lib.ConDeserializeType = undefined;
        const err1 = lib.con_deserialize_next(&context, &etype);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err1);
        try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_STRING), etype);

        const err2 = lib.con_deserialize_next(&context, &etype);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err2);
        try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_STRING), etype);
    }
}

test "next dict second" {
    const data = "{\"k\":\"a\",\"m\":\"b\"";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        var buffer: [3]u8 = undefined;
        var writer: lib.ConWriterString = undefined;
        const iw_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw_err);

        const key1_err = lib.con_deserialize_dict_key(&context, lib.con_writer_string_interface(&writer));
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key1_err);
        try testing.expectEqualStrings("k", buffer[0..1]);

        const str_err = lib.con_deserialize_string(&context, lib.con_writer_string_interface(&writer));
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), str_err);
        try testing.expectEqualStrings("a", buffer[1..2]);

        const key2_err = lib.con_deserialize_dict_key(&context, lib.con_writer_string_interface(&writer));
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key2_err);
        try testing.expectEqualStrings("m", buffer[2..3]);

        var etype: lib.ConDeserializeType = undefined;
        const err1 = lib.con_deserialize_next(&context, &etype);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err1);
        try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_STRING), etype);

        const err2 = lib.con_deserialize_next(&context, &etype);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err2);
        try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_STRING), etype);
    }
}

// Section: Values -------------------------------------------------------------

test "number int-like" {
    const data = "-6 ";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    var buffer: [5]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const iw_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw_err);

    const err = lib.con_deserialize_number(&context, lib.con_writer_string_interface(&writer));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err);
    try testing.expectEqual(2, writer.current);
    try testing.expectEqualStrings("-6", buffer[0..2]);
}

test "number float-like" {
    const data = "0.3";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    var buffer: [5]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const iw_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw_err);

    const err = lib.con_deserialize_number(&context, lib.con_writer_string_interface(&writer));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err);
    try testing.expectEqual(3, writer.current);
    try testing.expectEqualStrings("0.3", buffer[0..3]);
}

test "number scientific-like" {
    const data = "2e+4";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    var buffer: [5]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const iw_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw_err);

    const err = lib.con_deserialize_number(&context, lib.con_writer_string_interface(&writer));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err);
    try testing.expectEqual(4, writer.current);
    try testing.expectEqualStrings("2e+4", buffer[0..4]);
}

test "number small" {
    const data = "";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    var buffer: [5]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const iw_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw_err);

    const err1 = lib.con_deserialize_number(&context, lib.con_writer_string_interface(&writer));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_READER), err1);
}

test "number reader fail" {
    var reader: lib.ConReaderString = undefined;
    var buffer: [6]u8 = undefined;
    var writer: lib.ConWriterString = undefined;

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;

    const data1 = "2.";
    const ir1_err = lib.con_reader_string_init(&reader, data1, data1.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir1_err);
    const iw1_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw1_err);
    const init1_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init1_err);
    const err1 = lib.con_deserialize_number(&context, lib.con_writer_string_interface(&writer));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_READER), err1);
    try testing.expectEqual(2, writer.current);
    try testing.expectEqualStrings("2.", buffer[0..2]);

    const data2 = "2.5E";
    const ir2_err = lib.con_reader_string_init(&reader, data2, data2.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir2_err);
    const iw2_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw2_err);
    const init2_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init2_err);
    const err2 = lib.con_deserialize_number(&context, lib.con_writer_string_interface(&writer));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_READER), err2);
    try testing.expectEqual(4, writer.current);
    try testing.expectEqualStrings("2.5E", buffer[0..4]);

    const data3 = "-";
    const ir3_err = lib.con_reader_string_init(&reader, data3, data3.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir3_err);
    const iw3_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw3_err);
    const init3_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init3_err);
    const err3 = lib.con_deserialize_number(&context, lib.con_writer_string_interface(&writer));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_READER), err3);
    try testing.expectEqual(1, writer.current);
    try testing.expectEqualStrings("-", buffer[0..1]);

    const data4 = "3.4e-";
    const ir4_err = lib.con_reader_string_init(&reader, data4, data4.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir4_err);
    const iw4_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw4_err);
    const init4_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init4_err);
    const err4 = lib.con_deserialize_number(&context, lib.con_writer_string_interface(&writer));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_READER), err4);
    try testing.expectEqual(5, writer.current);
    try testing.expectEqualStrings("3.4e-", buffer[0..5]);
}

test "number invalid" {
    var reader: lib.ConReaderString = undefined;
    var buffer: [6]u8 = undefined;
    var writer: lib.ConWriterString = undefined;

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;

    const data1 = "+";
    const ir1_err = lib.con_reader_string_init(&reader, data1, data1.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir1_err);
    const iw1_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw1_err);
    const init1_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init1_err);
    const err1 = lib.con_deserialize_number(&context, lib.con_writer_string_interface(&writer));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_INVALID_JSON), err1);
    try testing.expectEqual(0, writer.current);

    const data2 = "0f";
    const ir2_err = lib.con_reader_string_init(&reader, data2, data2.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir2_err);
    const iw2_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw2_err);
    const init2_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init2_err);
    const err2 = lib.con_deserialize_number(&context, lib.con_writer_string_interface(&writer));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_INVALID_JSON), err2);
    try testing.expectEqual(1, writer.current);
    try testing.expectEqualStrings("0", buffer[0..1]);
}

test "string" {
    const data = "\"a b\"";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    var buffer: [5]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const iw_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw_err);

    const err = lib.con_deserialize_string(&context, lib.con_writer_string_interface(&writer));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err);
    try testing.expectEqual(3, writer.current);
    try testing.expectEqualStrings("a b", buffer[0..3]);
}

test "string escaped" {
    const data = "\"\\\"\\\\\\/\\b\\f\\n\\r\\t\\u12f4\"";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    var buffer: [16]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const iw_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw_err);

    const err = lib.con_deserialize_string(&context, lib.con_writer_string_interface(&writer));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err);
    try testing.expectEqual(10, writer.current);
    try testing.expectEqualStrings("\"\\/\x08\x0c\n\r\t\x12\xf4", buffer[0..10]);
}

test "string invalid" {
    var reader: lib.ConReaderString = undefined;
    var buffer: [6]u8 = undefined;
    var writer: lib.ConWriterString = undefined;

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;

    const data1 = "ab\"";
    const ir1_err = lib.con_reader_string_init(&reader, data1, data1.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir1_err);
    const iw1_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw1_err);
    const init1_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init1_err);
    const err1 = lib.con_deserialize_string(&context, lib.con_writer_string_interface(&writer));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_INVALID_JSON), err1);
    try testing.expectEqual(0, writer.current);

    const data2 = "\"ab";
    const ir2_err = lib.con_reader_string_init(&reader, data2, data2.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir2_err);
    const iw2_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw2_err);
    const init2_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init2_err);
    const err2 = lib.con_deserialize_string(&context, lib.con_writer_string_interface(&writer));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_READER), err2);
    try testing.expectEqual(2, writer.current);
    try testing.expectEqualStrings("ab", buffer[0..2]);

    const data3 = "\"1\\h";
    const ir3_err = lib.con_reader_string_init(&reader, data3, data3.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir3_err);
    const iw3_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw3_err);
    const init3_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init3_err);
    const err3 = lib.con_deserialize_string(&context, lib.con_writer_string_interface(&writer));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_INVALID_JSON), err3);
    try testing.expectEqual(1, writer.current);
    try testing.expectEqualStrings("1", buffer[0..1]);

    const data4 = "\"2\\u123";
    const ir4_err = lib.con_reader_string_init(&reader, data4, data4.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir4_err);
    const iw4_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw4_err);
    const init4_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init4_err);
    const err4 = lib.con_deserialize_string(&context, lib.con_writer_string_interface(&writer));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_READER), err4);
    try testing.expectEqual(1, writer.current);
    try testing.expectEqualStrings("2", buffer[0..1]);

    const data5 = "\"3\\u123G";
    const ir5_err = lib.con_reader_string_init(&reader, data5, data5.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir5_err);
    const iw5_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw5_err);
    const init5_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init5_err);
    const err5 = lib.con_deserialize_string(&context, lib.con_writer_string_interface(&writer));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_INVALID_JSON), err5);
    try testing.expectEqual(1, writer.current);
    try testing.expectEqualStrings("3", buffer[0..1]);
}

test "bool true" {
    const data = "true";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    var value: bool = undefined;
    const err = lib.con_deserialize_bool(&context, &value);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err);
    try testing.expectEqual(true, value);
}

test "bool false" {
    const data = "false";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    var value: bool = undefined;
    const err = lib.con_deserialize_bool(&context, &value);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err);
    try testing.expectEqual(false, value);
}

test "bool invalid" {
    var depth: [0]u8 = undefined;
    var reader: lib.ConReaderString = undefined;
    var context: lib.ConDeserialize = undefined;
    var value: bool = undefined;

    const data1 = "t";
    const i1_err = lib.con_reader_string_init(&reader, data1, data1.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i1_err);
    const init1_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init1_err);
    const err1 = lib.con_deserialize_bool(&context, &value);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_READER), err1);

    const data2 = "f a l s e";
    const i2_err = lib.con_reader_string_init(&reader, data2, data2.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i2_err);
    const init2_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init2_err);
    const err2 = lib.con_deserialize_bool(&context, &value);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_INVALID_JSON), err2);

    const data3 = "talse";
    const i3_err = lib.con_reader_string_init(&reader, data3, data3.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i3_err);
    const init3_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init3_err);
    const err3 = lib.con_deserialize_bool(&context, &value);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_INVALID_JSON), err3);

    const data4 = "frue";
    const i4_err = lib.con_reader_string_init(&reader, data4, data4.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i4_err);
    const init4_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init4_err);
    const err4 = lib.con_deserialize_bool(&context, &value);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_INVALID_JSON), err4);

    const data5 = "f,";
    const i5_err = lib.con_reader_string_init(&reader, data5, data5.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i5_err);
    const init5_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init5_err);
    const err5 = lib.con_deserialize_bool(&context, &value);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_INVALID_JSON), err5);

    const data6 = "truet";
    const i6_err = lib.con_reader_string_init(&reader, data6, data6.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i6_err);
    const init6_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init6_err);
    const err6 = lib.con_deserialize_bool(&context, &value);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_INVALID_JSON), err6);
}

test "null" {
    const data = "null";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const err = lib.con_deserialize_null(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err);
}

test "null invalid" {
    var depth: [0]u8 = undefined;
    var reader: lib.ConReaderString = undefined;
    var context: lib.ConDeserialize = undefined;

    const data1 = "n";
    const i1_err = lib.con_reader_string_init(&reader, data1, data1.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i1_err);
    const init1_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init1_err);
    const err1 = lib.con_deserialize_null(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_READER), err1);

    const data2 = "nulll";
    const i2_err = lib.con_reader_string_init(&reader, data2, data2.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i2_err);
    const init2_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init2_err);
    const err2 = lib.con_deserialize_null(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_INVALID_JSON), err2);

    const data3 = "nu ll";
    const i3_err = lib.con_reader_string_init(&reader, data3, data3.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i3_err);
    const init3_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init3_err);
    const err3 = lib.con_deserialize_null(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_INVALID_JSON), err3);
}

// Section: Containers ---------------------------------------------------------

test "array open" {
    const data = "[";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const err = lib.con_deserialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err);
}

test "array open too many" {
    const data = "[";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const err = lib.con_deserialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_TOO_DEEP), err);
}

test "array nested open too many" {
    const data = "[1,[";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        var buffer: [1]u8 = undefined;
        var writer: lib.ConWriterString = undefined;
        const iw_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw_err);

        const num_err = lib.con_deserialize_number(&context, lib.con_writer_string_interface(&writer));
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), num_err);

        const err = lib.con_deserialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_TOO_DEEP), err);
    }
}

test "array open reader fail" {
    const data = "";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const err = lib.con_deserialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_READER), err);
}

test "array close" {
    const data = "[]";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    const err = lib.con_deserialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err);
}

test "array close too many" {
    const data = "]";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const err = lib.con_deserialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_CLOSED_TOO_MANY), err);
}

test "array close reader fail" {
    const data = "[";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    const err = lib.con_deserialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_READER), err);
}

test "dict open" {
    const data = "{";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const err = lib.con_deserialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err);
}

test "dict open too many" {
    const data = "{";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const err = lib.con_deserialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_TOO_DEEP), err);
}

test "dict nested open too many" {
    const data = "[1,{";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        var buffer: [1]u8 = undefined;
        var writer: lib.ConWriterString = undefined;
        const iw_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw_err);

        const num_err = lib.con_deserialize_number(&context, lib.con_writer_string_interface(&writer));
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), num_err);

        const err = lib.con_deserialize_dict_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_TOO_DEEP), err);
    }
}

test "dict open reader fail" {
    const data = "";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const err = lib.con_deserialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_READER), err);
}

test "dict close" {
    const data = "{}";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    const close_err = lib.con_deserialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close_err);
}

test "dict close too many" {
    const data = "}";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const close_err = lib.con_deserialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_CLOSED_TOO_MANY), close_err);
}

test "dict close reader fail" {
    const data = "{";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    const close_err = lib.con_deserialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_READER), close_err);
}

// Section: Dict key -----------------------------------------------------------

test "dict key" {
    const data = "{\"k\":";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        var buffer: [1]u8 = undefined;
        var writer: lib.ConWriterString = undefined;
        const iw_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw_err);

        const key_err = lib.con_deserialize_dict_key(&context, lib.con_writer_string_interface(&writer));
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key_err);
        try testing.expectEqualStrings("k", &buffer);
    }
}

test "dict key multiple" {
    const data = "{\"k\":null,\"m\":";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        var buffer: [2]u8 = undefined;
        var writer: lib.ConWriterString = undefined;
        const iw_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw_err);

        const key1_err = lib.con_deserialize_dict_key(&context, lib.con_writer_string_interface(&writer));
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key1_err);
        try testing.expectEqualStrings("k", buffer[0..1]);

        const null_err = lib.con_deserialize_null(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), null_err);

        const key2_err = lib.con_deserialize_dict_key(&context, lib.con_writer_string_interface(&writer));
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key2_err);
        try testing.expectEqualStrings("m", buffer[1..2]);
    }
}

test "dict key reader fail" {
    const data = "{\"k";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        var buffer: [1]u8 = undefined;
        var writer: lib.ConWriterString = undefined;
        const iw_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw_err);

        const key_err = lib.con_deserialize_dict_key(&context, lib.con_writer_string_interface(&writer));
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_READER), key_err);
        try testing.expectEqual(1, writer.current);
        try testing.expectEqualStrings("k", &buffer);
    }
}

test "dict key colon reader fail" {
    const data = "{\"k\"";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        var buffer: [1]u8 = undefined;
        var writer: lib.ConWriterString = undefined;
        const iw_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw_err);

        const key_err = lib.con_deserialize_dict_key(&context, lib.con_writer_string_interface(&writer));
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_READER), key_err);
        try testing.expectEqual(1, writer.current);
        try testing.expectEqualStrings("k", &buffer);
    }
}

test "dict key outside dict" {
    const data = "\"k\"";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    var buffer: [1]u8 = undefined;
    var writer: lib.ConWriterString = undefined;
    const iw_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw_err);

    const key_err = lib.con_deserialize_dict_key(&context, lib.con_writer_string_interface(&writer));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_TYPE), key_err);
    try testing.expectEqual(0, writer.current);
}

test "dict key in array" {
    const data = "[\"k\":";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        var buffer: [0]u8 = undefined;
        var writer: lib.ConWriterString = undefined;
        const iw_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw_err);

        const key_err = lib.con_deserialize_dict_key(&context, lib.con_writer_string_interface(&writer));
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_TYPE), key_err);
    }
}

test "dict key twice" {
    const data = "{\"k\":\"m\":";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        var buffer: [1]u8 = undefined;
        var writer: lib.ConWriterString = undefined;
        const iw_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw_err);

        const key1_err = lib.con_deserialize_dict_key(&context, lib.con_writer_string_interface(&writer));
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key1_err);
        try testing.expectEqual(1, writer.current);
        try testing.expectEqualStrings("k", &buffer);

        const key2_err = lib.con_deserialize_dict_key(&context, lib.con_writer_string_interface(&writer));
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_TYPE), key2_err);
    }
}

test "dict number key missing" {
    const data = "{3";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        var buffer: [1]u8 = undefined;
        var writer: lib.ConWriterString = undefined;
        const iw_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw_err);

        const num_err = lib.con_deserialize_number(&context, lib.con_writer_string_interface(&writer));
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_KEY), num_err);
    }
}

test "dict number second key missing" {
    const data = "{\"k\":3,4";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        var buffer: [2]u8 = undefined;
        var writer: lib.ConWriterString = undefined;
        const iw_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw_err);

        const key_err = lib.con_deserialize_dict_key(&context, lib.con_writer_string_interface(&writer));
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key_err);
        try testing.expectEqualStrings("k", buffer[0..1]);

        const num1_err = lib.con_deserialize_number(&context, lib.con_writer_string_interface(&writer));
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), num1_err);
        try testing.expectEqualStrings("3", buffer[1..2]);

        const num2_err = lib.con_deserialize_number(&context, lib.con_writer_string_interface(&writer));
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_KEY), num2_err);
    }
}

test "dict string key missing" {
    const data = "{\"k\"";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        var buffer: [1]u8 = undefined;
        var writer: lib.ConWriterString = undefined;
        const iw_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw_err);

        const str_err = lib.con_deserialize_string(&context, lib.con_writer_string_interface(&writer));
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_KEY), str_err);
    }
}

test "dict string second key missing" {
    const data = "{\"k\":\"a\",\"b\"";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    {
        var buffer: [2]u8 = undefined;
        var writer: lib.ConWriterString = undefined;
        const iw_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw_err);

        const key_err = lib.con_deserialize_dict_key(&context, lib.con_writer_string_interface(&writer));
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key_err);
        try testing.expectEqualStrings("k", buffer[0..1]);

        const num1_err = lib.con_deserialize_string(&context, lib.con_writer_string_interface(&writer));
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), num1_err);
        try testing.expectEqualStrings("a", buffer[1..2]);

        const num2_err = lib.con_deserialize_string(&context, lib.con_writer_string_interface(&writer));
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_KEY), num2_err);
    }
}

test "dict array key missing" {
    const data = "{[";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [2]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open1_err = lib.con_deserialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open1_err);

    {
        const open2_err = lib.con_deserialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_KEY), open2_err);
    }
}

test "dict array second key missing" {
    const data = "{\"k\":[],[";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [2]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open1_err = lib.con_deserialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open1_err);

    {
        var buffer: [1]u8 = undefined;
        var writer: lib.ConWriterString = undefined;
        const iw_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw_err);

        const key_err = lib.con_deserialize_dict_key(&context, lib.con_writer_string_interface(&writer));
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key_err);

        const open2_err = lib.con_deserialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open2_err);
        const close2_err = lib.con_deserialize_array_close(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close2_err);

        const open3_err = lib.con_deserialize_array_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_KEY), open3_err);
    }
}

test "dict dict key missing" {
    const data = "{{";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [2]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open1_err = lib.con_deserialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open1_err);

    {
        const open2_err = lib.con_deserialize_dict_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_KEY), open2_err);
    }
}

test "dict dict second key missing" {
    const data = "{\"k\":{},{";
    var reader: lib.ConReaderString = undefined;
    const ir_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir_err);

    var depth: [2]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(
        &context,
        lib.con_reader_string_interface(&reader),
        &depth,
        depth.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open1_err = lib.con_deserialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open1_err);

    {
        var buffer: [1]u8 = undefined;
        var writer: lib.ConWriterString = undefined;
        const iw_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw_err);

        const key_err = lib.con_deserialize_dict_key(&context, lib.con_writer_string_interface(&writer));
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), key_err);

        const open2_err = lib.con_deserialize_dict_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open2_err);
        const close2_err = lib.con_deserialize_dict_close(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), close2_err);

        const open3_err = lib.con_deserialize_dict_open(&context);
        try testing.expectEqual(@as(c_uint, lib.CON_ERROR_KEY), open3_err);
    }
}

// Section: Combinations of containers -----------------------------------------

test "array open -> dict close" {
    const data = "[}";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_array_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    const close_err = lib.con_deserialize_dict_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_NOT_DICT), close_err);
}

test "dict open -> array close" {
    const data = "{]";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [1]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const open_err = lib.con_deserialize_dict_open(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), open_err);

    const close_err = lib.con_deserialize_array_close(&context);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_NOT_ARRAY), close_err);
}
