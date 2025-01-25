const std = @import("std");
const Allocator = std.mem.Allocator;
const con = @cImport({
    @cInclude("serialize.h");
    @cInclude("serialize_writer.h");
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

        pub fn dictKey(self: *Self, key: [:0]const u8) !void {
            self.inner.write_context = &self.writer;
            const err = con.con_serialize_dict_key(&self.inner, key.ptr);
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

        pub fn @"bool"(self: *Self, value: bool) !void {
            self.inner.write_context = &self.writer;
            const err = con.con_serialize_bool(&self.inner, value);
            return Self.enum_to_error(err);
        }

        pub fn @"null"(self: *Self) !void {
            self.inner.write_context = &self.writer;
            const err = con.con_serialize_null(&self.inner);
            return Self.enum_to_error(err);
        }

        fn writeCallback(writer: ?*const anyopaque, data: [*c]const u8) callconv(.C) c_int {
            std.debug.assert(null != writer);
            std.debug.assert(null != data);
            const w: *Writer = @constCast(@alignCast(@ptrCast(writer)));
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
                con.CON_SERIALIZE_COMPLETE => return error.Complete,
                con.CON_SERIALIZE_KEY => return error.Key,
                con.CON_SERIALIZE_VALUE => return error.Value,
                con.CON_SERIALIZE_NOT_ARRAY => return error.NotArray,
                con.CON_SERIALIZE_NOT_DICT => return error.NotDict,
                con.CON_SERIALIZE_STATE_UNKNOWN => return error.StateUnknown,
                else => return error.Unknown,
            }
        }
    };
}

pub fn IndentJson(Writer: type) type {
    // TODO: make a real writer (std.io.AnyWriter)
    // TODO: comptime verify type passed in is writer

    return struct {
        const Self = @This();

        indenter: con.ConWriterIndent,

        pub fn init(writer: *const Writer) Self {
            return .{ .indenter = con.con_serialize_writer_indent(writer, writeCallback) };
        }

        pub fn write(writer: *Self, bytes: []const u8) !usize {
            const result = con.con_serialize_writer_indent_write(&writer.indenter, bytes.ptr);

            if (result <= 0) {
                return error.Writer;
            }
            return @intCast(result);
        }

        fn writeCallback(writer: ?*const anyopaque, data: [*c]const u8) callconv(.C) c_int {
            std.debug.assert(null != writer);
            std.debug.assert(null != data);
            const w: *const Writer = @alignCast(@ptrCast(writer));
            const d = std.mem.span(data);
            return @intCast(w.write(d) catch 0);
        }
    };
}

const Fifo = std.fifo.LinearFifo(u8, .Slice);
const testing = std.testing;

test "context init" {
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);

    var depth: [1]u8 = undefined;
    const context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();
}

// Section: Values -------------------------------------------------------------

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

test "number writer fail" {
    var depth: [0]u8 = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    const err = context.number("2");
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

test "string first quote writer fail" {
    var depth: [0]u8 = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    const err = context.string("a");
    try testing.expectError(error.Writer, err);
}

test "string body writer fail" {
    var depth: [0]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    const err = context.string("a");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("\"", &buffer);
}

test "string second quote writer fail" {
    var depth: [0]u8 = undefined;
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    const err = context.string("a");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("\"a", &buffer);
}

test "bool true" {
    var depth: [0]u8 = undefined;
    var buffer: [4]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.bool(true);
    try testing.expectEqualStrings("true", &buffer);
}

test "bool true writer fail" {
    var depth: [0]u8 = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    const err = context.bool(true);
    try testing.expectError(error.Writer, err);
}

test "bool false" {
    var depth: [0]u8 = undefined;
    var buffer: [5]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.bool(false);
    try testing.expectEqualStrings("false", &buffer);
}

test "bool false writer fail" {
    var depth: [0]u8 = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    const err = context.bool(false);
    try testing.expectError(error.Writer, err);
}

test "null" {
    var depth: [0]u8 = undefined;
    var buffer: [4]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.null();
    try testing.expectEqualStrings("null", &buffer);
}

test "null writer fail" {
    var depth: [0]u8 = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    const err = context.null();
    try testing.expectError(error.Writer, err);
}

// Section: Containers ---------------------------------------------------------

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

test "array nested open too many" {
    var depth: [1]u8 = undefined;
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        try context.number("1");
        try testing.expectEqualStrings("[1", &buffer);

        const err = context.arrayOpen();
        try testing.expectError(error.TooDeep, err);
    }
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

test "array close too many" {
    var depth: [0]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    const err = context.arrayClose();
    try testing.expectError(error.ClosedTooMany, err);
}

test "array close writer fail" {
    var depth: [1]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();
    try testing.expectEqualStrings("[", &buffer);

    const err = context.arrayClose();
    try testing.expectError(error.Writer, err);
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

test "dict nested open too many" {
    var depth: [1]u8 = undefined;
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        try context.number("1");
        try testing.expectEqualStrings("[1", &buffer);

        const err = context.dictOpen();
        try testing.expectError(error.TooDeep, err);
    }
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

test "dict close too many" {
    var depth: [1]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    const err = context.dictClose();
    try testing.expectError(error.ClosedTooMany, err);
}

test "dict close writer fail" {
    var depth: [1]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.dictOpen();
    try testing.expectEqualStrings("{", &buffer);

    const err = context.dictClose();
    try testing.expectError(error.Writer, err);
}

// Section: Dict key -----------------------------------------------------------

test "dict key" {
    var depth: [1]u8 = undefined;
    var buffer: [7]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        try context.dictKey("key");
        try testing.expectEqualStrings("{\"key\":", &buffer);
    }
}

test "dict key multiple" {
    var depth: [1]u8 = undefined;
    var buffer: [13]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        try context.dictKey("k1");
        try context.number("1");

        try context.dictKey("k2");
        try testing.expectEqualStrings("{\"k1\":1,\"k2\":", &buffer);
    }
}

test "dict key comma writer fail" {
    var depth: [1]u8 = undefined;
    var buffer: [6]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        try context.dictKey("a");
        try context.number("1");
        try testing.expectEqualStrings("{\"a\":1", &buffer);

        const err = context.dictKey("2");
        try testing.expectError(error.Writer, err);
    }
}

test "dict key outside dict" {
    var depth: [1]u8 = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    const err = context.dictKey("key");
    try testing.expectError(error.NotDict, err);
}

test "dict key in array" {
    var depth: [1]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        const err = context.dictKey("key");
        try testing.expectError(error.NotDict, err);
    }
}

test "dict key twice" {
    var depth: [1]u8 = undefined;
    var buffer: [7]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        try context.dictKey("k1");

        const err = context.dictKey("k2");
        try testing.expectError(error.Value, err);
    }
}

test "dict number key missing" {
    var depth: [1]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        const err = context.number("5");
        try testing.expectError(error.Key, err);
    }
}

test "dict number second key missing" {
    var depth: [1]u8 = undefined;
    var buffer: [6]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        try context.dictKey("k");
        try context.number("1");
        try testing.expectEqualStrings("{\"k\":1", &buffer);

        const err = context.number("2");
        try testing.expectError(error.Key, err);
    }
}

test "dict string key missing" {
    var depth: [1]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        const err = context.string("2");
        try testing.expectError(error.Key, err);
    }
}

test "dict string second key missing" {
    var depth: [1]u8 = undefined;
    var buffer: [8]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        try context.dictKey("k");
        try context.string("a");
        try testing.expectEqualStrings("{\"k\":\"a\"", &buffer);

        const err = context.string("b");
        try testing.expectError(error.Key, err);
    }
}

test "dict array key missing" {
    var depth: [2]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        const err = context.arrayOpen();
        try testing.expectError(error.Key, err);
    }
}

test "dict array second key missing" {
    var depth: [2]u8 = undefined;
    var buffer: [6]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        try context.dictKey("k");
        try context.number("1");
        try testing.expectEqualStrings("{\"k\":1", &buffer);

        const err = context.arrayOpen();
        try testing.expectError(error.Key, err);
    }
}

test "dict dict key missing" {
    var depth: [2]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        const err = context.dictOpen();
        try testing.expectError(error.Key, err);
    }
}

test "dict dict second key missing" {
    var depth: [2]u8 = undefined;
    var buffer: [6]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        try context.dictKey("k");
        try context.number("1");
        try testing.expectEqualStrings("{\"k\":1", &buffer);

        const err = context.dictOpen();
        try testing.expectError(error.Key, err);
    }
}

// Section: Combinations of containers -----------------------------------------

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

test "array number single" {
    var depth: [1]u8 = undefined;
    var buffer: [3]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        try context.number("1");
    }

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

    {
        try context.number("1");
        try context.number("3");
    }

    try context.arrayClose();

    try testing.expectEqualStrings("[1,3]", &buffer);
}

test "array number comma writer fail" {
    var depth: [1]u8 = undefined;
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        try context.number("1");
        try testing.expectEqualStrings("[1", &buffer);

        const err = context.number("2");
        try testing.expectError(error.Writer, err);
    }
}

test "array string single" {
    var depth: [1]u8 = undefined;
    var buffer: [5]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        try context.string("a");
    }

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

    {
        try context.string("a");
        try context.string("b");
    }

    try context.arrayClose();

    try testing.expectEqualStrings("[\"a\",\"b\"]", &buffer);
}

test "array string comma writer fail" {
    var depth: [1]u8 = undefined;
    var buffer: [4]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        try context.string("a");
        try testing.expectEqualStrings("[\"a\"", &buffer);

        const err = context.string("b");
        try testing.expectError(error.Writer, err);
    }
}

test "array bool single" {
    var depth: [1]u8 = undefined;
    var buffer: [6]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        try context.bool(true);
    }

    try context.arrayClose();

    try testing.expectEqualStrings("[true]", &buffer);
}

test "array bool multiple" {
    var depth: [1]u8 = undefined;
    var buffer: [12]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        try context.bool(false);
        try context.bool(true);
    }

    try context.arrayClose();

    try testing.expectEqualStrings("[false,true]", &buffer);
}

test "array bool comma writer fail" {
    var depth: [1]u8 = undefined;
    var buffer: [5]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        try context.bool(true);
        try testing.expectEqualStrings("[true", &buffer);

        const err = context.bool(false);
        try testing.expectError(error.Writer, err);
    }
}

test "array null single" {
    var depth: [1]u8 = undefined;
    var buffer: [6]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        try context.null();
    }

    try context.arrayClose();

    try testing.expectEqualStrings("[null]", &buffer);
}

test "array null multiple" {
    var depth: [1]u8 = undefined;
    var buffer: [11]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        try context.null();
        try context.null();
    }

    try context.arrayClose();

    try testing.expectEqualStrings("[null,null]", &buffer);
}

test "array null comma writer fail" {
    var depth: [1]u8 = undefined;
    var buffer: [5]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        try context.null();
        try testing.expectEqualStrings("[null", &buffer);

        const err = context.null();
        try testing.expectError(error.Writer, err);
    }
}

test "array array single" {
    var depth: [2]u8 = undefined;
    var buffer: [4]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        try context.arrayOpen();
        try context.arrayClose();
    }

    try context.arrayClose();

    try testing.expectEqualStrings("[[]]", &buffer);
}

test "array array multiple" {
    var depth: [2]u8 = undefined;
    var buffer: [7]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        try context.arrayOpen();
        try context.arrayClose();

        try context.arrayOpen();
        try context.arrayClose();
    }

    try context.arrayClose();

    try testing.expectEqualStrings("[[],[]]", &buffer);
}

test "array array comma writer fail" {
    var depth: [2]u8 = undefined;
    var buffer: [3]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        try context.arrayOpen();
        try context.arrayClose();
        try testing.expectEqualStrings("[[]", &buffer);

        const err = context.arrayOpen();
        try testing.expectError(error.Writer, err);
    }
}

test "array dict single" {
    var depth: [2]u8 = undefined;
    var buffer: [4]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        try context.dictOpen();
        try context.dictClose();
    }

    try context.arrayClose();

    try testing.expectEqualStrings("[{}]", &buffer);
}

test "array dict multiple" {
    var depth: [2]u8 = undefined;
    var buffer: [7]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        try context.dictOpen();
        try context.dictClose();

        try context.dictOpen();
        try context.dictClose();
    }

    try context.arrayClose();

    try testing.expectEqualStrings("[{},{}]", &buffer);
}

test "array dict comma writer fail" {
    var depth: [2]u8 = undefined;
    var buffer: [3]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        try context.dictOpen();
        try context.dictClose();
        try testing.expectEqualStrings("[{}", &buffer);

        const err = context.dictOpen();
        try testing.expectError(error.Writer, err);
    }
}

test "dict number single" {
    var depth: [1]u8 = undefined;
    var buffer: [7]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        try context.dictKey("a");
        try context.number("1");
    }

    try context.dictClose();

    try testing.expectEqualStrings("{\"a\":1}", &buffer);
}

test "dict string single" {
    var depth: [1]u8 = undefined;
    var buffer: [9]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        try context.dictKey("a");
        try context.string("b");
    }

    try context.dictClose();

    try testing.expectEqualStrings("{\"a\":\"b\"}", &buffer);
}

test "dict bool single" {
    var depth: [1]u8 = undefined;
    var buffer: [10]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        try context.dictKey("a");
        try context.bool(true);
    }

    try context.dictClose();

    try testing.expectEqualStrings("{\"a\":true}", &buffer);
}

test "dict null single" {
    var depth: [1]u8 = undefined;
    var buffer: [10]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        try context.dictKey("a");
        try context.null();
    }

    try context.dictClose();

    try testing.expectEqualStrings("{\"a\":null}", &buffer);
}

test "dict array single" {
    var depth: [2]u8 = undefined;
    var buffer: [8]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        try context.dictKey("a");
        try context.arrayOpen();
        try context.arrayClose();
    }

    try context.dictClose();

    try testing.expectEqualStrings("{\"a\":[]}", &buffer);
}

test "dict dict single" {
    var depth: [2]u8 = undefined;
    var buffer: [8]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        try context.dictKey("a");
        try context.dictOpen();
        try context.dictClose();
    }

    try context.dictClose();

    try testing.expectEqualStrings("{\"a\":{}}", &buffer);
}

// Section: Completed ----------------------------------------------------------

test "number complete" {
    var depth: [1]u8 = undefined;
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);

    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);

    try context.arrayOpen();
    try context.arrayClose();
    try testing.expectEqualStrings("[]", &buffer);

    const err = context.number("1");
    try testing.expectError(error.Complete, err);
}

test "string complete" {
    var depth: [1]u8 = undefined;
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);

    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);

    try context.dictOpen();
    try context.dictClose();
    try testing.expectEqualStrings("{}", &buffer);

    const err = context.string("1");
    try testing.expectError(error.Complete, err);
}

test "bool complete" {
    var depth: [0]u8 = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);

    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);

    try context.number("1");
    try testing.expectEqualStrings("1", &buffer);

    const err = context.bool(true);
    try testing.expectError(error.Complete, err);
}

test "null complete" {
    var depth: [0]u8 = undefined;
    var buffer: [3]u8 = undefined;
    var fifo = Fifo.init(&buffer);

    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);

    try context.string("1");
    try testing.expectEqualStrings("\"1\"", &buffer);

    const err = context.null();
    try testing.expectError(error.Complete, err);
}

test "array complete" {
    var depth: [1]u8 = undefined;
    var buffer: [4]u8 = undefined;
    var fifo = Fifo.init(&buffer);

    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);

    try context.bool(true);
    try testing.expectEqualStrings("true", &buffer);

    const err = context.arrayOpen();
    try testing.expectError(error.Complete, err);
}

test "dict complete" {
    var depth: [1]u8 = undefined;
    var buffer: [4]u8 = undefined;
    var fifo = Fifo.init(&buffer);

    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);

    try context.null();
    try testing.expectEqualStrings("null", &buffer);

    const err = context.dictOpen();
    try testing.expectError(error.Complete, err);
}

// Section: Integration test ---------------------------------------------------

test "nested structures" {
    var depth: [3]u8 = undefined;
    var buffer: [55]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        try context.dictKey("a");
        try context.arrayOpen();
        {
            try context.string("hello");
            try context.dictOpen();
            {
                try context.dictKey("a.a");
                try context.null();

                try context.dictKey("a.b");
                try context.bool(true);
            }
            try context.dictClose();
        }
        try context.arrayClose();

        try context.dictKey("b");
        try context.arrayOpen();
        {
            try context.number("234");
            try context.bool(false);
        }
        try context.arrayClose();
    }

    try context.dictClose();

    try testing.expectEqualStrings("{\"a\":[\"hello\",{\"a.a\":null,\"a.b\":true}],\"b\":[234,false]}", &buffer);
}

// Section: Indent writer ------------------------------------------------------

test "indent writer" {
    var depth: [3]u8 = undefined;
    var buffer: [119]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    const indent_writer = IndentJson(Fifo.Writer).init(&fifo.writer());
    var context = try Serialize(IndentJson(Fifo.Writer)).init(indent_writer, &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        try context.dictOpen();
        {
            try context.dictKey("key1");
            try context.arrayOpen();
            try context.arrayClose();

            try context.dictKey("key2");
            try context.dictOpen();
            try context.dictClose();

            try context.dictKey("key3");
            try context.bool(true);
        }
        try context.dictClose();

        try context.number("123");
        try context.string("string");
        try context.string("\\\"[2, 3] {\\\"m\\\":1,\\\"n\\\":2}");
        try context.null();
    }

    try context.arrayClose();

    try testing.expectEqualStrings(
        \\[
        \\  {
        \\    "key1": [],
        \\    "key2": {},
        \\    "key3": true
        \\  },
        \\  123,
        \\  "string",
        \\  "\"[2, 3] {\"m\":1,\"n\":2}",
        \\  null
        \\]
    ,
        &buffer,
    );
}
