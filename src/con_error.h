#ifndef CON_ERROR_H
#define CON_ERROR_H

enum ConError {
    CON_ERROR_OK                = 0,
    CON_ERROR_NULL              = 1,
    CON_ERROR_WRITER            = 2,
    CON_ERROR_READER            = 3,
    CON_ERROR_CLOSED_TOO_MANY   = 4,
    CON_ERROR_BUFFER            = 5,
    CON_ERROR_TOO_DEEP          = 6,
    CON_ERROR_COMPLETE          = 7,
    CON_ERROR_KEY               = 8,
    CON_ERROR_VALUE             = 9,
    CON_ERROR_NOT_ARRAY         = 10,
    CON_ERROR_NOT_DICT          = 11,
    CON_ERROR_NOT_NUMBER        = 12,
    CON_ERROR_INVALID_JSON      = 13,
    CON_ERROR_TRAILING_COMMA    = 14,
    CON_ERROR_TYPE              = 15,
    CON_ERROR_STATE_UNKNOWN     = 16,
};

#endif
