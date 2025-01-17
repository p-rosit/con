#include <assert.h>
#include "serialize.h"

enum ConSerializeError con_serialize_context_init(
    struct ConSerialize *context,
    void const *write_context,
    ConWrite *write
) {
    if (context == NULL) { return CON_SERIALIZE_NULL; }
    if (write == NULL) { return CON_SERIALIZE_NULL; }

    context->write_context = write_context;
    context->write = write;

    return CON_SERIALIZE_OK;
}

enum ConSerializeError con_serialize_context_deinit(struct ConSerialize *context) {
    assert(context != NULL);
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
