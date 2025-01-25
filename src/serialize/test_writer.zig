const testing = @import("std").testing;
const con = @cImport({
    @cInclude("serialize.h");
    @cInclude("serialize_writer.h");
});

test "string init" {
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const init_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);
}

test "string init null" {
    var buffer: [1:0]u8 = undefined;
    const init_err = con.con_serialize_writer_string(null, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

test "string buffer null" {
    var writer: con.ConWriterString = undefined;
    const init_err = con.con_serialize_writer_string(&writer, null, 2);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

test "string length negative" {
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const init_err = con.con_serialize_writer_string(&writer, &buffer, -1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_BUFFER), init_err);
}

test "string buffer small" {
    var buffer: [0:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;
    const init_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_BUFFER), init_err);
}

test "string write" {
    var buffer: [2:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;

    const init_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const write_err = con.con_serialize_writer_string_write(&writer, "12");
    try testing.expect(0 <= write_err);
    try testing.expectEqualStrings("12", &buffer);
}

test "string overflow" {
    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;

    const init_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const write_err = con.con_serialize_writer_string_write(&writer, "12");
    try testing.expectEqual(con.EOF, write_err);
}
