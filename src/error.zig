const con_error = @cImport({
    @cInclude("con_error.h");
});

pub fn enumToError(err: con_error.ConError) !void {
    switch (err) {
        con_error.CON_ERROR_OK => return,
        con_error.CON_ERROR_NULL => return error.Null,
        con_error.CON_ERROR_WRITER => return error.Writer,
        con_error.CON_ERROR_CLOSED_TOO_MANY => return error.ClosedTooMany,
        con_error.CON_ERROR_BUFFER => return error.Buffer,
        con_error.CON_ERROR_TOO_DEEP => return error.TooDeep,
        con_error.CON_ERROR_COMPLETE => return error.Complete,
        con_error.CON_ERROR_KEY => return error.Key,
        con_error.CON_ERROR_VALUE => return error.Value,
        con_error.CON_ERROR_NOT_ARRAY => return error.NotArray,
        con_error.CON_ERROR_NOT_DICT => return error.NotDict,
        con_error.CON_ERROR_NOT_NUMBER => return error.NotNumber,
        con_error.CON_ERROR_STATE_UNKNOWN => return error.StateUnknown,
        else => return error.Unknown,
    }
}
