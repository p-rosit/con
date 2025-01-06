#include <assert.h>
#include "serialize.h"

enum ConSerializeError con_serialize_context_init(
    struct ConSerialize *context,
    char *out_buffer,
    int out_buffer_size
) {
    if (context == NULL) { return CON_SERIALIZE_NULL; }
    if (out_buffer == NULL) { return CON_SERIALIZE_NULL; }
    if (out_buffer_size <= 0) { return CON_SERIALIZE_BUFFER; }

    context->out_buffer = out_buffer;
    context->out_buffer_size = out_buffer_size;
    context->current_position = 0;

    return CON_SERIALIZE_OK;
}
