pub const lib = @cImport({
    @cInclude("con_serialize.h");
    @cInclude("con_interface_writer.h");
    @cInclude("con_writer.h");
    @cInclude("con_deserialize.h");
    @cInclude("con_interface_reader.h");
    @cInclude("con_reader.h");
    @cInclude("con_error.h");
});

pub fn enumToError(err: lib.ConError) !void {
    switch (err) {
        lib.CON_ERROR_OK => return,
        lib.CON_ERROR_NULL => return error.Null,
        lib.CON_ERROR_WRITER => return error.Writer,
        lib.CON_ERROR_READER => return error.Reader,
        lib.CON_ERROR_CLOSED_TOO_MANY => return error.ClosedTooMany,
        lib.CON_ERROR_BUFFER => return error.Buffer,
        lib.CON_ERROR_TOO_DEEP => return error.TooDeep,
        lib.CON_ERROR_COMPLETE => return error.Complete,
        lib.CON_ERROR_KEY => return error.Key,
        lib.CON_ERROR_VALUE => return error.Value,
        lib.CON_ERROR_NOT_ARRAY => return error.NotArray,
        lib.CON_ERROR_NOT_DICT => return error.NotDict,
        lib.CON_ERROR_NOT_NUMBER => return error.NotNumber,
        lib.CON_ERROR_INVALID_JSON => return error.InvalidJson,
        lib.CON_ERROR_TRAILING_COMMA => return error.TrailingComma,
        lib.CON_ERROR_STATE_UNKNOWN => return error.StateUnknown,
        else => return error.Unknown,
    }
}
