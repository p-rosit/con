const std = @import("std");
const con_error = @import("../error.zig");
const con = @cImport({
    @cInclude("reader.h");
});

inline fn readData(reader: *const anyopaque, buffer: [:0]u8) !usize {
    if (buffer.len > std.math.maxInt(c_int) - 1) {
        return error.Overflow;
    }

    const result = con.con_reader_read(reader, buffer.ptr, @as(c_int, @intCast(buffer.len)) + 1);
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

    pub fn read(self: *File, buffer: [:0]u8) !usize {
        return readData(&self.inner, buffer);
    }
};

pub const String = struct {
    inner: con.ConReaderString,

    pub fn init(data: []const u8) !String {
        if (data.len > std.math.maxInt(c_int)) {
            return error.Overflow;
        }

        var self: String = undefined;
        const err = con.con_reader_string(
            &self.inner,
            data.ptr,
            @intCast(data.len),
        );
        con_error.enumToError(err) catch |new_err| {
            return new_err;
        };
        return self;
    }

    pub fn read(self: *String, buffer: [:0]u8) !usize {
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

    var buffer: [1:0]u8 = undefined;
    const result = try reader.read(&buffer);
    try testing.expectEqual(1, result);
    try testing.expectEqualStrings("1", &buffer);

    const err = reader.read(&buffer);
    try testing.expectError(error.Reader, err);
}

test "string init" {
    var data: [1]u8 = undefined;
    _ = try String.init(&data);
}

test "string init overflow" {
    const data = try testing.allocator.alloc(u8, 2);
    defer testing.allocator.free(data);

    const fake_large_data: []u8 = @as(*[]u8, @alignCast(@ptrCast(@constCast(&.{
        .ptr = &data,
        .len = @as(usize, std.math.maxInt(c_int)) + 1,
    })))).*;

    const err = String.init(fake_large_data);
    try testing.expectError(error.Overflow, err);
}

test "string read" {
    const data: *const [3]u8 = "zig";
    var reader = try String.init(data);

    var buffer: [3:0]u8 = undefined;
    const amount_read = try reader.read(&buffer);
    try testing.expectEqual(3, amount_read);
    try testing.expectEqualStrings("zig", &buffer);
}

test "string read overflow" {
    const data: *const [1]u8 = "z";
    var reader = try String.init(data);

    var buffer: [2:0]u8 = undefined;
    const amount_read = try reader.read(&buffer);
    try testing.expectEqual(1, amount_read);
    try testing.expectEqualStrings("z\x00", &buffer);

    const err = reader.read(&buffer);
    try testing.expectError(error.Reader, err);
}
