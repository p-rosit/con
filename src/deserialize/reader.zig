const std = @import("std");
const con_error = @import("../error.zig");
const con = @cImport({
    @cInclude("reader.h");
});

inline fn readData(reader: *const anyopaque, buffer: []u8) !usize {
    if (buffer.len > std.math.maxInt(c_int)) {
        return error.Overflow;
    }

    const result = con.con_reader_read(reader, buffer.ptr, @as(c_int, @intCast(buffer.len)));
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

    pub fn read(self: *String, buffer: []u8) !usize {
        return readData(&self.inner, buffer);
    }
};

pub const Buffer = struct {
    inner: con.ConReaderBuffer,

    pub fn init(reader: *const anyopaque, buffer: []u8) !Buffer {
        if (buffer.len > std.math.maxInt(c_int)) {
            return error.Overflow;
        }

        var self: Buffer = undefined;
        const err = con.con_reader_buffer(
            &self.inner,
            reader,
            buffer.ptr,
            @intCast(buffer.len),
        );
        con_error.enumToError(err) catch |new_err| {
            return new_err;
        };
        return self;
    }

    pub fn read(self: *Buffer, buffer: []u8) !usize {
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
            std.debug.print("TODO: allow testing file reader on this os.\n", .{});
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

test "string init" {
    var data: [1]u8 = undefined;
    _ = try String.init(&data);
}

test "string init overflow" {
    var fake_large_data = try testing.allocator.alloc(u8, 2);
    fake_large_data.len = @as(usize, std.math.maxInt(c_int)) + 1;
    defer {
        fake_large_data.len = 2;
        testing.allocator.free(fake_large_data);
    }

    const err = String.init(fake_large_data);
    try testing.expectError(error.Overflow, err);
}

test "string read" {
    const data: *const [3]u8 = "zig";
    var reader = try String.init(data);

    var buffer: [3]u8 = undefined;
    const amount_read = try reader.read(&buffer);
    try testing.expectEqual(3, amount_read);
    try testing.expectEqualStrings("zig", &buffer);
}

test "string read overflow" {
    const data: *const [1]u8 = "z";
    var reader = try String.init(data);

    var buffer: [2]u8 = undefined;
    const amount_read = try reader.read(&buffer);
    try testing.expectEqual(1, amount_read);
    try testing.expectEqualStrings("z", buffer[0..1]);

    const err = reader.read(&buffer);
    try testing.expectError(error.Reader, err);
}

test "buffer init" {
    const d: *const [4]u8 = "data";
    var r = try String.init(d);

    var buffer: [2]u8 = undefined;
    _ = try Buffer.init(&r, &buffer);
}

test "buffer init buffer small" {
    const d: *const [4]u8 = "data";
    var r = try String.init(d);

    var buffer: [1]u8 = undefined;
    const err = Buffer.init(&r, &buffer);
    try testing.expectError(error.Buffer, err);
}

test "buffer init overflow" {
    var fake_large_buffer = try testing.allocator.alloc(u8, 2);
    fake_large_buffer.len = @as(usize, @intCast(std.math.maxInt(c_int))) + 1;
    defer {
        fake_large_buffer.len = 2;
        testing.allocator.free(fake_large_buffer);
    }

    const d: *const [4]u8 = "data";
    var r = try String.init(d);

    const err = Buffer.init(&r, fake_large_buffer);
    try testing.expectError(error.Overflow, err);
}

test "buffer read" {
    const d: *const [4]u8 = "data";
    var r = try String.init(d);

    var buffer: [3]u8 = undefined;
    var reader = try Buffer.init(&r, &buffer);

    var result: [2]u8 = undefined;
    const amount_read = try reader.read(&result);
    try testing.expectEqual(2, amount_read);
    try testing.expectEqualStrings("da", &result);
}

test "buffer read buffer twice" {
    const d: *const [4]u8 = "data";
    var r = try String.init(d);

    var buffer: [3]u8 = undefined;
    var reader = try Buffer.init(&r, &buffer);

    var result: [5]u8 = undefined;
    const amount_read = try reader.read(&result);
    try testing.expectEqual(4, amount_read);
    try testing.expectEqualStrings("data", result[0..4]);
}

test "buffer internal reader fail" {
    const d: *const [0]u8 = "";
    var r = try String.init(d);

    var buffer: [3]u8 = undefined;
    var reader = try Buffer.init(&r, &buffer);

    var result: [4]u8 = undefined;
    const err = reader.read(&result);
    try testing.expectError(error.Reader, err);
}
