const std = @import("std");
const internal = @import("../internal.zig");
const lib = internal.lib;

pub const InterfaceWriter = struct {
    writer: lib.ConInterfaceWriter,

    pub fn write(writer: InterfaceWriter, data: []const u8) !void {
        const result = lib.con_writer_write(writer.writer, data.ptr, data.len);
        if (result != data.len) {
            return error.Writer;
        }
    }
};

inline fn writeData(writer: *const anyopaque, data: []const u8) !void {
    const result = lib.con_writer_write(writer, data);
    if (result != data.len) {
        return error.Writer;
    }
}

pub fn Writer(AnyWriter: type) type {
    // TODO: comptime verify AnyWriter is writer
    return extern struct {
        const Self = @This();

        writer: *const AnyWriter,

        pub fn init(writer: *const AnyWriter) Self {
            return Self{ .writer = writer };
        }

        pub fn interface(self: *Self) InterfaceWriter {
            const writer = lib.ConInterfaceWriter{ .context = self, .write = writeCallback };
            return .{ .writer = writer };
        }

        fn writeCallback(context: ?*const anyopaque, data: [*c]const u8, data_size: usize) callconv(.C) usize {
            std.debug.assert(null != context);
            std.debug.assert(null != data);

            const self: *Self = @constCast(@alignCast(@ptrCast(context)));
            const w: *const AnyWriter = self.writer;
            const d = @as(*[]u8, @constCast(@ptrCast(&.{ .ptr = data, .len = data_size }))).*;
            return w.write(d) catch 0;
        }
    };
}

pub const File = struct {
    inner: lib.ConWriterFile,

    pub fn init(file: *lib.FILE) !File {
        var self: File = undefined;
        const err = lib.con_writer_file_init(&self.inner, file);
        internal.enumToError(err) catch |new_err| {
            return new_err;
        };
        return self;
    }

    pub fn interface(self: *File) InterfaceWriter {
        return .{ .writer = lib.con_writer_file_interface(&self.inner) };
    }
};

pub const String = struct {
    inner: lib.ConWriterString,

    pub fn init(buffer: []u8) !String {
        if (buffer.len > std.math.maxInt(c_int)) {
            return error.Overflow;
        }

        var self: String = undefined;
        const err = lib.con_writer_string_init(
            &self.inner,
            buffer.ptr,
            @intCast(buffer.len),
        );
        internal.enumToError(err) catch |new_err| {
            return new_err;
        };
        return self;
    }

    pub fn interface(self: *String) InterfaceWriter {
        return .{ .writer = lib.con_writer_string_interface(&self.inner) };
    }
};

pub const Buffer = struct {
    inner: lib.ConWriterBuffer,

    pub fn init(writer: InterfaceWriter, buffer: []u8) !Buffer {
        if (buffer.len >= std.math.maxInt(c_int)) {
            return error.Overflow;
        }

        var self: Buffer = undefined;
        const err = lib.con_writer_buffer_init(
            &self.inner,
            writer.writer,
            buffer.ptr,
            @intCast(buffer.len),
        );
        internal.enumToError(err) catch |new_err| {
            return new_err;
        };

        return self;
    }

    pub fn interface(self: *Buffer) InterfaceWriter {
        return .{ .writer = lib.con_writer_buffer_interface(&self.inner) };
    }

    pub fn flush(self: *Buffer) !void {
        const result = lib.con_writer_buffer_flush(&self.inner);
        if (!result) {
            return error.Writer;
        }
    }
};

pub const Indent = struct {
    inner: lib.ConWriterIndent,

    pub fn init(writer: InterfaceWriter) !Indent {
        var self: Indent = undefined;
        const err = lib.con_writer_indent_init(&self.inner, writer.writer);
        internal.enumToError(err) catch |new_err| {
            return new_err;
        };
        return self;
    }

    pub fn interface(self: *Indent) InterfaceWriter {
        return .{ .writer = lib.con_writer_indent_interface(&self.inner) };
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

    var context = FifoWriter.init(&fifo.writer());
    const writer = context.interface();

    try writer.write("1");
    try testing.expectEqualStrings("1", &buffer);
}

test "file init" {
    var context = try File.init(@ptrFromInt(256));
    _ = context.interface();
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
    defer _ = clib.fclose(file);

    var context = try File.init(@as([*c]lib.FILE, @ptrCast(file)));
    const writer = context.interface();

    try writer.write("1");

    const seek_err = clib.fseek(file, 0, lib.SEEK_SET);
    try testing.expectEqual(seek_err, 0);

    var buffer: [2]u8 = undefined;
    const result = clib.fread(&buffer, 1, 2, file);
    try testing.expectEqual(1, result);

    try testing.expectEqualStrings("1", buffer[0..1]);
}

test "string init" {
    var buffer: [0]u8 = undefined;
    var context = try String.init(&buffer);
    _ = context.interface();
}

test "string init overflow" {
    var fake_large_buffer = try testing.allocator.alloc(u8, 2);
    fake_large_buffer.len = @as(usize, std.math.maxInt(c_int)) + 1;
    defer {
        fake_large_buffer.len = 2;
        testing.allocator.free(fake_large_buffer);
    }

    const err = String.init(@ptrCast(fake_large_buffer));
    try testing.expectError(error.Overflow, err);
}

test "string write" {
    var buffer: [2]u8 = undefined;
    var context = try String.init(&buffer);
    const writer = context.interface();

    try writer.write("12");
    try testing.expectEqualStrings("12", &buffer);
}

test "string overflow" {
    var buffer: [0]u8 = undefined;
    var context = try String.init(&buffer);
    const writer = context.interface();

    const err = writer.write("1");
    try testing.expectError(error.Writer, err);
}

test "buffer init" {
    var b: [3]u8 = undefined;
    var c = try String.init(&b);

    var buffer: [1]u8 = undefined;
    var context = try Buffer.init(c.interface(), &buffer);
    _ = context.interface();
}

test "buffer init buffer small" {
    var b: [3]u8 = undefined;
    var c = try String.init(&b);

    var buffer: [0]u8 = undefined;
    const err = Buffer.init(c.interface(), &buffer);
    try testing.expectError(error.Buffer, err);
}

test "buffer init overflow" {
    var fake_large_buffer = try testing.allocator.alloc(u8, 2);
    fake_large_buffer.len = @as(usize, std.math.maxInt(c_int)) + 1;
    defer {
        fake_large_buffer.len = 2;
        testing.allocator.free(fake_large_buffer);
    }

    var b: [3]u8 = undefined;
    var c = try String.init(&b);

    const err = Buffer.init(c.interface(), @ptrCast(fake_large_buffer));
    try testing.expectError(error.Overflow, err);
}

test "buffer write" {
    var b: [1]u8 = undefined;
    var c = try String.init(&b);

    var buffer: [1]u8 = undefined;
    var context = try Buffer.init(c.interface(), &buffer);
    const writer = context.interface();

    try writer.write("1");
    try testing.expectEqualStrings("1", &b);
}

test "buffer flush" {
    var b: [1]u8 = undefined;
    var c = try String.init(&b);

    var buffer: [2]u8 = undefined;
    var context = try Buffer.init(c.interface(), &buffer);
    const writer = context.interface();

    try writer.write("1");

    try context.flush();
    try testing.expectEqualStrings("1", &b);
}

test "buffer internal writer fail" {
    var b: [0]u8 = undefined;
    var c = try String.init(&b);

    var buffer: [1]u8 = undefined;
    var context = try Buffer.init(c.interface(), &buffer);
    const writer = context.interface();

    const err = writer.write("1");
    try testing.expectError(error.Writer, err);
}

test "buffer flush writer fail" {
    var b: [0]u8 = undefined;
    var c = try String.init(&b);

    var buffer: [2]u8 = undefined;
    var context = try Buffer.init(c.interface(), &buffer);
    const writer = context.interface();

    try writer.write("1");

    const err = context.flush();
    try testing.expectError(error.Writer, err);
}

test "indent init" {
    var b: [0]u8 = undefined;
    var c = try String.init(&b);
    var context = try Indent.init(c.interface());
    _ = context.interface();
}

test "indent write" {
    var b: [1]u8 = undefined;
    var c = try String.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    try writer.write("1");
    try testing.expectEqualStrings("1", &b);
}

test "indent write minified" {
    var b: [56]u8 = undefined;
    var c = try String.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

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
    var b: [56]u8 = undefined;
    var c = try String.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const str = "[{\"k\":\":)\"},null,\"\\\"{1,2,3} [1,2,3]\"]";

    for (str) |ch| {
        const single: [1]u8 = .{ch};
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
    var b: [0]u8 = undefined;
    var c = try String.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const err = writer.write("1");
    try testing.expectError(error.Writer, err);
}

test "indent newline array open writer fail" {
    var b: [1]u8 = undefined;
    var c = try String.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const err = writer.write("[1]");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("[", &b);
}

test "indent whitespace array open writer fail" {
    var b: [2]u8 = undefined;
    var c = try String.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const err = writer.write("[1]");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("[\n", &b);
}

test "indent newline array close writer fail" {
    var b: [5]u8 = undefined;
    var c = try String.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const err = writer.write("[1]");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("[\n  1", &b);
}

test "indent whitespace array close writer fail" {
    var b: [6]u8 = undefined;
    var c = try String.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const err = writer.write("[1]");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("[\n  1\n", &b);
}

test "indent newline dict writer fail" {
    var b: [1]u8 = undefined;
    var c = try String.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const err = writer.write("{\"");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("{", &b);
}

test "indent whitespace dict writer fail" {
    var b: [2]u8 = undefined;
    var c = try String.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const err = writer.write("{\"");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("{\n", &b);
}

test "indent newline dict close writer fail" {
    var b: [10]u8 = undefined;
    var c = try String.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const err = writer.write("{\"k\":1}");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("{\n  \"k\": 1", &b);
}

test "indent whitespace dict close writer fail" {
    var b: [11]u8 = undefined;
    var c = try String.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const err = writer.write("{\"k\":1}");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("{\n  \"k\": 1\n", &b);
}

test "indent space writer fail" {
    var b: [8]u8 = undefined;
    var c = try String.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const err = writer.write("{\"k\":1}");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("{\n  \"k\":", &b);
}

test "indent newline comma writer fail" {
    var b: [6]u8 = undefined;
    var c = try String.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const err = writer.write("[1,2]");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("[\n  1,", &b);
}

test "indent whitespace comma writer fail" {
    var b: [7]u8 = undefined;
    var c = try String.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const err = writer.write("[1,2]");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("[\n  1,\n", &b);
}
