const std = @import("std");
const Allocator = std.mem.Allocator;
const con = @cImport({
    @cInclude("serialize.h");
});

pub fn Serialize(Writer: type) type {
    // TODO: comptime verify type passed in is writer

    return struct {
        const Self = @This();

        writer: Writer,
        inner: con.ConSerialize,

        pub fn init(w: Writer, depth: []u8) !Self {
            var context = Self{
                .writer = w,
                .inner = undefined,
            };

            if (depth.len > std.math.maxInt(c_int)) {
                return error.Overflow;
            }

            const err = con.con_serialize_init(
                &context.inner,
                &context.writer,
                Self.writeCallback,
                depth.ptr,
                @intCast(depth.len),
            );

            Self.enum_to_error(err) catch |new_err| {
                return new_err;
            };
            return context;
        }

        pub fn deinit(self: Self) void {
            _ = self;
        }

        pub fn arrayOpen(self: *Self) !void {
            self.inner.write_context = &self.writer;
            const err = con.con_serialize_array_open(&self.inner);
            return Self.enum_to_error(err);
        }

        pub fn arrayClose(self: *Self) !void {
            self.inner.write_context = &self.writer;
            const err = con.con_serialize_array_close(&self.inner);
            return Self.enum_to_error(err);
        }

        pub fn dictOpen(self: *Self) !void {
            self.inner.write_context = &self.writer;
            const err = con.con_serialize_dict_open(&self.inner);
            return Self.enum_to_error(err);
        }

        pub fn dictClose(self: *Self) !void {
            self.inner.write_context = &self.writer;
            const err = con.con_serialize_dict_close(&self.inner);
            return Self.enum_to_error(err);
        }

        pub fn number(self: *Self, num: [:0]const u8) !void {
            self.inner.write_context = &self.writer;
            const err = con.con_serialize_number(&self.inner, num.ptr);
            return Self.enum_to_error(err);
        }

        pub fn string(self: *Self, str: [:0]const u8) !void {
            self.inner.write_context = &self.writer;
            const err = con.con_serialize_string(&self.inner, str.ptr);
            return Self.enum_to_error(err);
        }

        fn writeCallback(writer: ?*const anyopaque, data: [*c]const u8) callconv(.C) c_int {
            std.debug.assert(null != writer);
            std.debug.assert(null != data);
            const w: *const Writer = @alignCast(@ptrCast(writer));
            const d = std.mem.span(data);
            return @intCast(w.write(d) catch 0);
        }

        fn enum_to_error(err: con.ConSerializeError) !void {
            switch (err) {
                con.CON_SERIALIZE_OK => return,
                con.CON_SERIALIZE_NULL => return error.Null,
                con.CON_SERIALIZE_WRITER => return error.Writer,
                con.CON_SERIALIZE_CLOSED_TOO_MANY => return error.ClosedTooMany,
                con.CON_SERIALIZE_BUFFER => return error.Buffer,
                con.CON_SERIALIZE_TOO_DEEP => return error.TooDeep,
                con.CON_SERIALIZE_NOT_ARRAY => return error.NotArray,
                con.CON_SERIALIZE_NOT_DICT => return error.NotDict,
                else => return error.Unknown,
            }
        }
    };
}

const con_dict = 1;
const con_array = 2;

const Fifo = std.fifo.LinearFifo(u8, .Slice);
const testing = std.testing;

test "context init" {
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);

    var depth: [1]u8 = undefined;
    const context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();
}

test "array open" {
    var depth: [1]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();
    try testing.expectEqualStrings("[", &buffer);
}

test "array open too many" {
    var depth: [0]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    const err = context.arrayOpen();
    try testing.expectError(error.TooDeep, err);
}

test "array open writer fail" {
    var depth: [1]u8 = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    const err = context.arrayOpen();
    try testing.expectError(error.Writer, err);
}

test "array close" {
    var depth: [1]u8 = undefined;
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();
    try context.arrayClose();
    try testing.expectEqualStrings("[]", &buffer);
}

test "array close writer fail" {
    var depth: [1]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();
    const err = context.arrayClose();
    try testing.expectError(error.Writer, err);
}

test "array close too many" {
    var depth: [0]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    const err = context.arrayClose();
    try testing.expectError(error.ClosedTooMany, err);
}

test "dict open" {
    var depth: [1]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.dictOpen();
    try testing.expectEqualStrings("{", &buffer);
}

test "dict open too many" {
    var depth: [0]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    const err = context.dictOpen();
    try testing.expectError(error.TooDeep, err);
}

test "dict open writer fail" {
    var depth: [1]u8 = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    const err = context.dictOpen();
    try testing.expectError(error.Writer, err);
}

test "dict close" {
    var depth: [1]u8 = undefined;
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.dictOpen();
    try context.dictClose();
    try testing.expectEqualStrings("{}", &buffer);
}

test "dict close writer fail" {
    var depth: [1]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.dictOpen();
    const err = context.dictClose();
    try testing.expectError(error.Writer, err);
}

test "dict close too many" {
    var depth: [1]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    const err = context.dictClose();
    try testing.expectError(error.ClosedTooMany, err);
}

test "array open -> dict close" {
    var depth: [1]u8 = undefined;
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    const err = context.dictClose();
    try testing.expectError(error.NotDict, err);
}

test "dict open -> array close" {
    var depth: [1]u8 = undefined;
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.dictOpen();

    const err = context.arrayClose();
    try testing.expectError(error.NotArray, err);
}

test "number int-like" {
    var depth: [0]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.number("5");
    try testing.expectEqualStrings("5", &buffer);
}

test "number float-like" {
    var depth: [0]u8 = undefined;
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.number("5.");
    try testing.expectEqualStrings("5.", &buffer);
}

test "number scientific-like" {
    var depth: [0]u8 = undefined;
    var buffer: [5]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.number("-1e-5");
    try testing.expectEqualStrings("-1e-5", &buffer);
}

test "number write fail" {
    var depth: [0]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    const err = context.number(".5");
    try testing.expectError(error.Writer, err);
}

test "string" {
    var depth: [0]u8 = undefined;
    var buffer: [3]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.string("a");
    try testing.expectEqualStrings("\"a\"", &buffer);
}

test "string first quote write fail" {
    var depth: [0]u8 = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    const err = context.string("a");
    try testing.expectError(error.Writer, err);
}

test "string body write fail" {
    var depth: [0]u8 = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    const err = context.string("a");
    try testing.expectError(error.Writer, err);
}

test "string second quote write fail" {
    var depth: [0]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    const err = context.string("a");
    try testing.expectError(error.Writer, err);
}

// Usage -----------

test "array string single" {
    var depth: [1]u8 = undefined;
    var buffer: [5]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();
    try context.string("a");
    try context.arrayClose();

    try testing.expectEqualStrings("[\"a\"]", &buffer);
}

test "array string multiple" {
    var depth: [1]u8 = undefined;
    var buffer: [9]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();
    try context.string("a");
    try context.string("b");
    try context.arrayClose();

    try testing.expectEqualStrings("[\"a\",\"b\"]", &buffer);
}

test "array number single" {
    var depth: [1]u8 = undefined;
    var buffer: [3]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();
    try context.number("1");
    try context.arrayClose();

    try testing.expectEqualStrings("[1]", &buffer);
}

test "array number multiple" {
    var depth: [1]u8 = undefined;
    var buffer: [5]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();
    try context.number("1");
    try context.number("3");
    try context.arrayClose();

    try testing.expectEqualStrings("[1,3]", &buffer);
}
