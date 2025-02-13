#ifndef CON_UTILS_H
#define CON_UTILS_H
#include <stdbool.h>

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
