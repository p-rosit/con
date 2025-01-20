#include <assert.h>
#include <limits.h>
#include "serialize.h"

enum ConSerializeContainer {
    CONTAINER_NONE  = 0,
    CONTAINER_DICT  = 1,
    CONTAINER_ARRAY = 2,
};

enum ConSerializeState {
    STATE_UNKNOWN   = 0,
    STATE_EMPTY     = 1,
    STATE_FIRST     = 2,
    STATE_LATER     = 3,
    STATE_COMPLETE  = 4,
    STATE_MAX,
};

static_assert(STATE_MAX < CHAR_MAX, "Only small amount of states allowed");

static inline enum ConSerializeError con_serialize_item(struct ConSerialize *context);

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
    context->state = STATE_EMPTY;

    return CON_SERIALIZE_OK;
}

enum ConSerializeError con_serialize_array_open(struct ConSerialize *context) {
    assert(context != NULL);

    if (context->depth >= context->depth_buffer_size) { return CON_SERIALIZE_TOO_DEEP; }
    context->depth_buffer[context->depth] = CONTAINER_ARRAY;
    context->depth += 1;

    int result = context->write(context->write_context, "[");
    if (result != 1) { return CON_SERIALIZE_WRITER; }

    context->state = STATE_FIRST;
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

    if (context->depth == 0) {
        context->state = STATE_COMPLETE;
    } else {
        context->state = STATE_LATER;
    }
    return CON_SERIALIZE_OK;
}

enum ConSerializeError con_serialize_dict_open(struct ConSerialize *context) {
    assert(context != NULL);

    if (context->depth >= context->depth_buffer_size) { return CON_SERIALIZE_TOO_DEEP; }
    context->depth_buffer[context->depth] = CONTAINER_DICT;
    context->depth += 1;

    int result = context->write(context->write_context, "{");
    if (result != 1) { return CON_SERIALIZE_WRITER; }

    context->state = STATE_FIRST;
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

    if (context->depth == 0) {
        context->state = STATE_COMPLETE;
    } else {
        context->state = STATE_LATER;
    }
    return CON_SERIALIZE_OK;
}

enum ConSerializeError con_serialize_number(struct ConSerialize *context, char const *number) {
    assert(context != NULL);
    if (number == NULL) { return CON_SERIALIZE_NULL; }

    enum ConSerializeError item_err = con_serialize_item(context);
    if (item_err) { return item_err; }

    int result = context->write(context->write_context, number);
    if (result <= 0) { return CON_SERIALIZE_WRITER; }

    return CON_SERIALIZE_OK;
}

enum ConSerializeError con_serialize_string(struct ConSerialize *context, char const *string) {
    assert(context != NULL);
    if (string == NULL) { return CON_SERIALIZE_NULL; }

    enum ConSerializeError item_err = con_serialize_item(context);
    if (item_err) { return item_err; }

    int result = context->write(context->write_context, "\"");
    if (result != 1) { return CON_SERIALIZE_WRITER; }
    result = context->write(context->write_context, string);
    if (result <= 0) { return CON_SERIALIZE_WRITER; }
    result = context->write(context->write_context, "\"");
    if (result != 1) { return CON_SERIALIZE_WRITER; }

    return CON_SERIALIZE_OK;
}

static inline enum ConSerializeError con_serialize_item(struct ConSerialize *context) {
    switch (context->state) {
        case (STATE_EMPTY):
            context->state = STATE_COMPLETE;
            break;
        case (STATE_FIRST):
            context->state = STATE_LATER;
            break;
        case (STATE_LATER):
            context->write(context->write_context, ",");
            break;
        case (STATE_COMPLETE):
            return CON_SERIALIZE_COMPLETE;
        default:
            assert(0);  // State is unknown
    }

    return CON_SERIALIZE_OK;
}
