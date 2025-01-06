#ifndef CON_SERIALIZE_H
#define CON_SERIALIZE_H
#include <stddef.h>

enum ConSerializeError {
    CON_SERIALIZE_OK,
};

struct ConSerialize {
};

enum ConSerializeError con_serialize_context_init(
    struct ConSerialize *context
);

#endif
