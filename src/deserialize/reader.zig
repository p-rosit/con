const std = @import("std");
const con_error = @import("../error.zig");
const con = @cImport({
    @cInclude("reader.h");
});

inline fn readData(reader: *const anyopaque, buffer: []u8) !usize {
    if (buffer.len > std.math.maxInt(c_int)) {
        return error.Overflow;
    }

    const result = con.con_reader_read(reader, buffer.ptr, @intCast(buffer.len));
    if (result <= 0) {
        return error.Reader;
    }
    return @intCast(result);
}

pub const File = struct {
    inner: con.ConReaderFile,

    pub fn init(file: *con.FILE) !File {
        var self: File = undefined;
        const err = con.con_reader_file(&self.inner, file);
        con_error.enumToError(err) catch |new_err| {
            return new_err;
        };
        return self;
    }

    pub fn read(self: *File, buffer: []u8) !usize {
        return readData(&self.inner, buffer);
    }
};

const testing = std.testing;
const builtin = @import("builtin");
const clib = @cImport({
    @cInclude("stdio.h");
});

test "file init" {
    _ = try File.init(@ptrFromInt(256));
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
            std.debug.print("TODO: allow testing file writer on this os.\n", .{});
            return;
        },
    }
    defer _ = clib.fclose(file);

    const written = clib.fputs("1", file);
    try testing.expectEqual(written, 1);

    const seek_err = clib.fseek(file, 0, clib.SEEK_SET);
    try testing.expectEqual(0, seek_err);

    var reader = try File.init(@as([*c]con.FILE, @ptrCast(file)));

    var buffer: [1]u8 = undefined;
    const result = try reader.read(&buffer);
    try testing.expectEqual(1, result);
    try testing.expectEqualStrings("1", &buffer);

    const err = reader.read(&buffer);
    try testing.expectError(error.Reader, err);
}
