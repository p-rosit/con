#include <stdbool.h>
#include <limits.h>
#include "con_reader.h"

int con_reader_file_read(void const *context, char *buffer, int buffer_size);
int con_reader_string_read(void const *context, char *buffer, int buffer_size);
int con_reader_buffer_read(void const *context, char *buffer, int buffer_size);

enum ConError con_reader_file(struct ConReaderFile *context, FILE *file) {
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

enum ConError con_reader_string(struct ConReaderString *context, char const *buffer, int buffer_size) {
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

enum ConError con_reader_buffer(
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
