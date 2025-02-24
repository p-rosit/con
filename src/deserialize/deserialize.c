#include <assert.h>
#include <ctype.h>
#include <utils.h>
#include "con_writer.h"
#include "con_deserialize.h"

static inline enum ConContainer con_deserialize_current_container(struct ConDeserialize *context);
static inline enum ConError con_deserialize_internal_next(struct ConDeserialize *context, enum ConDeserializeType *type, bool *same_token);
static inline enum ConError con_deserialize_internal_next_character(struct ConDeserialize *context, char *c, bool *same_token);

enum ConError con_deserialize_init(struct ConDeserialize *context, struct ConInterfaceReader reader, char *depth_buffer, int depth_buffer_size) {
    if (context == NULL) { return CON_ERROR_NULL; }
    if (depth_buffer == NULL && depth_buffer_size > 0) { return CON_ERROR_NULL; }
    if (depth_buffer_size < 0) { return CON_ERROR_BUFFER; }

    context->reader = reader;
    context->depth = 0;
    context->depth_buffer = depth_buffer;
    context->depth_buffer_size = depth_buffer_size;
    context->buffer_char = EOF;
    context->middle_of = CON_DESERIALIZE_TYPE_UNKNOWN;
    context->state = STATE_EMPTY;
    context->found_comma = false;

    return CON_ERROR_OK;
}

enum ConError con_deserialize_next(struct ConDeserialize *context, enum ConDeserializeType *type) {
    bool same_token;
    return con_deserialize_internal_next(context, type, &same_token);
}

enum ConError con_deserialize_number(struct ConDeserialize *context, char *buffer, size_t buffer_size, size_t *length) {
    assert(context != NULL);
    if (buffer == NULL) { return CON_ERROR_NULL; }
    if (length == NULL) { return CON_ERROR_NULL; }
    if (buffer_size < 1) { return CON_ERROR_NOT_NUMBER; }

    if (context->middle_of == CON_DESERIALIZE_TYPE_UNKNOWN) {
        enum ConDeserializeType next;
        enum ConError next_err = con_deserialize_next(context, &next);
        if (next_err) { return next_err; }
        if (next != CON_DESERIALIZE_TYPE_NUMBER) { return CON_ERROR_TYPE; }
    } else if (context->middle_of != CON_DESERIALIZE_TYPE_NUMBER) {
        return CON_ERROR_TYPE;
    }

    assert(isdigit((unsigned char) context->buffer_char));
    buffer[0] = (char) context->buffer_char;
    context->buffer_char = EOF;
    context->found_comma = false;

    size_t amount_read = 1;
    while (amount_read < buffer_size) {
        char c;
        struct ConReadResult result = con_reader_read(context->reader, &c, 1);

        if (result.length == 1) {
            if (isdigit((unsigned char) c)) {
                buffer[amount_read++] = c;
            } else {
                context->buffer_char = c;
                break;
            }
        } else if (result.length == 0 && !result.error) {
            break;
        } else {
            return CON_ERROR_READER;
        }
    }

    assert(amount_read <= buffer_size);
    *length = amount_read;

    if (amount_read >= buffer_size) {
        context->middle_of = CON_DESERIALIZE_TYPE_UNKNOWN;

        char c;
        struct ConReadResult result = con_reader_read(context->reader, &c, 1);

        if (result.length == 1) {
            if (isdigit((unsigned char) c)) {
                context->middle_of = CON_DESERIALIZE_TYPE_NUMBER;
                context->buffer_char = c;
            }
            return CON_ERROR_BUFFER;
        } else if (result.length == 0 && !result.error) {
            return CON_ERROR_OK;
        } else {
            return CON_ERROR_READER;
        }
    }
    return CON_ERROR_OK;
}

enum ConError con_deserialize_internal_next(struct ConDeserialize *context, enum ConDeserializeType *type, bool *same_token) {
    assert(context != NULL);
    if (type == NULL) { return CON_ERROR_NULL; }

    char next;
    enum ConError next_err = con_deserialize_internal_next_character(context, &next, same_token);
    if (next_err) { return next_err; }

    enum ConState state = con_utils_state_from_char(context->state);
    enum ConContainer container = con_deserialize_current_container(context);
    bool expect_key = container == CONTAINER_DICT && (state == STATE_FIRST || state == STATE_LATER);
    if (isdigit((unsigned char) next) || next == '.') {
        *type = CON_DESERIALIZE_TYPE_NUMBER;
    } else if (next == '"' && expect_key) {
        *type = CON_DESERIALIZE_TYPE_KEY;
    } else if (next == '"') {
        *type = CON_DESERIALIZE_TYPE_STRING;
    } else if (next == 't' || next == 'f') {
        *type = CON_DESERIALIZE_TYPE_BOOL;
    } else if (next == 'n') {
        *type = CON_DESERIALIZE_TYPE_NULL;
    } else if (next == '[') {
        *type = CON_DESERIALIZE_TYPE_ARRAY_OPEN;
    } else if (next == ']') {
        *type = CON_DESERIALIZE_TYPE_ARRAY_CLOSE;
        if (context->found_comma) { return CON_ERROR_TRAILING_COMMA; }
    } else if (next == '{') {
        *type = CON_DESERIALIZE_TYPE_DICT_OPEN;
    } else if (next == '}') {
        *type = CON_DESERIALIZE_TYPE_DICT_CLOSE;
        if (context->found_comma) { return CON_ERROR_TRAILING_COMMA; }
    } else {
        *type = CON_DESERIALIZE_TYPE_UNKNOWN;
        return CON_ERROR_INVALID_JSON;
    }

    return CON_ERROR_OK;
}

static inline enum ConError con_deserialize_internal_next_character(struct ConDeserialize *context, char *c, bool *same_token) {
    assert(context != NULL);
    assert(c != NULL);
    assert(same_token != NULL);

    if (context->buffer_char == EOF) {
        context->found_comma = false;
        context->same_token = true;

        while (true) {
            context->buffer_char = EOF;

            char next;
            struct ConReadResult result = con_reader_read(context->reader, &next, 1);
            if (result.error || result.length != 1) { return CON_ERROR_READER; }

            context->buffer_char = next;

            if (context->buffer_char == ',') {
                if (context->found_comma) {
                    return CON_ERROR_INVALID_JSON;  // multiple commas
                }

                context->found_comma = true;
                context->same_token = false;

                if (context->state != STATE_LATER) {
                    return CON_ERROR_INVALID_JSON;  // unexpected comma
                }
            } else if (isspace((unsigned char) next)) {
                context->same_token = false;
                continue;
            } else {
                break;
            }
        }
    } else if (context->buffer_char == ',') {
        return CON_ERROR_INVALID_JSON;  // multiple commas
    } else {
        if (context->found_comma && context->state != STATE_LATER) {
            return CON_ERROR_INVALID_JSON;  // unexpected comma
        }
    }

    if (!context->found_comma && context->state == STATE_LATER) {
        return CON_ERROR_INVALID_JSON;  // missing comma
    }

    *c = (char) context->buffer_char;
    *same_token = context->same_token;

    return CON_ERROR_OK;
}

static inline enum ConContainer con_deserialize_current_container(struct ConDeserialize *context) {
    assert(context != NULL);

    if (context->depth <= 0) {
        return CONTAINER_NONE;
    }

    assert(context->depth_buffer_size >= 0);
    assert(0 <= context->depth && context->depth <= (size_t) context->depth_buffer_size);
    char container_char = context->depth_buffer[context->depth - 1];
    enum ConContainer container = con_utils_container_from_char(container_char);

    assert(container == CONTAINER_ARRAY || container == CONTAINER_DICT);
    return (enum ConContainer) container;
}
