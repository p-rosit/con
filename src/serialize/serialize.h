#ifndef CON_SERIALIZE_H
#define CON_SERIALIZE_H
#include <stddef.h>

enum ConSerializeError {
    CON_SERIALIZE_OK,
    CON_SERIALIZE_NULL,
    CON_SERIALIZE_BUFFER,
    CON_SERIALIZE_MEM,
};

struct ConSerialize;
typedef void *(ConAlloc)(void *context, size_t size);
typedef void (ConFree)(void *context, void *data, size_t size);

enum ConSerializeError con_serialize_context_init(
    struct ConSerialize **context,
    void *allocator_context,
    ConAlloc *alloc,
    ConFree *free,
    int out_buffer_size
);
void con_serialize_context_deinit(
    struct ConSerialize *context,
    void *allocator_context,
    ConFree *free
);

enum ConSerializeError con_serialize_current_position(struct ConSerialize *context, int *current_position);
enum ConSerializeError con_serialize_buffer_get(struct ConSerialize *context, char **out_buffer, int *out_buffer_size);
enum ConSerializeError con_serialize_buffer_clear(struct ConSerialize *context);

enum ConSerializeError con_serialize_array_open(struct ConSerialize *context);
enum ConSerializeError con_serialize_array_close(struct ConSerialize *context);

#endif
