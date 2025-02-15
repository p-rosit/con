const serialize = @import("serialize/serialize.zig");
const writer = @import("serialize/writer.zig");
const reader = @import("deserialize/reader.zig");

pub const InterfaceWriter = writer.InterfaceWriter;
pub const Serialize = serialize.Serialize;

pub const Writer = writer.Writer;
pub const WriterFile = writer.File;
pub const WriterString = writer.String;
pub const WriterBuffer = writer.Buffer;
pub const WriterIndent = writer.Indent;

pub const Reader = reader.Reader;
pub const ReaderFile = reader.File;
pub const ReaderString = reader.String;
pub const ReaderBuffer = reader.Buffer;
pub const ReaderComment = reader.Comment;
pub const ReaderFail = reader.Fail;

test {
    @import("std").testing.refAllDecls(@This());
    _ = @import("serialize/test/test_serialize.zig");
    _ = @import("serialize/test/test_writer.zig");

    _ = @import("deserialize/test/test_reader.zig");
}
