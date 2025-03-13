#ifndef CON_UTILS_H
#define CON_UTILS_H
#include <stddef.h>
#include <stdbool.h>
#include "con_common.h"

enum ConState con_utils_state_init(void);
enum ConError con_utils_state_next(enum ConState *state, enum ConContainer current);
enum ConError con_utils_state_open(enum ConState *state, enum ConContainer current);
enum ConError con_utils_state_close(enum ConState *state, enum ConContainer current);
enum ConError con_utils_state_key(enum ConState *state, enum ConContainer current);

enum ConContainer con_utils_container_current(enum ConContainer *containers, size_t size, size_t depth);

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

enum StateNumber con_utils_state_number_next(enum StateNumber state, char c);
bool con_utils_state_number_terminal(enum StateNumber state);

enum ConJsonState {
    JSON_STATE_UNKNOWN      = 0,
    JSON_STATE_NORMAL       = 1,
    JSON_STATE_FIRST_ITEM   = 2,
    JSON_STATE_IN_STRING    = 3,
    JSON_STATE_ESCAPE       = 4,
    JSON_STATE_MAX,
};

enum ConJsonState con_utils_json_init(void);
enum ConJsonState con_utils_json_next(enum ConJsonState state, char c);
char con_utils_json_to_char(enum ConJsonState state);
enum ConJsonState con_utils_json_from_char(char state);

bool con_utils_json_is_meaningful(enum ConJsonState state, char c);
bool con_utils_json_is_open(enum ConJsonState state, char c);
bool con_utils_json_is_close(enum ConJsonState state, char c);
bool con_utils_json_is_key_separator(enum ConJsonState state, char c);
bool con_utils_json_is_item_separator(enum ConJsonState state, char c);
bool con_utils_json_is_empty(enum ConJsonState state);
bool con_utils_json_is_string(enum ConJsonState state);

#endif
