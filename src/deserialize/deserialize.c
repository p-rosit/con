#include <assert.h>
#include <ctype.h>
#include <utils.h>
#include <limits.h>
#include "con_writer.h"
#include "con_deserialize.h"

enum StateNumber {
    NUMBER_ERROR,
    NUMBER_START,
    NUMBER_NEGATIVE,
    NUMBER_ZERO,
    NUMBER_WHOLE,
    NUMBER_POINT,
    NUMBER_FRACTION,
    NUMBER_E,
    NUMBER_EXPONENT_SIGN,
    NUMBER_EXPONENT,
    STATE_NUMBER_MAX,
};

static inline enum ConContainer con_deserialize_current_container(struct ConDeserialize *context);
static inline enum ConError con_deserialize_internal_next(struct ConDeserialize *context, enum ConDeserializeType *type, bool *same_token);
static inline enum ConError con_deserialize_internal_next_character(struct ConDeserialize *context, char *c, bool *same_token);
static inline enum StateNumber con_deserialize_state_number_from_char(char state);
static inline char con_deserialize_state_number_to_char(enum StateNumber state);
static inline enum StateNumber con_deserialize_state_number_next(enum StateNumber state, char c);

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
    context->same_token = true;
    context->number_state = NUMBER_START;

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

    enum StateNumber state = con_deserialize_state_number_from_char(context->number_state);

    assert(context->buffer_char != EOF);
    state = con_deserialize_state_number_next(state, (char) context->buffer_char);

    if (state == NUMBER_ERROR) {
        return CON_ERROR_NOT_NUMBER;  // unexpected char
    }

    buffer[0] = (char) context->buffer_char;
    context->buffer_char = EOF;
    context->found_comma = false;

    size_t amount_read = 1;
    while (amount_read < buffer_size) {
        char c;
        struct ConReadResult result = con_reader_read(context->reader, &c, 1);

        if (result.length == 1) {
            state = con_deserialize_state_number_next(state, c);

            if (state != NUMBER_ERROR) {
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
    context->number_state = con_deserialize_state_number_to_char(state);

    if (amount_read >= buffer_size) {
        context->middle_of = CON_DESERIALIZE_TYPE_UNKNOWN;

        char c;
        bool same_token;
        enum ConError err = con_deserialize_internal_next_character(context, &c, &same_token);
        if (err == CON_ERROR_READER && c == '\0') {
            // ok
        } else if (err) {
            return err;
        }

        if (!same_token) {
            return CON_ERROR_OK;
        }

        state = con_deserialize_state_number_next(state, c);

        if (state != NUMBER_ERROR) {
            context->middle_of = CON_DESERIALIZE_TYPE_NUMBER;
            context->buffer_char = c;
            return CON_ERROR_BUFFER;
        } else {
            return CON_ERROR_OK;
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
    if (isdigit((unsigned char) next) || next == '.' || next == '-') {
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
            if (result.error || result.length != 1) {
                *c = result.error ? ' ' : '\0';
                return CON_ERROR_READER;
            }

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

static inline enum StateNumber con_deserialize_state_number_from_char(char state) {
    assert(0 <= state && state <= STATE_NUMBER_MAX);
    return (enum StateNumber) state;
}

static inline char con_deserialize_state_number_to_char(enum StateNumber state) {
    assert(0 <= state && state <= CHAR_MAX);
    assert(0 <= state && state <= STATE_NUMBER_MAX);
    return (char) state;
}

static inline enum StateNumber con_deserialize_state_number_next(enum StateNumber state, char c) {
    switch (state) {
        case (NUMBER_START):
            if (c == '-') {
                return NUMBER_NEGATIVE;
            } else if (c == '0') {
                return NUMBER_ZERO;
            } else if (isdigit((unsigned char) c)) {
                return NUMBER_WHOLE;
            } else {
                return NUMBER_ERROR;
            }
        case (NUMBER_NEGATIVE):
            if (c == '0') {
                return NUMBER_ZERO;
            } else if (isdigit((unsigned char) c)) {
                return NUMBER_WHOLE;
            } else {
                return NUMBER_ERROR;
            }
        case (NUMBER_ZERO):
            if (c == '.') {
                return NUMBER_POINT;
            } else if (c == 'e' || c == 'E') {
                return NUMBER_E;
            } else {
                return NUMBER_ERROR;
            }
        case (NUMBER_WHOLE):
            if (c == '.') {
                return NUMBER_POINT;
            } else if (c == 'e' || c == 'E') {
                return NUMBER_E;
            } else if (isdigit((unsigned char) c)) {
                return NUMBER_WHOLE;
            } else {
                return NUMBER_ERROR;
            }
        case (NUMBER_POINT):
            if (isdigit((unsigned char) c)) {
                return NUMBER_FRACTION;
            } else {
                return NUMBER_ERROR;
            }
        case (NUMBER_FRACTION):
            if (c == 'e' || c == 'E') {
                return NUMBER_E;
            } else if (isdigit((unsigned char) c)) {
                return NUMBER_FRACTION;
            } else {
                return NUMBER_ERROR;
            }
        case (NUMBER_E):
            if (c == '+' || c == '-') {
                return NUMBER_EXPONENT_SIGN;
            } else if (isdigit((unsigned char) c)) {
                return NUMBER_EXPONENT;
            } else {
                return NUMBER_ERROR;
            }
        case (NUMBER_EXPONENT_SIGN):
            if (isdigit((unsigned char) c)) {
                return NUMBER_EXPONENT;
            } else {
                return NUMBER_ERROR;
            }
        case (NUMBER_EXPONENT):
            if (isdigit((unsigned char) c)) {
                return NUMBER_EXPONENT;
            } else {
                return NUMBER_ERROR;
            }
        case (NUMBER_ERROR):
            return NUMBER_ERROR;
    }

    assert(false);
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
