#include <stdio.h>
#include <utils.h>
#include "con_reader.h"

size_t con_reader_comment_read(void const *context, char *buffer, size_t buffer_size);

enum ConError con_reader_comment_init(struct ConReaderComment *context, struct GciInterfaceReader reader) {
    if (context == NULL) { return CON_ERROR_NULL; }
    context->reader = reader;
    context->state = con_utils_state_char_init();
    context->buffer_char = EOF;
    context->in_comment = false;
    return CON_ERROR_OK;
}

struct GciInterfaceReader con_reader_comment_interface(struct ConReaderComment *context) {
    return (struct GciInterfaceReader) { .context = context, .read = con_reader_comment_read };
}

size_t con_reader_comment_comment_start(struct ConReaderComment *context, char *buffer, size_t buffer_size) {
    assert(context != NULL);
    size_t length = 0;

    char c;
    size_t l = gci_reader_read(context->reader, &c, 1);
    assert(l == 0 || l == 1);

    if (l != 1) {
        length = 0;
    } else if (c == '/') {
        length = 0;
        context->buffer_char = EOF;
        context->in_comment = true;
    } else {
        context->buffer_char = EOF;
        buffer[length++] = '/';

        if (length >= buffer_size) {
            context->buffer_char = c;
        } else {
            buffer[length++] = c;
        }
    }

    return length;
}

size_t con_reader_comment_read(void const *void_context, char *buffer, size_t buffer_size) {
    assert(void_context != NULL);
    struct ConReaderComment *context = (struct ConReaderComment*) void_context;

    bool any_read = false;
    size_t length = 0;

    assert(buffer != NULL);
    if (context->buffer_char != EOF) {
        if (context->buffer_char == '/') {
            assert(!context->in_comment);
            size_t l = con_reader_comment_comment_start(context, buffer, buffer_size);
            if (l == 0 && !context->in_comment) { return 0; }
            length += l;
        } else if (buffer_size >= 1) {
            buffer[0] = (char) context->buffer_char;
            context->buffer_char = EOF;

            length = 1;
            any_read = true;
        } else {
            return 0;
        }
    }

    while (length < buffer_size) {
        char c;

        size_t l = gci_reader_read(context->reader, &c, 1);
        assert(l == 0 || l == 1);
        if (l != 1) { break; }

        if (!context->in_comment && !con_utils_state_char_is_string(context->state) && c == '/') {
            l = con_reader_comment_comment_start(context, buffer + length, buffer_size - length);
            if (l == 0 && !context->in_comment) {
                context->buffer_char = '/';
                break;
            }

            length += l;
        } else if (context->in_comment && c == '\n') {
            context->in_comment = false;
            buffer[length++] = '\n';
        } else if (!context->in_comment) {
            buffer[length++] = c;
        }

        con_utils_state_char_next(&context->state, c);
        any_read = true;
    }

    assert(length <= buffer_size);
    return length;
}
