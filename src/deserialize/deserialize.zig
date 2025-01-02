const assert = @import("std").debug.assert;
const cond = @cImport({
    @cInclude("deserialize.h");
});

test "test-bunc" {
    assert(cond.bunc(4) == 4);
}
