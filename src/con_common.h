#ifndef CON_COMMON_H
#define CON_COMMON_H
#include <stdbool.h>

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
    CON_ERROR_COMMA_MISSING     = 14,
    CON_ERROR_COMMA_MULTIPLE    = 15,
    CON_ERROR_COMMA_TRAILING    = 16,
    CON_ERROR_COMMA_UNEXPECTED  = 17,
    CON_ERROR_TYPE              = 18,
    CON_ERROR_STATE_UNKNOWN     = 19,
};

enum ConState {
    CON_STATE_UNKNOWN   = 0,
    CON_STATE_EMPTY     = 1,
    CON_STATE_FIRST     = 2,
    CON_STATE_LATER     = 3,
    CON_STATE_COMPLETE  = 4,
    CON_STATE_VALUE     = 5,
    CON_STATE_MAX,
};

enum ConContainer {
    CON_CONTAINER_NONE  = 0,
    CON_CONTAINER_DICT  = 1,
    CON_CONTAINER_ARRAY = 2,
};

struct ConStateChar {
    enum ConState state;
    bool in_string;
    bool escaped;
};

#endif
