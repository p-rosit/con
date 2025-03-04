const std = @import("std");
const zcon = @import("../con.zig");
const internal = @import("../internal.zig");
const lib = internal.lib;

pub const Type = enum {
    number,
    string,
    bool,
    null,
    array_open,
    array_close,
    dict_open,
    dict_close,
    dict_key,
};

pub const Deserialize = struct {
    inner: lib.ConDeserialize,

    pub fn init(reader: zcon.InterfaceReader, depth: []u8) !Deserialize {
        if (depth.len > std.math.maxInt(c_int)) {
            return error.Overflow;
        }

        var context = Deserialize{ .inner = undefined };
        const err = lib.con_deserialize_init(
            &context.inner,
            reader.reader,
            depth.ptr,
            @intCast(depth.len),
        );

        try internal.enumToError(err);
        return context;
    }

    pub fn next(self: *Deserialize) !Type {
        var token_type: lib.ConDeserializeType = undefined;
        const err = lib.con_deserialize_next(&self.inner, &token_type);
        try internal.enumToError(err);

        return switch (token_type) {
            lib.CON_DESERIALIZE_TYPE_NUMBER => .number,
            lib.CON_DESERIALIZE_TYPE_STRING => .string,
            lib.CON_DESERIALIZE_TYPE_BOOL => .bool,
            lib.CON_DESERIALIZE_TYPE_NULL => .null,
            lib.CON_DESERIALIZE_TYPE_ARRAY_OPEN => .array_open,
            lib.CON_DESERIALIZE_TYPE_ARRAY_CLOSE => .array_close,
            lib.CON_DESERIALIZE_TYPE_DICT_OPEN => .dict_open,
            lib.CON_DESERIALIZE_TYPE_DICT_CLOSE => .dict_close,
            lib.CON_DESERIALIZE_TYPE_DICT_KEY => .dict_key,
            else => error.Unknown,
        };
    }

    pub fn arrayOpen(self: *Deserialize) !void {
        const err = lib.con_deserialize_array_open(&self.inner);
        return internal.enumToError(err);
    }

    pub fn arrayClose(self: *Deserialize) !void {
        const err = lib.con_deserialize_array_close(&self.inner);
        return internal.enumToError(err);
    }

    pub fn dictOpen(self: *Deserialize) !void {
        const err = lib.con_deserialize_dict_open(&self.inner);
        return internal.enumToError(err);
    }

    pub fn dictClose(self: *Deserialize) !void {
        const err = lib.con_deserialize_dict_close(&self.inner);
        return internal.enumToError(err);
    }

    pub fn dictKey(self: *Deserialize, writer: zcon.InterfaceWriter) !void {
        const err = lib.con_deserialize_dict_key(&self.inner, writer.writer);
        return internal.enumToError(err);
    }

    pub fn number(self: *Deserialize, writer: zcon.InterfaceWriter) !void {
        const err = lib.con_deserialize_number(&self.inner, writer.writer);
        return internal.enumToError(err);
    }

    pub fn string(self: *Deserialize, writer: zcon.InterfaceWriter) !void {
        const err = lib.con_deserialize_string(&self.inner, writer.writer);
        return internal.enumToError(err);
    }

    pub fn @"bool"(self: *Deserialize) !bool {
        var value: bool = undefined;
        const err = lib.con_deserialize_bool(&self.inner, &value);
        try internal.enumToError(err);
        return value;
    }

    pub fn @"null"(self: *Deserialize) !void {
        const err = lib.con_deserialize_null(&self.inner);
        return internal.enumToError(err);
    }
};

const testing = std.testing;

test "context init" {
    const data = "";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    _ = try Deserialize.init(reader.interface(), &depth);
}

test "context init depth buffer overflow" {
    const data = "";
    var reader = try zcon.ReaderString.init(data);

    var fake_large_depth = try testing.allocator.alloc(u8, 2);
    fake_large_depth.len = @as(usize, std.math.maxInt(c_int)) + 1;
    defer {
        fake_large_depth.len = 2;
        testing.allocator.free(fake_large_depth);
    }

    const err = Deserialize.init(reader.interface(), fake_large_depth);
    try testing.expectError(error.Overflow, err);
}

// Section: Next ---------------------------------------------------------------

test "next empty" {
    const data = "  \n\t ";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    const err1 = context.next();
    try testing.expectError(error.Reader, err1);

    const err2 = context.next();
    try testing.expectError(error.Reader, err2);
}

test "next error" {
    const data = "";
    var r = try zcon.ReaderString.init(data);
    var reader = try zcon.ReaderFail.init(r.interface(), 0);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    const err1 = context.next();
    try testing.expectError(error.Reader, err1);

    const err2 = context.next();
    try testing.expectError(error.Reader, err2);
}

test "next number" {
    const data = " 1";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    const etype1 = try context.next();
    try testing.expectEqual(.number, etype1);

    const etype2 = try context.next();
    try testing.expectEqual(.number, etype2);
}

test "next string" {
    const data = " \"abc\"";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    const etype1 = try context.next();
    try testing.expectEqual(.string, etype1);

    const etype2 = try context.next();
    try testing.expectEqual(.string, etype2);
}

test "next bool true" {
    const data = "  true";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    const etype1 = try context.next();
    try testing.expectEqual(.bool, etype1);

    const etype2 = try context.next();
    try testing.expectEqual(.bool, etype2);
}

test "next bool false" {
    const data = "\tfalse";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    const etype1 = try context.next();
    try testing.expectEqual(.bool, etype1);

    const etype2 = try context.next();
    try testing.expectEqual(.bool, etype2);
}

test "next null" {
    const data = "null";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    const etype1 = try context.next();
    try testing.expectEqual(.null, etype1);

    const etype2 = try context.next();
    try testing.expectEqual(.null, etype2);
}

test "next array open" {
    const data = "[";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    const etype1 = try context.next();
    try testing.expectEqual(.array_open, etype1);

    const etype2 = try context.next();
    try testing.expectEqual(.array_open, etype2);
}

test "next array close" {
    const data = "[]";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.arrayOpen();

    {
        const etype1 = try context.next();
        try testing.expectEqual(.array_close, etype1);

        const etype2 = try context.next();
        try testing.expectEqual(.array_close, etype2);
    }
}

test "next array first" {
    const data = "[true]";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.arrayOpen();

    {
        const etype1 = try context.next();
        try testing.expectEqual(.bool, etype1);

        const etype2 = try context.next();
        try testing.expectEqual(.bool, etype2);
    }
}

test "next array second" {
    const data = "[null, 0.0]";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.arrayOpen();

    {
        try context.null();

        const etype1 = try context.next();
        try testing.expectEqual(.number, etype1);

        const etype2 = try context.next();
        try testing.expectEqual(.number, etype2);
    }
}

test "next dict open" {
    const data = "{";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    const etype1 = try context.next();
    try testing.expectEqual(.dict_open, etype1);

    const etype2 = try context.next();
    try testing.expectEqual(.dict_open, etype2);
}

test "next dict close" {
    const data = "{}";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.dictOpen();

    const etype1 = try context.next();
    try testing.expectEqual(.dict_close, etype1);

    const etype2 = try context.next();
    try testing.expectEqual(.dict_close, etype2);
}

test "next dict key" {
    const data = "{\"k\":";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.dictOpen();

    {
        const etype1 = try context.next();
        try testing.expectEqual(.dict_key, etype1);

        const etype2 = try context.next();
        try testing.expectEqual(.dict_key, etype2);
    }
}

test "next dict first" {
    const data = "{\"k\":\"a\"";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.dictOpen();

    {
        var buffer: [1]u8 = undefined;
        var writer = try zcon.WriterString.init(&buffer);
        try context.dictKey(writer.interface());
        try testing.expectEqualStrings("k", &buffer);

        const etype1 = try context.next();
        try testing.expectEqual(.string, etype1);

        const etype2 = try context.next();
        try testing.expectEqual(.string, etype2);
    }
}

test "next dict second" {
    const data = "{\"k\":\"a\",\"m\":\"b\"";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.dictOpen();

    {
        var buffer: [3]u8 = undefined;
        var writer = try zcon.WriterString.init(&buffer);

        try context.dictKey(writer.interface());
        try testing.expectEqualStrings("k", buffer[0..1]);

        try context.string(writer.interface());
        try testing.expectEqualStrings("a", buffer[1..2]);

        try context.dictKey(writer.interface());
        try testing.expectEqualStrings("m", buffer[2..3]);

        const etype1 = try context.next();
        try testing.expectEqual(.string, etype1);

        const etype2 = try context.next();
        try testing.expectEqual(.string, etype2);
    }
}

// Section: Values -------------------------------------------------------------

test "number int-like" {
    const data = "-6";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    var buffer: [4]u8 = undefined;
    var writer = try zcon.WriterString.init(&buffer);
    try context.number(writer.interface());
    try testing.expectEqual(2, writer.inner.current);
    try testing.expectEqualStrings("-6", buffer[0..2]);
}

test "number float-like" {
    const data = "0.3";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    var buffer: [5]u8 = undefined;
    var writer = try zcon.WriterString.init(&buffer);
    try context.number(writer.interface());
    try testing.expectEqual(3, writer.inner.current);
    try testing.expectEqualStrings("0.3", buffer[0..3]);
}

test "number scientific-like" {
    const data = "2e+4";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    var buffer: [5]u8 = undefined;
    var writer = try zcon.WriterString.init(&buffer);
    try context.number(writer.interface());
    try testing.expectEqual(4, writer.inner.current);
    try testing.expectEqualStrings("2e+4", buffer[0..4]);
}

test "number small" {
    const data = "";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    var buffer: [0]u8 = undefined;
    var writer = try zcon.WriterString.init(&buffer);
    const err = context.number(writer.interface());
    try testing.expectError(error.Reader, err);
    try testing.expectEqual(0, writer.inner.current);
}

test "number reader fail" {
    var reader: zcon.ReaderString = undefined;
    var buffer: [5]u8 = undefined;
    var writer: zcon.WriterString = undefined;

    var depth: [0]u8 = undefined;
    var context: Deserialize = undefined;

    const data1 = "2.";
    reader = try zcon.ReaderString.init(data1);
    writer = try zcon.WriterString.init(&buffer);
    context = try Deserialize.init(reader.interface(), &depth);
    const err1 = context.number(writer.interface());
    try testing.expectError(error.Reader, err1);
    try testing.expectEqual(2, writer.inner.current);
    try testing.expectEqualStrings("2.", buffer[0..2]);

    const data2 = "2.5E";
    reader = try zcon.ReaderString.init(data2);
    writer = try zcon.WriterString.init(&buffer);
    context = try Deserialize.init(reader.interface(), &depth);
    const err2 = context.number(writer.interface());
    try testing.expectError(error.Reader, err2);
    try testing.expectEqual(4, writer.inner.current);
    try testing.expectEqualStrings("2.5E", buffer[0..4]);

    const data3 = "-";
    reader = try zcon.ReaderString.init(data3);
    writer = try zcon.WriterString.init(&buffer);
    context = try Deserialize.init(reader.interface(), &depth);
    const err3 = context.number(writer.interface());
    try testing.expectError(error.Reader, err3);
    try testing.expectEqual(1, writer.inner.current);
    try testing.expectEqualStrings("-", buffer[0..1]);

    const data4 = "3.4e-";
    reader = try zcon.ReaderString.init(data4);
    writer = try zcon.WriterString.init(&buffer);
    context = try Deserialize.init(reader.interface(), &depth);
    const err4 = context.number(writer.interface());
    try testing.expectError(error.Reader, err4);
    try testing.expectEqual(5, writer.inner.current);
    try testing.expectEqualStrings("3.4e-", buffer[0..5]);
}

test "number invalid" {
    var reader: zcon.ReaderString = undefined;
    var buffer: [5]u8 = undefined;
    var writer: zcon.WriterString = undefined;

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    const data1 = "+";
    reader = try zcon.ReaderString.init(data1);
    writer = try zcon.WriterString.init(&buffer);
    const err1 = context.number(writer.interface());
    try testing.expectError(error.InvalidJson, err1);
    try testing.expectEqual(0, writer.inner.current);

    const data2 = "0f";
    reader = try zcon.ReaderString.init(data2);
    writer = try zcon.WriterString.init(&buffer);
    context = try Deserialize.init(reader.interface(), &depth);
    const err2 = context.number(writer.interface());
    try testing.expectError(error.InvalidJson, err2);
    try testing.expectEqual(1, writer.inner.current);
    try testing.expectEqualStrings("0", buffer[0..1]);
}

test "string" {
    const data = "\"a b\"";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    var buffer: [5]u8 = undefined;
    var writer = try zcon.WriterString.init(&buffer);
    try context.string(writer.interface());
    try testing.expectEqual(3, writer.inner.current);
    try testing.expectEqualStrings("a b", buffer[0..3]);
}

test "string escaped" {
    const data = "\"\\\"\\\\\\/\\b\\f\\n\\r\\t\\u12f4\"";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    var buffer: [16]u8 = undefined;
    var writer = try zcon.WriterString.init(&buffer);
    try context.string(writer.interface());
    try testing.expectEqual(10, writer.inner.current);
    try testing.expectEqualStrings("\"\\/\x08\x0c\n\r\t\x12\xf4", buffer[0..10]);
}

test "string invalid" {
    var reader: zcon.ReaderString = undefined;
    var buffer: [5]u8 = undefined;
    var writer: zcon.WriterString = undefined;

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    const data1 = "ab\"";
    reader = try zcon.ReaderString.init(data1);
    writer = try zcon.WriterString.init(&buffer);
    const err1 = context.string(writer.interface());
    try testing.expectError(error.InvalidJson, err1);
    try testing.expectEqual(0, writer.inner.current);

    const data2 = "\"ab";
    reader = try zcon.ReaderString.init(data2);
    writer = try zcon.WriterString.init(&buffer);
    context = try Deserialize.init(reader.interface(), &depth);
    const err2 = context.string(writer.interface());
    try testing.expectError(error.Reader, err2);
    try testing.expectEqual(2, writer.inner.current);
    try testing.expectEqualStrings("ab", buffer[0..2]);

    const data3 = "\"1\\h";
    reader = try zcon.ReaderString.init(data3);
    writer = try zcon.WriterString.init(&buffer);
    context = try Deserialize.init(reader.interface(), &depth);
    const err3 = context.string(writer.interface());
    try testing.expectError(error.InvalidJson, err3);
    try testing.expectEqual(1, writer.inner.current);
    try testing.expectEqualStrings("1", buffer[0..1]);

    const data4 = "\"2\\u123";
    reader = try zcon.ReaderString.init(data4);
    writer = try zcon.WriterString.init(&buffer);
    context = try Deserialize.init(reader.interface(), &depth);
    const err4 = context.string(writer.interface());
    try testing.expectError(error.Reader, err4);
    try testing.expectEqual(1, writer.inner.current);
    try testing.expectEqualStrings("2", buffer[0..1]);

    const data5 = "\"3\\u123G";
    reader = try zcon.ReaderString.init(data5);
    writer = try zcon.WriterString.init(&buffer);
    context = try Deserialize.init(reader.interface(), &depth);
    const err5 = context.string(writer.interface());
    try testing.expectError(error.InvalidJson, err5);
    try testing.expectEqual(1, writer.inner.current);
    try testing.expectEqualStrings("3", buffer[0..1]);
}

test "bool true" {
    const data = "true";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    const val = try context.bool();
    try testing.expectEqual(true, val);
}

test "bool false" {
    const data = "false";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    const val = try context.bool();
    try testing.expectEqual(false, val);
}

test "bool invalid" {
    var depth: [0]u8 = undefined;
    var reader: zcon.ReaderString = undefined;
    var context: Deserialize = undefined;

    const data1 = "t";
    reader = try zcon.ReaderString.init(data1);
    context = try Deserialize.init(reader.interface(), &depth);
    const err1 = context.bool();
    try testing.expectError(error.Reader, err1);

    const data2 = "f a l s e";
    reader = try zcon.ReaderString.init(data2);
    context = try Deserialize.init(reader.interface(), &depth);
    const err2 = context.bool();
    try testing.expectError(error.InvalidJson, err2);

    const data3 = "talse";
    reader = try zcon.ReaderString.init(data3);
    context = try Deserialize.init(reader.interface(), &depth);
    const err3 = context.bool();
    try testing.expectError(error.InvalidJson, err3);

    const data4 = "frue";
    reader = try zcon.ReaderString.init(data4);
    context = try Deserialize.init(reader.interface(), &depth);
    const err4 = context.bool();
    try testing.expectError(error.InvalidJson, err4);

    const data5 = "f,";
    reader = try zcon.ReaderString.init(data5);
    context = try Deserialize.init(reader.interface(), &depth);
    const err5 = context.bool();
    try testing.expectError(error.InvalidJson, err5);

    const data6 = "truet";
    reader = try zcon.ReaderString.init(data6);
    context = try Deserialize.init(reader.interface(), &depth);
    const err6 = context.bool();
    try testing.expectError(error.InvalidJson, err6);
}

test "null" {
    const data = "null";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.null();
}

test "null invalid" {
    var depth: [0]u8 = undefined;
    var reader: zcon.ReaderString = undefined;
    var context: Deserialize = undefined;

    const data1 = "n";
    reader = try zcon.ReaderString.init(data1);
    context = try Deserialize.init(reader.interface(), &depth);
    const err1 = context.null();
    try testing.expectError(error.Reader, err1);

    const data2 = "nulll";
    reader = try zcon.ReaderString.init(data2);
    context = try Deserialize.init(reader.interface(), &depth);
    const err2 = context.null();
    try testing.expectError(error.InvalidJson, err2);

    const data3 = "nu ll";
    reader = try zcon.ReaderString.init(data3);
    context = try Deserialize.init(reader.interface(), &depth);
    const err3 = context.null();
    try testing.expectError(error.InvalidJson, err3);
}

// Section: Containers ---------------------------------------------------------

test "array open" {
    const data = "[";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.arrayOpen();
}

test "array open too many" {
    const data = "[";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    const err = context.arrayOpen();
    try testing.expectError(error.TooDeep, err);
}

test "array nested open too many" {
    const data = "[1,[";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.arrayOpen();

    {
        var buffer: [1]u8 = undefined;
        var writer = try zcon.WriterString.init(&buffer);
        try context.number(writer.interface());

        const err = context.arrayOpen();
        try testing.expectError(error.TooDeep, err);
    }
}

test "array open reader fail" {
    const data = "";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    const err = context.arrayOpen();
    try testing.expectError(error.Reader, err);
}

test "array close" {
    const data = "[]";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.arrayOpen();
    try context.arrayClose();
}

test "array close too many" {
    const data = "]";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    const err = context.arrayClose();
    try testing.expectError(error.ClosedTooMany, err);
}

test "array close reader fail" {
    const data = "[";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.arrayOpen();
    const err = context.arrayClose();
    try testing.expectError(error.Reader, err);
}

test "dict open" {
    const data = "{";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.dictOpen();
}

test "dict open too many" {
    const data = "{";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    const err = context.dictOpen();
    try testing.expectError(error.TooDeep, err);
}

test "dict nested open too many" {
    const data = "[1,{";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.arrayOpen();

    {
        var buffer: [1]u8 = undefined;
        var writer = try zcon.WriterString.init(&buffer);
        try context.number(writer.interface());

        const err = context.dictOpen();
        try testing.expectError(error.TooDeep, err);
    }
}

test "dict open reader fail" {
    const data = "";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    const err = context.dictOpen();
    try testing.expectError(error.Reader, err);
}

test "dict close" {
    const data = "{}";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.dictOpen();
    try context.dictClose();
}

test "dict close too many" {
    const data = "}";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    const err = context.dictClose();
    try testing.expectError(error.ClosedTooMany, err);
}

test "dict close reader fail" {
    const data = "{";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.dictOpen();

    const err = context.dictClose();
    try testing.expectError(error.Reader, err);
}

// Section: Dict key -----------------------------------------------------------

test "dict key" {
    const data = "{\"k\":";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.dictOpen();

    {
        var buffer: [1]u8 = undefined;
        var writer = try zcon.WriterString.init(&buffer);
        try context.dictKey(writer.interface());
        try testing.expectEqualStrings("k", &buffer);
    }
}

test "dict key multiple" {
    const data = "{\"k\":null,\"m\":";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.dictOpen();

    {
        var buffer: [2]u8 = undefined;
        var writer = try zcon.WriterString.init(&buffer);
        try context.dictKey(writer.interface());
        try testing.expectEqualStrings("k", buffer[0..1]);

        try context.null();

        try context.dictKey(writer.interface());
        try testing.expectEqualStrings("m", buffer[1..2]);
    }
}

test "dict key reader fail" {
    const data = "{\"k";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.dictOpen();

    {
        var buffer: [1]u8 = undefined;
        var writer = try zcon.WriterString.init(&buffer);

        const err = context.dictKey(writer.interface());
        try testing.expectError(error.Reader, err);
        try testing.expectEqualStrings("k", &buffer);
    }
}

test "dict key colon reader fail" {
    const data = "{\"k\"";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.dictOpen();

    {
        var buffer: [1]u8 = undefined;
        var writer = try zcon.WriterString.init(&buffer);

        const err = context.dictKey(writer.interface());
        try testing.expectError(error.Reader, err);
        try testing.expectEqualStrings("k", &buffer);
    }
}

test "dict key outside dict" {
    const data = "\"k\"";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    var buffer: [1]u8 = undefined;
    var writer = try zcon.WriterString.init(&buffer);

    const err = context.dictKey(writer.interface());
    try testing.expectError(error.Type, err);
    try testing.expectEqual(0, writer.inner.current);
}

test "dict key in array" {
    const data = "[\"k\":";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.arrayOpen();

    {
        var buffer: [1]u8 = undefined;
        var writer = try zcon.WriterString.init(&buffer);

        const err = context.dictKey(writer.interface());
        try testing.expectError(error.Type, err);
        try testing.expectEqual(0, writer.inner.current);
    }
}

test "dict key twice" {
    const data = "{\"k\":\"m\":";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.dictOpen();

    {
        var buffer: [2]u8 = undefined;
        var writer = try zcon.WriterString.init(&buffer);
        try context.dictKey(writer.interface());
        try testing.expectEqualStrings("k", buffer[0..1]);

        const err = context.dictKey(writer.interface());
        try testing.expectError(error.Type, err);
    }
}

test "dict number key missing" {
    const data = "{3";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.dictOpen();

    {
        var buffer: [2]u8 = undefined;
        var writer = try zcon.WriterString.init(&buffer);
        const err = context.number(writer.interface());
        try testing.expectError(error.Key, err);
        try testing.expectEqual(0, writer.inner.current);
    }
}

test "dict number second key missing" {
    const data = "{\"k\":3,4";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.dictOpen();

    {
        var buffer: [2]u8 = undefined;
        var writer = try zcon.WriterString.init(&buffer);

        try context.dictKey(writer.interface());
        try testing.expectEqualStrings("k", buffer[0..1]);

        try context.number(writer.interface());
        try testing.expectEqualStrings("3", buffer[1..2]);

        const err = context.number(writer.interface());
        try testing.expectError(error.Key, err);
        try testing.expectEqual(2, writer.inner.current);
    }
}

test "dict string key missing" {
    const data = "{\"k\"";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.dictOpen();

    {
        var buffer: [2]u8 = undefined;
        var writer = try zcon.WriterString.init(&buffer);
        const err = context.string(writer.interface());
        try testing.expectError(error.Key, err);
        try testing.expectEqual(0, writer.inner.current);
    }
}

test "dict string second key missing" {
    const data = "{\"k\":\"a\",\"b\"";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.dictOpen();

    {
        var buffer: [2]u8 = undefined;
        var writer = try zcon.WriterString.init(&buffer);

        try context.dictKey(writer.interface());
        try testing.expectEqualStrings("k", buffer[0..1]);

        try context.string(writer.interface());
        try testing.expectEqualStrings("a", buffer[1..2]);

        const err = context.string(writer.interface());
        try testing.expectError(error.Key, err);
        try testing.expectEqual(2, writer.inner.current);
    }
}

test "dict array key missing" {
    const data = "{[";
    var reader = try zcon.ReaderString.init(data);

    var depth: [2]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.dictOpen();

    {
        const err = context.arrayOpen();
        try testing.expectError(error.Key, err);
    }
}

test "dict array second key missing" {
    const data = "{\"k\":[],[";
    var reader = try zcon.ReaderString.init(data);

    var depth: [2]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.dictOpen();

    {
        var buffer: [1]u8 = undefined;
        var writer = try zcon.WriterString.init(&buffer);
        try context.dictKey(writer.interface());
        try testing.expectEqualStrings("k", &buffer);

        try context.arrayOpen();
        try context.arrayClose();

        const err = context.arrayOpen();
        try testing.expectError(error.Key, err);
    }
}

test "dict dict key missing" {
    const data = "{{";
    var reader = try zcon.ReaderString.init(data);

    var depth: [2]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.dictOpen();

    {
        const err = context.dictOpen();
        try testing.expectError(error.Key, err);
    }
}

test "dict dict second key missing" {
    const data = "{\"k\":{},{";
    var reader = try zcon.ReaderString.init(data);

    var depth: [2]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.dictOpen();

    {
        var buffer: [1]u8 = undefined;
        var writer = try zcon.WriterString.init(&buffer);
        try context.dictKey(writer.interface());
        try testing.expectEqualStrings("k", &buffer);

        try context.dictOpen();
        try context.dictClose();

        const err = context.dictOpen();
        try testing.expectError(error.Key, err);
    }
}

// Section: Combinations of containers -----------------------------------------

test "array open -> dict close" {
    const data = "[}";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.arrayOpen();

    const err = context.dictClose();
    try testing.expectError(error.NotDict, err);
}

test "dict open -> array close" {
    const data = "{]";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.dictOpen();

    const err = context.arrayClose();
    try testing.expectError(error.NotArray, err);
}

test "array number single" {
    const data = "[2]";
    var reader = try zcon.ReaderString.init(data);

    var depth: [1]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    try context.arrayOpen();

    {
        var buffer: [1]u8 = undefined;
        var writer = try zcon.WriterString.init(&buffer);

        try context.number(writer.interface());
        try testing.expectEqualStrings("2", &buffer);
    }

    try context.arrayClose();
}
