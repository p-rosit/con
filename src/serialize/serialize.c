#include <assert.h>
#include "serialize.h"

enum ConSerializeError con_serialize_context_init(
    struct ConSerialize *context,
    char *out_buffer,
    int out_buffer_size
) {
    assert(context != NULL);
    assert(out_buffer != NULL);

    context->out_buffer = out_buffer;
    context->out_buffer_size = out_buffer_size;

    return CON_SERIALIZE_OK;
}
