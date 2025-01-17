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

        pub fn init(w: Writer) !Self {
            var context = Self{
                .writer = w,
                .inner = undefined,
            };

            const err = con.con_serialize_context_init(
                &context.inner,
                &context.writer,
                Self.writeCallback,
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
                else => return error.Unknown,
            }
        }
    };
}

const Fifo = std.fifo.LinearFifo(u8, .Slice);
const testing = std.testing;

test "context init" {
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);

    const context = try Serialize(Fifo.Writer).init(fifo.writer());
    defer context.deinit();
}

test "array open" {
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer());
    defer context.deinit();

    try context.arrayOpen();
    try testing.expectEqualStrings("[", &buffer);
}

test "array open full buffer" {
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer());
    defer context.deinit();

    const err = context.arrayOpen();
    try testing.expectError(error.Writer, err);
}

test "array close" {
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer());
    defer context.deinit();

    context.inner.depth = 1;
    try context.arrayClose();
    try testing.expectEqualStrings("]", &buffer);
}

test "array close full buffer" {
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer());
    defer context.deinit();

    context.inner.depth = 1;
    const err = context.arrayClose();
    try testing.expectError(error.Writer, err);
}

test "array close too many" {
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer());
    defer context.deinit();

    const err = context.arrayClose();
    try testing.expectError(error.ClosedTooMany, err);
}

test "dict open" {
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer());
    defer context.deinit();

    try context.dictOpen();
    try testing.expectEqualStrings("{", &buffer);
}

test "dict open full buffer" {
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer());
    defer context.deinit();

    const err = context.dictOpen();
    try testing.expectError(error.Writer, err);
}

test "dict close" {
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer());
    defer context.deinit();

    context.inner.depth = 1;
    try context.dictClose();
    try testing.expectEqualStrings("}", &buffer);
}

test "dict close full buffer" {
    var buffer: [0]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer());
    defer context.deinit();

    context.inner.depth = 1;
    const err = context.dictClose();
    try testing.expectError(error.Writer, err);
}

test "dict close too many" {
    var buffer: [1]u8 = undefined;
    var fifo = Fifo.init(&buffer);
    var context = try Serialize(Fifo.Writer).init(fifo.writer());
    defer context.deinit();

    const err = context.dictClose();
    try testing.expectError(error.ClosedTooMany, err);
}
