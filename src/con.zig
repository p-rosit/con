const serialize = @import("serialize/serialize.zig");
const writer = @import("serialize/writer.zig");

pub const Serialize = serialize.Serialize;
pub const Writer = writer.Writer;
pub const File = writer.File;
pub const String = writer.String;
pub const Buffer = writer.Buffer;
pub const Indent = writer.Indent;

test {
    _ = @import("serialize/serialize.zig");
    _ = @import("serialize/writer.zig");
    _ = @import("serialize/test/test.zig");
    _ = @import("serialize/test/test_writer.zig");
}
