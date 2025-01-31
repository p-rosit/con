const serialize = @import("src/serialize/serialize.zig");
const writer = @import("src/serialize/writer.zig");

pub const Serialize = serialize.Serialize;
pub const Writer = writer.Writer;
pub const File = writer.File;
pub const String = writer.String;
pub const Buffer = writer.Buffer;
pub const Indent = writer.Indent;

test {
    _ = @import("src/serialize/serialize.zig");
    _ = @import("src/serialize/writer.zig");
    _ = @import("src/serialize/test/test.zig");
    _ = @import("src/serialize/test/test_writer.zig");
}
