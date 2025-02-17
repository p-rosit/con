const std = @import("std");
const zcon = @import("../con.zig");
const internal = @import("../internal.zig");
const lib = internal.lib;

pub const Deserialize = struct {
    inner: lib.ConDeserialize,

    pub fn init(reader: zcon.InterfaceReader) !Deserialize {
        var context = Deserialize{ .inner = undefined };
        const err = lib.con_deserialize_init(
            &context.inner,
            reader.reader,
        );

        internal.enumToError(err) catch |new_err| {
            return new_err;
        };
        return context;
    }
};

const testing = std.testing;

test "context init" {
    const data = "";
    var reader = try zcon.ReaderString.init(data);

    _ = try Deserialize.init(reader.interface());
}
