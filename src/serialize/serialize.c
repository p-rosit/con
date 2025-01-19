#include <assert.h>
#include "serialize.h"

enum ConSerializeContainer {
    CONTAINER_NONE,
    CONTAINER_DICT,
    CONTAINER_ARRAY,
};

enum ConSerializeError con_serialize_init(
    struct ConSerialize *context,
    void const *write_context,
    ConWrite *write,
    char *depth_buffer,
    int depth_buffer_size
) {
    if (context == NULL) { return CON_SERIALIZE_NULL; }
    if (write == NULL) { return CON_SERIALIZE_NULL; }
    if (depth_buffer == NULL && depth_buffer_size > 0) { return CON_SERIALIZE_NULL; }
    if (depth_buffer_size < 0) { return CON_SERIALIZE_BUFFER; }

    context->write_context = write_context;
    context->write = write;
    context->depth = 0;
    context->depth_buffer = depth_buffer;
    context->depth_buffer_size = depth_buffer_size;

    return CON_SERIALIZE_OK;
}

enum ConSerializeError con_serialize_array_open(struct ConSerialize *context) {
    assert(context != NULL);

    if (context->depth >= context->depth_buffer_size) { return CON_SERIALIZE_TOO_DEEP; }
    context->depth_buffer[context->depth] = CONTAINER_ARRAY;
    context->depth += 1;

    int result = context->write(context->write_context, "[");
    if (result != 1) { return CON_SERIALIZE_WRITER; }

    return CON_SERIALIZE_OK;
}

enum ConSerializeError con_serialize_array_close(struct ConSerialize *context) {
    assert(context != NULL);
    if (context->depth <= 0) { return CON_SERIALIZE_CLOSED_TOO_MANY; }

    if (context->depth_buffer[context->depth - 1] != CONTAINER_ARRAY) {
        return CON_SERIALIZE_CLOSED_WRONG;
    }

    int result = context->write(context->write_context, "]");
    if (result != 1) { return CON_SERIALIZE_WRITER; }

    context->depth -= 1;

    return CON_SERIALIZE_OK;
}

enum ConSerializeError con_serialize_dict_open(struct ConSerialize *context) {
    assert(context != NULL);

    if (context->depth >= context->depth_buffer_size) { return CON_SERIALIZE_TOO_DEEP; }
    context->depth_buffer[context->depth] = CONTAINER_DICT;
    context->depth += 1;

    int result = context->write(context->write_context, "{");
    if (result != 1) { return CON_SERIALIZE_WRITER; }

    return CON_SERIALIZE_OK;
}

enum ConSerializeError con_serialize_dict_close(struct ConSerialize *context) {
    assert(context != NULL);
    if (context->depth <= 0) { return CON_SERIALIZE_CLOSED_TOO_MANY; }

    if (context->depth_buffer[context->depth - 1] != CONTAINER_DICT) {
        return CON_SERIALIZE_CLOSED_WRONG;
    }

    int result = context->write(context->write_context, "}");
    if (result != 1) { return CON_SERIALIZE_WRITER; }

    context->depth -= 1;

    return CON_SERIALIZE_OK;
}
