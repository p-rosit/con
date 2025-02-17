#ifndef CON_DESERIALIZE_H
#define CON_DESERIALIZE_H
#include <con_error.h>
#include <con_interface_reader.h>

struct ConDeserialize {
    struct ConInterfaceReader reader;
    size_t depth;
    char *depth_buffer;
    int depth_buffer_size;
};

enum ConError con_deserialize_init(struct ConDeserialize *context, struct ConInterfaceReader reader, char *depth_buffer, int depth_buffer_size);

#endif
