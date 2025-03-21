#include <assert.h>
#include <ctype.h>
#include <utils.h>
#include "con_writer.h"
#include "con_serialize.h"

static inline enum ConError con_serialize_comma(struct ConSerialize *context, enum ConState state);
static inline enum ConContainer con_serialize_container_current(struct ConSerialize *context);

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
    context->state = con_utils_state_init();

    return CON_ERROR_OK;
}

enum ConError con_serialize_array_open(struct ConSerialize *context) {
    assert(context != NULL);

    assert(context->depth_buffer_size >= 0);
    assert(0 <= context->depth && context->depth <= (size_t) context->depth_buffer_size);
    if (context->depth >= (size_t) context->depth_buffer_size) { return CON_ERROR_TOO_DEEP; }

    enum ConState prev = context->state;
    enum ConContainer current = con_serialize_container_current(context);
    enum ConError state_err = con_utils_state_open(&context->state, current);
    if (state_err) { return state_err; }

    enum ConError comma_err = con_serialize_comma(context, prev);
    if (comma_err) { return comma_err; }

    assert(context->depth_buffer != NULL);
    context->depth_buffer[context->depth] = CON_CONTAINER_ARRAY;
    context->depth += 1;

    size_t result = con_writer_write(context->writer, "[", 1);
    if (result != 1) { return CON_ERROR_WRITER; }
    return CON_ERROR_OK;
}

enum ConError con_serialize_array_close(struct ConSerialize *context) {
    assert(context != NULL);

    assert(context->depth_buffer_size >= 0);
    assert(0 <= context->depth && context->depth <= (size_t) context->depth_buffer_size);
    if (context->depth <= 0) { return CON_ERROR_CLOSED_TOO_MANY; }

    enum ConContainer current = con_serialize_container_current(context);
    if (current != CON_CONTAINER_ARRAY) { return CON_ERROR_NOT_ARRAY; }

    enum ConError err = con_utils_state_close(&context->state, current);
    if (err) { return err; }

    size_t result = con_writer_write(context->writer, "]", 1);
    if (result != 1) { return CON_ERROR_WRITER; }

    context->depth -= 1;

    if (context->depth == 0) {
        context->state = CON_STATE_COMPLETE;
    }
    return CON_ERROR_OK;
}

enum ConError con_serialize_dict_open(struct ConSerialize *context) {
    assert(context != NULL);

    assert(context->depth_buffer_size >= 0);
    assert(0 <= context->depth && context->depth <= (size_t) context->depth_buffer_size);
    if (context->depth >= (size_t) context->depth_buffer_size) { return CON_ERROR_TOO_DEEP; }

    enum ConState prev = context->state;
    enum ConContainer current = con_serialize_container_current(context);
    enum ConError state_err = con_utils_state_open(&context->state, current);
    if (state_err) { return state_err; }

    enum ConError comma_err = con_serialize_comma(context, prev);
    if (comma_err) { return comma_err; }

    assert(context->depth_buffer != NULL);
    context->depth_buffer[context->depth] = CON_CONTAINER_DICT;
    context->depth += 1;

    size_t result = con_writer_write(context->writer, "{", 1);
    if (result != 1) { return CON_ERROR_WRITER; }
    return CON_ERROR_OK;
}

enum ConError con_serialize_dict_close(struct ConSerialize *context) {
    assert(context != NULL);

    assert(context->depth_buffer_size >= 0);
    assert(0 <= context->depth && context->depth <= (size_t) context->depth_buffer_size);
    if (context->depth <= 0) { return CON_ERROR_CLOSED_TOO_MANY; }

    enum ConContainer current = con_serialize_container_current(context);
    if (current != CON_CONTAINER_DICT) { return CON_ERROR_NOT_DICT; }

    enum ConError err = con_utils_state_close(&context->state, current);
    if (err) { return err; }

    size_t result = con_writer_write(context->writer, "}", 1);
    if (result != 1) { return CON_ERROR_WRITER; }

    context->depth -= 1;

    if (context->depth == 0) {
        context->state = CON_STATE_COMPLETE;
    }
    return CON_ERROR_OK;
}

enum ConError con_serialize_dict_key(struct ConSerialize *context, char const *key, size_t key_size) {
    assert(context != NULL);
    if (key == NULL) { return CON_ERROR_NULL; }

    enum ConContainer current = con_serialize_container_current(context);
    if (current != CON_CONTAINER_DICT) {
        return CON_ERROR_NOT_DICT;
    }

    enum ConState prev = context->state;
    enum ConError state_err = con_utils_state_key(&context->state, current);
    if (state_err) { return state_err; }

    enum ConError comma_err = con_serialize_comma(context, prev);
    if (comma_err) { return comma_err; }

    size_t result = con_writer_write(context->writer, "\"", 1);
    if (result != 1) { return CON_ERROR_WRITER; }
    result = con_writer_write(context->writer, key, key_size);
    if (result != key_size) { return CON_ERROR_WRITER; }
    result = con_writer_write(context->writer, "\":", 2);
    if (result != 2) { return CON_ERROR_WRITER; }
    return CON_ERROR_OK;
}

enum ConError con_serialize_number(struct ConSerialize *context, char const *number, size_t number_size) {
    assert(context != NULL);
    if (number == NULL) { return CON_ERROR_NULL; }
    if (number[0] == '\0') { return CON_ERROR_NOT_NUMBER; }

    enum StateNumber state = NUMBER_START;
    for (size_t i = 0; i < number_size; i++) {
        state = con_utils_state_number_next(state, number[i]);
        if (state == NUMBER_ERROR) { return CON_ERROR_NOT_NUMBER; }
    }

    enum ConState prev = context->state;
    enum ConContainer current = con_serialize_container_current(context);
    enum ConError state_err = con_utils_state_next(&context->state, current);
    if (state_err) { return state_err; }

    enum ConError comma_err = con_serialize_comma(context, prev);
    if (comma_err) { return comma_err; }

    if (!con_utils_state_number_terminal(state)) {
        return CON_ERROR_NOT_NUMBER;
    }

    size_t result = con_writer_write(context->writer, number, number_size);
    if (result != number_size) { return CON_ERROR_WRITER; }

    return CON_ERROR_OK;
}

enum ConError con_serialize_string(struct ConSerialize *context, char const *string, size_t string_size) {
    assert(context != NULL);
    if (string == NULL) { return CON_ERROR_NULL; }

    {
        bool escaped = false;
        for (size_t i = 0; i < string_size; i++) {
            if (!escaped) {
                escaped = string[i] == '\\';
            } else {
                switch (string[i]) {
                    case '"':
                    case '\\':
                    case '/':
                    case 'b':
                    case 'f':
                    case 'n':
                    case 'r':
                    case 't':
                        break;
                    case 'u':
                        if (i + 4 >= string_size) { return CON_ERROR_INVALID_JSON; }
                        size_t start = i + 1;
                        for (i = start; i < start + 4; i++) {
                            if (!isxdigit((unsigned char) string[i])) {
                                return CON_ERROR_INVALID_JSON;
                            }
                        }
                        break;
                    default:
                        return CON_ERROR_INVALID_JSON;
                }

                escaped = false;
            }
        }

        if (escaped) { return CON_ERROR_INVALID_JSON; }
    }

    enum ConState prev = context->state;
    enum ConContainer current = con_serialize_container_current(context);
    enum ConError state_err = con_utils_state_next(&context->state, current);
    if (state_err) { return state_err; }

    enum ConError comma_err = con_serialize_comma(context, prev);
    if (comma_err) { return comma_err; }

    size_t result = con_writer_write(context->writer, "\"", 1);
    if (result != 1) { return CON_ERROR_WRITER; }

    for (size_t i = 0; i < string_size; i++) {
        switch (string[i]) {
            case ('"'): {
                char next[2] = "\\\"";
                result = con_writer_write(context->writer, next, 2);
                if (result != 2) { return CON_ERROR_WRITER; }
                break;
            }
            case ('\b'): {
                char next[2] = "\\b";
                result = con_writer_write(context->writer, next, 2);
                if (result != 2) { return CON_ERROR_WRITER; }
                break;
            }
            case ('\f'): {
                char next[2] = "\\f";
                result = con_writer_write(context->writer, next, 2);
                if (result != 2) { return CON_ERROR_WRITER; }
                break;
            }
            case ('\n'): {
                char next[2] = "\\n";
                result = con_writer_write(context->writer, next, 2);
                if (result != 2) { return CON_ERROR_WRITER; }
                break;
            }
            case ('\r'): {
                char next[2] = "\\r";
                result = con_writer_write(context->writer, next, 2);
                if (result != 2) { return CON_ERROR_WRITER; }
                break;
            }
            case ('\t'): {
                char next[2] = "\\t";
                result = con_writer_write(context->writer, next, 2);
                if (result != 2) { return CON_ERROR_WRITER; }
                break;
            }
            case ('\\'): {
                if (i < string_size && string[i + 1] == '\\') {
                    char next[2] = "\\\\";
                    result = con_writer_write(context->writer, next, 2);
                    if (result != 2) { return CON_ERROR_WRITER; }
                    i += 1;
                    break;
                }
            }
            default:
                result = con_writer_write(context->writer, string + i, 1);
                if (result != 1) { return CON_ERROR_WRITER; }
                break;
        }
    }

    result = con_writer_write(context->writer, "\"", 1);
    if (result != 1) { return CON_ERROR_WRITER; }

    return CON_ERROR_OK;
}

enum ConError con_serialize_bool(struct ConSerialize *context, bool value) {
    assert(context != NULL);
    enum ConState prev = context->state;
    enum ConContainer current = con_serialize_container_current(context);
    enum ConError state_err = con_utils_state_next(&context->state, current);
    if (state_err) { return state_err; }

    enum ConError comma_err = con_serialize_comma(context, prev);
    if (comma_err) { return comma_err; }

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
    enum ConState prev = context->state;
    enum ConContainer current = con_serialize_container_current(context);
    enum ConError state_err = con_utils_state_next(&context->state, current);
    if (state_err) { return state_err; }

    enum ConError comma_err = con_serialize_comma(context, prev);
    if (comma_err) { return comma_err; }

    size_t result = con_writer_write(context->writer, "null", 4);
    if (result != 4) { return CON_ERROR_WRITER; }

    return CON_ERROR_OK;
}

static inline enum ConContainer con_serialize_container_current(struct ConSerialize *context) {
    assert(context != NULL);
    assert(context->depth_buffer_size >= 0);
    size_t size = (size_t) context->depth_buffer_size;
    return con_utils_container_current(context->depth_buffer, size, context->depth);
}

static inline enum ConError con_serialize_comma(struct ConSerialize *context, enum ConState state) {
    if (state != CON_STATE_LATER) {
        return CON_ERROR_OK;
    }

    assert(context != NULL);
    size_t result = con_writer_write(context->writer, ",", 1);
    if (result != 1) { return CON_ERROR_WRITER; }

    return CON_ERROR_OK;
}
