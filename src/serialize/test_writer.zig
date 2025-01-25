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
    const init_err = con.con_serialize_writer_string(&writer, &buffer, 0);
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
    var buffer: [0:0]u8 = undefined;
    var writer: con.ConWriterString = undefined;

    const init_err = con.con_serialize_writer_string(&writer, &buffer, buffer.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const write_err = con.con_serialize_writer_string_write(&writer, "1");
    try testing.expectEqual(con.EOF, write_err);
}

test "buffer init" {
    var b: [1:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterBuffer = undefined;
    const init_err = con.con_serialize_writer_buffer(
        &writer,
        &w,
        con.con_serialize_writer_string_write,
        &buffer,
        buffer.len + 1,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);
}

test "buffer init null" {
    var b: [1:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var buffer: [1:0]u8 = undefined;
    const init_err = con.con_serialize_writer_buffer(
        null,
        &w,
        con.con_serialize_writer_string_write,
        &buffer,
        buffer.len + 1,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

test "buffer init buffer null" {
    var b: [1:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var writer: con.ConWriterBuffer = undefined;
    const init_err = con.con_serialize_writer_buffer(
        &writer,
        &w,
        con.con_serialize_writer_string_write,
        null,
        2,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_NULL), init_err);
}

test "buffer init length negative" {
    var b: [1:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterBuffer = undefined;
    const init_err = con.con_serialize_writer_buffer(
        &writer,
        &w,
        con.con_serialize_writer_string_write,
        &buffer,
        -1,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_BUFFER), init_err);
}

test "buffer init buffer small" {
    var b: [1:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var buffer: [0:0]u8 = undefined;
    var writer: con.ConWriterBuffer = undefined;
    const init_err = con.con_serialize_writer_buffer(
        &writer,
        &w,
        con.con_serialize_writer_string_write,
        &buffer,
        buffer.len + 1,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_BUFFER), init_err);
}

test "buffer write" {
    var b: [1:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterBuffer = undefined;
    const init_err = con.con_serialize_writer_buffer(
        &writer,
        &w,
        con.con_serialize_writer_string_write,
        &buffer,
        buffer.len + 1,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const err = con.con_serialize_writer_buffer_write(&writer, "1");
    try testing.expect(0 <= err);
    try testing.expectEqualStrings("1", &b);
}

test "buffer flush" {
    var b: [1:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var buffer: [2:0]u8 = undefined;
    var writer: con.ConWriterBuffer = undefined;
    const init_err = con.con_serialize_writer_buffer(
        &writer,
        &w,
        con.con_serialize_writer_string_write,
        &buffer,
        buffer.len + 1,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const err = con.con_serialize_writer_buffer_write(&writer, "1");
    try testing.expect(0 <= err);

    const flush_err = con.con_serialize_writer_buffer_flush(&writer);
    try testing.expect(0 <= flush_err);
    try testing.expectEqualStrings("1", &b);
}

test "buffer internal writer fail" {
    var b: [0:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var buffer: [1:0]u8 = undefined;
    var writer: con.ConWriterBuffer = undefined;
    const init_err = con.con_serialize_writer_buffer(
        &writer,
        &w,
        con.con_serialize_writer_string_write,
        &buffer,
        buffer.len + 1,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const err = con.con_serialize_writer_buffer_write(&writer, "1");
    try testing.expectEqual(con.EOF, err);
}

test "buffer flush writer fail" {
    var b: [0:0]u8 = undefined;
    var w: con.ConWriterString = undefined;
    const i_err = con.con_serialize_writer_string(&w, &b, b.len + 1);
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), i_err);

    var buffer: [2:0]u8 = undefined;
    var writer: con.ConWriterBuffer = undefined;
    const init_err = con.con_serialize_writer_buffer(
        &writer,
        &w,
        con.con_serialize_writer_string_write,
        &buffer,
        buffer.len + 1,
    );
    try testing.expectEqual(@as(c_uint, con.CON_SERIALIZE_OK), init_err);

    const err = con.con_serialize_writer_buffer_write(&writer, "1");
    try testing.expect(0 <= err);

    const flush_err = con.con_serialize_writer_buffer_flush(&writer);
    try testing.expectEqual(con.EOF, flush_err);
}
