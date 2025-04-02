const std = @import("std");
const builtin = @import("builtin");
const testing = @import("std").testing;
const lib = @import("../../internal.zig").lib;
const clib = @cImport({
    @cInclude("stdio.h");
});

test "fail init" {
    const data = "";
    var c: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&c, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConReaderFail = undefined;
    const init_err = lib.con_reader_fail_init(&context, lib.con_reader_string_interface(&c), 1);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    _ = lib.con_reader_fail_interface(&context);
}

test "fail fails" {
    const data = "12";
    var c: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&c, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConReaderFail = undefined;
    const init_err = lib.con_reader_fail_init(&context, lib.con_reader_string_interface(&c), 1);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const reader = lib.con_reader_fail_interface(&context);

    var buffer: [1]u8 = undefined;
    const length1 = lib.con_reader_read(reader, &buffer, buffer.len);
    try testing.expectEqual(1, length1);
    try testing.expectEqualStrings("1", buffer[0..1]);

    const length2 = lib.con_reader_read(reader, &buffer, buffer.len);
    try testing.expectEqual(0, length2);
}

test "file init" {
    var context: lib.ConReaderFile = undefined;
    const init_err = lib.con_reader_file_init(&context, @ptrFromInt(256));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
}

test "file read" {
    var file: [*c]clib.FILE = undefined;

    switch (builtin.os.tag) {
        .linux => {
            file = clib.tmpfile();
        },
        .windows => {
            @compileError("TODO: allow testing file reader, something to do with `GetTempFileNameA` and `GetTempPathA`");
        },
        else => {
            std.debug.print("TODO: allow testing file reader on this os.\n", .{});
            return;
        },
    }
    defer _ = clib.fclose(file);

    const written = clib.fputs("1", file);
    try testing.expectEqual(written, 1);

    const seek_err = clib.fseek(file, 0, clib.SEEK_SET);
    try testing.expectEqual(0, seek_err);

    var context: lib.ConReaderFile = undefined;
    const init_err = lib.con_reader_file_init(&context, @ptrCast(file));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
    const reader = lib.con_reader_file_interface(&context);

    var buffer: [1]u8 = undefined;
    const length1 = lib.con_reader_read(reader, &buffer, buffer.len);
    try testing.expectEqual(1, length1);
    try testing.expectEqualStrings("1", &buffer);

    const length2 = lib.con_reader_read(reader, &buffer, buffer.len);
    try testing.expectEqual(0, length2);
}

test "string init" {
    var data: [1]u8 = undefined;
    var context: lib.ConReaderString = undefined;
    const init_err = lib.con_reader_string_init(&context, &data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
    _ = lib.con_reader_string_interface(&context);
}

test "string init null" {
    var data: [1]u8 = undefined;
    const init_err = lib.con_reader_string_init(null, &data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_NULL), init_err);
}

test "string init null buffer" {
    var context: lib.ConReaderString = undefined;
    const init_err = lib.con_reader_string_init(&context, null, 2);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_NULL), init_err);
}

test "string read" {
    const data = "zig";
    var context: lib.ConReaderString = undefined;
    const init_err = lib.con_reader_string_init(&context, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
    const reader = lib.con_reader_string_interface(&context);

    var buffer: [3]u8 = undefined;
    const length = lib.con_reader_read(reader, &buffer, buffer.len);
    try testing.expectEqual(3, length);
    try testing.expectEqualStrings("zig", &buffer);
}

test "string read overflow" {
    const data = "z";
    var context: lib.ConReaderString = undefined;
    const init_err = lib.con_reader_string_init(&context, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
    const reader = lib.con_reader_string_interface(&context);

    var buffer: [2]u8 = undefined;
    const length1 = lib.con_reader_read(reader, &buffer, buffer.len);
    try testing.expectEqual(1, length1);
    try testing.expectEqualStrings("z", buffer[0..1]);

    const length2 = lib.con_reader_read(reader, &buffer, buffer.len);
    try testing.expectEqual(0, length2);
}

test "buffer init" {
    const data = "data";
    var c: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&c, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var buffer: [2]u8 = undefined;
    var context: lib.ConReaderBuffer = undefined;
    const init_err = lib.con_reader_buffer_init(
        &context,
        lib.con_reader_string_interface(&c),
        &buffer,
        buffer.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
    _ = lib.con_reader_buffer_interface(&context);
}

test "buffer init null" {
    const data = "data";
    var c: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&c, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var buffer: [2]u8 = undefined;
    const init_err = lib.con_reader_buffer_init(
        null,
        lib.con_reader_string_interface(&c),
        &buffer,
        buffer.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_NULL), init_err);
}

test "buffer init null buffer" {
    const data = "data";
    var c: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&c, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConReaderBuffer = undefined;
    const init_err = lib.con_reader_buffer_init(
        &context,
        lib.con_reader_string_interface(&c),
        null,
        1,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_NULL), init_err);
}

test "buffer read" {
    const data = "data";
    var c: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&c, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var buffer: [3]u8 = undefined;
    var context: lib.ConReaderBuffer = undefined;
    const init_err = lib.con_reader_buffer_init(
        &context,
        lib.con_reader_string_interface(&c),
        &buffer,
        buffer.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
    const reader = lib.con_reader_buffer_interface(&context);

    var result_buffer: [2]u8 = undefined;
    const length = lib.con_reader_read(reader, &result_buffer, result_buffer.len);
    try testing.expectEqual(2, length);
    try testing.expectEqualStrings("da", result_buffer[0..2]);
}

test "buffer read buffer twice" {
    const data = "data";
    var c: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&c, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var buffer: [3]u8 = undefined;
    var context: lib.ConReaderBuffer = undefined;
    const init_err = lib.con_reader_buffer_init(
        &context,
        lib.con_reader_string_interface(&c),
        &buffer,
        buffer.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
    const reader = lib.con_reader_buffer_interface(&context);

    var result_buffer: [5]u8 = undefined;
    const length = lib.con_reader_read(reader, &result_buffer, result_buffer.len);
    try testing.expectEqual(4, length);
    try testing.expectEqualStrings("data", result_buffer[0..4]);
}

test "buffer internal reader empty" {
    const data = "";
    var c: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&c, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var buffer: [3]u8 = undefined;
    var context: lib.ConReaderBuffer = undefined;
    const init_err = lib.con_reader_buffer_init(
        &context,
        lib.con_reader_string_interface(&c),
        &buffer,
        buffer.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
    const reader = lib.con_reader_buffer_interface(&context);

    var result_buffer: [2]u8 = undefined;
    const length = lib.con_reader_read(reader, &result_buffer, result_buffer.len);
    try testing.expectEqual(0, length);
}

test "buffer internal reader fail" {
    var c1: lib.ConReaderString = undefined;
    const i1_err = lib.con_reader_string_init(&c1, "1", 1);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i1_err);

    var c2: lib.ConReaderFail = undefined;
    const i2_err = lib.con_reader_fail_init(&c2, lib.con_reader_string_interface(&c1), 0);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i2_err);

    var buffer: [3]u8 = undefined;
    var context: lib.ConReaderBuffer = undefined;
    const init_err = lib.con_reader_buffer_init(
        &context,
        lib.con_reader_fail_interface(&c2),
        &buffer,
        buffer.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
    const reader = lib.con_reader_buffer_interface(&context);

    var result_buffer: [2]u8 = undefined;
    const length = lib.con_reader_read(reader, &result_buffer, result_buffer.len);
    try testing.expectEqual(0, length);
}

test "buffer internal reader large fail" {
    var c1: lib.ConReaderString = undefined;
    const i1_err = lib.con_reader_string_init(&c1, "1", 1);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i1_err);

    var c2: lib.ConReaderFail = undefined;
    const i2_err = lib.con_reader_fail_init(&c2, lib.con_reader_string_interface(&c1), 0);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i2_err);

    var buffer: [3]u8 = undefined;
    var context: lib.ConReaderBuffer = undefined;
    const init_err = lib.con_reader_buffer_init(
        &context,
        lib.con_reader_fail_interface(&c2),
        &buffer,
        buffer.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
    const reader = lib.con_reader_buffer_interface(&context);

    var result_buffer: [10]u8 = undefined;
    const length = lib.con_reader_read(reader, &result_buffer, result_buffer.len);
    try testing.expectEqual(0, length);
}

test "buffer clear error" {
    const data = "122";
    var c1: lib.ConReaderString = undefined;
    const i1_err = lib.con_reader_string_init(&c1, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i1_err);

    var c2: lib.ConReaderFail = undefined;
    const i2_err = lib.con_reader_fail_init(&c2, lib.con_reader_string_interface(&c1), 1);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i2_err);

    var b: [2]u8 = undefined;
    var context: lib.ConReaderBuffer = undefined;
    const init_err = lib.con_reader_buffer_init(&context, lib.con_reader_fail_interface(&c2), &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const reader = lib.con_reader_buffer_interface(&context);

    var buffer1: [1]u8 = undefined;
    const length1 = lib.con_reader_read(reader, &buffer1, buffer1.len);
    try testing.expectEqual(1, length1);
    try testing.expectEqualStrings("1", &buffer1);
    try testing.expectEqual(2, c1.current);

    var buffer2: [2]u8 = undefined;
    const length2 = lib.con_reader_read(reader, &buffer2, buffer2.len);
    try testing.expectEqual(0, length2);
    try testing.expectEqual(2, c1.current);

    c2.amount_of_reads = 0; // Clear error

    // Single buffered reader never recovers
    const length3 = lib.con_reader_read(reader, &buffer2, buffer2.len);
    try testing.expectEqual(0, length3);
    try testing.expectEqual(2, c1.current);
}

test "buffer clear error large" {
    const data = "1222";
    var c1: lib.ConReaderString = undefined;
    const i1_err = lib.con_reader_string_init(&c1, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i1_err);

    var c2: lib.ConReaderFail = undefined;
    const i2_err = lib.con_reader_fail_init(&c2, lib.con_reader_string_interface(&c1), 1);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i2_err);

    var b: [2]u8 = undefined;
    var context: lib.ConReaderBuffer = undefined;
    const init_err = lib.con_reader_buffer_init(&context, lib.con_reader_fail_interface(&c2), &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const reader = lib.con_reader_buffer_interface(&context);

    var buffer1: [1]u8 = undefined;
    const length1 = lib.con_reader_read(reader, &buffer1, buffer1.len);
    try testing.expectEqual(1, length1);
    try testing.expectEqualStrings("1", &buffer1);
    try testing.expectEqual(2, c1.current);

    var buffer2: [3]u8 = undefined;
    const length2 = lib.con_reader_read(reader, &buffer2, buffer2.len);
    try testing.expectEqual(0, length2);
    try testing.expectEqual(2, c1.current);

    c2.amount_of_reads = 0; // Clear error

    // Single buffered reader never recovers
    const length3 = lib.con_reader_read(reader, &buffer2, buffer2.len);
    try testing.expectEqual(0, length3);
    try testing.expectEqual(2, c1.current);
}

test "double buffer init" {
    const data = "";
    var c: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&c, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var buffer: [4]u8 = undefined;
    var context: lib.ConReaderBuffer = undefined;
    const init_err = lib.con_reader_double_buffer_init(
        &context,
        lib.con_reader_string_interface(&c),
        &buffer,
        buffer.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
    _ = lib.con_reader_buffer_interface(&context);
}

test "double buffer init null" {
    const data = "";
    var c: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&c, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var buffer: [4]u8 = undefined;
    const init_err = lib.con_reader_double_buffer_init(
        null,
        lib.con_reader_string_interface(&c),
        &buffer,
        buffer.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_NULL), init_err);
}

test "double buffer init null buffer" {
    const data = "";
    var c: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&c, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var context: lib.ConReaderBuffer = undefined;
    const init_err = lib.con_reader_double_buffer_init(
        &context,
        lib.con_reader_string_interface(&c),
        null,
        10,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_NULL), init_err);
}

test "double buffer init small" {
    const data = "";
    var c: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&c, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var buffer: [2]u8 = undefined;
    var context: lib.ConReaderBuffer = undefined;
    const init_err = lib.con_reader_double_buffer_init(
        &context,
        lib.con_reader_string_interface(&c),
        &buffer,
        buffer.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_BUFFER), init_err);
}

test "double buffer init odd" {
    const data = "";
    var c: lib.ConReaderString = undefined;
    const i_err = lib.con_reader_string_init(&c, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i_err);

    var buffer: [5]u8 = undefined;
    var context: lib.ConReaderBuffer = undefined;
    const init_err = lib.con_reader_double_buffer_init(
        &context,
        lib.con_reader_string_interface(&c),
        &buffer,
        buffer.len,
    );
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_BUFFER), init_err);
}

test "double buffer clear error" {
    const data = "122";
    var c1: lib.ConReaderString = undefined;
    const i1_err = lib.con_reader_string_init(&c1, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i1_err);

    var c2: lib.ConReaderFail = undefined;
    const i2_err = lib.con_reader_fail_init(&c2, lib.con_reader_string_interface(&c1), 1);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i2_err);

    var b: [4]u8 = undefined;
    var context: lib.ConReaderBuffer = undefined;
    const init_err = lib.con_reader_double_buffer_init(&context, lib.con_reader_fail_interface(&c2), &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const reader = lib.con_reader_buffer_interface(&context);

    var buffer1: [1]u8 = undefined;
    const length1 = lib.con_reader_read(reader, &buffer1, buffer1.len);
    try testing.expectEqual(1, length1);
    try testing.expectEqualStrings("1", &buffer1);
    try testing.expectEqual(2, c1.current);

    var buffer2: [2]u8 = undefined;
    const length2 = lib.con_reader_read(reader, &buffer2, buffer2.len);
    try testing.expectEqual(0, length2);
    try testing.expectEqual(2, c1.current);

    c2.amount_of_reads = 0; // Clear error

    const length3 = lib.con_reader_read(reader, &buffer2, buffer2.len);
    try testing.expectEqual(2, length3);
    try testing.expectEqualStrings("22", &buffer2);
    try testing.expectEqual(3, c1.current);
}

test "double buffer clear error large" {
    const data = "1222";
    var c1: lib.ConReaderString = undefined;
    const i1_err = lib.con_reader_string_init(&c1, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i1_err);

    var c2: lib.ConReaderFail = undefined;
    const i2_err = lib.con_reader_fail_init(&c2, lib.con_reader_string_interface(&c1), 1);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), i2_err);

    var b: [4]u8 = undefined;
    var context: lib.ConReaderBuffer = undefined;
    const init_err = lib.con_reader_double_buffer_init(&context, lib.con_reader_fail_interface(&c2), &b, b.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);

    const reader = lib.con_reader_buffer_interface(&context);

    var buffer1: [1]u8 = undefined;
    const length1 = lib.con_reader_read(reader, &buffer1, buffer1.len);
    try testing.expectEqual(1, length1);
    try testing.expectEqualStrings("1", &buffer1);
    try testing.expectEqual(2, c1.current);

    var buffer2: [3]u8 = undefined;
    const length2 = lib.con_reader_read(reader, &buffer2, buffer2.len);
    try testing.expectEqual(0, length2);
    try testing.expectEqual(2, c1.current);

    c2.amount_of_reads = 0; // Clear error

    const length3 = lib.con_reader_read(reader, &buffer2, buffer2.len);
    try testing.expectEqual(3, length3);
    try testing.expectEqualStrings("222", &buffer2);
    try testing.expectEqual(4, c1.current);
}

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
