const std = @import("std");
const con = @cImport({
    @cInclude("serialize.h");
});

pub const Serialize = struct {
    c: con.ConSerialize,

    pub fn init(buffer: []c_char) !Serialize {
        var context: Serialize = undefined;
        if (buffer.len > std.math.maxInt(c_int)) {
            return error.Overflow;
        }

        const err = con.con_serialize_context_init(
            @ptrCast(&context.c),
            @ptrCast(buffer),
            @intCast(buffer.len),
        );
        assert(err == con.CON_SERIALIZE_OK);

        return context;
    }

    fn enum_to_error(err: con.ConSerializeError) !void {
        switch (err) {
            con.CON_SERIALIZE_OK => return,
            con.CON_SERIALIZE_NULL => return error.Null,
            con.CON_SERIALIZE_BUFFER => return error.Buffer,
        }
    }
};

const testing = @import("std").testing;
const assert = @import("std").debug.assert;

test "init" {
    var buffer: [5]c_char = undefined;
    _ = try Serialize.init(&buffer);
}

test "large_buffer" {
    const buffer = try testing.allocator.alloc(c_char, std.math.maxInt(c_int) + 1);
    defer testing.allocator.free(buffer);

    const result = Serialize.init(buffer);
    if (result) |_| {
        assert(false);
    } else |err| {
        assert(err == error.Overflow);
    }
}
