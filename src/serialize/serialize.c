#include <assert.h>
#include <utils.h>
#include "con_writer.h"
#include "con_serialize.h"

enum ConSerializeState {
    STATE_UNKNOWN   = 0,
    STATE_EMPTY     = 1,
    STATE_FIRST     = 2,
    STATE_LATER     = 3,
    STATE_COMPLETE  = 4,
    STATE_VALUE     = 5,
    STATE_MAX,
};

static inline enum ConSerializeState con_serialize_state(struct ConSerialize *context);
static inline enum ConSerializeContainer con_serialize_current_container(struct ConSerialize *context);
static inline enum ConError con_serialize_value_prefix(struct ConSerialize *context);
static inline enum ConError con_serialize_requires_key(struct ConSerialize *context);

enum ConError con_serialize_init(
    struct ConSerialize *context,
    struct ConInterfaceWriter writer,
    char *depth_buffer,
    int depth_buffer_size
) {
    if (context == NULL) { return CON_ERROR_NULL; }
    if (depth_buffer == NULL && depth_buffer_size > 0) { return CON_ERROR_NULL; }
    if (depth_buffer_size < 0) { return CON_ERROR_BUFFER; }

    context->writer = writer;
    context->depth = 0;
    context->depth_buffer = depth_buffer;
    context->depth_buffer_size = depth_buffer_size;
    context->state = STATE_EMPTY;

    return CON_ERROR_OK;
}

enum ConError con_serialize_array_open(struct ConSerialize *context) {
    assert(context != NULL);

    assert(context->depth_buffer_size >= 0);
    assert(0 <= context->depth && context->depth <= (size_t) context->depth_buffer_size);
    if (context->depth >= (size_t) context->depth_buffer_size) { return CON_ERROR_TOO_DEEP; }

    enum ConError err = con_serialize_value_prefix(context);
    if (err) { return err; }

    assert(context->depth_buffer != NULL);
    context->depth_buffer[context->depth] = CONTAINER_ARRAY;
    context->depth += 1;

    size_t result = con_writer_write(context->writer, "[", 1);
    if (result != 1) { return CON_ERROR_WRITER; }

    context->state = STATE_FIRST;
    return CON_ERROR_OK;
}

enum ConError con_serialize_array_close(struct ConSerialize *context) {
    assert(context != NULL);

    assert(context->depth_buffer_size >= 0);
    assert(0 <= context->depth && context->depth <= (size_t) context->depth_buffer_size);
    if (context->depth <= 0) { return CON_ERROR_CLOSED_TOO_MANY; }

    enum ConSerializeContainer current = con_serialize_current_container(context);
    if (current != CONTAINER_ARRAY) {
        return CON_ERROR_NOT_ARRAY;
    }

    size_t result = con_writer_write(context->writer, "]", 1);
    if (result != 1) { return CON_ERROR_WRITER; }

    context->depth -= 1;

    if (context->depth == 0) {
        context->state = STATE_COMPLETE;
    } else {
        context->state = STATE_LATER;
    }
    return CON_ERROR_OK;
}

enum ConError con_serialize_dict_open(struct ConSerialize *context) {
    assert(context != NULL);

    assert(context->depth_buffer_size >= 0);
    assert(0 <= context->depth && context->depth <= (size_t) context->depth_buffer_size);
    if (context->depth >= (size_t) context->depth_buffer_size) { return CON_ERROR_TOO_DEEP; }

    enum ConError err = con_serialize_value_prefix(context);
    if (err) { return err; }

    assert(context->depth_buffer != NULL);
    context->depth_buffer[context->depth] = CONTAINER_DICT;
    context->depth += 1;

    size_t result = con_writer_write(context->writer, "{", 1);
    if (result != 1) { return CON_ERROR_WRITER; }

    context->state = STATE_FIRST;
    return CON_ERROR_OK;
}

enum ConError con_serialize_dict_close(struct ConSerialize *context) {
    assert(context != NULL);

    assert(context->depth_buffer_size >= 0);
    assert(0 <= context->depth && context->depth <= (size_t) context->depth_buffer_size);
    if (context->depth <= 0) { return CON_ERROR_CLOSED_TOO_MANY; }

    assert(context->depth_buffer != NULL);
    enum ConSerializeContainer current = con_serialize_current_container(context);
    if (current != CONTAINER_DICT) {
        return CON_ERROR_NOT_DICT;
    }

    size_t result = con_writer_write(context->writer, "}", 1);
    if (result != 1) { return CON_ERROR_WRITER; }

    context->depth -= 1;

    if (context->depth == 0) {
        context->state = STATE_COMPLETE;
    } else {
        context->state = STATE_LATER;
    }
    return CON_ERROR_OK;
}

enum ConError con_serialize_dict_key(struct ConSerialize *context, char const *key, size_t key_size) {
    assert(context != NULL);
    if (key == NULL) { return CON_ERROR_NULL; }

    enum ConSerializeContainer current = con_serialize_current_container(context);
    if (current != CONTAINER_DICT) {
        return CON_ERROR_NOT_DICT;
    }

    enum ConSerializeState state = con_serialize_state(context);
    if (state != STATE_FIRST && state != STATE_LATER) {
        return CON_ERROR_VALUE;
    }

    if (state == STATE_LATER) {
        size_t result = con_writer_write(context->writer, ",", 1);
        if (result != 1) { return CON_ERROR_WRITER; }
    }

    size_t result = con_writer_write(context->writer, "\"", 1);
    if (result != 1) { return CON_ERROR_WRITER; }
    result = con_writer_write(context->writer, key, key_size);
    if (result != key_size) { return CON_ERROR_WRITER; }
    result = con_writer_write(context->writer, "\":", 2);
    if (result != 2) { return CON_ERROR_WRITER; }

    context->state = STATE_VALUE;
    return CON_ERROR_OK;
}

enum ConError con_serialize_number(struct ConSerialize *context, char const *number, size_t number_size) {
    assert(context != NULL);
    if (number == NULL) { return CON_ERROR_NULL; }
    if (number[0] == '\0') { return CON_ERROR_NOT_NUMBER; }

    enum ConError err = con_serialize_value_prefix(context);
    if (err) { return err; }

    size_t result = con_writer_write(context->writer, number, number_size);
    if (result != number_size) { return CON_ERROR_WRITER; }

    return CON_ERROR_OK;
}

enum ConError con_serialize_string(struct ConSerialize *context, char const *string, size_t string_size) {
    assert(context != NULL);
    if (string == NULL) { return CON_ERROR_NULL; }

    enum ConError err = con_serialize_value_prefix(context);
    if (err) { return err; }

    size_t result = con_writer_write(context->writer, "\"", 1);
    if (result != 1) { return CON_ERROR_WRITER; }
    result = con_writer_write(context->writer, string, string_size);
    if (result != string_size) { return CON_ERROR_WRITER; }
    result = con_writer_write(context->writer, "\"", 1);
    if (result != 1) { return CON_ERROR_WRITER; }

    return CON_ERROR_OK;
}

enum ConError con_serialize_bool(struct ConSerialize *context, bool value) {
    assert(context != NULL);
    enum ConError err = con_serialize_value_prefix(context);
    if (err) { return err; }

    size_t result;
    size_t expected;
    if (value) {
        expected = 4;
        result = con_writer_write(context->writer, "true", expected);
    } else {
        expected = 5;
        result = con_writer_write(context->writer, "false", expected);
    }
    if (result != expected) { return CON_ERROR_WRITER; }

    return CON_ERROR_OK;
}

enum ConError con_serialize_null(struct ConSerialize *context) {
    assert(context != NULL);
    enum ConError err = con_serialize_value_prefix(context);
    if (err) { return err; }

    size_t result = con_writer_write(context->writer, "null", 4);
    if (result != 4) { return CON_ERROR_WRITER; }

    return CON_ERROR_OK;
}

static inline enum ConError con_serialize_value_prefix(struct ConSerialize *context) {
    assert(context != NULL);

    enum ConError key_err = con_serialize_requires_key(context);
    if (key_err) { return key_err; }

    enum ConSerializeState state = con_serialize_state(context);
    switch (state) {
        case (STATE_EMPTY):
            context->state = STATE_COMPLETE;
            break;
        case (STATE_FIRST):
            context->state = STATE_LATER;
            break;
        case (STATE_LATER): {
            size_t result = con_writer_write(context->writer, ",", 1);
            if (result != 1) { return CON_ERROR_WRITER; }
            break;
        }
        case (STATE_COMPLETE):
            return CON_ERROR_COMPLETE;
        case (STATE_VALUE):
            context->state = STATE_LATER;
            break;
        default:
            assert(0);  // State is unknown
            return CON_ERROR_STATE_UNKNOWN;
    }

    return CON_ERROR_OK;
}

static inline enum ConError con_serialize_requires_key(struct ConSerialize *context) {
    assert(context != NULL);
    assert(context->depth_buffer_size >= 0);
    assert(0 <= context->depth && context->depth <= (size_t) context->depth_buffer_size);
    if (context->depth > 0) {
        enum ConSerializeState state = con_serialize_state(context);
        enum ConSerializeContainer current = con_serialize_current_container(context);

        if (current == CONTAINER_DICT && (state == STATE_FIRST || state == STATE_LATER)) {
            return CON_ERROR_KEY;
        }
    }

    return CON_ERROR_OK;
}

static inline enum ConSerializeState con_serialize_state(struct ConSerialize *context) {
    assert(context != NULL);

    char state = context->state;
    assert(0 < state && state < STATE_MAX);
    return (enum ConSerializeState) state;
}

static inline enum ConSerializeContainer con_serialize_current_container(struct ConSerialize *context) {
    assert(context != NULL);

    if (context->depth <= 0) {
        return CONTAINER_NONE;
    }

    assert(context->depth_buffer_size >= 0);
    assert(0 <= context->depth && context->depth <= (size_t) context->depth_buffer_size);
    char container = context->depth_buffer[context->depth - 1];

    assert(container == CONTAINER_ARRAY || container == CONTAINER_DICT);
    return (enum ConSerializeContainer) container;
}
