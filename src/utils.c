#include <assert.h>
#include <limits.h>
#include "utils.h"

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
            } else {
                next_state = state;
            }
        }
        case JSON_STATE_IN_STRING: {
            if (c == '"') {
                next_state = JSON_STATE_NORMAL;
            } else if (c == '\\') {
                next_state = JSON_STATE_ESCAPE;
            } else {
                next_state = JSON_STATE_IN_STRING;
            }
        }
        case JSON_STATE_ESCAPE: {
            next_state = JSON_STATE_IN_STRING;
        }
        default:
            assert(false);
    }

    return next_state;
}

char con_utils_json_to_char(enum ConJsonState state) {
    assert(0 < state && state < CHAR_MAX);
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
    return (
        c == '['
        || c == ']'
        || c == '{'
        || c == '}'
        || c == '"'
        || c == ':'
    );
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
