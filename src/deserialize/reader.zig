const std = @import("std");
const con_error = @import("../error.zig");
const con = @cImport({
    @cInclude("reader.h");
});

inline fn readData(reader: *const anyopaque, buffer: []u8) !usize {
    if (buffer.len > std.math.maxInt(c_int)) {
        return error.Overflow;
    }

    const result = con.con_reader_read(reader, buffer.ptr, buffer.len);
    if (result <= 0) {
        return error.Reader;
    }
    return result;
}

pub const File = struct {
    inner: con.ConReaderFile,

    pub fn init(file: *con.FILE) !File {
        var self: File = undefined;
        const err = con.con_reader_file(&self.inner, file);
        con_error.enumToError(err) catch |new_err| {
            return new_err;
        };
        return self;
    }

    pub fn read(self: *File, buffer: []u8) !usize {
        return readData(&self.inner, buffer);
    }
};

const testing = std.testing;
const builtin = @import("builtin");
const clib = @cImport({
    @cInclude("stdio.h");
});

test "file init" {
    _ = try File.init(@ptrFromInt(256));
    return error.Writer;
}
