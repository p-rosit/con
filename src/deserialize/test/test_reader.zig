const std = @import("std");
const builtin = @import("builtin");
const testing = @import("std").testing;
const lib = @import("../../internal.zig").lib;
const clib = @cImport({
    @cInclude("stdio.h");
});

test "file init" {
    var context: lib.ConReaderFile = undefined;
    const init_err = lib.con_reader_file_init(&context, @ptrFromInt(256));
    try testing.expectEqual(@as(c_uint, lib.CON_ERROR_OK), init_err);
}
