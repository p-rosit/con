const assert = @import("std").debug.assert;
const cons = @cImport({
    @cInclude("serialize.h");
});

test "test-func" {
    assert(cons.func(5) == 5);
}
