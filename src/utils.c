#include <assert.h>
#include <limits.h>
#include <ctype.h>
#include "utils.h"

char con_utils_container_to_char(enum ConContainer container) {
    assert(container == CONTAINER_NONE || container == CONTAINER_DICT || container == CONTAINER_ARRAY);
    return (char) container;
}

enum ConContainer con_utils_container_from_char(char container) {
    assert(container == CONTAINER_NONE || container == CONTAINER_DICT || container == CONTAINER_ARRAY);
    return (enum ConContainer) container;
}

enum ConState con_utils_state_init(void) {
    return STATE_EMPTY;
}

char con_utils_state_to_char(enum ConState state) {
    assert(0 < state && state < CHAR_MAX);
    assert(0 < state && state < STATE_MAX);
    return (char) state;
}

enum ConState con_utils_state_from_char(char state) {
    assert(0 < state && state < STATE_MAX);
    return (enum ConState) state;
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
