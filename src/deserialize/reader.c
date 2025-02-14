#include <limits.h>
#include <string.h>
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
        return 0;
    }

    size_t read_length = (size_t)(context->buffer_size - context->current);
    read_length = read_length > (size_t) buffer_size ? (size_t) buffer_size : read_length;

    memcpy(buffer, context->buffer + context->current, read_length);
    context->current += read_length;

    assert(read_length <= INT_MAX);
    return (int) read_length;
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
    context->current = 0;
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
    assert(0 <= context->length_read && context->length_read <= context->buffer_size);
    assert(context->current <= context->length_read) ;

    int read_length = context->length_read - context->current;
    read_length = read_length > buffer_size ? buffer_size : read_length;

    assert(read_length >= 0);
    memcpy(buffer, context->buffer + context->current, (size_t) read_length);
    context->current += read_length;

    if (context->current >= context->length_read) {
        if (buffer_size - read_length >= context->buffer_size) {
            int result = con_reader_read(context->reader, buffer + read_length, buffer_size - read_length);
            read_length += result;
        } else {
            int result = con_reader_read(context->reader, context->buffer, context->buffer_size);
            if (result <= 0) { return (int)read_length; }
            context->length_read = result;
            context->current = 0;

            int next_length = context->length_read;
            next_length = next_length > (buffer_size - read_length) ? (buffer_size - read_length) : next_length;

            assert(next_length >= 0);
            memcpy(buffer, context->buffer, (size_t) next_length);
            context->current = next_length;
            read_length += next_length;
        }
    }

    return read_length;
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
