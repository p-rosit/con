const testing = @import("std").testing;
const lib = @import("../../internal.zig").lib;

test "indent init" {
    var c: lib.GciWriterString = undefined;
    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_init(
        &context,
        lib.gci_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    _ = lib.con_writer_indent_interface(&context);
}

test "indent write" {
    var b: [1]u8 = undefined;
    var c: lib.GciWriterString = undefined;
    const i_err = lib.gci_writer_string_init(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_init(
        &context,
        lib.gci_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.gci_writer_write(writer, "1", 1);
    try testing.expectEqual(1, res);
    try testing.expectEqualStrings("1", &b);
}

test "indent write minified" {
    var b: [56]u8 = undefined;
    var c: lib.GciWriterString = undefined;
    const i_err = lib.gci_writer_string_init(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_init(
        &context,
        lib.gci_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const json = "[{\"k\" : \":)\"}\n\t,  \r\nnull,\"\\\"{1,2,3} [1,2,3]\"]";
    const res = lib.gci_writer_write(writer, json, 45);
    try testing.expectEqual(45, res);
    try testing.expectEqualStrings(
        \\[
        \\  {
        \\    "k": ":)"
        \\  },
        \\  null,
        \\  "\"{1,2,3} [1,2,3]"
        \\]
    ,
        &b,
    );
}

test "indent write one character at a time" {
    var b: [56]u8 = undefined;
    var c: lib.GciWriterString = undefined;
    const i_err = lib.gci_writer_string_init(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_init(
        &context,
        lib.gci_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const str = "[{\"k\":\":)\"},null,\"\\\"{1,2,3} [1,2,3]\"]";

    const writer = lib.con_writer_indent_interface(&context);

    for (str) |ch| {
        const amount_written = lib.gci_writer_write(writer, &ch, 1);
        try testing.expectEqual(1, amount_written);
    }

    try testing.expectEqualStrings(
        \\[
        \\  {
        \\    "k": ":)"
        \\  },
        \\  null,
        \\  "\"{1,2,3} [1,2,3]"
        \\]
    ,
        &b,
    );
}

test "indent empty container" {
    var b: [14]u8 = undefined;
    var c: lib.GciWriterString = undefined;
    const i_err = lib.gci_writer_string_init(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_init(
        &context,
        lib.gci_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const json = "[{},[]]";
    const res = lib.gci_writer_write(writer, json, 7);
    try testing.expectEqual(7, res);
    try testing.expectEqualStrings(
        \\[
        \\  {},
        \\  []
        \\]
    ,
        &b,
    );
}

test "indent body writer fail" {
    var b: [0]u8 = undefined;
    var c: lib.GciWriterString = undefined;
    const i_err = lib.gci_writer_string_init(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_init(
        &context,
        lib.gci_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.gci_writer_write(writer, "1", 1);
    try testing.expectEqual(0, res);
}

test "indent newline array open writer fail" {
    var b: [1]u8 = undefined;
    var c: lib.GciWriterString = undefined;
    const i_err = lib.gci_writer_string_init(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_init(
        &context,
        lib.gci_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.gci_writer_write(writer, "[1]", 3);
    try testing.expectEqual(1, res);
    try testing.expectEqualStrings("[", &b);
}

test "indent whitespace array open writer fail" {
    var b: [2]u8 = undefined;
    var c: lib.GciWriterString = undefined;
    const i_err = lib.gci_writer_string_init(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_init(
        &context,
        lib.gci_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.gci_writer_write(writer, "[1]", 3);
    try testing.expectEqual(1, res);
    try testing.expectEqualStrings("[\n", &b);
}

test "indent newline array close writer fail" {
    var b: [5]u8 = undefined;
    var c: lib.GciWriterString = undefined;
    const i_err = lib.gci_writer_string_init(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_init(
        &context,
        lib.gci_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.gci_writer_write(writer, "[1]", 3);
    try testing.expectEqual(2, res);
    try testing.expectEqualStrings("[\n  1", &b);
}

test "indent whitespace array close writer fail" {
    var b: [6]u8 = undefined;
    var c: lib.GciWriterString = undefined;
    const i_err = lib.gci_writer_string_init(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_init(
        &context,
        lib.gci_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.gci_writer_write(writer, "[1]", 3);
    try testing.expectEqual(2, res);
    try testing.expectEqualStrings("[\n  1\n", &b);
}

test "indent newline dict writer fail" {
    var b: [1]u8 = undefined;
    var c: lib.GciWriterString = undefined;
    const i_err = lib.gci_writer_string_init(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_init(
        &context,
        lib.gci_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.gci_writer_write(writer, "{\"", 2);
    try testing.expectEqual(1, res);
    try testing.expectEqualStrings("{", &b);
}

test "indent whitespace dict writer fail" {
    var b: [2]u8 = undefined;
    var c: lib.GciWriterString = undefined;
    const i_err = lib.gci_writer_string_init(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_init(
        &context,
        lib.gci_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.gci_writer_write(writer, "{\"", 2);
    try testing.expectEqual(1, res);
    try testing.expectEqualStrings("{\n", &b);
}

test "indent newline dict close writer fail" {
    var b: [10]u8 = undefined;
    var c: lib.GciWriterString = undefined;
    const i_err = lib.gci_writer_string_init(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_init(
        &context,
        lib.gci_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.gci_writer_write(writer, "{\"k\":1}", 7);
    try testing.expectEqual(6, res);
    try testing.expectEqualStrings("{\n  \"k\": 1", &b);
}

test "indent whitespace dict close writer fail" {
    var b: [11]u8 = undefined;
    var c: lib.GciWriterString = undefined;
    const i_err = lib.gci_writer_string_init(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_init(
        &context,
        lib.gci_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.gci_writer_write(writer, "{\"k\":1}", 7);
    try testing.expectEqual(6, res);
    try testing.expectEqualStrings("{\n  \"k\": 1\n", &b);
}

test "indent space writer fail" {
    var b: [8]u8 = undefined;
    var c: lib.GciWriterString = undefined;
    const i_err = lib.gci_writer_string_init(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_init(
        &context,
        lib.gci_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.gci_writer_write(writer, "{\"k\":", 5);
    try testing.expectEqual(5, res);
    try testing.expectEqualStrings("{\n  \"k\":", &b);
}

test "indent newline comma writer fail" {
    var b: [6]u8 = undefined;
    var c: lib.GciWriterString = undefined;
    const i_err = lib.gci_writer_string_init(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_init(
        &context,
        lib.gci_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.gci_writer_write(writer, "[1,2]", 5);
    try testing.expectEqual(3, res);
    try testing.expectEqualStrings("[\n  1,", &b);
}

test "indent whitespace comma writer fail" {
    var b: [7]u8 = undefined;
    var c: lib.GciWriterString = undefined;
    const i_err = lib.gci_writer_string_init(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_init(
        &context,
        lib.gci_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.gci_writer_write(writer, "[1,2]", 5);
    try testing.expectEqual(3, res);
    try testing.expectEqualStrings("[\n  1,\n", &b);
}
