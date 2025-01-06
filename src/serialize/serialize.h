#ifndef CON_SERIALIZE_H
#define CON_SERIALIZE_H
#include <stddef.h>

enum ConSerializeError {
    CON_SERIALIZE_OK,
};

struct ConSerialize {
    char *out_buffer;
    int out_buffer_size;
};

enum ConSerializeError con_serialize_context_init(
    struct ConSerialize *context,
    char *out_buffer,
    int out_buffer_size
);

#endif
