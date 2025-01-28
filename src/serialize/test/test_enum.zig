const testing = @import("std").testing;
const con = @cImport({
    @cInclude("serialize.h");
    @cInclude("writer.h");
});

test "numbers equal" {
    try testing.expectEqual(con.CON_SERIALIZE_OK, con.CON_WRITER_OK);
    try testing.expectEqual(con.CON_SERIALIZE_NULL, con.CON_WRITER_NULL);
    try testing.expectEqual(con.CON_SERIALIZE_BUFFER, con.CON_WRITER_BUFFER);
}
