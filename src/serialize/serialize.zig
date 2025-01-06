const testing = @import("std").testing;
const assert = @import("std").debug.assert;
const con = @cImport({
    @cInclude("serialize.h");
});

test "init" {
    var context: con.ConSerialize = undefined;
    var buffer: [5]u8 = undefined;

    const init_err = con.con_serialize_context_init(&context, @ptrCast(&buffer), buffer.len);
    assert(init_err == con.CON_SERIALIZE_OK);
    assert(context.out_buffer == @as([*c]u8, @ptrCast(&buffer)));
    assert(context.out_buffer_size == buffer.len);
}
