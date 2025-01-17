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

enum ConSerializeError con_serialize_array_open(struct ConSerialize *context) {
    assert(context != NULL);
    int result = context->write(context->write_context, "[");

    if (result != 1) { return CON_SERIALIZE_WRITER; }
    return CON_SERIALIZE_OK;
}

enum ConSerializeError con_serialize_array_close(struct ConSerialize *context) {
    assert(context != NULL);
    int result = context->write(context->write_context, "]");

    if (result != 1) { return CON_SERIALIZE_WRITER; }
    return CON_SERIALIZE_OK;
}
