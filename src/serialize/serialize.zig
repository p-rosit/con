const std = @import("std");
const zcon = @import("../con.zig");
const internal = @import("../internal.zig");
const lib = internal.lib;

pub const Serialize = struct {
    inner: lib.ConSerialize,

    pub fn init(writer: zcon.InterfaceWriter, depth: []lib.ConContainer) !Serialize {
        if (depth.len > std.math.maxInt(c_int)) {
            return error.Overflow;
        }

        var context = Serialize{ .inner = undefined };
        const err = lib.con_serialize_init(
            &context.inner,
            writer.writer,
            depth.ptr,
            @intCast(depth.len),
        );

        try internal.enumToError(err);
        return context;
    }

    pub fn deinit(self: Serialize) void {
        _ = self;
    }

    pub fn arrayOpen(self: *Serialize) !void {
        const err = lib.con_serialize_array_open(&self.inner);
        return internal.enumToError(err);
    }

    pub fn arrayClose(self: *Serialize) !void {
        const err = lib.con_serialize_array_close(&self.inner);
        return internal.enumToError(err);
    }

    pub fn dictOpen(self: *Serialize) !void {
        const err = lib.con_serialize_dict_open(&self.inner);
        return internal.enumToError(err);
    }

    pub fn dictClose(self: *Serialize) !void {
        const err = lib.con_serialize_dict_close(&self.inner);
        return internal.enumToError(err);
    }

    pub fn dictKey(self: *Serialize, key: []const u8) !void {
        const err = lib.con_serialize_dict_key(&self.inner, key.ptr, key.len);
        return internal.enumToError(err);
    }

    pub fn number(self: *Serialize, num: []const u8) !void {
        const err = lib.con_serialize_number(&self.inner, num.ptr, num.len);
        return internal.enumToError(err);
    }

    pub fn string(self: *Serialize, str: []const u8) !void {
        const err = lib.con_serialize_string(&self.inner, str.ptr, str.len);
        return internal.enumToError(err);
    }

    pub fn @"bool"(self: *Serialize, value: bool) !void {
        const err = lib.con_serialize_bool(&self.inner, value);
        return internal.enumToError(err);
    }

    pub fn @"null"(self: *Serialize) !void {
        const err = lib.con_serialize_null(&self.inner);
        return internal.enumToError(err);
    }
};

const Fifo = std.fifo.LinearFifo(u8, .Slice);
const ConFifo = zcon.Writer(Fifo.Writer);
const testing = std.testing;

test "context init" {
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());

    var depth: [1]zcon.Container = undefined;
    const context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();
}

test "context init depth buffer overflow" {
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());

    var fake_large_depth = try testing.allocator.alloc(zcon.Container, 2);
    fake_large_depth.len = @as(usize, std.math.maxInt(c_int)) + 1;
    defer {
        fake_large_depth.len = 2;
        testing.allocator.free(fake_large_depth);
    }

    const err = Serialize.init(writer.interface(), fake_large_depth);
    try testing.expectError(error.Overflow, err);
}

// Section: Values -------------------------------------------------------------

test "number int-like" {
    var depth: [0]zcon.Container = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.number("5");
    try testing.expectEqualStrings("5", &buffer);
}

test "number float-like" {
    var depth: [0]zcon.Container = undefined;
    var buffer: [3]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.number("5.0");
    try testing.expectEqualStrings("5.0", &buffer);
}

test "number scientific-like" {
    var depth: [0]zcon.Container = undefined;
    var buffer: [5]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.number("-1e-5");
    try testing.expectEqualStrings("-1e-5", &buffer);
}

test "number writer fail" {
    var depth: [0]zcon.Container = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    const err = context.number("2");
    try testing.expectError(error.Writer, err);
}

test "number empty" {
    var depth: [0]zcon.Container = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    const err = context.number("");
    try testing.expectError(error.NotNumber, err);
}

test "number not terminated" {
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var depth: [0]zcon.Container = undefined;
    var context: Serialize = undefined;

    context = try Serialize.init(writer.interface(), &depth);
    const err1 = context.number("2.");
    try testing.expectError(error.NotNumber, err1);

    context = try Serialize.init(writer.interface(), &depth);
    const err2 = context.number("2.5E");
    try testing.expectError(error.NotNumber, err2);

    context = try Serialize.init(writer.interface(), &depth);
    const err3 = context.number("-");
    try testing.expectError(error.NotNumber, err3);

    context = try Serialize.init(writer.interface(), &depth);
    const err4 = context.number("3.4e-");
    try testing.expectError(error.NotNumber, err4);
}

test "number invalid" {
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var depth: [0]zcon.Container = undefined;
    var context: Serialize = undefined;

    context = try Serialize.init(writer.interface(), &depth);
    const err1 = context.number("-");
    try testing.expectError(error.NotNumber, err1);

    context = try Serialize.init(writer.interface(), &depth);
    const err2 = context.number("0f");
    try testing.expectError(error.NotNumber, err2);
}

test "string" {
    var depth: [0]zcon.Container = undefined;
    var buffer: [3]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.string("a");
    try testing.expectEqualStrings("\"a\"", &buffer);
}

test "string unescaped" {
    var depth: [0]zcon.Container = undefined;
    var buffer: [16]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.string("\"\\\\\x08\x0c\n\r\t");
    try testing.expectEqualStrings("\"\\\"\\\\\\b\\f\\n\\r\\t\"", &buffer);
}

test "string escaped" {
    var depth: [0]zcon.Container = undefined;
    var buffer: [18]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.string("\\b\\f\\n\\r\\t\\uaf12");
    try testing.expectEqualStrings("\"\\b\\f\\n\\r\\t\\uaf12\"", &buffer);
}

test "string invalid escape" {
    var depth: [0]zcon.Container = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context: Serialize = undefined;

    context = try Serialize.init(writer.interface(), &depth);
    const err1 = context.string("1\\h");
    try testing.expectError(error.InvalidJson, err1);

    context = try Serialize.init(writer.interface(), &depth);
    const err2 = context.string("\\u23g4");
    try testing.expectError(error.InvalidJson, err2);

    context = try Serialize.init(writer.interface(), &depth);
    const err3 = context.string("\\uff");
    try testing.expectError(error.InvalidJson, err3);

    context = try Serialize.init(writer.interface(), &depth);
    const err4 = context.string("\\");
    try testing.expectError(error.InvalidJson, err4);
}

test "string first quote writer fail" {
    var depth: [0]zcon.Container = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    const err = context.string("a");
    try testing.expectError(error.Writer, err);
}

test "string body writer fail" {
    var depth: [0]zcon.Container = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    const err = context.string("a");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("\"", &buffer);
}

test "string second quote writer fail" {
    var depth: [0]zcon.Container = undefined;
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    const err = context.string("a");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("\"a", &buffer);
}

test "bool true" {
    var depth: [0]zcon.Container = undefined;
    var buffer: [4]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.bool(true);
    try testing.expectEqualStrings("true", &buffer);
}

test "bool true writer fail" {
    var depth: [0]zcon.Container = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    const err = context.bool(true);
    try testing.expectError(error.Writer, err);
}

test "bool false" {
    var depth: [0]zcon.Container = undefined;
    var buffer: [5]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.bool(false);
    try testing.expectEqualStrings("false", &buffer);
}

test "bool false writer fail" {
    var depth: [0]zcon.Container = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    const err = context.bool(false);
    try testing.expectError(error.Writer, err);
}

test "null" {
    var depth: [0]zcon.Container = undefined;
    var buffer: [4]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.null();
    try testing.expectEqualStrings("null", &buffer);
}

test "null writer fail" {
    var depth: [0]zcon.Container = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    const err = context.null();
    try testing.expectError(error.Writer, err);
}

// Section: Containers ---------------------------------------------------------

test "array open" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.arrayOpen();
    try testing.expectEqualStrings("[", &buffer);
}

test "array open too many" {
    var depth: [0]zcon.Container = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    const err = context.arrayOpen();
    try testing.expectError(error.TooDeep, err);
}

test "array nested open too many" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [1]zcon.Container = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    const err = context.arrayOpen();
    try testing.expectError(error.Writer, err);
}

test "array close" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.arrayOpen();
    try context.arrayClose();
    try testing.expectEqualStrings("[]", &buffer);
}

test "array close too many" {
    var depth: [0]zcon.Container = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    const err = context.arrayClose();
    try testing.expectError(error.ClosedTooMany, err);
}

test "array close writer fail" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.arrayOpen();
    try testing.expectEqualStrings("[", &buffer);

    const err = context.arrayClose();
    try testing.expectError(error.Writer, err);
}

test "dict open" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.dictOpen();
    try testing.expectEqualStrings("{", &buffer);
}

test "dict open too many" {
    var depth: [0]zcon.Container = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    const err = context.dictOpen();
    try testing.expectError(error.TooDeep, err);
}

test "dict nested open too many" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [1]zcon.Container = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    const err = context.dictOpen();
    try testing.expectError(error.Writer, err);
}

test "dict close" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.dictOpen();
    try context.dictClose();
    try testing.expectEqualStrings("{}", &buffer);
}

test "dict close too many" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    const err = context.dictClose();
    try testing.expectError(error.ClosedTooMany, err);
}

test "dict close writer fail" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.dictOpen();
    try testing.expectEqualStrings("{", &buffer);

    const err = context.dictClose();
    try testing.expectError(error.Writer, err);
}

// Section: Dict key -----------------------------------------------------------

test "dict key" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [7]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        try context.dictKey("key");
        try testing.expectEqualStrings("{\"key\":", &buffer);
    }
}

test "dict key multiple" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [13]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [1]zcon.Container = undefined;
    var buffer: [6]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [1]zcon.Container = undefined;
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    const err = context.dictKey("key");
    try testing.expectError(error.NotDict, err);
}

test "dict key in array" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        const err = context.dictKey("key");
        try testing.expectError(error.NotDict, err);
    }
}

test "dict key twice" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [7]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        try context.dictKey("k1");

        const err = context.dictKey("k2");
        try testing.expectError(error.Value, err);
    }
}

test "dict number key missing" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        const err = context.number("5");
        try testing.expectError(error.Key, err);
    }
}

test "dict number second key missing" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [6]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [1]zcon.Container = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        const err = context.string("2");
        try testing.expectError(error.Key, err);
    }
}

test "dict string second key missing" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [8]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [2]zcon.Container = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        const err = context.arrayOpen();
        try testing.expectError(error.Key, err);
    }
}

test "dict array second key missing" {
    var depth: [2]zcon.Container = undefined;
    var buffer: [6]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [2]zcon.Container = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.dictOpen();

    {
        const err = context.dictOpen();
        try testing.expectError(error.Key, err);
    }
}

test "dict dict second key missing" {
    var depth: [2]zcon.Container = undefined;
    var buffer: [6]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [1]zcon.Container = undefined;
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    const err = context.dictClose();
    try testing.expectError(error.NotDict, err);
}

test "dict open -> array close" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.dictOpen();

    const err = context.arrayClose();
    try testing.expectError(error.NotArray, err);
}

test "array number single" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [3]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        try context.number("1");
    }

    try context.arrayClose();

    try testing.expectEqualStrings("[1]", &buffer);
}

test "array number multiple" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [5]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [1]zcon.Container = undefined;
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [1]zcon.Container = undefined;
    var buffer: [5]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        try context.string("a");
    }

    try context.arrayClose();

    try testing.expectEqualStrings("[\"a\"]", &buffer);
}

test "array string multiple" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [9]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [1]zcon.Container = undefined;
    var buffer: [4]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [1]zcon.Container = undefined;
    var buffer: [6]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        try context.bool(true);
    }

    try context.arrayClose();

    try testing.expectEqualStrings("[true]", &buffer);
}

test "array bool multiple" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [12]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [1]zcon.Container = undefined;
    var buffer: [5]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [1]zcon.Container = undefined;
    var buffer: [6]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
    defer context.deinit();

    try context.arrayOpen();

    {
        try context.null();
    }

    try context.arrayClose();

    try testing.expectEqualStrings("[null]", &buffer);
}

test "array null multiple" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [11]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [1]zcon.Container = undefined;
    var buffer: [5]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [2]zcon.Container = undefined;
    var buffer: [4]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [2]zcon.Container = undefined;
    var buffer: [7]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [2]zcon.Container = undefined;
    var buffer: [3]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [2]zcon.Container = undefined;
    var buffer: [4]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [2]zcon.Container = undefined;
    var buffer: [7]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [2]zcon.Container = undefined;
    var buffer: [3]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [1]zcon.Container = undefined;
    var buffer: [7]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [1]zcon.Container = undefined;
    var buffer: [9]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [1]zcon.Container = undefined;
    var buffer: [10]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [1]zcon.Container = undefined;
    var buffer: [10]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [2]zcon.Container = undefined;
    var buffer: [8]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [2]zcon.Container = undefined;
    var buffer: [8]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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
    var depth: [1]zcon.Container = undefined;
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());

    var context = try Serialize.init(writer.interface(), &depth);

    try context.arrayOpen();
    try context.arrayClose();
    try testing.expectEqualStrings("[]", &buffer);

    const err = context.number("1");
    try testing.expectError(error.Complete, err);
}

test "string complete" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [2]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());

    var context = try Serialize.init(writer.interface(), &depth);

    try context.dictOpen();
    try context.dictClose();
    try testing.expectEqualStrings("{}", &buffer);

    const err = context.string("1");
    try testing.expectError(error.Complete, err);
}

test "bool complete" {
    var depth: [0]zcon.Container = undefined;
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());

    var context = try Serialize.init(writer.interface(), &depth);

    try context.number("1");
    try testing.expectEqualStrings("1", &buffer);

    const err = context.bool(true);
    try testing.expectError(error.Complete, err);
}

test "null complete" {
    var depth: [0]zcon.Container = undefined;
    var buffer: [3]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());

    var context = try Serialize.init(writer.interface(), &depth);

    try context.string("1");
    try testing.expectEqualStrings("\"1\"", &buffer);

    const err = context.null();
    try testing.expectError(error.Complete, err);
}

test "array complete" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [4]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());

    var context = try Serialize.init(writer.interface(), &depth);

    try context.bool(true);
    try testing.expectEqualStrings("true", &buffer);

    const err = context.arrayOpen();
    try testing.expectError(error.Complete, err);
}

test "dict complete" {
    var depth: [1]zcon.Container = undefined;
    var buffer: [4]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());

    var context = try Serialize.init(writer.interface(), &depth);

    try context.null();
    try testing.expectEqualStrings("null", &buffer);

    const err = context.dictOpen();
    try testing.expectError(error.Complete, err);
}

// Section: Integration test ---------------------------------------------------

test "nested structures" {
    var depth: [3]zcon.Container = undefined;
    var buffer: [55]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var writer = ConFifo.init(&fifo.writer());
    var context = try Serialize.init(writer.interface(), &depth);
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

test "indent writer" {
    var depth: [3]zcon.Container = undefined;
    var buffer: [119]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var c = ConFifo.init(&fifo.writer());

    var indent = try zcon.WriterIndent.init(c.interface());

    var context = try Serialize.init(indent.interface(), &depth);
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
        try context.string("\"[2, 3] {\"m\":1,\"n\":2}");
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
