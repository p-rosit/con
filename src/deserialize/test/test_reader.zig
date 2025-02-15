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
    try testing.expectEqual(0, err.length);
}

test "file init" {
    var context: lib.ConReaderFile = undefined;
    const init_err = lib.con_reader_file_init(&context, @ptrFromInt(256));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
}
