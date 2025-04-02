const testing = @import("std").testing;
const lib = @import("../../internal.zig").lib;

test "comment init" {
    const d = "";
    var c: lib.GciReaderString = undefined;
    const i_err = lib.gci_reader_string_init(&c, d, d.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConReaderComment = undefined;
    const init_err = lib.con_reader_comment_init(
        &context,
        lib.gci_reader_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    _ = lib.con_reader_comment_interface(&context);
}

test "comment read" {
    const d = "12";
    var c: lib.GciReaderString = undefined;
    const i_err = lib.gci_reader_string_init(&c, d, d.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConReaderComment = undefined;
    const init_err = lib.con_reader_comment_init(
        &context,
        lib.gci_reader_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
    const reader = lib.con_reader_comment_interface(&context);

    var buffer: [2]u8 = undefined;
    const length = lib.gci_reader_read(reader, &buffer, buffer.len);
    try testing.expectEqual(2, length);
    try testing.expectEqualStrings("12", &buffer);
}

test "comment read comment" {
    const d = "[  //:(\n \"k //:)\",1/]";
    var c: lib.GciReaderString = undefined;
    const i_err = lib.gci_reader_string_init(&c, d, d.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConReaderComment = undefined;
    const init_err = lib.con_reader_comment_init(
        &context,
        lib.gci_reader_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
    const reader = lib.con_reader_comment_interface(&context);

    var buffer: [17]u8 = undefined;
    const length = lib.gci_reader_read(reader, &buffer, buffer.len);
    try testing.expectEqual(17, length);
    try testing.expectEqualStrings("[  \n \"k //:)\",1/]", &buffer);
}

test "comment read comment one char at a time" {
    const d = "[  //:(\n \"k //:)\",1/]";
    var c: lib.GciReaderString = undefined;
    const i_err = lib.gci_reader_string_init(&c, d, d.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConReaderComment = undefined;
    const init_err = lib.con_reader_comment_init(
        &context,
        lib.gci_reader_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
    const reader = lib.con_reader_comment_interface(&context);

    var buffer: [17]u8 = undefined;
    for (0..17) |i| {
        const length = lib.gci_reader_read(reader, buffer[i .. i + 1].ptr, 1);
        try testing.expectEqual(1, length);
    }

    try testing.expectEqualStrings("[  \n \"k //:)\",1/]", &buffer);
}

test "comment inner reader empty" {
    const d = "";
    var c: lib.GciReaderString = undefined;
    const i_err = lib.gci_reader_string_init(&c, d, d.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConReaderComment = undefined;
    const init_err = lib.con_reader_comment_init(
        &context,
        lib.gci_reader_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
    const reader = lib.con_reader_comment_interface(&context);

    var buffer: [1]u8 = undefined;
    const length = lib.gci_reader_read(reader, &buffer, buffer.len);
    try testing.expectEqual(0, length);
}

test "comment inner reader empty comment" {
    const d = "/";
    var c: lib.GciReaderString = undefined;
    const i_err = lib.gci_reader_string_init(&c, d, d.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConReaderComment = undefined;
    const init_err = lib.con_reader_comment_init(
        &context,
        lib.gci_reader_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
    const reader = lib.con_reader_comment_interface(&context);

    var buffer: [1]u8 = undefined;
    const length = lib.gci_reader_read(reader, &buffer, buffer.len);
    try testing.expectEqual(0, length);
}

test "comment inner reader fail" {
    const d = "1";
    var c1: lib.GciReaderString = undefined;
    const i1_err = lib.gci_reader_string_init(&c1, d, d.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i1_err);

    var c2: lib.GciReaderFail = undefined;
    const i2_err = lib.gci_reader_fail_init(
        &c2,
        lib.gci_reader_string_interface(&c1),
        0,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i2_err);

    var context: lib.ConReaderComment = undefined;
    const init_err = lib.con_reader_comment_init(
        &context,
        lib.gci_reader_fail_interface(&c2),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
    const reader = lib.con_reader_comment_interface(&context);

    var buffer: [1]u8 = undefined;
    const length = lib.gci_reader_read(reader, &buffer, buffer.len);
    try testing.expectEqual(0, length);
}

test "comment inner reader fail comment" {
    const d = "/";
    var c1: lib.GciReaderString = undefined;
    const i1_err = lib.gci_reader_string_init(&c1, d, d.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i1_err);

    var c2: lib.GciReaderFail = undefined;
    const i2_err = lib.gci_reader_fail_init(
        &c2,
        lib.gci_reader_string_interface(&c1),
        1,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i2_err);

    var context: lib.ConReaderComment = undefined;
    const init_err = lib.con_reader_comment_init(
        &context,
        lib.gci_reader_fail_interface(&c2),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
    const reader = lib.con_reader_comment_interface(&context);

    var buffer: [1]u8 = undefined;
    const length1 = lib.gci_reader_read(reader, &buffer, buffer.len);
    try testing.expectEqual(0, length1);

    const length2 = lib.gci_reader_read(reader, &buffer, buffer.len);
    try testing.expectEqual(0, length2);
}

test "comment read only comment" {
    const d = "// only a comment";
    var c: lib.GciReaderString = undefined;
    const i_err = lib.gci_reader_string_init(&c, d, d.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConReaderComment = undefined;
    const init_err = lib.con_reader_comment_init(
        &context,
        lib.gci_reader_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
    const reader = lib.con_reader_comment_interface(&context);

    var buffer: [3]u8 = undefined;
    const length = lib.gci_reader_read(reader, &buffer, buffer.len);
    try testing.expectEqual(0, length);
}

test "comment read clear error" {
    const d = "1";
    var c1: lib.GciReaderString = undefined;
    const i1_err = lib.gci_reader_string_init(&c1, d, d.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i1_err);

    var c2: lib.GciReaderFail = undefined;
    const i2_err = lib.gci_reader_fail_init(
        &c2,
        lib.gci_reader_string_interface(&c1),
        0,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i2_err);

    var context: lib.ConReaderComment = undefined;
    const init_err = lib.con_reader_comment_init(
        &context,
        lib.gci_reader_fail_interface(&c2),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
    const reader = lib.con_reader_comment_interface(&context);

    var buffer: [2]u8 = undefined;
    const length1 = lib.gci_reader_read(reader, &buffer, buffer.len);
    try testing.expectEqual(0, length1);

    c2.reads_before_fail = 1;
    const length2 = lib.gci_reader_read(reader, &buffer, buffer.len);
    try testing.expectEqual(1, length2);
    try testing.expectEqualStrings("1", buffer[0..1]);
}

test "comment read comment clear error" {
    const d = "//\n1";
    var c1: lib.GciReaderString = undefined;
    const i1_err = lib.gci_reader_string_init(&c1, d, d.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i1_err);

    var c2: lib.GciReaderFail = undefined;
    const i2_err = lib.gci_reader_fail_init(
        &c2,
        lib.gci_reader_string_interface(&c1),
        1,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i2_err);

    var context: lib.ConReaderComment = undefined;
    const init_err = lib.con_reader_comment_init(
        &context,
        lib.gci_reader_fail_interface(&c2),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
    const reader = lib.con_reader_comment_interface(&context);

    var buffer: [3]u8 = undefined;
    const length1 = lib.gci_reader_read(reader, &buffer, buffer.len);
    try testing.expectEqual(0, length1);
    try testing.expectEqual('/', context.buffer_char);

    c2.reads_before_fail = 4;
    const length2 = lib.gci_reader_read(reader, &buffer, buffer.len);
    try testing.expectEqual(2, length2);
    try testing.expectEqualStrings("\n1", buffer[0..2]);
}

test "comment reader half comment clear error" {
    const d = "/1";
    var c1: lib.GciReaderString = undefined;
    const i1_err = lib.gci_reader_string_init(&c1, d, d.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i1_err);

    var c2: lib.GciReaderFail = undefined;
    const i2_err = lib.gci_reader_fail_init(
        &c2,
        lib.gci_reader_string_interface(&c1),
        1,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i2_err);

    var context: lib.ConReaderComment = undefined;
    const init_err = lib.con_reader_comment_init(
        &context,
        lib.gci_reader_fail_interface(&c2),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
    const reader = lib.con_reader_comment_interface(&context);

    var buffer: [3]u8 = undefined;
    const length1 = lib.gci_reader_read(reader, &buffer, buffer.len);
    try testing.expectEqual(0, length1);
    try testing.expectEqual('/', context.buffer_char);

    c2.reads_before_fail = 2;
    const length2 = lib.gci_reader_read(reader, &buffer, buffer.len);
    try testing.expectEqual(2, length2);
    try testing.expectEqualStrings("/1", buffer[0..2]);
}
