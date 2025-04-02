const gci = @import("gci");
const internal = @import("../internal.zig");
const lib = internal.lib;

pub const Indent = struct {
    inner: lib.ConWriterIndent,

    pub fn init(writer: gci.InterfaceWriter) !Indent {
        var self: Indent = undefined;
        const err = lib.con_writer_indent_init(&self.inner, @as(*lib.GciInterfaceWriter, @ptrCast(@constCast(&writer.writer))).*);
        try internal.enumToError(err);
        return self;
    }

    pub fn interface(self: *Indent) gci.InterfaceWriter {
        const temp: gci.InterfaceWriter = undefined;
        return .{ .writer = @as(
            *@TypeOf(temp.writer),
            @ptrCast(@constCast(&lib.con_writer_indent_interface(&self.inner))),
        ).* };
    }
};

const testing = @import("std").testing;

test "indent init" {
    var b: [0]u8 = undefined;
    var c = try gci.WriterString.init(&b);
    var context = try Indent.init(c.interface());
    _ = context.interface();
}

test "indent write" {
    var b: [1]u8 = undefined;
    var c = try gci.WriterString.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    try writer.write("1");
    try testing.expectEqualStrings("1", &b);
}

test "indent write minified" {
    var b: [56]u8 = undefined;
    var c = try gci.WriterString.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    try writer.write("[{\"k\" : \":)\"}\n\t,  \r\nnull,\"\\\"{1,2,3} [1,2,3]\"]");
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
    var c = try gci.WriterString.init(&b);
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

test "indent empty container" {
    var b: [14]u8 = undefined;
    var c = try gci.WriterString.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const str = "[{},[]]";

    for (str) |ch| {
        const single: [1]u8 = .{ch};
        try writer.write(&single);
    }

    try testing.expectEqualStrings(
        \\[
        \\  {},
        \\  []
        \\]
    ,
        &b,
    );
}

test "indent body writer fail" {
    var b: [0]u8 = undefined;
    var c = try gci.WriterString.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const err = writer.write("1");
    try testing.expectError(error.Writer, err);
}

test "indent newline array open writer fail" {
    var b: [1]u8 = undefined;
    var c = try gci.WriterString.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const err = writer.write("[1]");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("[", &b);
}

test "indent whitespace array open writer fail" {
    var b: [2]u8 = undefined;
    var c = try gci.WriterString.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const err = writer.write("[1]");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("[\n", &b);
}

test "indent newline array close writer fail" {
    var b: [5]u8 = undefined;
    var c = try gci.WriterString.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const err = writer.write("[1]");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("[\n  1", &b);
}

test "indent whitespace array close writer fail" {
    var b: [6]u8 = undefined;
    var c = try gci.WriterString.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const err = writer.write("[1]");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("[\n  1\n", &b);
}

test "indent newline dict writer fail" {
    var b: [1]u8 = undefined;
    var c = try gci.WriterString.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const err = writer.write("{\"");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("{", &b);
}

test "indent whitespace dict writer fail" {
    var b: [2]u8 = undefined;
    var c = try gci.WriterString.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const err = writer.write("{\"");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("{\n", &b);
}

test "indent newline dict close writer fail" {
    var b: [10]u8 = undefined;
    var c = try gci.WriterString.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const err = writer.write("{\"k\":1}");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("{\n  \"k\": 1", &b);
}

test "indent whitespace dict close writer fail" {
    var b: [11]u8 = undefined;
    var c = try gci.WriterString.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const err = writer.write("{\"k\":1}");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("{\n  \"k\": 1\n", &b);
}

test "indent space writer fail" {
    var b: [8]u8 = undefined;
    var c = try gci.WriterString.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const err = writer.write("{\"k\":1}");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("{\n  \"k\":", &b);
}

test "indent newline comma writer fail" {
    var b: [6]u8 = undefined;
    var c = try gci.WriterString.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const err = writer.write("[1,2]");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("[\n  1,", &b);
}

test "indent whitespace comma writer fail" {
    var b: [7]u8 = undefined;
    var c = try gci.WriterString.init(&b);
    var context = try Indent.init(c.interface());
    const writer = context.interface();

    const err = writer.write("[1,2]");
    try testing.expectError(error.Writer, err);
    try testing.expectEqualStrings("[\n  1,\n", &b);
}
