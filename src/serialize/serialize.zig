const testing = @import("std").testing;
const assert = @import("std").debug.assert;
const con = @cImport({
    @cInclude("serialize.h");
});

test "init" {
    var context: con.ConSerialize = undefined;

    const err = con.con_serialize_context_init(&context);
    assert(err == con.CON_SERIALIZE_OK);
}
