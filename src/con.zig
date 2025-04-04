const lib = @import("internal.zig").lib;
const serialize = @import("serialize/serialize.zig");
const writer = @import("serialize/writer.zig");
const deserialize = @import("deserialize/deserialize.zig");
const reader = @import("deserialize/reader.zig");

pub const State = lib.ConState;
pub const Container = lib.ConContainer;

pub const Serialize = serialize.Serialize;
pub const WriterIndent = writer.Indent;

pub const DeserializeType = deserialize.Type;
pub const Deserialize = deserialize.Deserialize;
pub const ReaderComment = reader.Comment;

test {
    @import("std").testing.refAllDecls(@This());
    _ = @import("serialize/test/test_serialize.zig");
    _ = @import("serialize/test/test_writer.zig");

    _ = @import("deserialize/test/test_deserialize.zig");
    _ = @import("deserialize/test/test_reader.zig");
}
