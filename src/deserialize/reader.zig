const gci = @import("gci");
const internal = @import("../internal.zig");
const lib = internal.lib;

pub const Comment = struct {
    inner: lib.ConReaderComment,

    pub fn init(reader: gci.InterfaceReader) !Comment {
        var self: Comment = undefined;
        const err = lib.con_reader_comment_init(
            &self.inner,
            @as(*lib.GciInterfaceReader, @ptrCast(@constCast(&reader.reader))).*,
        );
        try internal.enumToError(err);
        return self;
    }

    pub fn interface(self: *Comment) gci.InterfaceReader {
        const temp: gci.InterfaceReader = undefined;
        return .{ .reader = @as(
            *@TypeOf(temp.reader),
            @ptrCast(@constCast(&lib.con_reader_comment_interface(&self.inner))),
        ).* };
    }
};

const testing = @import("std").testing;

test "comment init" {
    const d = "";
    var c = try gci.ReaderString.init(d);

    var context = try Comment.init(c.interface());
    _ = context.interface();
}

test "comment read" {
    const d = "12";
    var c = try gci.ReaderString.init(d);

    var context = try Comment.init(c.interface());
    const reader = context.interface();

    var buffer: [2]u8 = undefined;
    const result = try reader.read(&buffer);
    try testing.expectEqualStrings("12", result);
}

test "comment read comment" {
    const d = "[  //:(\n \"k //:)\",1/]";
    var c = try gci.ReaderString.init(d);

    var context = try Comment.init(c.interface());
    const reader = context.interface();

    var buffer: [17]u8 = undefined;
    const result = try reader.read(&buffer);
    try testing.expectEqualStrings("[  \n \"k //:)\",1/]", result);
}

test "comment read comment one char at a time" {
    const d = "[  //:(\n \"k //:)\",1/]";
    var c = try gci.ReaderString.init(d);

    var context = try Comment.init(c.interface());
    const reader = context.interface();

    var buffer: [17]u8 = undefined;
    for (0..17) |i| {
        const result = try reader.read(buffer[i .. i + 1]);
        try testing.expectEqual(1, result.len);
    }

    try testing.expectEqualStrings("[  \n \"k //:)\",1/]", &buffer);
}

test "comment inner reader empty" {
    const d = "";
    var c = try gci.ReaderString.init(d);

    var context = try Comment.init(c.interface());
    const reader = context.interface();

    var buffer: [1]u8 = undefined;
    const err = reader.read(&buffer);
    try testing.expectError(error.Reader, err);
}

test "comment inner reader empty comment" {
    const d = "/";
    var c = try gci.ReaderString.init(d);

    var context = try Comment.init(c.interface());
    const reader = context.interface();

    var buffer: [1]u8 = undefined;
    const err = reader.read(&buffer);
    try testing.expectError(error.Reader, err);
}

test "comment inner reader fail" {
    var c1 = try gci.ReaderString.init("1");
    var c2 = try gci.ReaderFail.init(c1.interface(), 0);

    var context = try Comment.init(c2.interface());
    const reader = context.interface();

    var buffer: [1]u8 = undefined;
    const err = reader.read(&buffer);
    try testing.expectError(error.Reader, err);
}

test "comment inner reader fail comment" {
    var c1 = try gci.ReaderString.init("/");
    var c2 = try gci.ReaderFail.init(c1.interface(), 1);

    var context = try Comment.init(c2.interface());
    const reader = context.interface();

    var buffer: [1]u8 = undefined;
    const err1 = reader.read(&buffer);
    try testing.expectError(error.Reader, err1);

    const err2 = reader.read(&buffer);
    try testing.expectError(error.Reader, err2);
}

test "comment read only comment" {
    const d = "// only a comment";
    var c = try gci.ReaderString.init(d);

    var context = try Comment.init(c.interface());
    const reader = context.interface();

    var buffer: [3]u8 = undefined;
    const err1 = reader.read(&buffer);
    try testing.expectError(error.Reader, err1);
}

test "comment read clear error" {
    var c1 = try gci.ReaderString.init("1");
    var c2 = try gci.ReaderFail.init(c1.interface(), 0);

    var context = try Comment.init(c2.interface());
    const reader = context.interface();

    var buffer: [2]u8 = undefined;
    const err = reader.read(&buffer);
    try testing.expectError(error.Reader, err);

    c2.inner.reads_before_fail = 1;
    const result = try reader.read(&buffer);
    try testing.expectEqualStrings("1", result);
}

test "comment read comment clear error" {
    var c1 = try gci.ReaderString.init("//\n1");
    var c2 = try gci.ReaderFail.init(c1.interface(), 1);

    var context = try Comment.init(c2.interface());
    const reader = context.interface();

    var buffer: [3]u8 = undefined;
    const err = reader.read(&buffer);
    try testing.expectError(error.Reader, err);
    try testing.expectEqual('/', context.inner.buffer_char);

    c2.inner.reads_before_fail = 4;
    const result = try reader.read(&buffer);
    try testing.expectEqualStrings("\n1", result);
}

test "comment reader half comment clear error" {
    var c1 = try gci.ReaderString.init("/1");
    var c2 = try gci.ReaderFail.init(c1.interface(), 1);

    var context = try Comment.init(c2.interface());
    const reader = context.interface();

    var buffer: [3]u8 = undefined;
    const err = reader.read(&buffer);
    try testing.expectError(error.Reader, err);
    try testing.expectEqual('/', context.inner.buffer_char);

    c2.inner.reads_before_fail = 2;
    const result = try reader.read(&buffer);
    try testing.expectEqualStrings("/1", result);
}
