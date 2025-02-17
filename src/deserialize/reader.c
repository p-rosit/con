#include <limits.h>
#include <string.h>
#include <utils.h>
#include "con_reader.h"

struct ConReadResult con_reader_fail_read(void const *context, char *buffer, size_t buffer_size);
struct ConReadResult con_reader_file_read(void const *context, char *buffer, size_t buffer_size);
struct ConReadResult con_reader_string_read(void const *context, char *buffer, size_t buffer_size);
struct ConReadResult con_reader_buffer_read(void const *context, char *buffer, size_t buffer_size);
struct ConReadResult con_reader_comment_read(void const *context, char *buffer, size_t buffer_size);

enum ConError con_reader_fail_init(struct ConReaderFail *context, struct ConInterfaceReader reader, size_t reads_before_fail) {
    if (context == NULL) { return CON_ERROR_NULL; }

    context->reader = reader;
    context->reads_before_fail = reads_before_fail;
    context->amount_of_reads = 0;
    context->final_read = false;

    return CON_ERROR_OK;
}

struct ConInterfaceReader con_reader_fail_interface(struct ConReaderFail *context) {
    return (struct ConInterfaceReader) { .context = context, .read = con_reader_fail_read };
}

struct ConReadResult con_reader_fail_read(void const *void_context, char *buffer, size_t buffer_size) {
    assert(void_context != NULL);
    struct ConReaderFail *context = (struct ConReaderFail*) void_context;

    struct ConReadResult result = {
        .error = context->amount_of_reads >= context->reads_before_fail,
        .length = 0,
    };

    if (!result.error || !context->final_read) {
        context->amount_of_reads += 1;

        struct ConReadResult r = con_reader_read(context->reader, buffer, buffer_size);
        assert(!r.error);
        result.length = r.length;
    }

    context->final_read = result.error;
    return result;
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

struct ConReadResult con_reader_file_read(void const *void_context, char *buffer, size_t buffer_size) {
    assert(void_context != NULL);
    struct ConReaderFile *context = (struct ConReaderFile*) void_context;

    assert(buffer != NULL);
    size_t read_length = fread(buffer, sizeof(char), buffer_size, context->file);

    bool is_error = ferror(context->file) != 0;
    assert(read_length <= buffer_size);
    return (struct ConReadResult) { .error = is_error, .length = read_length };
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

struct ConReadResult con_reader_string_read(void const *void_context, char *buffer, size_t buffer_size) {
    assert(void_context != NULL);
    struct ConReaderString *context = (struct ConReaderString*) void_context;

    assert(0 <= context->current && context->current <= context->buffer_size);
    if (context->current >= context->buffer_size) {
        return (struct ConReadResult) { .error = false, .length = 0 };
    }

    size_t read_length = context->buffer_size - context->current;
    read_length = read_length > buffer_size ? buffer_size : read_length;

    assert(buffer != NULL);
    assert(context->buffer != NULL);
    memcpy(buffer, context->buffer + context->current, read_length);
    context->current += read_length;

    assert(read_length <= buffer_size);
    return (struct ConReadResult) { .error = false, .length = read_length };
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
    context->buffer_size = buffer_size;
    context->current = 0;
    context->length_read = 0;

    return CON_ERROR_OK;
}

struct ConInterfaceReader con_reader_buffer_interface(struct ConReaderBuffer *context) {
    return (struct ConInterfaceReader) { .context = context, .read = con_reader_buffer_read };
}

struct ConReadResult con_reader_buffer_read(void const *void_context, char *buffer, size_t buffer_size) {
    assert(void_context != NULL);

    struct ConReaderBuffer *context = (struct ConReaderBuffer*) void_context;
    assert(0 <= context->current && context->current <= context->buffer_size);
    assert(0 <= context->length_read && context->length_read <= context->buffer_size);
    assert(context->current <= context->length_read) ;

    size_t read_length = context->length_read - context->current;
    read_length = read_length > buffer_size ? buffer_size : read_length;

    assert(buffer != NULL);
    assert(context->buffer != NULL);
    memcpy(buffer, context->buffer + context->current, read_length);
    context->current += read_length;

    bool error = false;
    if (context->current >= context->length_read) {
        assert(read_length <= buffer_size);
        size_t length_left = buffer_size - read_length;

        if (buffer_size - read_length >= context->buffer_size) {
            struct ConReadResult result = con_reader_read(context->reader, buffer + read_length, length_left);
            error = result.error;
            read_length += result.length;
        } else {
            struct ConReadResult result = con_reader_read(context->reader, context->buffer, context->buffer_size);
            context->length_read = result.length;

            size_t next_length = context->length_read > length_left ? length_left : context->length_read;

            memcpy(buffer + read_length, context->buffer, next_length);
            context->current = next_length;

            error = result.error;
            read_length += next_length;
        }
    }

    assert(read_length <= buffer_size);
    return (struct ConReadResult) { .error = error, .length = read_length };
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

struct ConReadResult con_reader_comment_read(void const *void_context, char *buffer, size_t buffer_size) {
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
            return (struct ConReadResult) { .error = false, .length = 0 };
        }
    }

    bool error = false;
    while (length < buffer_size && !error) {
        enum ConJsonState state = con_utils_json_from_char(context->state);
        char c;

        struct ConReadResult result = con_reader_read(context->reader, &c, 1);
        assert(result.length == 0 || result.length == 1);
        error = result.error;
        if (result.length != 1) { break; }

        if (!context->in_comment && !con_utils_json_is_string(state) && c == '/') {
            result = con_reader_read(context->reader, &c, 1);
            assert(result.length == 0 || result.length == 1);
            error = result.error;

            if (result.length != 1) {
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

            if (error) { break; }
        } else if (context->in_comment && c == '\n') {
            context->in_comment = false;
            buffer[length++] = '\n';
        } else if (!context->in_comment) {
            buffer[length++] = c;
        }

        context->state = con_utils_json_to_char(con_utils_json_next(state, c));
        any_read = true;

        if (error) { break; }
    }

    assert(length <= buffer_size);
    return (struct ConReadResult) { .error = error, .length = length };
}
