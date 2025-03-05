#include <assert.h>
#include <ctype.h>
#include <utils.h>
#include <limits.h>
#include <string.h>
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
static inline enum ConError con_deserialize_internal_state_value(struct ConDeserialize *context);
static inline enum StateNumber con_deserialize_state_number_next(enum StateNumber state, char c);
static inline bool con_deserialize_state_number_terminal(enum StateNumber state);
static inline enum ConError con_deserialize_string_get(struct ConDeserialize *context, struct ConInterfaceWriter writer);
static inline enum ConError con_deserialize_string_next(struct ConDeserialize *context, bool escaped, char *c, bool *is_u);

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
    context->found_comma = false;

    return CON_ERROR_OK;
}

enum ConError con_deserialize_next(struct ConDeserialize *context, enum ConDeserializeType *type) {
    bool same_token;
    return con_deserialize_internal_next(context, type, &same_token);
}

enum ConError con_deserialize_array_open(struct ConDeserialize *context) {
    assert(context != NULL);

    enum ConDeserializeType next;
    enum ConError next_err = con_deserialize_next(context, &next);
    if (next_err) { return next_err; }
    if (next != CON_DESERIALIZE_TYPE_ARRAY_OPEN) { return CON_ERROR_TYPE; }

    assert(context->depth_buffer_size >= 0);
    assert(0 <= context->depth && context->depth <= (size_t) context->depth_buffer_size);
    if (context->depth >= (size_t) context->depth_buffer_size) { return CON_ERROR_TOO_DEEP; }

    enum ConError state_err = con_deserialize_internal_state_value(context);
    if (state_err) { return state_err; }

    assert(context->depth_buffer != NULL);
    context->depth_buffer[context->depth] = con_utils_container_to_char(CONTAINER_ARRAY);
    context->depth += 1;

    assert(context->buffer_char == '[');
    context->buffer_char = EOF;

    context->state = con_utils_state_to_char(STATE_FIRST);
    return CON_ERROR_OK;
}

enum ConError con_deserialize_array_close(struct ConDeserialize *context) {
    assert(context != NULL);

    enum ConDeserializeType next;
    enum ConError next_err = con_deserialize_next(context, &next);

    enum ConState current_state = con_utils_state_from_char(context->state);
    assert(current_state == STATE_EMPTY || current_state == STATE_FIRST || current_state == STATE_LATER);
    if (current_state == STATE_FIRST && next_err != CON_ERROR_OK) {
        assert(next_err != CON_ERROR_MISSING_COMMA);
        return next_err;
    } else if (current_state == STATE_LATER && next_err != CON_ERROR_COMMA_MISSING) {
        assert(next_err != CON_ERROR_OK);
        return next_err;
    }
    if (next != CON_DESERIALIZE_TYPE_ARRAY_CLOSE) { return CON_ERROR_TYPE; }

    assert(context->depth_buffer_size >= 0);
    assert(0 <= context->depth && context->depth <= (size_t) context->depth_buffer_size);
    if (context->depth <= 0) { return CON_ERROR_CLOSED_TOO_MANY; }
    assert(current_state != STATE_EMPTY);

    enum ConContainer current = con_deserialize_current_container(context);
    if (current != CONTAINER_ARRAY) {
        return CON_ERROR_NOT_ARRAY;
    }

    assert(context->buffer_char == ']');
    context->buffer_char = EOF;

    context->depth -= 1;

    if (context->depth == 0) {
        context->state = con_utils_state_to_char(STATE_COMPLETE);
    } else {
        context->state = con_utils_state_to_char(STATE_LATER);
    }
    return CON_ERROR_OK;
}

enum ConError con_deserialize_dict_open(struct ConDeserialize *context) {
    assert(context != NULL);

    enum ConDeserializeType next;
    enum ConError next_err = con_deserialize_next(context, &next);
    if (next_err) { return next_err; }
    if (next != CON_DESERIALIZE_TYPE_DICT_OPEN) { return CON_ERROR_TYPE; }

    assert(context->depth_buffer_size >= 0);
    assert(0 <= context->depth && context->depth <= (size_t) context->depth_buffer_size);
    if (context->depth >= (size_t) context->depth_buffer_size) { return CON_ERROR_TOO_DEEP; }

    enum ConError state_err = con_deserialize_internal_state_value(context);
    if (state_err) { return state_err; }

    assert(context->depth_buffer != NULL);
    context->depth_buffer[context->depth] = con_utils_container_to_char(CONTAINER_DICT);
    context->depth += 1;

    assert(context->buffer_char == '{');
    context->buffer_char = EOF;

    context->state = con_utils_state_to_char(STATE_FIRST);
    return CON_ERROR_OK;
}

enum ConError con_deserialize_dict_close(struct ConDeserialize *context) {
    assert(context != NULL);

    enum ConDeserializeType next;
    enum ConError next_err = con_deserialize_next(context, &next);

    enum ConState current_state = con_utils_state_from_char(context->state);
    assert(current_state == STATE_EMPTY || current_state == STATE_FIRST || current_state == STATE_LATER);
    if (current_state == STATE_FIRST && next_err != CON_ERROR_OK) {
        assert(next_err != CON_ERROR_MISSING_COMMA);
        return next_err;
    } else if (current_state == STATE_LATER && next_err != CON_ERROR_COMMA_MISSING) {
        assert(next_err != CON_ERROR_OK);
        return next_err;
    }
    if (next != CON_DESERIALIZE_TYPE_DICT_CLOSE) { return CON_ERROR_TYPE; }

    assert(context->depth_buffer_size >= 0);
    assert(0 <= context->depth && context->depth <= (size_t) context->depth_buffer_size);
    if (context->depth <= 0) { return CON_ERROR_CLOSED_TOO_MANY; }
    assert(current_state != STATE_EMPTY);

    enum ConContainer current = con_deserialize_current_container(context);
    if (current != CONTAINER_DICT) {
        return CON_ERROR_NOT_DICT;
    }

    assert(context->buffer_char == '}');
    context->buffer_char = EOF;

    context->depth -= 1;

    if (context->depth == 0) {
        context->state = con_utils_state_to_char(STATE_COMPLETE);
    } else {
        context->state = con_utils_state_to_char(STATE_LATER);
    }
    return CON_ERROR_OK;
}

enum ConError con_deserialize_dict_key(struct ConDeserialize *context, struct ConInterfaceWriter writer) {
    assert(context != NULL);

    enum ConDeserializeType next;
    enum ConError next_err = con_deserialize_next(context, &next);
    if (next_err) { return next_err; }
    if (next != CON_DESERIALIZE_TYPE_DICT_KEY) { return CON_ERROR_TYPE; }

    enum ConContainer current = con_deserialize_current_container(context);
    if (current != CONTAINER_DICT) {
        return CON_ERROR_NOT_DICT;
    }

    enum ConState state = con_utils_state_from_char(context->state);
    if (state != STATE_FIRST && state != STATE_LATER) {
        return CON_ERROR_VALUE;
    }

    enum ConError err = con_deserialize_string_get(context, writer);
    if (err) { return err; }

    {
        char c = '*';
        bool same_token;
        context->buffer_char = EOF;
        enum ConError err = con_deserialize_internal_next_character(context, &c, &same_token);
        if (err != CON_ERROR_OK && err != CON_ERROR_COMMA_MISSING) {
            return err;
        } else if (c != ':') {
            return CON_ERROR_INVALID_JSON;  // Missing ':'
        }

        context->buffer_char = -1;
    }

    context->state = con_utils_state_to_char(STATE_VALUE);
    return CON_ERROR_OK;
}

enum ConError con_deserialize_number(struct ConDeserialize *context, struct ConInterfaceWriter writer) {
    assert(context != NULL);

    enum ConDeserializeType next;
    enum ConError next_err = con_deserialize_next(context, &next);
    if (next_err) { return next_err; }
    if (next != CON_DESERIALIZE_TYPE_NUMBER) { return CON_ERROR_TYPE; }

    enum ConError state_err = con_deserialize_internal_state_value(context);
    if (state_err) { return state_err; }

    enum StateNumber state = NUMBER_START;

    assert(context->buffer_char != EOF);
    state = con_deserialize_state_number_next(state, (char) context->buffer_char);

    if (state == NUMBER_ERROR) {
        return CON_ERROR_NOT_NUMBER;  // unexpected char
    }
    size_t amount_written = con_writer_write(writer, (char*) &context->buffer_char, 1);
    if (amount_written != 1) { return CON_ERROR_WRITER; }

    context->buffer_char = EOF;
    while (true) {
        char c = '*';
        bool same_token = false;
        context->buffer_char = EOF;
        enum ConError err = con_deserialize_internal_next_character(context, &c, &same_token);

        if (err == CON_ERROR_READER && con_deserialize_state_number_terminal(state)) {
            break;  // number may be done
        } else if (err != CON_ERROR_OK && err != CON_ERROR_COMMA_MISSING) {
            return err;
        } else if (!same_token) {
            break;  // number done
        } else {
            state = con_deserialize_state_number_next(state, c);

            if (state != NUMBER_ERROR) {
                amount_written = con_writer_write(writer, &c, 1);
                if (amount_written != 1) { return CON_ERROR_WRITER; }
            } else if (c == ',' || c == ']' || c == '}') {
                return CON_ERROR_OK;
            } else {
                return CON_ERROR_INVALID_JSON;
            }
        }
    }

    if (!con_deserialize_state_number_terminal(state)) {
        return CON_ERROR_NOT_NUMBER;
    }

    return CON_ERROR_OK;
}

enum ConError con_deserialize_string(struct ConDeserialize *context, struct ConInterfaceWriter writer) {
    assert(context != NULL);

    enum ConDeserializeType next;
    enum ConError next_err = con_deserialize_next(context, &next);
    if (next_err) { return next_err; }

    enum ConError state_err = con_deserialize_internal_state_value(context);
    if (state_err) { return state_err; }

    return con_deserialize_string_get(context, writer);
}

enum ConError con_deserialize_bool(struct ConDeserialize *context, bool *value) {
    assert(context != NULL);

    enum ConDeserializeType next;
    enum ConError next_err = con_deserialize_next(context, &next);
    if (next_err) { return next_err; }
    if (next != CON_DESERIALIZE_TYPE_BOOL) { return CON_ERROR_TYPE; }

    assert(context->buffer_char == 't' || context->buffer_char == 'f');
    bool is_true = context->buffer_char == 't';

    size_t length;
    char expected[4];

    if (is_true) {
        length = 3;
        memcpy(expected, "rue", length);
    } else {
        length = 4;
        memcpy(expected, "alse", length);
    }

    for (size_t i = 0; i < length; i++) {
        char c;
        bool same_token = false;
        context->buffer_char = EOF;
        enum ConError err = con_deserialize_internal_next_character(context, &c, &same_token);

        if (err) {
            return err;
        } else if (!same_token) {
            return CON_ERROR_INVALID_JSON;
        } else {
            if (expected[i] != c) {
                return CON_ERROR_INVALID_JSON;
            }
        }
    }

    *value = is_true;

    enum ConError state_err = con_deserialize_internal_state_value(context);
    if (state_err) { return state_err; }

    char c;
    bool same_token;
    context->buffer_char = EOF;
    enum ConError err = con_deserialize_internal_next_character(context, &c, &same_token);
    if (err == CON_ERROR_READER) {
        return CON_ERROR_OK;
    } else if (err) {
        return err;
    } else if (same_token) {
        return CON_ERROR_INVALID_JSON;
    }

    return CON_ERROR_OK;
}

enum ConError con_deserialize_null(struct ConDeserialize *context) {
    assert(context != NULL);

    enum ConDeserializeType next;
    enum ConError next_err = con_deserialize_next(context, &next);
    if (next_err) { return next_err; }
    if (next != CON_DESERIALIZE_TYPE_NULL) { return CON_ERROR_TYPE; }

    assert(context->buffer_char == 'n');
    size_t length = 3;
    char *expected = "ull";

    for (size_t i = 0; i < length; i++) {
        char c;
        bool same_token = false;
        context->buffer_char = EOF;
        enum ConError err = con_deserialize_internal_next_character(context, &c, &same_token);

        if (err) {
            return err;
        } else if (!same_token) {
            return CON_ERROR_INVALID_JSON;
        } else {
            if (expected[i] != c) {
                return CON_ERROR_INVALID_JSON;
            }
        }
    }

    enum ConError state_err = con_deserialize_internal_state_value(context);
    if (state_err) { return state_err; }

    char c;
    bool same_token;
    context->buffer_char = EOF;
    enum ConError err = con_deserialize_internal_next_character(context, &c, &same_token);
    if (err == CON_ERROR_READER) {
        return CON_ERROR_OK;
    } else if (err) {
        return err;
    } else if (same_token) {
        return CON_ERROR_INVALID_JSON;
    }

    return CON_ERROR_OK;
}

enum ConError con_deserialize_internal_next(struct ConDeserialize *context, enum ConDeserializeType *type, bool *same_token) {
    assert(context != NULL);
    if (type == NULL) { return CON_ERROR_NULL; }

    char next;
    enum ConError next_err = con_deserialize_internal_next_character(context, &next, same_token);
    if (next_err != CON_ERROR_OK && next_err != CON_ERROR_COMMA_MISSING) { return next_err; }

    enum ConState state = con_utils_state_from_char(context->state);
    enum ConContainer container = con_deserialize_current_container(context);
    bool expect_key = container == CONTAINER_DICT && (state == STATE_FIRST || state == STATE_LATER);
    if (isdigit((unsigned char) next) || next == '.' || next == '-') {
        *type = CON_DESERIALIZE_TYPE_NUMBER;
    } else if (next == '"' && expect_key) {
        *type = CON_DESERIALIZE_TYPE_DICT_KEY;
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
        if (context->found_comma) { return CON_ERROR_COMMA_TRAILING; }
    } else if (next == '{') {
        *type = CON_DESERIALIZE_TYPE_DICT_OPEN;
    } else if (next == '}') {
        *type = CON_DESERIALIZE_TYPE_DICT_CLOSE;
        if (context->found_comma) { return CON_ERROR_COMMA_TRAILING; }
    } else {
        *type = CON_DESERIALIZE_TYPE_UNKNOWN;
        return CON_ERROR_INVALID_JSON;
    }

    return next_err;
}

static inline enum ConError con_deserialize_internal_next_character(struct ConDeserialize *context, char *c, bool *same_token) {
    assert(context != NULL);
    assert(c != NULL);
    assert(same_token != NULL);

    if (context->buffer_char == EOF) {
        context->found_comma = false;
        *same_token = true;

        while (true) {
            context->buffer_char = EOF;

            char next;
            struct ConReadResult result = con_reader_read(context->reader, &next, 1);
            if (result.error || result.length != 1) {
                return CON_ERROR_READER;
            }
            context->buffer_char = next;

            if (context->buffer_char == ',') {
                if (context->found_comma) {
                    if (result.error) { return CON_ERROR_READER; }
                    return CON_ERROR_COMMA_MULTIPLE;
                }

                context->found_comma = true;
                *same_token = false;

                if (result.error) { return CON_ERROR_READER; }
                if (context->state != STATE_LATER) {
                    return CON_ERROR_COMMA_UNEXPECTED;
                }
            } else if (isspace((unsigned char) next)) {
                *same_token = false;

                if (result.error) { return CON_ERROR_READER; }
                continue;
            } else {
                if (result.error) { return CON_ERROR_READER; }
                break;
            }
        }
    } else if (context->buffer_char == ',') {
        return CON_ERROR_COMMA_MULTIPLE;
    } else {
        if (context->found_comma && context->state != STATE_LATER) {
            return CON_ERROR_COMMA_UNEXPECTED;
        }
    }

    *c = (char) context->buffer_char;

    if (!context->found_comma && context->state == STATE_LATER) {
        return CON_ERROR_COMMA_MISSING;
    }
    return CON_ERROR_OK;
}

static inline enum ConError con_deserialize_internal_state_value(struct ConDeserialize *context) {
    enum ConContainer current = con_deserialize_current_container(context);
    enum ConState context_state = con_utils_state_from_char(context->state);
    switch (context_state) {
        case (STATE_EMPTY):
            context->state = con_utils_state_to_char(STATE_COMPLETE);
            break;
        case (STATE_FIRST):
        case (STATE_LATER):
            if (current == CONTAINER_DICT) { return CON_ERROR_KEY; }
            context->state = con_utils_state_to_char(STATE_LATER);
            break;
        case (STATE_COMPLETE):
            assert(false);
            break;
        case (STATE_VALUE):
            context->state = con_utils_state_to_char(STATE_LATER);
            break;
        default:
            assert(false);
            return CON_ERROR_STATE_UNKNOWN;
    }

    return CON_ERROR_OK;
}

static inline bool con_deserialize_state_number_terminal(enum StateNumber state) {
    assert(0 <= state && state <= STATE_NUMBER_MAX);
    return (
        state == NUMBER_ZERO
        || state == NUMBER_WHOLE
        || state == NUMBER_FRACTION
        || state == NUMBER_EXPONENT
    );
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
        case (STATE_NUMBER_MAX):
            assert(false);
    }

    assert(false);
}

static inline enum ConError con_deserialize_string_get(struct ConDeserialize *context, struct ConInterfaceWriter writer) {
    assert(context != NULL);

    assert(context->buffer_char != -1);
    assert(context->buffer_char == '"');
    context->buffer_char = EOF;

    bool escaped = false;
    while (true) {
        bool is_u;
        char c[2];
        enum ConError err = con_deserialize_string_next(context, escaped, c, &is_u);
        if (err) { return err; }

        if (*c == '"' && !escaped) {
            break;  // string done
        } else if (*c == '\\' && !escaped) {
            escaped = true;
        } else {
            escaped = false;
            size_t amount_written = con_writer_write(writer, c, 1 + is_u);
            if (amount_written != 1 + is_u) { return CON_ERROR_WRITER; }
        }
    }

    return CON_ERROR_OK;
}

static inline enum ConError con_deserialize_string_next(struct ConDeserialize *context, bool escaped, char *c, bool *is_u) {
    struct ConReadResult result = con_reader_read(context->reader, c, 1);
    if (result.error || result.length != 1) { return CON_ERROR_READER; }
    *is_u = false;

    if (escaped) {
        switch (*c) {
            case '"':
                break;
            case '\\':
                break;
            case '/':
                break;
            case 'b':
                *c = '\b';
                break;
            case 'f':
                *c = '\f';
                break;
            case 'n':
                *c = '\n';
                break;
            case 'r':
                *c = '\r';
                break;
            case 't':
                *c = '\t';
                break;
            case 'u': {
                *is_u = true;

                for (int i = 0; i < 2; i++) {
                    for (int j = 0; j < 2; j++) {
                        char d;
                        struct ConReadResult r = con_reader_read(context->reader, &d, 1);
                        if (r.error || r.length != 1) { return CON_ERROR_READER; }
                        if (!isxdigit((unsigned char) d)) { return CON_ERROR_INVALID_JSON; }

                        // Here we convert a hex digit to a number in a complicated way:
                        // '0' to '9' are guaranteed to be contiguous, i.e. d - '0' results
                        // in the correct value. Alas 'a' to 'f' and 'A' to 'F' are not
                        // guaranteed to be contiguous by the C standard which means that
                        // if we know that d is lower case then 10 + d - 'a' is not guaranteed
                        // to equal the value we're looking for...
                        switch (d) {
                            case '0':
                            case '1':
                            case '2':
                            case '3':
                            case '4':
                            case '5':
                            case '6':
                            case '7':
                            case '8':
                            case '9':
                                d -= '0';
                                break;
                            case 'a':
                            case 'A':
                                d = 10;
                                break;
                            case 'b':
                            case 'B':
                                d = 11;
                                break;
                            case 'c':
                            case 'C':
                                d = 12;
                                break;
                            case 'd':
                            case 'D':
                                d = 13;
                                break;
                            case 'e':
                            case 'E':
                                d = 14;
                                break;
                            case 'f':
                            case 'F':
                                d = 15;
                                break;
                            default:
                                assert(false);
                        }

                        c[i] = 16 * c[i] + d;
                    }
                }
                break;
            }
            default:
                return CON_ERROR_INVALID_JSON;
        }
    }

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
