const serialize = @import("src/serialize/serialize.zig");

pub const Serialize = serialize.Serialize;
pub const IndentJson = serialize.IndentJson;

test {
    _ = @import("src/serialize/serialize.zig");
    _ = @import("src/serialize/test/test.zig");
    _ = @import("src/serialize/test/test_writer.zig");
}
