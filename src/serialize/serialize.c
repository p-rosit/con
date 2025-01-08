#include <stddef.h>
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

enum ConSerializeError con_serialize_current_position(struct ConSerialize *context, int *current_position) {
    assert(context != NULL);
    if (current_position == NULL) { return CON_SERIALIZE_NULL; }
    *current_position = context->current_position;
    return CON_SERIALIZE_OK;
}

enum ConSerializeError con_serialize_buffer_set(struct ConSerialize *context, char *out_buffer, int out_buffer_size) {
    assert(context != NULL);
    if (out_buffer == NULL) { return CON_SERIALIZE_NULL; }
    if (out_buffer_size <= 0) { return CON_SERIALIZE_BUFFER; }

    context->out_buffer = out_buffer;
    context->out_buffer_size = out_buffer_size;
    context->current_position = 0;
    return CON_SERIALIZE_OK;
}

enum ConSerializeError con_serialize_buffer_get(struct ConSerialize *context, char **out_buffer, int *out_buffer_size) {
    assert(context != NULL);
    if (out_buffer == NULL) { return CON_SERIALIZE_NULL; }
    if (out_buffer_size == NULL) { return CON_SERIALIZE_NULL; }

    *out_buffer = context->out_buffer;
    *out_buffer_size = context->out_buffer_size;
    return CON_SERIALIZE_OK;
}

enum ConSerializeError con_serialize_buffer_clear(struct ConSerialize *context) {
    assert(context != NULL);
    context->current_position = 0;
    return CON_SERIALIZE_OK;
}
