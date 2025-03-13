#include <limits.h>
#include <string.h>
#include <utils.h>
#include "con_reader.h"

size_t con_reader_fail_read(void const *context, char *buffer, size_t buffer_size);
size_t con_reader_file_read(void const *context, char *buffer, size_t buffer_size);
size_t con_reader_string_read(void const *context, char *buffer, size_t buffer_size);
size_t con_reader_buffer_read(void const *context, char *buffer, size_t buffer_size);
size_t con_reader_comment_read(void const *context, char *buffer, size_t buffer_size);

enum ConError con_reader_fail_init(struct ConReaderFail *context, struct ConInterfaceReader reader, size_t reads_before_fail) {
    if (context == NULL) { return CON_ERROR_NULL; }

    context->reader = reader;
    context->reads_before_fail = reads_before_fail;
    context->amount_of_reads = 0;

    return CON_ERROR_OK;
}

struct ConInterfaceReader con_reader_fail_interface(struct ConReaderFail *context) {
    return (struct ConInterfaceReader) { .context = context, .read = con_reader_fail_read };
}

size_t con_reader_fail_read(void const *void_context, char *buffer, size_t buffer_size) {
    assert(void_context != NULL);
    struct ConReaderFail *context = (struct ConReaderFail*) void_context;

    bool error = context->amount_of_reads >= context->reads_before_fail;
    size_t length = 0;

    if (!error) {
        context->amount_of_reads += 1;

        length = con_reader_read(context->reader, buffer, buffer_size);
        assert(length >= 0 || buffer_size == 0);
    } else {
        memset(buffer, 0, buffer_size);
    }

    return length;
}

enum ConError con_reader_file_init(struct ConReaderFile *context, FILE *file) {
    if (context == NULL) { return CON_ERROR_NULL; }

    context->file = file;
    if (file == NULL) { return CON_ERROR_NULL; }

    return CON_ERROR_OK;
}

struct ConInterfaceReader con_reader_file_interface(struct ConReaderFile *context) {
    return (struct ConInterfaceReader) { .context = context, .read = con_reader_file_read };
}

size_t con_reader_file_read(void const *void_context, char *buffer, size_t buffer_size) {
    assert(void_context != NULL);
    struct ConReaderFile *context = (struct ConReaderFile*) void_context;

    assert(buffer != NULL);
    size_t read_length = fread(buffer, sizeof(char), buffer_size, context->file);

    assert(read_length <= buffer_size);
    return read_length;
}

enum ConError con_reader_string_init(struct ConReaderString *context, char const *buffer, size_t buffer_size) {
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

size_t con_reader_string_read(void const *void_context, char *buffer, size_t buffer_size) {
    assert(void_context != NULL);
    struct ConReaderString *context = (struct ConReaderString*) void_context;

    assert(0 <= context->current && context->current <= context->buffer_size);
    if (context->current >= context->buffer_size) {
        return 0;
    }

    size_t read_length = context->buffer_size - context->current;
    read_length = read_length > buffer_size ? buffer_size : read_length;

    assert(buffer != NULL);
    assert(context->buffer != NULL);
    memcpy(buffer, context->buffer + context->current, read_length);
    context->current += read_length;

    assert(read_length <= buffer_size);
    return read_length;
}

enum ConError con_reader_buffer_init(
    struct ConReaderBuffer *context,
    struct ConInterfaceReader reader,
    char *buffer,
    size_t buffer_size
) {
    if (context == NULL) { return CON_ERROR_NULL; }
    if (buffer == NULL) { return CON_ERROR_NULL; }
    if (buffer_size <= 1) { return CON_ERROR_BUFFER; }

    context->reader = reader;
    context->buffer = buffer;
    context->next_read = buffer;
    context->buffer_size = buffer_size;
    context->current = 0;
    context->length_read = 0;

    return CON_ERROR_OK;
}

enum ConError con_reader_double_buffer_init(
    struct ConReaderBuffer *context,
    struct ConInterfaceReader reader,
    char *buffer,
    size_t buffer_size
) {
    if (context == NULL) { return CON_ERROR_NULL; }
    if (buffer == NULL) { return CON_ERROR_NULL; }

    size_t half_size = buffer_size / 2;
    if (half_size <= 1 || buffer_size % 2 != 0) { return CON_ERROR_BUFFER; }

    context->reader = reader;
    context->buffer = buffer;
    context->next_read = buffer + half_size;
    context->buffer_size = half_size;
    context->current = 0;
    context->length_read = 0;

    return CON_ERROR_OK;
}

struct ConInterfaceReader con_reader_buffer_interface(struct ConReaderBuffer *context) {
    return (struct ConInterfaceReader) { .context = context, .read = con_reader_buffer_read };
}

size_t con_reader_buffer_read(void const *void_context, char *buffer, size_t buffer_size) {
    assert(void_context != NULL);

    struct ConReaderBuffer *context = (struct ConReaderBuffer*) void_context;
    assert(0 <= context->current && context->current <= context->buffer_size);
    assert(0 <= context->length_read && context->length_read <= context->buffer_size);
    assert(context->current <= context->length_read) ;

    if (context->next_read == NULL) {
        return 0;
    }

    size_t read_length = context->length_read - context->current;
    read_length = read_length > buffer_size ? buffer_size : read_length;

    assert(buffer != NULL);
    assert(context->buffer != NULL);
    memcpy(buffer, context->buffer + context->current, read_length);
    context->current += read_length;

    if (context->current >= context->length_read) {
        assert(read_length <= buffer_size);
        size_t length_left = buffer_size - read_length;

        if (buffer_size - read_length >= context->buffer_size) {
            size_t length = con_reader_read(context->reader, buffer + read_length, length_left);
            if (length == 0) {
                if (context->buffer == context->next_read) {
                    context->next_read = NULL;
                }
                context->current -= read_length;
                read_length = 0;
            } else {
                read_length += length;
            }
        } else {
            size_t length = con_reader_read(context->reader, context->next_read, context->buffer_size);
            if (length == 0) {
                if (context->buffer == context->next_read) {
                    context->next_read = NULL;
                }

                assert(read_length <= context->current);
                context->current -= read_length;
                read_length = 0;
            } else {
                char *temp = context->buffer;
                context->buffer = context->next_read;
                context->next_read = temp;

                context->length_read = length;

                size_t next_length = context->length_read > length_left ? length_left : context->length_read;

                memcpy(buffer + read_length, context->buffer, next_length);
                context->current = next_length;

                read_length += next_length;
            }
        }
    }

    assert(read_length <= buffer_size);
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

size_t con_reader_comment_comment_start(struct ConReaderComment *context, char *buffer, size_t buffer_size) {
    assert(context != NULL);
    size_t length = 0;

    char c;
    size_t l = con_reader_read(context->reader, &c, 1);
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
        if (buffer_size >= 1) {
            buffer[0] = (char) context->buffer_char;
            context->buffer_char = EOF;

            length = 1;
            any_read = true;
        } else {
            return 0;
        }
    }

    while (length < buffer_size) {
        enum ConJsonState state = con_utils_json_from_char(context->state);
        char c;

        size_t l = con_reader_read(context->reader, &c, 1);
        assert(l == 0 || l == 1);
        if (l != 1) { break; }

        if (!context->in_comment && !con_utils_json_is_string(state) && c == '/') {
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

        context->state = con_utils_json_to_char(con_utils_json_next(state, c));
        any_read = true;
    }

    assert(length <= buffer_size);
    return length;
}
