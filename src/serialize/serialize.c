#include <assert.h>
#include "serialize.h"

enum ConSerializeError con_serialize_context_init(
    struct ConSerialize *context,
    void const *write_context,
    ConWrite *write,
    void const *allocator_context,
    ConAlloc *alloc,
    ConFree *free,
    int out_buffer_size
) {
    if (context == NULL) { return CON_SERIALIZE_NULL; }
    if (write == NULL) { return CON_SERIALIZE_NULL; }
    if (alloc == NULL) { return CON_SERIALIZE_NULL; }
    if (free == NULL) { return CON_SERIALIZE_NULL; }
    if (out_buffer_size <= 0) { return CON_SERIALIZE_BUFFER; }

    context->write_context = write_context;
    context->write = write;

    return CON_SERIALIZE_OK;
}

enum ConSerializeError con_serialize_context_deinit(
    struct ConSerialize *context,
    void const *allocator_context,
    ConFree *free
) {
    assert(context != NULL);
    if (free == NULL) { return CON_SERIALIZE_NULL; }
    return CON_SERIALIZE_OK;
}

enum ConSerializeError con_serialize_array_open(struct ConSerialize *context) {
    assert(context != NULL);
    context->write(context->write_context, "[");
    return CON_SERIALIZE_OK;
}

enum ConSerializeError con_serialize_array_close(struct ConSerialize *context) {
    assert(context != NULL);
    context->write(context->write_context, "]");
    return CON_SERIALIZE_OK;
}
