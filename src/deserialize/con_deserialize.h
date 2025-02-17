#ifndef CON_DESERIALIZE_H
#define CON_DESERIALIZE_H
#include <con_error.h>
#include <con_interface_reader.h>

enum ConDeserializeType {
    CON_DESERIALIZE_TYPE_UNKNOWN    = 0,
    CON_DESERIALIZE_TYPE_NUMBER     = 1,
    CON_DESERIALIZE_TYPE_STRING     = 2,
    CON_DESERIALIZE_TYPE_BOOL       = 3,
    CON_DESERIALIZE_TYPE_NULL       = 4,
    CON_DESERIALIZE_TYPE_ARRAY      = 5,
    CON_DESERIALIZE_TYPE_DICT       = 6,
    CON_DESERIALIZE_TYPE_KEY        = 7,
    CON_DESERIALIZE_TYPE_MAX,
};

struct ConDeserialize {
    struct ConInterfaceReader reader;
    size_t depth;
    char *depth_buffer;
    int depth_buffer_size;
};

enum ConError con_deserialize_init(
    struct ConDeserialize *context,
    struct ConInterfaceReader reader,
    char *depth_buffer,
    int depth_buffer_size
);

enum ConError con_deserialize_next(
    struct ConDeserialize *context,
    enum ConDeserializeType *type
);

#endif
