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
    const result = lib.con_reader_read(reader, &buffer, buffer.len);
    try testing.expect(!result.@"error");
    try testing.expectEqual(1, result.length);
    try testing.expectEqualStrings("1", buffer[0..1]);

    const err = lib.con_reader_read(reader, &buffer, buffer.len);
    try testing.expect(err.@"error");
    try testing.expectEqual(1, err.length);
    try testing.expectEqualStrings("2", buffer[0..1]);
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
    const result = lib.con_reader_read(reader, &buffer, buffer.len);
    try testing.expect(!result.@"error");
    try testing.expectEqual(1, result.length);
    try testing.expectEqualStrings("1", &buffer);

    const empty = lib.con_reader_read(reader, &buffer, buffer.len);
    try testing.expect(!empty.@"error");
    try testing.expectEqual(0, empty.length);
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
    const result = lib.con_reader_read(reader, &buffer, buffer.len);
    try testing.expect(!result.@"error");
    try testing.expectEqual(3, result.length);
    try testing.expectEqualStrings("zig", &buffer);
}

test "string read overflow" {
    const data = "z";
    var context: lib.ConReaderString = undefined;
    const init_err = lib.con_reader_string_init(&context, data, data.len);
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
    const reader = lib.con_reader_string_interface(&context);

    var buffer: [2]u8 = undefined;
    const result = lib.con_reader_read(reader, &buffer, buffer.len);
    try testing.expect(!result.@"error");
    try testing.expectEqual(1, result.length);
    try testing.expectEqualStrings("z", buffer[0..1]);

    const empty = lib.con_reader_read(reader, &buffer, buffer.len);
    try testing.expect(!empty.@"error");
    try testing.expectEqual(0, empty.length);
}
