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
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const data1 = "2.";
    const ir1_err = lib.con_reader_string_init(&reader, data1, data1.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir1_err);
    const iw1_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw1_err);
    const err1 = lib.con_deserialize_number(&context, lib.con_writer_string_interface(&writer));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_READER), err1);
    try testing.expectEqual(2, writer.current);
    try testing.expectEqualStrings("2.", buffer[0..2]);

    const data2 = "2.5E";
    const ir2_err = lib.con_reader_string_init(&reader, data2, data2.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir2_err);
    const iw2_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw2_err);
    const err2 = lib.con_deserialize_number(&context, lib.con_writer_string_interface(&writer));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_READER), err2);
    try testing.expectEqual(4, writer.current);
    try testing.expectEqualStrings("2.5E", buffer[0..4]);

    const data3 = "-";
    const ir3_err = lib.con_reader_string_init(&reader, data3, data3.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir3_err);
    const iw3_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw3_err);
    const err3 = lib.con_deserialize_number(&context, lib.con_writer_string_interface(&writer));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_READER), err3);
    try testing.expectEqual(1, writer.current);
    try testing.expectEqualStrings("-", buffer[0..1]);

    const data4 = "3.4e-";
    const ir4_err = lib.con_reader_string_init(&reader, data4, data4.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), ir4_err);
    const iw4_err = lib.con_writer_string_init(&writer, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), iw4_err);
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
