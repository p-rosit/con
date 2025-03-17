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

struct ConStateChar con_utils_state_char_init(void) {
    return (struct ConStateChar) {
        .state = con_utils_state_init(),
        .in_string = false,
        .escaped = false,
    };
}

void con_utils_state_char_next(struct ConStateChar *state, char c) {
    if (state->in_string && state->escaped) {
        state->escaped = false;
    } else if (state->in_string && !state->escaped) {
        if (c == '"') {
            state->in_string = false;
        } else if (c == '\\') {
            state->escaped = true;
        }
    } else {
        switch (state->state) {
            case (CON_STATE_EMPTY):
            case (CON_STATE_FIRST):
            case (CON_STATE_LATER):
                if (c == '[' || c == '{') {
                    enum ConError err = con_utils_state_open(&state->state, CON_CONTAINER_ARRAY);
                    assert(err == CON_ERROR_OK);
                } else if (c == ']' || c == '}') {
                    enum ConError err = con_utils_state_close(&state->state, CON_CONTAINER_ARRAY);
                    assert(err == CON_ERROR_OK);
                } else if (c == '"') {
                    enum ConError err = con_utils_state_next(&state->state, CON_CONTAINER_ARRAY);
                    assert(err == CON_ERROR_OK);
                    state->in_string = true;
                } else if (isdigit((unsigned char) c) || c == '-') {
                    enum ConError err = con_utils_state_next(&state->state, CON_CONTAINER_ARRAY);
                    assert(err == CON_ERROR_OK);
                    if (state->state == CON_STATE_COMPLETE) {
                        state->state = CON_STATE_LATER;
                    }
                }
                assert(state->state != CON_STATE_COMPLETE);
                break;
            case (CON_STATE_COMPLETE):
            case (CON_STATE_VALUE):
            case (CON_STATE_MAX):
            case (CON_STATE_UNKNOWN):
                assert(false);
                break;
        }
    }
}

bool con_utils_state_char_is_meaningful(struct ConStateChar state, char c) {
    return state.in_string || !isspace((unsigned char) c);
}

bool con_utils_state_char_is_open(struct ConStateChar state, char c) {
    return !state.in_string && (c == '[' || c == '{');
}

bool con_utils_state_char_is_close(struct ConStateChar state, char c) {
    return !state.in_string && (c == ']' || c == '}');
}

bool con_utils_state_char_is_key_separator(struct ConStateChar state, char c) {
    return !state.in_string && c == ':';
}

bool con_utils_state_char_is_item_separator(struct ConStateChar state, char c) {
    return !state.in_string && c == ',';
}

bool con_utils_state_char_is_container_empty(struct ConStateChar state) {
    return state.state == CON_STATE_FIRST;
}

bool con_utils_state_char_is_string(struct ConStateChar state) {
    return state.in_string;
}
