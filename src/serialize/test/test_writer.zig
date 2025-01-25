const std = @import("std");
const builtin = @import("builtin");
const testing = @import("std").testing;
const clib = @cImport({
    @cInclude("stdio.h");
});
const con = @cImport({
    @cInclude("serialize.h");
    @cInclude("serialize_writer.h");
});

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

    const err = con.con_serialize_writer_file_write(file, "1");
    try testing.expect(0 <= err);

    const seek_err = clib.fseek(file, 0, con.SEEK_SET);
    try testing.expectEqual(seek_err, 0);

    var buffer: [1:0]u8 = undefined;
    const result = clib.fread(&buffer, 1, 2, file);
    try testing.expectEqual(1, result);

    buffer[buffer.len] = 0;
    try testing.expectEqualStrings("1", &buffer);
}

test "string init" {
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const init_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);
}

test "string init null" {
    var buffer: [1:0]u8 = undefined;
    const init_err = con.con_serialize_writer_string(null, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

test "string buffer null" {
    var writer: con.ConWriterString = undefined;
    const init_err = con.con_serialize_writer_string(&writer, null, 2);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

test "string length negative" {
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const init_err = con.con_serialize_writer_string(&writer, &buffer, -1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_BUFFER), init_err);
}

test "string buffer small" {
    var buffer: [0:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const init_err = con.con_serialize_writer_string(&writer, &buffer, 0);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_BUFFER), init_err);
}

test "string write" {
    var buffer: [3:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;

    const init_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const write_err = con.con_serialize_writer_string_write(&writer, "12");
    try testing.expect(0 <= write_err);
    try testing.expectEqualStrings("12\x00", &buffer);
}

test "string overflow" {
    var buffer: [0:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;

    const init_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const write_err = con.con_serialize_writer_string_write(&writer, "1");
    try testing.expectEqual(con.EOF, write_err);
}

test "buffer init" {
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterBuffer = undefined;
    const init_err = con.con_serialize_writer_buffer(
        &writer,
        null,
        con.con_serialize_writer_string_write,
        &buffer,
        buffer.len + 1,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);
}

test "buffer init null" {
    var buffer: [1:0]u8 = undefined;
    const init_err = con.con_serialize_writer_buffer(
        null,
        null,
        con.con_serialize_writer_string_write,
        &buffer,
        buffer.len + 1,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

test "buffer init write null" {
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterBuffer = undefined;
    const init_err = con.con_serialize_writer_buffer(
        &writer,
        null,
        null,
        &buffer,
        buffer.len + 1,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

test "buffer init buffer null" {
    var writer: con.ConWriterBuffer = undefined;
    const init_err = con.con_serialize_writer_buffer(
        &writer,
        null,
        con.con_serialize_writer_string_write,
        null,
        2,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

test "buffer init length negative" {
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterBuffer = undefined;
    const init_err = con.con_serialize_writer_buffer(
        &writer,
        null,
        con.con_serialize_writer_string_write,
        &buffer,
        -1,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_BUFFER), init_err);
}

test "buffer init buffer small" {
    var buffer: [0:0]u8 = undefined;
    var writer: con.ConWriterBuffer = undefined;
    const init_err = con.con_serialize_writer_buffer(
        &writer,
        null,
        con.con_serialize_writer_string_write,
        &buffer,
        buffer.len + 1,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_BUFFER), init_err);
}

test "buffer write" {
    var b: [1:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterBuffer = undefined;
    const init_err = con.con_serialize_writer_buffer(
        &writer,
        &w,
        con.con_serialize_writer_string_write,
        &buffer,
        buffer.len + 1,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const err = con.con_serialize_writer_buffer_write(&writer, "1");
    try testing.expect(0 <= err);
    try testing.expectEqualStrings("1", &b);
}

test "buffer flush" {
    var b: [1:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var buffer: [2:0]u8 = undefined;
    var writer: con.ConWriterBuffer = undefined;
    const init_err = con.con_serialize_writer_buffer(
        &writer,
        &w,
        con.con_serialize_writer_string_write,
        &buffer,
        buffer.len + 1,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const err = con.con_serialize_writer_buffer_write(&writer, "1");
    try testing.expect(0 <= err);

    const flush_err = con.con_serialize_writer_buffer_flush(&writer);
    try testing.expect(0 <= flush_err);
    try testing.expectEqualStrings("1", &b);
}

test "buffer internal writer fail" {
    var b: [0:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterBuffer = undefined;
    const init_err = con.con_serialize_writer_buffer(
        &writer,
        &w,
        con.con_serialize_writer_string_write,
        &buffer,
        buffer.len + 1,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const err = con.con_serialize_writer_buffer_write(&writer, "1");
    try testing.expectEqual(con.EOF, err);
}

test "buffer flush writer fail" {
    var b: [0:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var buffer: [2:0]u8 = undefined;
    var writer: con.ConWriterBuffer = undefined;
    const init_err = con.con_serialize_writer_buffer(
        &writer,
        &w,
        con.con_serialize_writer_string_write,
        &buffer,
        buffer.len + 1,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const err = con.con_serialize_writer_buffer_write(&writer, "1");
    try testing.expect(0 <= err);

    const flush_err = con.con_serialize_writer_buffer_flush(&writer);
    try testing.expectEqual(con.EOF, flush_err);
}

test "indent init" {
    var writer: con.ConWriterIndent = undefined;
    const init_err = con.con_serialize_writer_indent(&writer, null, con.con_serialize_writer_string_write);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);
}

test "indent init write null" {
    var writer: con.ConWriterIndent = undefined;
    const init_err = con.con_serialize_writer_indent(&writer, null, null);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

test "indent write" {
    var b: [1:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var writer: con.ConWriterIndent = undefined;
    const init_err = con.con_serialize_writer_indent(&writer, &w, con.con_serialize_writer_string_write);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const err = con.con_serialize_writer_indent_write(&writer, "1");
    try testing.expect(0 <= err);
    try testing.expectEqualStrings("1", &b);
}

test "indent write minified" {
    var b: [56:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var writer: con.ConWriterIndent = undefined;
    const init_err = con.con_serialize_writer_indent(&writer, &w, con.con_serialize_writer_string_write);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const err = con.con_serialize_writer_indent_write(&writer, "[{\"k\":\":)\"},null,\"\\\"{1,2,3} [1,2,3]\"]");
    try testing.expect(0 <= err);
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
    var b: [56:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var writer: con.ConWriterIndent = undefined;
    const init_err = con.con_serialize_writer_indent(&writer, &w, con.con_serialize_writer_string_write);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const str = "[{\"k\":\":)\"},null,\"\\\"{1,2,3} [1,2,3]\"]";

    for (str) |c| {
        const single: [1:0]u8 = .{c};
        const err = con.con_serialize_writer_indent_write(&writer, &single);
        try testing.expect(0 <= err);
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
    var b: [0:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var writer: con.ConWriterIndent = undefined;
    const init_err = con.con_serialize_writer_indent(&writer, &w, con.con_serialize_writer_string_write);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const err = con.con_serialize_writer_indent_write(&writer, "1");
    try testing.expectEqual(con.EOF, err);
}

test "indent newline array open writer fail" {
    var b: [1:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var writer: con.ConWriterIndent = undefined;
    const init_err = con.con_serialize_writer_indent(&writer, &w, con.con_serialize_writer_string_write);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const err = con.con_serialize_writer_indent_write(&writer, "[1]");
    try testing.expectEqual(con.EOF, err);
    try testing.expectEqualStrings("[", &b);
}

test "indent whitespace array open writer fail" {
    var b: [2:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var writer: con.ConWriterIndent = undefined;
    const init_err = con.con_serialize_writer_indent(&writer, &w, con.con_serialize_writer_string_write);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const err = con.con_serialize_writer_indent_write(&writer, "[1]");
    try testing.expectEqual(con.EOF, err);
    try testing.expectEqualStrings("[\n", &b);
}

test "indent newline array close writer fail" {
    var b: [5:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var writer: con.ConWriterIndent = undefined;
    const init_err = con.con_serialize_writer_indent(&writer, &w, con.con_serialize_writer_string_write);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const err = con.con_serialize_writer_indent_write(&writer, "[1]");
    try testing.expectEqual(con.EOF, err);
    try testing.expectEqualStrings("[\n  1", &b);
}

test "indent whitespace array close writer fail" {
    var b: [6:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var writer: con.ConWriterIndent = undefined;
    const init_err = con.con_serialize_writer_indent(&writer, &w, con.con_serialize_writer_string_write);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const err = con.con_serialize_writer_indent_write(&writer, "[1]");
    try testing.expectEqual(con.EOF, err);
    try testing.expectEqualStrings("[\n  1\n", &b);
}

test "indent newline dict writer fail" {
    var b: [1:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var writer: con.ConWriterIndent = undefined;
    const init_err = con.con_serialize_writer_indent(&writer, &w, con.con_serialize_writer_string_write);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const err = con.con_serialize_writer_indent_write(&writer, "{\"");
    try testing.expectEqual(con.EOF, err);
    try testing.expectEqualStrings("{", &b);
}

test "indent whitespace dict writer fail" {
    var b: [2:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var writer: con.ConWriterIndent = undefined;
    const init_err = con.con_serialize_writer_indent(&writer, &w, con.con_serialize_writer_string_write);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const err = con.con_serialize_writer_indent_write(&writer, "{\"");
    try testing.expectEqual(con.EOF, err);
    try testing.expectEqualStrings("{\n", &b);
}

test "indent newline dict close writer fail" {
    var b: [10:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var writer: con.ConWriterIndent = undefined;
    const init_err = con.con_serialize_writer_indent(&writer, &w, con.con_serialize_writer_string_write);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const err = con.con_serialize_writer_indent_write(&writer, "{\"k\":1}");
    try testing.expectEqual(con.EOF, err);
    try testing.expectEqualStrings("{\n  \"k\": 1", &b);
}

test "indent whitespace dict close writer fail" {
    var b: [11:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var writer: con.ConWriterIndent = undefined;
    const init_err = con.con_serialize_writer_indent(&writer, &w, con.con_serialize_writer_string_write);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const err = con.con_serialize_writer_indent_write(&writer, "{\"k\":1}");
    try testing.expectEqual(con.EOF, err);
    try testing.expectEqualStrings("{\n  \"k\": 1\n", &b);
}

test "indent space writer fail" {
    var b: [8:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var writer: con.ConWriterIndent = undefined;
    const init_err = con.con_serialize_writer_indent(&writer, &w, con.con_serialize_writer_string_write);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const err = con.con_serialize_writer_indent_write(&writer, "{\"k\":");
    try testing.expectEqual(con.EOF, err);
    try testing.expectEqualStrings("{\n  \"k\":", &b);
}

test "indent newline comma writer fail" {
    var b: [6:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var writer: con.ConWriterIndent = undefined;
    const init_err = con.con_serialize_writer_indent(&writer, &w, con.con_serialize_writer_string_write);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const err = con.con_serialize_writer_indent_write(&writer, "[1,2]");
    try testing.expectEqual(con.EOF, err);
    try testing.expectEqualStrings("[\n  1,", &b);
}

test "indent whitespace comma writer fail" {
    var b: [7:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var writer: con.ConWriterIndent = undefined;
    const init_err = con.con_serialize_writer_indent(&writer, &w, con.con_serialize_writer_string_write);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const err = con.con_serialize_writer_indent_write(&writer, "[1,2]");
    try testing.expectEqual(con.EOF, err);
    try testing.expectEqualStrings("[\n  1,\n", &b);
}
