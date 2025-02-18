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
    const err = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_READER), err);
}

test "next number" {
    const data = " 12";
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
    const err = lib.con_deserialize_next(&context, &etype);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), err);
    try testing.expectEqual(@as(c_uint, lib.CON_DESERIALIZE_TYPE_NUMBER), etype);
}
