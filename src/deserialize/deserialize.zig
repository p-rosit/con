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

    const err = context.next();
    try testing.expectError(error.Reader, err);
}

test "next number" {
    const data = " 12";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    const etype = try context.next();
    try testing.expectEqual(.number, etype);
}

test "next string" {
    const data = " \"abc\"";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    const etype = try context.next();
    try testing.expectEqual(.string, etype);
}

test "next bool true" {
    const data = "  true";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    const etype = try context.next();
    try testing.expectEqual(.bool, etype);
}

test "next bool false" {
    const data = "\tfalse";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    const etype = try context.next();
    try testing.expectEqual(.bool, etype);
}

test "next null" {
    const data = "null";
    var reader = try zcon.ReaderString.init(data);

    var depth: [0]u8 = undefined;
    var context = try Deserialize.init(reader.interface(), &depth);

    const etype = try context.next();
    try testing.expectEqual(.null, etype);
}
