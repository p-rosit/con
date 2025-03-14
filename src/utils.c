#include <assert.h>
#include <limits.h>
#include <ctype.h>
#include "utils.h"

enum ConState con_utils_state_init(void) {
    return CON_STATE_EMPTY;
}

enum ConError con_utils_state_next(enum ConState *state, enum ConContainer current) {
    assert(state != NULL);
    enum ConState s = *state;

    assert(current == CON_CONTAINER_NONE || current == CON_CONTAINER_ARRAY || current == CON_CONTAINER_DICT);
    if (current == CON_CONTAINER_DICT && (s == CON_STATE_FIRST || s == CON_STATE_LATER)) {
        return CON_ERROR_KEY;
    }

    assert(CON_STATE_UNKNOWN <= s && s <= CON_STATE_MAX);
    switch (s) {
        case (CON_STATE_EMPTY):
            *state = CON_STATE_COMPLETE;
            return CON_ERROR_OK;
        case (CON_STATE_FIRST):
        case (CON_STATE_LATER):
            *state = CON_STATE_LATER;
            return CON_ERROR_OK;
        case (CON_STATE_COMPLETE):
            return CON_ERROR_COMPLETE;
        case (CON_STATE_VALUE):
            *state = CON_STATE_LATER;
            return CON_ERROR_OK;
        case (CON_STATE_MAX):
        case (CON_STATE_UNKNOWN):
            break;
    }

    assert(0);
    return CON_ERROR_STATE_UNKNOWN;
}

enum ConError con_utils_state_open(enum ConState *state, enum ConContainer current) {
    enum ConError err = con_utils_state_next(state, current);
    if (err) { return err; }

    assert(CON_STATE_UNKNOWN <= *state && *state <= CON_STATE_MAX);
    *state = CON_STATE_FIRST;
    return CON_ERROR_OK;
}

enum ConError con_utils_state_close(enum ConState *state, enum ConContainer current) {
    assert(current == CON_CONTAINER_NONE || current == CON_CONTAINER_ARRAY || current == CON_CONTAINER_DICT);
    assert(CON_STATE_UNKNOWN <= *state && *state <= CON_STATE_MAX);
    *state = CON_STATE_LATER;
    return CON_ERROR_OK;
}

enum ConError con_utils_state_key(enum ConState *state, enum ConContainer current) {
    assert(current == CON_CONTAINER_NONE || current == CON_CONTAINER_ARRAY || current == CON_CONTAINER_DICT);
    if (current != CON_CONTAINER_DICT) { return CON_ERROR_VALUE; }

    assert(CON_STATE_UNKNOWN <= *state && *state <= CON_STATE_MAX);
    if (*state == CON_STATE_VALUE) { return CON_ERROR_VALUE; }
    *state = CON_STATE_VALUE;
    return CON_ERROR_OK;
}

enum ConContainer con_utils_container_current(enum ConContainer *containers, size_t size, size_t depth) {
    assert(0 <= depth && depth <= size);
    if (depth == 0) { return CON_CONTAINER_NONE; }

    assert(containers != NULL);
    enum ConContainer current = containers[depth - 1];
    assert(current == CON_CONTAINER_ARRAY || current == CON_CONTAINER_DICT);
    return current;
}

bool con_utils_state_number_terminal(enum StateNumber state) {
    assert(0 <= state && state <= STATE_NUMBER_MAX);
    return (
        state == NUMBER_ZERO
        || state == NUMBER_WHOLE
        || state == NUMBER_FRACTION
        || state == NUMBER_EXPONENT
    );
}

enum StateNumber con_utils_state_number_next(enum StateNumber state, char c) {
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

enum ConJsonState con_utils_json_init(void) {
    return JSON_STATE_NORMAL;
}

enum ConJsonState con_utils_json_next(enum ConJsonState state, char c) {
    assert(0 < state && state < JSON_STATE_MAX);
    enum ConJsonState next_state;

    switch (state) {
        case JSON_STATE_UNKNOWN:
        case JSON_STATE_MAX:
            assert(false);
        case JSON_STATE_FIRST_ITEM:
        case JSON_STATE_NORMAL: {
            if (c == '[' || c == '{') {
                next_state = JSON_STATE_FIRST_ITEM;
            } else if (c == ']' || c == '}') {
                next_state = JSON_STATE_NORMAL;
            } else if (c == '"') {
                next_state = JSON_STATE_IN_STRING;
            } else if (!isspace((unsigned char) c)) {
                next_state = JSON_STATE_NORMAL;
            } else {
                next_state = state;
            }
            break;
        }
        case JSON_STATE_IN_STRING: {
            if (c == '"') {
                next_state = JSON_STATE_NORMAL;
            } else if (c == '\\') {
                next_state = JSON_STATE_ESCAPE;
            } else {
                next_state = JSON_STATE_IN_STRING;
            }
            break;
        }
        case JSON_STATE_ESCAPE: {
            next_state = JSON_STATE_IN_STRING;
            break;
        }
        default:
            assert(false);
    }

    return next_state;
}

char con_utils_json_to_char(enum ConJsonState state) {
    assert(0 < state && state < CHAR_MAX);
    assert(0 < state && state < JSON_STATE_MAX);
    return (char) state;
}

enum ConJsonState con_utils_json_from_char(char state) {
    assert(0 < state && state < JSON_STATE_MAX);
    return (enum ConJsonState) state;
}

bool con_utils_json_is_meaningful(enum ConJsonState state, char c) {
    assert(0 < state && state < JSON_STATE_MAX);
    if (state == JSON_STATE_IN_STRING || state == JSON_STATE_ESCAPE) {
        return true;
    }
    return !isspace((unsigned char) c);
}

bool con_utils_json_is_open(enum ConJsonState state, char c) {
    assert(0 < state && state < JSON_STATE_MAX);
    if (state != JSON_STATE_NORMAL && state != JSON_STATE_FIRST_ITEM) {
        return false;
    }
    return c == '[' || c == '{';
}

bool con_utils_json_is_close(enum ConJsonState state, char c) {
    assert(0 < state && state < JSON_STATE_MAX);
    if (state != JSON_STATE_NORMAL && state != JSON_STATE_FIRST_ITEM) {
        return false;
    }
    return c == ']' || c == '}';
}

bool con_utils_json_is_key_separator(enum ConJsonState state, char c) {
    assert(0 < state && state < JSON_STATE_MAX);
    if (state != JSON_STATE_NORMAL && state != JSON_STATE_FIRST_ITEM) {
        return false;
    }
    return c == ':';
}

bool con_utils_json_is_item_separator(enum ConJsonState state, char c) {
    assert(0 < state && state < JSON_STATE_MAX);
    if (state != JSON_STATE_NORMAL && state != JSON_STATE_FIRST_ITEM) {
        return false;
    }
    return c == ',';
}

bool con_utils_json_is_empty(enum ConJsonState state) {
    assert(0 < state && state < JSON_STATE_MAX);
    return state == JSON_STATE_FIRST_ITEM;
}

bool con_utils_json_is_string(enum ConJsonState state) {
    assert(0 < state && state < JSON_STATE_MAX);
    return state == JSON_STATE_IN_STRING || state == JSON_STATE_ESCAPE;
}
