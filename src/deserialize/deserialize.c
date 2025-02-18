#include <assert.h>
#include <ctype.h>
#include <utils.h>
#include "con_writer.h"
#include "con_deserialize.h"

static inline enum ConState con_deserialize_state(struct ConDeserialize *context);
static inline enum ConContainer con_deserialize_current_container(struct ConDeserialize *context);

enum ConError con_deserialize_init(struct ConDeserialize *context, struct ConInterfaceReader reader, char *depth_buffer, int depth_buffer_size) {
    if (context == NULL) { return CON_ERROR_NULL; }
    if (depth_buffer == NULL && depth_buffer_size > 0) { return CON_ERROR_NULL; }
    if (depth_buffer_size < 0) { return CON_ERROR_BUFFER; }

    context->reader = reader;
    context->depth = 0;
    context->depth_buffer = depth_buffer;
    context->depth_buffer_size = depth_buffer_size;
    context->buffer_char = EOF;
    context->state = STATE_EMPTY;

    return CON_ERROR_OK;
}

enum ConError con_deserialize_next(struct ConDeserialize *context, enum ConDeserializeType *type) {
    assert(context != NULL);
    if (type == NULL) { return CON_ERROR_NULL; }

    char next = ' ';
    bool found_comma = false;
    while (isspace((unsigned char) next)) {
        struct ConReadResult result = con_reader_read(context->reader, &next, 1);
        if (result.error || result.length != 1) { return CON_ERROR_READER; }

        if (next == ',') {
            found_comma = true;

            if (context->state != STATE_LATER) {
                return CON_ERROR_INVALID_JSON;  // unexpected comma
            }
        }
    }

    if (!found_comma && context->state == STATE_LATER) {
        return CON_ERROR_INVALID_JSON;  // missing comma
    }

    enum ConState state = con_deserialize_state(context);
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
        if (found_comma) { return CON_ERROR_TRAILING_COMMA; }
    } else if (next == '{') {
        *type = CON_DESERIALIZE_TYPE_DICT_OPEN;
    } else if (next == '}') {
        *type = CON_DESERIALIZE_TYPE_DICT_CLOSE;
        if (found_comma) { return CON_ERROR_TRAILING_COMMA; }
    } else {
        *type = CON_DESERIALIZE_TYPE_UNKNOWN;
        return CON_ERROR_INVALID_JSON;
    }

    return CON_ERROR_OK;
}

static inline enum ConState con_deserialize_state(struct ConDeserialize *context) {
    assert(context != NULL);

    char state = context->state;
    assert(0 < state && state < STATE_MAX);
    return (enum ConState) state;
}

static inline enum ConContainer con_deserialize_current_container(struct ConDeserialize *context) {
    assert(context != NULL);

    if (context->depth <= 0) {
        return CONTAINER_NONE;
    }

    assert(context->depth_buffer_size >= 0);
    assert(0 <= context->depth && context->depth <= (size_t) context->depth_buffer_size);
    char container = context->depth_buffer[context->depth - 1];

    assert(container == CONTAINER_ARRAY || container == CONTAINER_DICT);
    return (enum ConContainer) container;
}
