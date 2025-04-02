#include <stdint.h>
#include <utils.h>
#include "con_writer.h"

size_t con_writer_indent_write(void const *void_context, char const *data, size_t data_size);

enum ConError con_writer_indent_init(
    struct ConWriterIndent *context,
    struct GciInterfaceWriter writer
) {
    if (context == NULL) { return CON_ERROR_NULL; }

    context->writer = writer;
    context->state = con_utils_state_char_init();
    context->depth = 0;

    return CON_ERROR_OK;
}

struct GciInterfaceWriter con_writer_indent_interface(struct ConWriterIndent *context) {
    return (struct GciInterfaceWriter) { .context=context, .write=con_writer_indent_write };
}

static inline bool con_writer_indent_whitespace(struct ConWriterIndent *context) {
    size_t result = gci_writer_write(context->writer, "\n", 1);
    if (result != 1) { return false; }

    for (size_t i = 0; i < context->depth; i++) {
        result = gci_writer_write(context->writer, "  ", 2);
        if (result != 2) { return false; }
    }

    return true;
}

size_t con_writer_indent_write(void const *void_context, char const *data, size_t data_size) {
    assert(void_context != NULL);
    assert(data != NULL);

    struct ConWriterIndent *context = (struct ConWriterIndent*) void_context;

    size_t length = 0;
    while (length < data_size) {
        char c = data[length];

        if (con_utils_state_char_is_container_empty(context->state) && !con_utils_state_char_is_close(context->state, c)) {
            bool success = con_writer_indent_whitespace(context);
            if (!success) { break; }
        }

        if (con_utils_state_char_is_close(context->state, c) && context->depth > 0) {
            context->depth -= 1;

            if (context->state.state != CON_STATE_FIRST) {
                bool success = con_writer_indent_whitespace(context);
                if (!success) { break; }
            }
        } else if (con_utils_state_char_is_open(context->state, c)) {
            if (context->depth > SIZE_MAX - 1) {
                return length;
            }

            context->depth += 1;
        }

        if (con_utils_state_char_is_meaningful(context->state, c)) {
            size_t result = gci_writer_write(context->writer, &c, 1);
            if (result != 1) { break; }
        }
        length += 1;

        if (con_utils_state_char_is_key_separator(context->state, c)) {
            size_t result = gci_writer_write(context->writer, " ", 1);
            if (result != 1) { break; }
        }

        if (con_utils_state_char_is_item_separator(context->state, c)) {
            bool success = con_writer_indent_whitespace(context);
            if (!success) { break; }
        }

        con_utils_state_char_next(&context->state, c);
    }

    return length;
}
