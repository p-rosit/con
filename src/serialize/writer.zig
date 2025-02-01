const std = @import("std");
const con_error = @import("../error.zig");
const con = @cImport({
    @cInclude("writer.h");
});

inline fn writeData(writer: *const anyopaque, data: [:0]const u8) !void {
    const result = con.con_writer_write(writer, data);
    if (result <= 0) {
        return error.Writer;
    }
}

pub fn Writer(AnyWriter: type) type {
    // TODO: comptime verify AnyWriter is writer
    return extern struct {
        const Self = @This();

        callback: con.ConWriter = .{ .write = writeCallback },
        writer: *const AnyWriter,

        pub fn init(writer: *const AnyWriter) Self {
            return Self{ .writer = writer };
        }

        pub fn write(writer: *Self, data: [:0]const u8) !void {
            return writeData(writer, data);
        }

        fn writeCallback(context: ?*const anyopaque, data: [*c]const u8) callconv(.C) c_int {
            std.debug.assert(null != context);
            std.debug.assert(null != data);

            const self: *Self = @constCast(@alignCast(@ptrCast(context)));
            const w: *const AnyWriter = self.writer;
            const d = std.mem.span(data);
            const result = w.write(d) catch 0;

            if (result > 0) {
                return 1;
            } else {
                return con.EOF;
            }
        }
    };
}

pub const File = struct {
    inner: con.ConWriterFile,

    pub fn init(file: *con.FILE) !File {
        var self: File = undefined;
        const err = con.con_writer_file(&self.inner, file);
        con_error.enumToError(err) catch |new_err| {
            return new_err;
        };
        return self;
    }

    pub fn write(self: *File, data: [:0]const u8) !void {
        return writeData(&self.inner, data);
    }
};

pub const String = struct {
    inner: con.ConWriterString,

    pub fn init(buffer: [:0]u8) !String {
        if (buffer.len > std.math.maxInt(c_int)) {
            return error.Overflow;
        }

        var self: String = undefined;
        const err = con.con_writer_string(
            &self.inner,
            buffer.ptr,
            @intCast(buffer.len + 1),
        );
        con_error.enumToError(err) catch |new_err| {
            return new_err;
        };
        return self;
    }

    pub fn write(self: *String, data: [:0]const u8) !void {
        return writeData(&self.inner, data);
    }
};

pub const Buffer = struct {
    inner: con.ConWriterBuffer,

    pub fn init(writer: *const anyopaque, buffer: [:0]u8) !Buffer {
        if (buffer.len >= std.math.maxInt(c_int)) {
            return error.Overflow;
        }

        var self: Buffer = undefined;
        const err = con.con_writer_buffer(
            &self.inner,
            writer,
            buffer.ptr,
            @intCast(buffer.len + 1),
        );
        con_error.enumToError(err) catch |new_err| {
            return new_err;
        };

        return self;
    }

    pub fn write(self: *Buffer, data: [:0]const u8) !void {
        return writeData(&self.inner, data);
    }

    pub fn flush(self: *Buffer) !void {
        const result = con.con_writer_buffer_flush(&self.inner);
        if (result <= 0) {
            return error.Writer;
        }
    }
};

pub const Indent = struct {
    inner: con.ConWriterIndent,

    pub fn init(writer: *const anyopaque) !Indent {
        var self: Indent = undefined;
        const err = con.con_writer_indent(&self.inner, writer);
        con_error.enumToError(err) catch |new_err| {
            return new_err;
        };
        return self;
    }

    pub fn write(self: *Indent, data: [:0]const u8) !void {
        return writeData(&self.inner, data);
    }
};

const testing = std.testing;
const builtin = @import("builtin");
const clib = @cImport({
    @cInclude("stdio.h");
});

test "zig writer" {
    const Fifo = std.fifo.LinearFifo(u8, .Slice);
    const FifoWriter = Writer(Fifo.Writer);

    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);

    var writer = FifoWriter.init(&fifo.writer());

    try writer.write("1");
    try testing.expectEqualStrings("1", &buffer);
}

test "file init" {
    _ = try File.init(@ptrFromInt(256));
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

    var writer = try File.init(@as([*c]con.FILE, @ptrCast(file)));

    try writer.write("1");

    const seek_err = clib.fseek(file, 0, con.SEEK_SET);
    try testing.expectEqual(seek_err, 0);

    var buffer: [1:0]u8 = undefined;
    const result = clib.fread(&buffer, 1, 2, file);
    try testing.expectEqual(1, result);

    buffer[buffer.len] = 0;
    try testing.expectEqualStrings("1", &buffer);
}

test "string init" {
    var buffer: [0:0]u8 = undefined;
    _ = try String.init(&buffer);
}

test "string init overflow" {
    const buffer = try testing.allocator.alloc(u8, 2);
    defer testing.allocator.free(buffer);

    const fake_large_buffer: [:0]u8 = @as(*[:0]u8, @alignCast(@ptrCast(@constCast(&.{
        .ptr = &buffer,
        .len = @as(usize, std.math.maxInt(c_int)) + 1,
    })))).*;

    const err = String.init(fake_large_buffer);
    try testing.expectError(error.Overflow, err);
}

test "string write" {
    var buffer: [3:0]u8 = undefined;
    var writer = try String.init(&buffer);

    try writer.write("12");
    try testing.expectEqualStrings("12\x00", &buffer);
}

test "string overflow" {
    var buffer: [0:0]u8 = undefined;
    var writer = try String.init(&buffer);

    const err = writer.write("1");
    try testing.expectError(error.Writer, err);
}

test "buffer init" {
    var b: [3:0]u8 = undefined;
    var w = try String.init(&b);

    var buffer: [1:0]u8 = undefined;
    _ = try Buffer.init(&w, &buffer);
}

test "buffer init buffer small" {
    var b: [3:0]u8 = undefined;
    var w = try String.init(&b);

    var buffer: [0:0]u8 = undefined;
    const err = Buffer.init(&w, &buffer);
    try testing.expectError(error.Buffer, err);
}

test "buffer write" {
    var b: [1:0]u8 = undefined;
    var w = try String.init(&b);

    var buffer: [1:0]u8 = undefined;
    var writer = try Buffer.init(&w, &buffer);

    try writer.write("1");
    try testing.expectEqualStrings("1", &b);
}

test "buffer flush" {
    var b: [1:0]u8 = undefined;
    var w = try String.init(&b);

    var buffer: [2:0]u8 = undefined;
    var writer = try Buffer.init(&w, &buffer);

    try writer.write("1");

    try writer.flush();
    try testing.expectEqualStrings("1", &b);
}

test "buffer internal writer fail" {
    var b: [0:0]u8 = undefined;
    var w = try String.init(&b);

    var buffer: [1:0]u8 = undefined;
    var writer = try Buffer.init(&w, &buffer);

    const err = writer.write("1");
    try testing.expectError(error.Writer, err);
}

test "buffer flush writer fail" {
    var b: [0:0]u8 = undefined;
    var w = try String.init(&b);

    var buffer: [2:0]u8 = undefined;
    var writer = try Buffer.init(&w, &buffer);

    try writer.write("1");

    const err = writer.flush();
    try testing.expectError(error.Writer, err);
}

test "indent init" {
    var b: [0:0]u8 = undefined;
    var w = try String.init(&b);
    _ = try Indent.init(&w);
}

test "indent write" {
    var b: [1:0]u8 = undefined;
    var w = try String.init(&b);
    var writer = try Indent.init(&w);

    try writer.write("1");
    try testing.expectEqualStrings("1", &b);
}

test "indent write minified" {
    var b: [56:0]u8 = undefined;
    var w = try String.init(&b);
    var writer = try Indent.init(&w);

    try writer.write("[{\"k\":\":)\"},null,\"\\\"{1,2,3} [1,2,3]\"]");
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
    var w = try String.init(&b);
    var writer = try Indent.init(&w);

    const str = "[{\"k\":\":)\"},null,\"\\\"{1,2,3} [1,2,3]\"]";

    for (str) |c| {
        const single: [1:0]u8 = .{c};
        try writer.write(&single);
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
    var w = try String.init(&b);
    var writer = try Indent.init(&w);

    const err = writer.write("1");
    try testing.expectError(error.Writer, err);
}

test "indent newline array open writer fail" {
    var b: [1:0]u8 = undefined;
    var w = try String.init(&b);
    var writer = try Indent.init(&w);

    const err = writer.write("[1]");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("[", &b);
}

test "indent whitespace array open writer fail" {
    var b: [2:0]u8 = undefined;
    var w = try String.init(&b);
    var writer = try Indent.init(&w);

    const err = writer.write("[1]");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("[\n", &b);
}

test "indent newline array close writer fail" {
    var b: [5:0]u8 = undefined;
    var w = try String.init(&b);
    var writer = try Indent.init(&w);

    const err = writer.write("[1]");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("[\n  1", &b);
}

test "indent whitespace array close writer fail" {
    var b: [6:0]u8 = undefined;
    var w = try String.init(&b);
    var writer = try Indent.init(&w);

    const err = writer.write("[1]");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("[\n  1\n", &b);
}

test "indent newline dict writer fail" {
    var b: [1:0]u8 = undefined;
    var w = try String.init(&b);
    var writer = try Indent.init(&w);

    const err = writer.write("{\"");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("{", &b);
}

test "indent whitespace dict writer fail" {
    var b: [2:0]u8 = undefined;
    var w = try String.init(&b);
    var writer = try Indent.init(&w);

    const err = writer.write("{\"");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("{\n", &b);
}

test "indent newline dict close writer fail" {
    var b: [10:0]u8 = undefined;
    var w = try String.init(&b);
    var writer = try Indent.init(&w);

    const err = writer.write("{\"k\":1}");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("{\n  \"k\": 1", &b);
}

test "indent whitespace dict close writer fail" {
    var b: [11:0]u8 = undefined;
    var w = try String.init(&b);
    var writer = try Indent.init(&w);

    const err = writer.write("{\"k\":1}");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("{\n  \"k\": 1\n", &b);
}

test "indent space writer fail" {
    var b: [8:0]u8 = undefined;
    var w = try String.init(&b);
    var writer = try Indent.init(&w);

    const err = writer.write("{\"k\":1}");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("{\n  \"k\":", &b);
}

test "indent newline comma writer fail" {
    var b: [6:0]u8 = undefined;
    var w = try String.init(&b);
    var writer = try Indent.init(&w);

    const err = writer.write("[1,2]");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("[\n  1,", &b);
}

test "indent whitespace comma writer fail" {
    var b: [7:0]u8 = undefined;
    var w = try String.init(&b);
    var writer = try Indent.init(&w);

    const err = writer.write("[1,2]");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("[\n  1,\n", &b);
}
