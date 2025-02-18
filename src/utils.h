#ifndef CON_UTILS_H
#define CON_UTILS_H
#include <stdbool.h>

enum ConContainer {
    CONTAINER_NONE  = 0,
    CONTAINER_DICT  = 1,
    CONTAINER_ARRAY = 2,
};

enum ConState {
    STATE_UNKNOWN   = 0,
    STATE_EMPTY     = 1,
    STATE_FIRST     = 2,
    STATE_LATER     = 3,
    STATE_COMPLETE  = 4,
    STATE_VALUE     = 5,
    STATE_MAX,
};

enum ConJsonState {
    JSON_STATE_UNKNOWN      = 0,
    JSON_STATE_NORMAL       = 1,
    JSON_STATE_FIRST_ITEM   = 2,
    JSON_STATE_IN_STRING    = 3,
    JSON_STATE_ESCAPE       = 4,
    JSON_STATE_MAX,
};

char con_utils_container_to_char(enum ConContainer container);
enum ConContainer con_utils_container_from_char(char container);

enum ConState con_utils_state_init(void);
char con_utils_state_to_char(enum ConState state);
enum ConState con_utils_state_from_char(char state);

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
