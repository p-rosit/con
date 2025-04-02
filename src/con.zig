const lib = @import("internal.zig").lib;
const serialize = @import("serialize/serialize.zig");
const writer = @import("serialize/writer.zig");
const deserialize = @import("deserialize/deserialize.zig");
const reader = @import("deserialize/reader.zig");

pub const State = lib.ConState;
pub const Container = lib.ConContainer;

pub const Serialize = serialize.Serialize;
pub const WriterIndent = writer.Indent;

pub const InterfaceReader = reader.InterfaceReader;
pub const Deserialize = deserialize.Deserialize;

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

    _ = @import("deserialize/test/test_deserialize.zig");
    _ = @import("deserialize/test/test_reader.zig");
}
