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

struct ConStateChar con_utils_state_char_init(void);
void con_utils_state_char_next(struct ConStateChar *state, char c);
bool con_utils_state_char_is_meaningful(struct ConStateChar state, char c);
bool con_utils_state_char_is_open(struct ConStateChar state, char c);
bool con_utils_state_char_is_close(struct ConStateChar state, char c);
bool con_utils_state_char_is_key_separator(struct ConStateChar state, char c);
bool con_utils_state_char_is_item_separator(struct ConStateChar state, char c);
bool con_utils_state_char_is_container_empty(struct ConStateChar state);
bool con_utils_state_char_is_string(struct ConStateChar state);

#endif
