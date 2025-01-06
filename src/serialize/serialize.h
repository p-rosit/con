#ifndef CON_SERIALIZE_H
#define CON_SERIALIZE_H
#include <stddef.h>

enum ConSerializeError {
    CON_SERIALIZE_OK,
    CON_SERIALIZE_NULL,
    CON_SERIALIZE_BUFFER
};

struct ConSerialize {
    char *out_buffer;
    int out_buffer_size;
    int current_position;
};

enum ConSerializeError con_serialize_context_init(
    struct ConSerialize *context,
    char *out_buffer,
    int out_buffer_size
);

#endif
