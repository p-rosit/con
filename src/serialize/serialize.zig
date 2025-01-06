const testing = @import("std").testing;
const assert = @import("std").debug.assert;
const cons = @cImport({
    @cInclude("serialize.h");
});

test "init" {
    var context: cons.ConSerialize = undefined;

    const err = cons.con_serialize_context_init(&context);
    assert(err == cons.CON_SERIALIZE_OK);
}
