const std = @import("std");
const internal = @import("../internal.zig");
const lib = internal.lib;

pub const Fail = struct {
    inner: lib.ConReaderFail,

    pub fn init(reads_before_fail: usize) !Fail {
        var self: Fail = undefined;
        const err = lib.con_reader_fail_init(&self.inner, reads_before_fail);
        internal.enumToError(err) catch |new_err| {
            return new_err;
        };
        return self;
    }

    pub fn interface(self: *Fail) InterfaceReader {
        return .{ .reader = lib.con_reader_fail_interface(&self.inner) };
    }
};

pub const InterfaceReader = struct {
    reader: lib.ConInterfaceReader,

    pub fn read(reader: InterfaceReader, buffer: []u8) ![]u8 {
        if (buffer.len > std.math.maxInt(c_int)) {
            return error.Overflow;
        }
        const result = lib.con_reader_read(reader.reader, buffer.ptr, buffer.len);
        if (result.@"error") {
            return error.Reader;
        } else {
            return buffer[0..result.length];
        }
    }
};

pub fn Reader(AnyReader: type) type {
    // TODO: comptime verify AnyReader is reader
    return extern struct {
        const Self = @This();

        reader: *const AnyReader,

        pub fn init(reader: *const AnyReader) Self {
            return Self{ .reader = reader };
        }

        pub fn interface(self: *Self) InterfaceReader {
            const reader = lib.ConReaderInterface{ .context = self, .read = readCallback };
            return .{ .reader = reader };
        }

        fn readCallback(context: ?*const anyopaque, buffer: [*c]u8, buffer_size: c_int) callconv(.C) c_int {
            std.debug.assert(null != context);
            std.debug.assert(null != buffer);

            const self: *Self = @constCast(@alignCast(@ptrCast(context)));
            const r: *const AnyReader = self.reader;
            const b = @as(*[]u8, @constCast(@ptrCast(&.{ .ptr = buffer, .len = buffer_size }))).*;

            return r.read(b) catch 0;
        }
    };
}

pub const File = struct {
    inner: lib.ConReaderFile,

    pub fn init(file: *lib.FILE) !File {
        var self: File = undefined;
        const err = lib.con_reader_file_init(&self.inner, file);
        internal.enumToError(err) catch |new_err| {
            return new_err;
        };
        return self;
    }

    pub fn interface(self: *File) InterfaceReader {
        return .{ .reader = lib.con_reader_file_interface(&self.inner) };
    }
};

pub const String = struct {
    inner: lib.ConReaderString,

    pub fn init(data: []const u8) !String {
        if (data.len > std.math.maxInt(c_int)) {
            return error.Overflow;
        }

        var self: String = undefined;
        const err = lib.con_reader_string_init(
            &self.inner,
            data.ptr,
            @intCast(data.len),
        );
        internal.enumToError(err) catch |new_err| {
            return new_err;
        };
        return self;
    }

    pub fn interface(self: *String) InterfaceReader {
        return .{ .reader = lib.con_reader_string_interface(&self.inner) };
    }
};

pub const Buffer = struct {
    inner: lib.ConReaderBuffer,

    pub fn init(reader: InterfaceReader, buffer: []u8) !Buffer {
        if (buffer.len > std.math.maxInt(c_int)) {
            return error.Overflow;
        }

        var self: Buffer = undefined;
        const err = lib.con_reader_buffer_init(
            &self.inner,
            reader.reader,
            buffer.ptr,
            @intCast(buffer.len),
        );
        internal.enumToError(err) catch |new_err| {
            return new_err;
        };
        return self;
    }

    pub fn interface(self: *Buffer) InterfaceReader {
        return .{ .reader = lib.con_reader_buffer_interface(&self.inner) };
    }
};

pub const Comment = struct {
    inner: lib.ConReaderComment,

    pub fn init(reader: InterfaceReader) !Comment {
        var self: Comment = undefined;
        const err = lib.con_reader_comment_init(
            &self.inner,
            reader.reader,
        );
        internal.enumToError(err) catch |new_err| {
            return new_err;
        };
        return self;
    }

    pub fn interface(self: *Comment) InterfaceReader {
        return .{ .reader = lib.con_reader_comment_interface(&self.inner) };
    }
};

const testing = std.testing;
const builtin = @import("builtin");
const clib = @cImport({
    @cInclude("stdio.h");
});

test "fail init" {
    var context = try Fail.init(0);
    _ = context.interface();
}

test "fail fails" {
    var context = try Fail.init(1);
    const reader = context.interface();

    var buffer: [0]u8 = undefined;
    _ = try reader.read(&buffer);

    const err = reader.read(&buffer);
    try testing.expectError(error.Reader, err);
}

test "file init" {
    var context = try File.init(@ptrFromInt(256));
    _ = context.interface();
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

    var context = try File.init(@as([*c]lib.FILE, @ptrCast(file)));
    const reader = context.interface();

    var buffer: [1]u8 = undefined;
    const result = try reader.read(&buffer);
    try testing.expectEqualStrings("1", result);

    const empty = try reader.read(&buffer);
    try testing.expectEqualStrings("", empty);
}

test "string init" {
    var data: [1]u8 = undefined;
    var context = try String.init(&data);
    _ = context.interface();
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
    const data = "zig";
    var context = try String.init(data);
    const reader = context.interface();

    var buffer: [3]u8 = undefined;
    const result = try reader.read(&buffer);
    try testing.expectEqualStrings("zig", result);
}

test "string read overflow" {
    const data = "z";
    var context = try String.init(data);
    const reader = context.interface();

    var buffer: [2]u8 = undefined;
    const result = try reader.read(&buffer);
    try testing.expectEqualStrings("z", result);

    const empty = try reader.read(&buffer);
    try testing.expectEqualStrings("", empty);
}

test "buffer init" {
    const d = "data";
    var c = try String.init(d);

    var buffer: [2]u8 = undefined;
    var context = try Buffer.init(c.interface(), &buffer);
    _ = context.interface();
}

test "buffer init buffer small" {
    const d = "data";
    var c = try String.init(d);

    var buffer: [1]u8 = undefined;
    const err = Buffer.init(c.interface(), &buffer);
    try testing.expectError(error.Buffer, err);
}

test "buffer init overflow" {
    var fake_large_buffer = try testing.allocator.alloc(u8, 2);
    fake_large_buffer.len = @as(usize, @intCast(std.math.maxInt(c_int))) + 1;
    defer {
        fake_large_buffer.len = 2;
        testing.allocator.free(fake_large_buffer);
    }

    const d = "data";
    var c = try String.init(d);

    const err = Buffer.init(c.interface(), fake_large_buffer);
    try testing.expectError(error.Overflow, err);
}

test "buffer read" {
    const d = "data";
    var c = try String.init(d);

    var buffer: [3]u8 = undefined;
    var context = try Buffer.init(c.interface(), &buffer);
    const reader = context.interface();

    var result_buffer: [2]u8 = undefined;
    const result = try reader.read(&result_buffer);
    try testing.expectEqualStrings("da", result);
}

test "buffer read buffer twice" {
    const d = "data";
    var c = try String.init(d);

    var buffer: [3]u8 = undefined;
    var context = try Buffer.init(c.interface(), &buffer);
    const reader = context.interface();

    var result_buffer: [5]u8 = undefined;
    const result = try reader.read(&result_buffer);
    try testing.expectEqualStrings("data", result);
}

test "buffer internal reader empty" {
    const d = "";
    var c = try String.init(d);

    var buffer: [3]u8 = undefined;
    var context = try Buffer.init(c.interface(), &buffer);
    const reader = context.interface();

    var result_buffer: [4]u8 = undefined;
    const result = try reader.read(&result_buffer);
    try testing.expectEqualStrings("", result);
}

test "buffer internal reader fail" {
    var c = try Fail.init(0);

    var buffer: [3]u8 = undefined;
    var context = try Buffer.init(c.interface(), &buffer);
    const reader = context.interface();

    var result_buffer: [2]u8 = undefined;
    const err = reader.read(&result_buffer);
    try testing.expectError(error.Reader, err);
}

test "buffer internal reader large fail" {
    var c = try Fail.init(0);

    var buffer: [3]u8 = undefined;
    var context = try Buffer.init(c.interface(), &buffer);
    const reader = context.interface();

    var result_buffer: [10]u8 = undefined;
    const err = reader.read(&result_buffer);
    try testing.expectError(error.Reader, err);
}

test "comment init" {
    const d = "";
    var c = try String.init(d);

    var context = try Comment.init(c.interface());
    _ = context.interface();
}

test "comment read" {
    const d = "12";
    var c = try String.init(d);

    var context = try Comment.init(c.interface());
    const reader = context.interface();

    var buffer: [2]u8 = undefined;
    const result = try reader.read(&buffer);
    try testing.expectEqualStrings("12", result);
}

test "comment read comment" {
    const d = "[  //:(\n \"k //:)\",1/]";
    var c = try String.init(d);

    var context = try Comment.init(c.interface());
    const reader = context.interface();

    var buffer: [17]u8 = undefined;
    const result = try reader.read(&buffer);
    try testing.expectEqualStrings("[  \n \"k //:)\",1/]", result);
}

test "comment read comment one char at a time" {
    const d = "[  //:(\n \"k //:)\",1/]";
    var c = try String.init(d);

    var context = try Comment.init(c.interface());
    const reader = context.interface();

    var buffer: [17]u8 = undefined;
    for (0..17) |i| {
        const result = try reader.read(buffer[i .. i + 1]);
        try testing.expectEqual(1, result.len);
    }

    try testing.expectEqualStrings("[  \n \"k //:)\",1/]", &buffer);
}

test "comment inner reader empty" {
    const d = "";
    var c = try String.init(d);

    var context = try Comment.init(c.interface());
    const reader = context.interface();

    var buffer: [1]u8 = undefined;
    const result = try reader.read(&buffer);
    try testing.expectEqualStrings("", result);
}

test "comment inner reader empty comment" {
    const d = "/";
    var c = try String.init(d);

    var context = try Comment.init(c.interface());
    const reader = context.interface();

    var buffer: [1]u8 = undefined;
    const result = try reader.read(&buffer);
    try testing.expectEqualStrings("/", result);
}

test "comment inner reader fail" {
    var c = try Fail.init(0);

    var context = try Comment.init(c.interface());
    const reader = context.interface();

    var buffer: [1]u8 = undefined;
    const err = reader.read(&buffer);
    try testing.expectError(error.Reader, err);
}

test "comment read only comment" {
    const d = "// only a comment";
    var c = try String.init(d);

    var context = try Comment.init(c.interface());
    const reader = context.interface();

    var buffer: [3]u8 = undefined;
    const result = try reader.read(&buffer);
    try testing.expectEqualStrings("", result);
}
