#ifndef CON_ERROR_H
#define CON_ERROR_H

enum ConError {
    CON_ERROR_OK                = 0,
    CON_ERROR_NULL              = 1,
    CON_ERROR_WRITER            = 2,
    CON_ERROR_CLOSED_TOO_MANY   = 3,
    CON_ERROR_BUFFER            = 4,
    CON_ERROR_TOO_DEEP          = 5,
    CON_ERROR_COMPLETE          = 6,
    CON_ERROR_KEY               = 7,
    CON_ERROR_VALUE             = 8,
    CON_ERROR_NOT_ARRAY         = 9,
    CON_ERROR_NOT_DICT          = 10,
    CON_ERROR_NOT_NUMBER        = 11,
    CON_ERROR_STATE_UNKNOWN     = 12,
};

#endif
