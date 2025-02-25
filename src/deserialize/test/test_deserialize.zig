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
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

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

test "next number" {
    const data = " 1";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

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
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

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
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

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
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

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
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

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
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

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
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

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

// test "next dict close" {}
//
// test "next dict first" {}
//
// test "next dict second" {}
//
// test "next dict key" {}

// Section: Values -------------------------------------------------------------

test "number int-like" {
    const data = "-6";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    var buffer: [4]u8 = undefined;
    var length: usize = undefined;
    const err = lib.con_deserialize_number(&context, &buffer, buffer.len, &length);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err);
    try testing.expectEqual(2, length);
    try testing.expectEqualStrings("-6", buffer[0..2]);
}

test "number int-like one character at a time" {
    const data = "-6";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    var buffer: [1]u8 = undefined;
    var length: usize = undefined;
    const err1 = lib.con_deserialize_number(&context, &buffer, buffer.len, &length);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_BUFFER), err1);
    try testing.expectEqual(1, length);
    try testing.expectEqualStrings("-", &buffer);

    const err2 = lib.con_deserialize_number(&context, &buffer, buffer.len, &length);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err2);
    try testing.expectEqual(1, length);
    try testing.expectEqualStrings("6", &buffer);
}

test "number float-like" {
    const data = "0.3";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    var buffer: [4]u8 = undefined;
    var length: usize = undefined;
    const err = lib.con_deserialize_number(&context, &buffer, buffer.len, &length);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err);
    try testing.expectEqual(3, length);
    try testing.expectEqualStrings("0.3", buffer[0..3]);
}

test "number float-like one character at a time" {
    const data = "0.3";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    var buffer: [1]u8 = undefined;
    var length: usize = undefined;
    const err1 = lib.con_deserialize_number(&context, &buffer, buffer.len, &length);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_BUFFER), err1);
    try testing.expectEqual(1, length);
    try testing.expectEqualStrings("0", &buffer);

    const err2 = lib.con_deserialize_number(&context, &buffer, buffer.len, &length);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_BUFFER), err2);
    try testing.expectEqual(1, length);
    try testing.expectEqualStrings(".", &buffer);

    const err3 = lib.con_deserialize_number(&context, &buffer, buffer.len, &length);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err3);
    try testing.expectEqual(1, length);
    try testing.expectEqualStrings("3", &buffer);
}

test "number scientific-like" {
    const data = "2e+4";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    var buffer: [5]u8 = undefined;
    var length: usize = undefined;
    const err = lib.con_deserialize_number(&context, &buffer, buffer.len, &length);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err);
    try testing.expectEqual(4, length);
    try testing.expectEqualStrings("2e+4", buffer[0..4]);
}

test "number scientific-like one character at a time" {
    const data = "2e+4";
    var reader: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&reader, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var depth: [0]u8 = undefined;
    var context: lib.ConDeserialize = undefined;
    const init_err = lib.con_deserialize_init(&context, lib.con_reader_string_interface(&reader), &depth, depth.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    var buffer: [1]u8 = undefined;
    var length: usize = undefined;
    const err1 = lib.con_deserialize_number(&context, &buffer, buffer.len, &length);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_BUFFER), err1);
    try testing.expectEqual(1, length);
    try testing.expectEqualStrings("2", &buffer);

    const err2 = lib.con_deserialize_number(&context, &buffer, buffer.len, &length);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_BUFFER), err2);
    try testing.expectEqual(1, length);
    try testing.expectEqualStrings("e", &buffer);

    const err3 = lib.con_deserialize_number(&context, &buffer, buffer.len, &length);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_BUFFER), err3);
    try testing.expectEqual(1, length);
    try testing.expectEqualStrings("+", &buffer);

    const err4 = lib.con_deserialize_number(&context, &buffer, buffer.len, &length);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err4);
    try testing.expectEqual(1, length);
    try testing.expectEqualStrings("4", &buffer);
}
