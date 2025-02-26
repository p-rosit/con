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
    key,
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

        internal.enumToError(err) catch |new_err| {
            return new_err;
        };
        return context;
    }

    pub fn next(self: *Deserialize) !Type {
        var token_type: lib.ConDeserializeType = undefined;
        const err = lib.con_deserialize_next(&self.inner, &token_type);

        internal.enumToError(err) catch |new_err| {
            return new_err;
        };

        return switch (token_type) {
            lib.CON_DESERIALIZE_TYPE_NUMBER => .number,
            lib.CON_DESERIALIZE_TYPE_STRING => .string,
            lib.CON_DESERIALIZE_TYPE_BOOL => .bool,
            lib.CON_DESERIALIZE_TYPE_NULL => .null,
            lib.CON_DESERIALIZE_TYPE_ARRAY_OPEN => .array_open,
            lib.CON_DESERIALIZE_TYPE_ARRAY_CLOSE => .array_close,
            lib.CON_DESERIALIZE_TYPE_DICT_OPEN => .dict_open,
            lib.CON_DESERIALIZE_TYPE_DICT_CLOSE => .dict_close,
            lib.CON_DESERIALIZE_TYPE_KEY => .key,
            else => error.Unknown,
        };
    }

    pub fn number(self: *Deserialize, buffer: []u8) ![]u8 {
        var length: usize = undefined;
        const err = lib.con_deserialize_number(
            &self.inner,
            buffer.ptr,
            buffer.len,
            &length,
        );
        internal.enumToError(err) catch |e| {
            return e;
        };
        return buffer[0..length];
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
    try testing.expectError(error.Empty, err1);

    const err2 = context.next();
    try testing.expectError(error.Empty, err2);
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

// Section: Values -------------------------------------------------------------

test "number int-like" {
    const data = "-6";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    var buffer: [4]u8 = undefined;
    const num = try context.number(&buffer);
    try testing.expectEqualStrings("-6", num);
}

test "number int-like one character at a time" {
    const data = "-6";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    var buffer: [1]u8 = undefined;
    const err1 = context.number(&buffer);
    try testing.expectError(error.Buffer, err1);
    try testing.expectEqualStrings("-", &buffer);

    const num = try context.number(&buffer);
    try testing.expectEqualStrings("6", num);
}

test "number float-like" {
    const data = "0.3";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    var buffer: [5]u8 = undefined;
    const num = try context.number(&buffer);
    try testing.expectEqualStrings("0.3", num);
}

test "number float-like one character at a time" {
    const data = "0.3";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    var buffer: [1]u8 = undefined;
    const err1 = context.number(&buffer);
    try testing.expectError(error.Buffer, err1);
    try testing.expectEqualStrings("0", &buffer);

    const err2 = context.number(&buffer);
    try testing.expectError(error.Buffer, err2);
    try testing.expectEqualStrings(".", &buffer);

    const num = try context.number(&buffer);
    try testing.expectEqualStrings("3", num);
}

test "number scientific-like" {
    const data = "2e+4";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    var buffer: [5]u8 = undefined;
    const num = try context.number(&buffer);
    try testing.expectEqualStrings("2e+4", num);
}

test "number scientific-like one character at a time" {
    const data = "2e+4";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    var buffer: [1]u8 = undefined;
    const err1 = context.number(&buffer);
    try testing.expectError(error.Buffer, err1);
    try testing.expectEqualStrings("2", &buffer);

    const err2 = context.number(&buffer);
    try testing.expectError(error.Buffer, err2);
    try testing.expectEqualStrings("e", &buffer);

    const err3 = context.number(&buffer);
    try testing.expectError(error.Buffer, err3);
    try testing.expectEqualStrings("+", &buffer);

    const num = try context.number(&buffer);
    try testing.expectEqualStrings("4", num);
}

test "number small" {
    const data = "";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    var buffer: [0]u8 = undefined;
    const err = context.number(&buffer);
    try testing.expectError(error.NotNumber, err);
}
