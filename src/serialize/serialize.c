#include <assert.h>
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
    STATE_VALUE     = 5,
    STATE_MAX,
};

static inline enum ConSerializeError con_serialize_value_prefix(struct ConSerialize *context);
static inline enum ConSerializeError con_serialize_state_change(struct ConSerialize *context, int *needs_comma);
static inline enum ConSerializeError con_serialize_requires_key(struct ConSerialize *context);

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

    assert(0 < context->state && context->state < STATE_MAX);
    if (context->state == STATE_COMPLETE) {
        return CON_SERIALIZE_COMPLETE;
    }

    enum ConSerializeError key_err = con_serialize_requires_key(context);
    if (key_err) { return key_err; }

    assert(context->depth_buffer != NULL);
    assert(0 <= context->depth && context->depth <= context->depth_buffer_size);
    if (context->depth >= context->depth_buffer_size) { return CON_SERIALIZE_TOO_DEEP; }
    context->depth_buffer[context->depth] = CONTAINER_ARRAY;
    context->depth += 1;

    if (context->state == STATE_LATER) {
        assert(context->write != NULL);
        int result = context->write(context->write_context, ",");
        if (result != 1) { return CON_SERIALIZE_WRITER; }
    }

    assert(context->write != NULL);
    int result = context->write(context->write_context, "[");
    if (result != 1) { return CON_SERIALIZE_WRITER; }

    context->state = STATE_FIRST;
    return CON_SERIALIZE_OK;
}

enum ConSerializeError con_serialize_array_close(struct ConSerialize *context) {
    assert(context != NULL);
    assert(0 < context->state && context->state < STATE_MAX);
    assert(0 <= context->depth && context->depth <= context->depth_buffer_size);
    if (context->depth <= 0) { return CON_SERIALIZE_CLOSED_TOO_MANY; }

    assert(context->depth_buffer != NULL);
    assert(0 <= context->depth && context->depth <= context->depth_buffer_size);
    if (context->depth_buffer[context->depth - 1] != CONTAINER_ARRAY) {
        return CON_SERIALIZE_NOT_ARRAY;
    }

    assert(context->write != NULL);
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
    assert(0 < context->state && context->state < STATE_MAX);
    if (context->state == STATE_COMPLETE) {
        return CON_SERIALIZE_COMPLETE;
    }

    enum ConSerializeError key_err = con_serialize_requires_key(context);
    if (key_err) { return key_err; }

    assert(context->depth_buffer != NULL);
    assert(0 <= context->depth && context->depth <= context->depth_buffer_size);
    if (context->depth >= context->depth_buffer_size) { return CON_SERIALIZE_TOO_DEEP; }
    context->depth_buffer[context->depth] = CONTAINER_DICT;
    context->depth += 1;

    if (context->state == STATE_LATER) {
        assert(context->write != NULL);
        int result = context->write(context->write_context, ",");
        if (result != 1) { return CON_SERIALIZE_WRITER; }
    }

    assert(context->write != NULL);
    int result = context->write(context->write_context, "{");
    if (result != 1) { return CON_SERIALIZE_WRITER; }

    context->state = STATE_FIRST;
    return CON_SERIALIZE_OK;
}

enum ConSerializeError con_serialize_dict_close(struct ConSerialize *context) {
    assert(context != NULL);
    assert(0 <= context->depth && context->depth <= context->depth_buffer_size);
    if (context->depth <= 0) { return CON_SERIALIZE_CLOSED_TOO_MANY; }

    assert(context->depth_buffer != NULL);
    if (context->depth_buffer[context->depth - 1] != CONTAINER_DICT) {
        return CON_SERIALIZE_NOT_DICT;
    }

    assert(context->write != NULL);
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

enum ConSerializeError con_serialize_dict_key(struct ConSerialize *context, char const *key) {
    assert(context != NULL);
    if (key == NULL) { return CON_SERIALIZE_NULL; }

    assert(context->depth_buffer != NULL);
    assert(0 <= context->depth && context->depth <= context->depth_buffer_size);
    if (context->depth <= 0) { return CON_SERIALIZE_NOT_DICT; }
    if (context->depth_buffer[context->depth-1] != CONTAINER_DICT) {
        return CON_SERIALIZE_NOT_DICT;
    }

    assert(0 < context->state && context->state < STATE_MAX);
    if (context->state != STATE_FIRST && context->state != STATE_LATER) {
        return CON_SERIALIZE_VALUE;
    }

    int needs_comma = 0;
    enum ConSerializeError item_err = con_serialize_state_change(context, &needs_comma);
    if (item_err) { return item_err; }

    if (needs_comma) {
        assert(context->write != NULL);
        int result = context->write(context->write_context, ",");
        if (result != 1) { return CON_SERIALIZE_WRITER; }
    }

    assert(context->write != NULL);
    int result = context->write(context->write_context, "\"");
    if (result != 1) { return CON_SERIALIZE_WRITER; }
    result = context->write(context->write_context, key);
    if (result <= 0) { return CON_SERIALIZE_WRITER; }
    result = context->write(context->write_context, "\"");
    if (result != 1) { return CON_SERIALIZE_WRITER; }

    result = context->write(context->write_context, ":");
    if (result < 0) { return CON_SERIALIZE_WRITER; }

    context->state = STATE_VALUE;
    return CON_SERIALIZE_OK;
}

enum ConSerializeError con_serialize_number(struct ConSerialize *context, char const *number) {
    assert(context != NULL);
    if (number == NULL) { return CON_SERIALIZE_NULL; }

    enum ConSerializeError err = con_serialize_value_prefix(context);
    if (err) { return err; }

    assert(context->write != NULL);
    int result = context->write(context->write_context, number);
    if (result <= 0) { return CON_SERIALIZE_WRITER; }

    return CON_SERIALIZE_OK;
}

enum ConSerializeError con_serialize_string(struct ConSerialize *context, char const *string) {
    assert(context != NULL);
    if (string == NULL) { return CON_SERIALIZE_NULL; }

    enum ConSerializeError err = con_serialize_value_prefix(context);
    if (err) { return err; }

    assert(context->write != NULL);
    int result = context->write(context->write_context, "\"");
    if (result != 1) { return CON_SERIALIZE_WRITER; }
    result = context->write(context->write_context, string);
    if (result <= 0) { return CON_SERIALIZE_WRITER; }
    result = context->write(context->write_context, "\"");
    if (result != 1) { return CON_SERIALIZE_WRITER; }

    return CON_SERIALIZE_OK;
}

enum ConSerializeError con_serialize_bool(struct ConSerialize *context, bool value) {
    assert(context != NULL);
    enum ConSerializeError err = con_serialize_value_prefix(context);
    if (err) { return err; }

    assert(context->write != NULL);
    int result;
    if (value) {
        result = context->write(context->write_context, "true");
    } else {
        result = context->write(context->write_context, "false");
    }
    if (result <= 0) { return CON_SERIALIZE_WRITER; }

    return CON_SERIALIZE_OK;
}

enum ConSerializeError con_serialize_null(struct ConSerialize *context) {
    assert(context != NULL);
    enum ConSerializeError err = con_serialize_value_prefix(context);
    if (err) { return err; }

    assert(context->write != NULL);
    int result = context->write(context->write_context, "null");
    if (result <= 0) { return CON_SERIALIZE_WRITER; }

    return CON_SERIALIZE_OK;
}

static inline enum ConSerializeError con_serialize_value_prefix(struct ConSerialize *context) {
    assert(context != NULL);

    enum ConSerializeError key_err = con_serialize_requires_key(context);
    if (key_err) { return key_err; }

    int needs_comma = 0;
    enum ConSerializeError err = con_serialize_state_change(context, &needs_comma);
    if (err) { return err; }

    if (needs_comma) {
        assert(context->write != NULL);
        int result = context->write(context->write_context, ",");
        if (result != 1) { return CON_SERIALIZE_WRITER; }
    }

    return CON_SERIALIZE_OK;
}

static inline enum ConSerializeError con_serialize_state_change(struct ConSerialize *context, int *needs_comma) {
    assert(needs_comma != NULL);
    assert(context != NULL);
    assert(0 < context->state && context->state < STATE_MAX);
    *needs_comma = 0;
    switch (context->state) {
        case (STATE_EMPTY):
            context->state = STATE_COMPLETE;
            break;
        case (STATE_FIRST):
            context->state = STATE_LATER;
            break;
        case (STATE_LATER):
            *needs_comma = 1;
            break;
        case (STATE_COMPLETE):
            return CON_SERIALIZE_COMPLETE;
        case (STATE_VALUE):
            context->state = STATE_LATER;
            break;
        default:
            assert(0);  // State is unknown
            return CON_SERIALIZE_STATE_UNKNOWN;
    }
    return CON_SERIALIZE_OK;
}

static inline enum ConSerializeError con_serialize_requires_key(struct ConSerialize *context) {
    assert(context->depth_buffer != NULL);
    assert(0 <= context->depth && context->depth <= context->depth_buffer_size);
    if (context->depth > 0) {
        enum ConSerializeState state = context->state;
        enum ConSerializeContainer current = context->depth_buffer[context->depth - 1];
        assert(current == CONTAINER_DICT || current == CONTAINER_ARRAY);

        if (current == CONTAINER_DICT && (state == STATE_FIRST || state == STATE_LATER)) {
            return CON_SERIALIZE_KEY;
        }
    }

    return CON_SERIALIZE_OK;
}
