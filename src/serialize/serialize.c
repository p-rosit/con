#include <stddef.h>
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

int con_serialize_current_position(struct ConSerialize *context) {
    return context->current_position;
}

enum ConSerializeError con_serialize_buffer_set(struct ConSerialize *context, char *out_buffer, int out_buffer_size) {
    if (out_buffer == NULL) { return CON_SERIALIZE_NULL; }
    if (out_buffer_size <= 0) { return CON_SERIALIZE_BUFFER; }

    context->out_buffer = out_buffer;
    context->out_buffer_size = out_buffer_size;
    context->current_position = 0;
    return CON_SERIALIZE_OK;
}

enum ConSerializeError con_serialize_buffer_get(struct ConSerialize *context, char **out_buffer, int *out_buffer_size) {
    if (out_buffer == NULL) { return CON_SERIALIZE_NULL; }
    if (out_buffer_size == NULL) { return CON_SERIALIZE_NULL; }

    *out_buffer = context->out_buffer;
    *out_buffer_size = context->out_buffer_size;
    return CON_SERIALIZE_OK;
}
