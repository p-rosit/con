#include <limits.h>
#include <utils.h>
#include "con_reader.h"

int con_reader_file_read(void const *context, char *buffer, int buffer_size);
int con_reader_string_read(void const *context, char *buffer, int buffer_size);
int con_reader_buffer_read(void const *context, char *buffer, int buffer_size);
int con_reader_comment_read(void const *context, char *buffer, int buffer_size);

enum ConError con_reader_file_init(struct ConReaderFile *context, FILE *file) {
    if (context == NULL) { return CON_ERROR_NULL; }

    context->file = file;
    if (file == NULL) { return CON_ERROR_NULL; }

    return CON_ERROR_OK;
}

struct ConInterfaceReader con_reader_file_interface(struct ConReaderFile *context) {
    return (struct ConInterfaceReader) { .context = context, .read = con_reader_file_read };
}

int con_reader_file_read(void const *void_context, char *buffer, int buffer_size) {
    assert(void_context != NULL);
    struct ConReaderFile *context = (struct ConReaderFile*) void_context;

    assert(buffer != NULL);
    assert(buffer_size >= 0);
    size_t amount_read = fread(buffer, sizeof(char), (size_t) buffer_size, context->file);

    assert(amount_read <= INT_MAX);
    return (int) amount_read;
}

enum ConError con_reader_string_init(struct ConReaderString *context, char const *buffer, int buffer_size) {
    if (context == NULL) { return CON_ERROR_NULL; }

    context->buffer = NULL;
    if (buffer == NULL) { return CON_ERROR_NULL; }
    if (buffer_size < 0) { return CON_ERROR_BUFFER; }

    context->buffer = buffer;
    context->buffer_size = buffer_size;
    context->current = 0;

    return CON_ERROR_OK;
}

struct ConInterfaceReader con_reader_string_interface(struct ConReaderString *context) {
    return (struct ConInterfaceReader) { .context = context, .read = con_reader_string_read };
}

int con_reader_string_read(void const *void_context, char *buffer, int buffer_size) {
    assert(void_context != NULL);
    assert(buffer != NULL);
    assert(buffer_size >= 0);

    struct ConReaderString *context = (struct ConReaderString*) void_context;
    assert(context->buffer != NULL);
    assert(0 <= context->current && context->current <= context->buffer_size);

    if (context->current >= context->buffer_size) {
        return -1;
    }

    int current = context->current;
    int length = 0;
    while (length < buffer_size && current < context->buffer_size) {
        buffer[length++] = context->buffer[current++];
    }

    context->current = current;
    return length;
}

enum ConError con_reader_buffer_init(
    struct ConReaderBuffer *context,
    struct ConInterfaceReader reader,
    char *buffer,
    int buffer_size
) {
    if (context == NULL) { return CON_ERROR_NULL; }
    if (buffer == NULL) { return CON_ERROR_NULL; }
    if (buffer_size <= 1) { return CON_ERROR_BUFFER; }

    context->reader = reader;
    context->buffer = buffer;
    context->buffer_size = buffer_size;
    context->current = buffer_size;
    context->length_read = 0;

    return CON_ERROR_OK;
}

struct ConInterfaceReader con_reader_buffer_interface(struct ConReaderBuffer *context) {
    return (struct ConInterfaceReader) { .context = context, .read = con_reader_buffer_read };
}

int con_reader_buffer_read(void const *void_context, char *buffer, int buffer_size) {
    assert(void_context != NULL);
    assert(buffer != NULL);
    assert(buffer_size >= 0);

    struct ConReaderBuffer *context = (struct ConReaderBuffer*) void_context;
    assert(context->buffer != NULL);
    assert(0 <= context->current && context->current <= context->buffer_size);

    bool any_read = false;
    int length = 0;
    while (length < buffer_size) {
        if (context->current >= context->length_read) {
            context->length_read = 0;
            int length_read = con_reader_read(context->reader, context->buffer, context->buffer_size);
            if (any_read && length_read <= 0) { break; }
            if (length_read <= 0) { return length_read; }

            context->current = 0;
            context->length_read = length_read;
        }

        any_read = true;
        buffer[length++] = context->buffer[context->current++];
    }

    return length;
}

enum ConError con_reader_comment_init(struct ConReaderComment *context, struct ConInterfaceReader reader) {
    if (context == NULL) { return CON_ERROR_NULL; }
    context->reader = reader;
    context->buffer_char = EOF;
    context->state = con_utils_json_to_char(con_utils_json_init());
    context->in_comment = false;
    return CON_ERROR_OK;
}

struct ConInterfaceReader con_reader_comment_interface(struct ConReaderComment *context) {
    return (struct ConInterfaceReader) { .context = context, .read = con_reader_comment_read };
}

int con_reader_comment_read(void const *void_context, char *buffer, int buffer_size) {
    assert(void_context != NULL);

    struct ConReaderComment *context = (struct ConReaderComment*) void_context;

    bool any_read = false;
    int length = 0;

    if (context->buffer_char != EOF) {
        if (buffer_size >= 1) {
            buffer[0] = (char) context->buffer_char;
            context->buffer_char = EOF;

            length = 1;
            any_read = true;
        } else {
            return -1;
        }
    }

    while (length < buffer_size) {
        enum ConJsonState state = con_utils_json_from_char(context->state);
        char c;

        int result = con_reader_read(context->reader, &c, 1);
        if (any_read && result <= 0) { break; }
        if (result <= 0) { return result; }

        if (!context->in_comment && !con_utils_json_is_string(state) && c == '/') {
            result = con_reader_read(context->reader, &c, 1);
            if (result <= 0) {
                buffer[length++] = '/';
            } else if (c == '/') {
                context->in_comment = true;
            } else {
                buffer[length++] = '/';

                if (length >= buffer_size) {
                    context->buffer_char = c;
                    break;
                }

                buffer[length++] = c;
            }
        } else if (context->in_comment && c == '\n') {
            context->in_comment = false;
            buffer[length++] = '\n';
        } else if (!context->in_comment) {
            buffer[length++] = c;
        }

        context->state = con_utils_json_to_char(con_utils_json_next(state, c));
        any_read = true;
    }

    assert(length <= INT_MAX);
    return length;
}
