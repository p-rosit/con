#ifndef CON_SERIALIZE_H
#define CON_SERIALIZE_H
#include <stddef.h>

enum ConSerializeError {
    CON_SERIALIZE_OK,
    CON_SERIALIZE_NULL,
    CON_SERIALIZE_WRITER,
    CON_SERIALIZE_CLOSED_TOO_MANY,
};

struct ConSerialize;
typedef int (ConWrite)(void const *context, char *data);

struct ConSerialize {
    void const *write_context;
    ConWrite *write;
    size_t depth;
};

enum ConSerializeError con_serialize_context_init(
    struct ConSerialize *context,
    void const *write_context,
    ConWrite *write
);

enum ConSerializeError con_serialize_array_open(struct ConSerialize *context);
enum ConSerializeError con_serialize_array_close(struct ConSerialize *context);

#endif
