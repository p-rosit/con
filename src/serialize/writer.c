#include <stdint.h>
#include <limits.h>
#include <string.h>
#include "con_writer.h"

size_t con_writer_file_write(void const *void_context, char const *data, size_t data_size);
size_t con_writer_string_write(void const *void_context, char const *data, size_t data_size);
size_t con_writer_buffer_write(void const *void_context, char const *data, size_t data_size);
size_t con_writer_indent_write(void const *void_context, char const *data, size_t data_size);

enum ConError con_writer_file_context(struct ConWriterFile *context, FILE *file) {
    if (context == NULL) { return CON_ERROR_NULL; }

    context->file = file;
    if (file == NULL) { return CON_ERROR_NULL; }

    return CON_ERROR_OK;
}

struct ConInterfaceWriter con_writer_file_interface(struct ConWriterFile *writer) {
    assert(writer != NULL);
    return (struct ConInterfaceWriter) { .context = writer, .write = con_writer_file_write };
}

size_t con_writer_file_write(void const *context, char const *data, size_t data_size) {
    assert(context != NULL);
    assert(data != NULL);
    struct ConWriterFile *writer = (struct ConWriterFile*) context;
    return fwrite(data, sizeof(char), data_size, writer->file);
}

enum ConError con_writer_string_context(
    struct ConWriterString *context,
    char *buffer,
    size_t buffer_size
) {
    if (context == NULL) { return CON_ERROR_NULL; }
    context->buffer = buffer;
    if (buffer == NULL) { return CON_ERROR_NULL; }

    context->buffer_size = buffer_size;
    context->current = 0;

    return CON_ERROR_OK;
}

struct ConInterfaceWriter con_writer_string_interface(struct ConWriterString *context) {
    return (struct ConInterfaceWriter) { .context = context, .write = con_writer_string_write };
}

size_t con_writer_string_write(void const *void_context, char const *data, size_t data_size) {
    assert(void_context != NULL);
    assert(data != NULL);

    struct ConWriterString *context = (struct ConWriterString*) void_context;
    assert(context->buffer != NULL);
    if (context->buffer_size <= 0) {
        assert(context->current == 0);
    } else {
        assert(0 <= context->current && context->current <= context->buffer_size);
    }

    size_t write_length = context->buffer_size - context->current;
    write_length = write_length > data_size ? data_size : write_length;

    memcpy(context->buffer + context->current, data, write_length);
    context->current += write_length;

    return write_length;
}

enum ConError con_writer_buffer_context(
        struct ConWriterBuffer *context,
        struct ConInterfaceWriter writer,
        char *buffer,
        size_t buffer_size
) {
    if (context == NULL) { return CON_ERROR_NULL; }
    context->buffer = buffer;
    if (buffer == NULL) { return CON_ERROR_NULL; }
    if (buffer_size <= 0) { return CON_ERROR_BUFFER; }

    context->writer = writer;
    context->buffer_size = buffer_size;
    context->current = 0;

    return CON_ERROR_OK;
}

struct ConInterfaceWriter con_writer_buffer_interface(struct ConWriterBuffer *context) {
    return (struct ConInterfaceWriter) { .context = context, .write = con_writer_buffer_write };
}

size_t con_writer_buffer_write(void const *void_context, char const *data, size_t data_size) {
    assert(void_context != NULL);
    assert(data != NULL);

    struct ConWriterBuffer *context = (struct ConWriterBuffer*) void_context;
    assert(context->buffer != NULL);
    assert(0 <= context->current && context->current < context->buffer_size);

    size_t write_length = context->buffer_size - context->current;
    write_length = write_length > data_size ? data_size : write_length;

    memcpy(context->buffer + context->current, data, write_length);
    context->current += write_length;

    if (context->current >= context->buffer_size) {
        bool flush_success = con_writer_buffer_flush(context);
        if (!flush_success) { return 0; }

        if (data_size - write_length >= context->buffer_size) {
            size_t result = con_writer_write(context->writer, data + write_length, data_size - write_length);
            if (result < data_size - write_length) { return write_length + result; }
        } else {
            memcpy(context->buffer, data + write_length, data_size + write_length);
        }
    }
    return data_size;
}

bool con_writer_buffer_flush(struct ConWriterBuffer *context) {
    assert(context != NULL);
    assert(context->buffer != NULL);
    assert(0 <= context->current && context->current <= context->buffer_size);

    size_t length = context->current;
    size_t result = con_writer_write(context->writer, context->buffer, length);
    context->current = 0;

    if (result != length) {
        return false;
    } else {
        return true;
    }
}

enum StateIndent {
    INDENT_UNKNOWN      = 0,
    INDENT_NORMAL       = 1,
    INDENT_FIRST_ITEM   = 2,
    INDENT_IN_STRING    = 3,
    INDENT_ESCAPE       = 4,
    INDENT_MAX,
};

enum ConError con_writer_indent_context(
    struct ConWriterIndent *context,
    struct ConInterfaceWriter writer
) {
    if (context == NULL) { return CON_ERROR_NULL; }

    context->writer = writer;
    context->depth = 0;
    context->state = INDENT_NORMAL;

    return CON_ERROR_OK;
}

struct ConInterfaceWriter con_writer_indent_interface(struct ConWriterIndent *context) {
    return (struct ConInterfaceWriter) { .context=context, .write=con_writer_indent_write };
}

static inline bool con_serialize_writer_indent_whitespace(struct ConWriterIndent *context) {
    size_t result = con_writer_write(context->writer, "\n", 1);
    if (result != 1) { return false; }

    for (size_t i = 0; i < context->depth; i++) {
        result = con_writer_write(context->writer, "  ", 2);
        if (result != 2) { return false; }
    }

    return true;
}

size_t con_writer_indent_write(void const *void_context, char const *data, size_t data_size) {
    assert(void_context != NULL);
    assert(data != NULL);

    struct ConWriterIndent *context = (struct ConWriterIndent*) void_context;
    assert(0 < context->state && context->state < INDENT_MAX);

    size_t length = 0;
    for (; length < data_size; length++) {
        char c = data[length];
        bool in_string = context->state == INDENT_IN_STRING || context->state == INDENT_ESCAPE;
        bool normal = context->state == INDENT_FIRST_ITEM || context->state == INDENT_NORMAL;

        if (context->state == INDENT_FIRST_ITEM && c != ']' && c != '}') {
            bool success = con_serialize_writer_indent_whitespace(context);
            if (!success) { return length; }

            context->state = INDENT_NORMAL;
        }

        if (normal && (c == ']' || c == '}') && context->depth > 0) {
            context->depth -= 1;

            if (context->state != INDENT_FIRST_ITEM) {
                bool success = con_serialize_writer_indent_whitespace(context);
                if (!success) { return length; }
            }

            context->state = INDENT_NORMAL;
        }

        if (normal && (c == '[' || c == '{')) {
            context->state = INDENT_FIRST_ITEM;

            if (context->depth > SIZE_MAX - 1) {
                return 0;
            }

            context->depth += 1;
        }

        size_t result = con_writer_write(context->writer, &c, 1);
        if (result != 1) { return length; }

        if (c == '"' && in_string && context->state != INDENT_ESCAPE) {
            context->state = INDENT_NORMAL;
        } else if (c == '"' && !in_string) {
            context->state = INDENT_IN_STRING;
        }

        if (c == '\\' && context->state == INDENT_IN_STRING) {
            context->state = INDENT_ESCAPE;
        } else if (in_string && context->state == INDENT_ESCAPE) {
            context->state = INDENT_IN_STRING;
        }

        if (c == ':' && !in_string) {
            size_t result = con_writer_write(context->writer, " ", 1);
            if (result != 1) { return length + 1; }
        }

        if (c == ',' && !in_string) {
            bool success = con_serialize_writer_indent_whitespace(context);
            if (!success) { return length + 1; }
        }
    }

    return length;
}
