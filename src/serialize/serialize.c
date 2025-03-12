#include <assert.h>
#include <utils.h>
#include "con_writer.h"
#include "con_serialize.h"

static inline enum ConError con_serialize_value_prefix(struct ConSerialize *context);
static inline enum ConError con_serialize_requires_key(struct ConSerialize *context);

enum ConError con_serialize_init(
    struct ConSerialize *context,
    struct ConInterfaceWriter writer,
    enum ConContainer *depth_buffer,
    int depth_buffer_size
) {
    if (context == NULL) { return CON_ERROR_NULL; }
    if (depth_buffer == NULL && depth_buffer_size > 0) { return CON_ERROR_NULL; }
    if (depth_buffer_size < 0) { return CON_ERROR_BUFFER; }

    context->writer = writer;
    context->depth = 0;
    context->depth_buffer = depth_buffer;
    context->depth_buffer_size = depth_buffer_size;
    context->state = CON_STATE_EMPTY;

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
    context->depth_buffer[context->depth] = CON_CONTAINER_ARRAY;
    context->depth += 1;

    size_t result = con_writer_write(context->writer, "[", 1);
    if (result != 1) { return CON_ERROR_WRITER; }

    context->state = CON_STATE_FIRST;
    return CON_ERROR_OK;
}

enum ConError con_serialize_array_close(struct ConSerialize *context) {
    assert(context != NULL);

    assert(context->depth_buffer_size >= 0);
    assert(0 <= context->depth && context->depth <= (size_t) context->depth_buffer_size);
    if (context->depth <= 0) { return CON_ERROR_CLOSED_TOO_MANY; }

    assert(context->depth_buffer_size >= 0);
    enum ConContainer current = con_utils_container_current(context->depth_buffer, (size_t) context->depth_buffer_size, context->depth);
    if (current != CON_CONTAINER_ARRAY) {
        return CON_ERROR_NOT_ARRAY;
    }

    size_t result = con_writer_write(context->writer, "]", 1);
    if (result != 1) { return CON_ERROR_WRITER; }

    context->depth -= 1;

    if (context->depth == 0) {
        context->state = CON_STATE_COMPLETE;
    } else {
        context->state = CON_STATE_LATER;
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
    context->depth_buffer[context->depth] = CON_CONTAINER_DICT;
    context->depth += 1;

    size_t result = con_writer_write(context->writer, "{", 1);
    if (result != 1) { return CON_ERROR_WRITER; }

    context->state = CON_STATE_FIRST;
    return CON_ERROR_OK;
}

enum ConError con_serialize_dict_close(struct ConSerialize *context) {
    assert(context != NULL);

    assert(context->depth_buffer_size >= 0);
    assert(0 <= context->depth && context->depth <= (size_t) context->depth_buffer_size);
    if (context->depth <= 0) { return CON_ERROR_CLOSED_TOO_MANY; }

    assert(context->depth_buffer_size >= 0);
    enum ConContainer current = con_utils_container_current(context->depth_buffer, (size_t) context->depth_buffer_size, context->depth);
    if (current != CON_CONTAINER_DICT) {
        return CON_ERROR_NOT_DICT;
    }

    size_t result = con_writer_write(context->writer, "}", 1);
    if (result != 1) { return CON_ERROR_WRITER; }

    context->depth -= 1;

    if (context->depth == 0) {
        context->state = CON_STATE_COMPLETE;
    } else {
        context->state = CON_STATE_LATER;
    }
    return CON_ERROR_OK;
}

enum ConError con_serialize_dict_key(struct ConSerialize *context, char const *key, size_t key_size) {
    assert(context != NULL);
    if (key == NULL) { return CON_ERROR_NULL; }

    assert(context->depth_buffer_size >= 0);
    enum ConContainer current = con_utils_container_current(context->depth_buffer, (size_t) context->depth_buffer_size, context->depth);
    if (current != CON_CONTAINER_DICT) {
        return CON_ERROR_NOT_DICT;
    }

    enum ConState state = context->state;
    if (state != CON_STATE_FIRST && state != CON_STATE_LATER) {
        return CON_ERROR_VALUE;
    }

    if (state == CON_STATE_LATER) {
        size_t result = con_writer_write(context->writer, ",", 1);
        if (result != 1) { return CON_ERROR_WRITER; }
    }

    size_t result = con_writer_write(context->writer, "\"", 1);
    if (result != 1) { return CON_ERROR_WRITER; }
    result = con_writer_write(context->writer, key, key_size);
    if (result != key_size) { return CON_ERROR_WRITER; }
    result = con_writer_write(context->writer, "\":", 2);
    if (result != 2) { return CON_ERROR_WRITER; }

    context->state = CON_STATE_VALUE;
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

    enum ConState state = context->state;
    switch (state) {
        case (CON_STATE_EMPTY):
            context->state = CON_STATE_COMPLETE;
            break;
        case (CON_STATE_FIRST):
            context->state = CON_STATE_LATER;
            break;
        case (CON_STATE_LATER): {
            size_t result = con_writer_write(context->writer, ",", 1);
            if (result != 1) { return CON_ERROR_WRITER; }
            break;
        }
        case (CON_STATE_COMPLETE):
            return CON_ERROR_COMPLETE;
        case (CON_STATE_VALUE):
            context->state = CON_STATE_LATER;
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
        assert(context->depth_buffer_size >= 0);
        enum ConContainer current = con_utils_container_current(context->depth_buffer, (size_t) context->depth_buffer_size, context->depth);
        enum ConState state = context->state;

        if (current == CON_CONTAINER_DICT && (state == CON_STATE_FIRST || state == CON_STATE_LATER)) {
            return CON_ERROR_KEY;
        }
    }

    return CON_ERROR_OK;
}
