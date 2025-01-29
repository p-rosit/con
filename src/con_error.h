#ifndef CON_ERROR_H
#define CON_ERROR_H

enum ConSerializeError {
    CON_SERIALIZE_OK                = 0,
    CON_SERIALIZE_NULL              = 1,
    CON_SERIALIZE_WRITER            = 2,
    CON_SERIALIZE_CLOSED_TOO_MANY   = 3,
    CON_SERIALIZE_BUFFER            = 4,
    CON_SERIALIZE_TOO_DEEP          = 5,
    CON_SERIALIZE_COMPLETE          = 6,
    CON_SERIALIZE_KEY               = 7,
    CON_SERIALIZE_VALUE             = 8,
    CON_SERIALIZE_NOT_ARRAY         = 9,
    CON_SERIALIZE_NOT_DICT          = 10,
    CON_SERIALIZE_NOT_NUMBER        = 11,
    CON_SERIALIZE_STATE_UNKNOWN     = 12,
};

#endif
