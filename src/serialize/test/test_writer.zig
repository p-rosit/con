const std = @import("std");
const builtin = @import("builtin");
const testing = @import("std").testing;
const lib = @import("../../internal.zig").lib;
const clib = @cImport({
    @cInclude("stdio.h");
});

test "file init" {
    var context: lib.ConWriterFile = undefined;
    const init_err = lib.con_writer_file_context(&context, @ptrFromInt(256));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    _ = lib.con_writer_file_interface(&context);
}

test "file write" {
    var file: [*c]clib.FILE = undefined;

    switch (builtin.os.tag) {
        .linux => {
            file = clib.tmpfile();
        },
        .windows => {
            @compileError("TODO: allow testing file writer, something to do with `GetTempFileNameA` and `GetTempPathA`");
        },
        else => {
            std.debug.print("TODO: allow testing file writer on this os.\n", .{});
            return;
        },
    }

    var context: lib.ConWriterFile = undefined;
    const init_err = lib.con_writer_file_context(&context, @as([*c]lib.FILE, @ptrCast(file)));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_file_interface(&context);

    const res = lib.con_writer_write(writer, "1", 1);
    try testing.expectEqual(1, res);

    const seek_err = clib.fseek(file, 0, lib.SEEK_SET);
    try testing.expectEqual(seek_err, 0);

    var buffer: [2]u8 = undefined;
    const result = clib.fread(&buffer, 1, 2, file);
    try testing.expectEqual(1, result);

    try testing.expectEqualStrings("1", buffer[0..1]);
}

test "string init" {
    var buffer: [1]u8 = undefined;
    var context: lib.ConWriterString = undefined;
    const init_err = lib.con_writer_string_context(&context, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    _ = lib.con_writer_string_interface(&context);
}

test "string init null" {
    var buffer: [1]u8 = undefined;
    const init_err = lib.con_writer_string_context(null, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_NULL), init_err);
}

test "string buffer null" {
    var context: lib.ConWriterString = undefined;
    const init_err = lib.con_writer_string_context(&context, null, 2);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_NULL), init_err);
}

test "string write" {
    var buffer: [2]u8 = undefined;
    var context: lib.ConWriterString = undefined;

    const init_err = lib.con_writer_string_context(&context, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_string_interface(&context);

    const res = lib.con_writer_write(writer, "12", 2);
    try testing.expectEqual(2, res);
    try testing.expectEqualStrings("12", &buffer);
}

test "string write multiple" {
    var buffer: [2]u8 = undefined;
    var context: lib.ConWriterString = undefined;

    const init_err = lib.con_writer_string_context(&context, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_string_interface(&context);

    const write_err1 = lib.con_writer_write(writer, "1", 1);
    try testing.expectEqual(1, write_err1);

    const write_err2 = lib.con_writer_write(writer, "2", 1);
    try testing.expectEqual(1, write_err2);

    try testing.expectEqualStrings("12", &buffer);
}

test "string overflow" {
    var buffer: [0]u8 = undefined;
    var context: lib.ConWriterString = undefined;

    const init_err = lib.con_writer_string_context(&context, &buffer, buffer.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_string_interface(&context);

    const res = lib.con_writer_write(writer, "1", 1);
    try testing.expectEqual(0, res);
}

test "buffer init" {
    var c: lib.ConWriterString = undefined;

    var buffer: [1]u8 = undefined;
    var context: lib.ConWriterBuffer = undefined;
    const init_err = lib.con_writer_buffer_context(
        &context,
        lib.con_writer_string_interface(&c),
        &buffer,
        buffer.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    _ = lib.con_writer_buffer_interface(&context);
}

test "buffer init null" {
    var c: lib.ConWriterString = undefined;
    var buffer: [1]u8 = undefined;
    const init_err = lib.con_writer_buffer_context(
        null,
        lib.con_writer_string_interface(&c),
        &buffer,
        buffer.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_NULL), init_err);
}

test "buffer init buffer null" {
    var c: lib.ConWriterString = undefined;
    var context: lib.ConWriterBuffer = undefined;
    const init_err = lib.con_writer_buffer_context(
        &context,
        lib.con_writer_string_interface(&c),
        null,
        2,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_NULL), init_err);
}

test "buffer init buffer small" {
    var c: lib.ConWriterString = undefined;
    var buffer: [0]u8 = undefined;
    var context: lib.ConWriterBuffer = undefined;
    const init_err = lib.con_writer_buffer_context(
        &context,
        lib.con_writer_string_interface(&c),
        &buffer,
        buffer.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_BUFFER), init_err);
}

test "buffer write" {
    var b: [1]u8 = undefined;
    var c: lib.ConWriterString = undefined;
    const i_err = lib.con_writer_string_context(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var buffer: [1]u8 = undefined;
    var context: lib.ConWriterBuffer = undefined;
    const init_err = lib.con_writer_buffer_context(
        &context,
        lib.con_writer_string_interface(&c),
        &buffer,
        buffer.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_buffer_interface(&context);

    const res = lib.con_writer_write(writer, "1", 1);
    try testing.expectEqual(1, res);
    try testing.expectEqualStrings("1", &b);
}

test "buffer write moderate" {
    var b: [2]u8 = undefined;
    var c: lib.ConWriterString = undefined;
    const i_err = lib.con_writer_string_context(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var buffer: [2]u8 = undefined;
    var context: lib.ConWriterBuffer = undefined;
    const init_err = lib.con_writer_buffer_context(
        &context,
        lib.con_writer_string_interface(&c),
        &buffer,
        buffer.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_buffer_interface(&context);

    const res1 = lib.con_writer_write(writer, "1", 1);
    try testing.expectEqual(1, res1);

    // First buffer is filled and flushed, then buffer filled with rest of string
    const res2 = lib.con_writer_write(writer, "12", 1);
    try testing.expectEqual(1, res2);

    // Buffer is not flushed after second write
    try testing.expectEqualStrings("11", &b);
}

test "buffer write large" {
    var b: [7]u8 = undefined;
    var c: lib.ConWriterString = undefined;
    const i_err = lib.con_writer_string_context(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var buffer: [2]u8 = undefined;
    var context: lib.ConWriterBuffer = undefined;
    const init_err = lib.con_writer_buffer_context(
        &context,
        lib.con_writer_string_interface(&c),
        &buffer,
        buffer.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_buffer_interface(&context);

    // First buffer is filled and flushed, then rest of string is written
    // directly without passing buffer
    const res = lib.con_writer_write(writer, "1234567", 7);
    try testing.expectEqual(7, res);

    // Rest of string didn't pass buffer since last 7 was written instead
    // of left in buffer
    try testing.expectEqualStrings("1234567", &b);
}

test "buffer flush" {
    var b: [1]u8 = undefined;
    var c: lib.ConWriterString = undefined;
    const i_err = lib.con_writer_string_context(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var buffer: [2]u8 = undefined;
    var context: lib.ConWriterBuffer = undefined;
    const init_err = lib.con_writer_buffer_context(
        &context,
        lib.con_writer_string_interface(&c),
        &buffer,
        buffer.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_buffer_interface(&context);

    const res = lib.con_writer_write(writer, "1", 1);
    try testing.expectEqual(1, res);

    const flush_res = lib.con_writer_buffer_flush(&context);
    try testing.expect(flush_res);
    try testing.expectEqualStrings("1", &b);
}

test "buffer internal writer fail" {
    var b: [0]u8 = undefined;
    var c: lib.ConWriterString = undefined;
    const i_err = lib.con_writer_string_context(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var buffer: [1]u8 = undefined;
    var context: lib.ConWriterBuffer = undefined;
    const init_err = lib.con_writer_buffer_context(
        &context,
        lib.con_writer_string_interface(&c),
        &buffer,
        buffer.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_buffer_interface(&context);
    const res = lib.con_writer_write(writer, "1", 1);
    try testing.expectEqual(0, res);
}

test "buffer flush writer fail" {
    var b: [0]u8 = undefined;
    var c: lib.ConWriterString = undefined;
    const i_err = lib.con_writer_string_context(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var buffer: [2]u8 = undefined;
    var context: lib.ConWriterBuffer = undefined;
    const init_err = lib.con_writer_buffer_context(
        &context,
        lib.con_writer_string_interface(&c),
        &buffer,
        buffer.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_buffer_interface(&context);

    const res = lib.con_writer_write(writer, "1", 1);
    try testing.expectEqual(1, res);

    const flush_res = lib.con_writer_buffer_flush(&context);
    try testing.expect(!flush_res);
}

test "indent init" {
    var c: lib.ConWriterString = undefined;
    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_context(
        &context,
        lib.con_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    _ = lib.con_writer_indent_interface(&context);
}

test "indent write" {
    var b: [1]u8 = undefined;
    var c: lib.ConWriterString = undefined;
    const i_err = lib.con_writer_string_context(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_context(
        &context,
        lib.con_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.con_writer_write(writer, "1", 1);
    try testing.expectEqual(1, res);
    try testing.expectEqualStrings("1", &b);
}

test "indent write minified" {
    var b: [56]u8 = undefined;
    var c: lib.ConWriterString = undefined;
    const i_err = lib.con_writer_string_context(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_context(
        &context,
        lib.con_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const json = "[{\"k\":\":)\"},null,\"\\\"{1,2,3} [1,2,3]\"]";
    const res = lib.con_writer_write(writer, json, 37);
    try testing.expectEqual(37, res);
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
    var c: lib.ConWriterString = undefined;
    const i_err = lib.con_writer_string_context(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_context(
        &context,
        lib.con_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const str = "[{\"k\":\":)\"},null,\"\\\"{1,2,3} [1,2,3]\"]";

    const writer = lib.con_writer_indent_interface(&context);

    for (str) |ch| {
        const amount_written = lib.con_writer_write(writer, &ch, 1);
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

test "indent body writer fail" {
    var b: [0]u8 = undefined;
    var c: lib.ConWriterString = undefined;
    const i_err = lib.con_writer_string_context(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_context(
        &context,
        lib.con_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.con_writer_write(writer, "1", 1);
    try testing.expectEqual(0, res);
}

test "indent newline array open writer fail" {
    var b: [1]u8 = undefined;
    var c: lib.ConWriterString = undefined;
    const i_err = lib.con_writer_string_context(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_context(
        &context,
        lib.con_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.con_writer_write(writer, "[1]", 3);
    try testing.expectEqual(1, res);
    try testing.expectEqualStrings("[", &b);
}

test "indent whitespace array open writer fail" {
    var b: [2]u8 = undefined;
    var c: lib.ConWriterString = undefined;
    const i_err = lib.con_writer_string_context(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_context(
        &context,
        lib.con_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.con_writer_write(writer, "[1]", 3);
    try testing.expectEqual(1, res);
    try testing.expectEqualStrings("[\n", &b);
}

test "indent newline array close writer fail" {
    var b: [5]u8 = undefined;
    var c: lib.ConWriterString = undefined;
    const i_err = lib.con_writer_string_context(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_context(
        &context,
        lib.con_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.con_writer_write(writer, "[1]", 3);
    try testing.expectEqual(2, res);
    try testing.expectEqualStrings("[\n  1", &b);
}

test "indent whitespace array close writer fail" {
    var b: [6]u8 = undefined;
    var c: lib.ConWriterString = undefined;
    const i_err = lib.con_writer_string_context(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_context(
        &context,
        lib.con_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.con_writer_write(writer, "[1]", 3);
    try testing.expectEqual(2, res);
    try testing.expectEqualStrings("[\n  1\n", &b);
}

test "indent newline dict writer fail" {
    var b: [1]u8 = undefined;
    var c: lib.ConWriterString = undefined;
    const i_err = lib.con_writer_string_context(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_context(
        &context,
        lib.con_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.con_writer_write(writer, "{\"", 2);
    try testing.expectEqual(1, res);
    try testing.expectEqualStrings("{", &b);
}

test "indent whitespace dict writer fail" {
    var b: [2]u8 = undefined;
    var c: lib.ConWriterString = undefined;
    const i_err = lib.con_writer_string_context(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_context(
        &context,
        lib.con_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.con_writer_write(writer, "{\"", 2);
    try testing.expectEqual(1, res);
    try testing.expectEqualStrings("{\n", &b);
}

test "indent newline dict close writer fail" {
    var b: [10]u8 = undefined;
    var c: lib.ConWriterString = undefined;
    const i_err = lib.con_writer_string_context(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_context(
        &context,
        lib.con_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.con_writer_write(writer, "{\"k\":1}", 7);
    try testing.expectEqual(6, res);
    try testing.expectEqualStrings("{\n  \"k\": 1", &b);
}

test "indent whitespace dict close writer fail" {
    var b: [11]u8 = undefined;
    var c: lib.ConWriterString = undefined;
    const i_err = lib.con_writer_string_context(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_context(
        &context,
        lib.con_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.con_writer_write(writer, "{\"k\":1}", 7);
    try testing.expectEqual(6, res);
    try testing.expectEqualStrings("{\n  \"k\": 1\n", &b);
}

test "indent space writer fail" {
    var b: [8]u8 = undefined;
    var c: lib.ConWriterString = undefined;
    const i_err = lib.con_writer_string_context(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_context(
        &context,
        lib.con_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.con_writer_write(writer, "{\"k\":", 5);
    try testing.expectEqual(5, res);
    try testing.expectEqualStrings("{\n  \"k\":", &b);
}

test "indent newline comma writer fail" {
    var b: [6]u8 = undefined;
    var c: lib.ConWriterString = undefined;
    const i_err = lib.con_writer_string_context(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_context(
        &context,
        lib.con_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.con_writer_write(writer, "[1,2]", 5);
    try testing.expectEqual(3, res);
    try testing.expectEqualStrings("[\n  1,", &b);
}

test "indent whitespace comma writer fail" {
    var b: [7]u8 = undefined;
    var c: lib.ConWriterString = undefined;
    const i_err = lib.con_writer_string_context(&c, &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConWriterIndent = undefined;
    const init_err = lib.con_writer_indent_context(
        &context,
        lib.con_writer_string_interface(&c),
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const writer = lib.con_writer_indent_interface(&context);

    const res = lib.con_writer_write(writer, "[1,2]", 5);
    try testing.expectEqual(3, res);
    try testing.expectEqualStrings("[\n  1,\n", &b);
}
