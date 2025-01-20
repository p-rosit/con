#ifndef CON_SERIALIZE_H
#define CON_SERIALIZE_H
#include <stddef.h>

enum ConSerializeError {
    CON_SERIALIZE_OK                = 0,
    CON_SERIALIZE_NULL              = 1,
    CON_SERIALIZE_WRITER            = 2,
    CON_SERIALIZE_CLOSED_TOO_MANY   = 3,
    CON_SERIALIZE_CLOSED_WRONG      = 4,
    CON_SERIALIZE_BUFFER            = 5,
    CON_SERIALIZE_TOO_DEEP          = 6,
};

struct ConSerialize;
typedef int (ConWrite)(void const *context, char const *data);

struct ConSerialize {
    void const *write_context;
    ConWrite *write;
    size_t depth;
    char *depth_buffer;
    int depth_buffer_size;
};

enum ConSerializeError con_serialize_init(
    struct ConSerialize *context,
    void const *write_context,
    ConWrite *write,
    char *depth_buffer,
    int depth_buffer_size
);

enum ConSerializeError con_serialize_array_open(struct ConSerialize *context);
enum ConSerializeError con_serialize_array_close(struct ConSerialize *context);

enum ConSerializeError con_serialize_dict_open(struct ConSerialize *context);
enum ConSerializeError con_serialize_dict_close(struct ConSerialize *context);

enum ConSerializeError con_serialize_number(struct ConSerialize *context, char const *number);

#endif
