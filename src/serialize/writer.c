#include <stdint.h>
#include <stdbool.h>
#include <limits.h>
#include "con_writer.h"

int con_writer_file_write(void const *void_context, char const *data);
int con_writer_string_write(void const *void_context, char const *data);
int con_writer_buffer_write(void const *void_context, char const *data);
int con_writer_indent_write(void const *void_context, char const *data);

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

int con_writer_file_write(void const *context, char const *data) {
    assert(context != NULL);
    assert(data != NULL);
    struct ConWriterFile *writer = (struct ConWriterFile*) context;
    return fputs(data, writer->file);
}

enum ConError con_writer_string_context(
    struct ConWriterString *context,
    char *buffer,
    int buffer_size
) {
    if (context == NULL) { return CON_ERROR_NULL; }

    context->buffer = NULL;
    if (buffer == NULL) { return CON_ERROR_NULL; }
    if (buffer_size <= 0) { return CON_ERROR_BUFFER; }

    context->buffer = buffer;
    context->buffer_size = buffer_size;
    context->current = 0;

    return CON_ERROR_OK;
}

struct ConInterfaceWriter con_writer_string_interface(struct ConWriterString *context) {
    return (struct ConInterfaceWriter) { .context = context, .write = con_writer_string_write };
}

int con_writer_string_write(void const *void_context, char const *data) {
    assert(void_context != NULL);
    assert(data != NULL);

    struct ConWriterString *context = (struct ConWriterString*) void_context;
    assert(context->buffer != NULL);
    assert(0 <= context->current && context->current < context->buffer_size);

    char c = data[0];
    size_t length = 0;
    while (c != '\0') {
        if (context->current >= context->buffer_size - 1) {
            return EOF;
        }

        context->buffer[context->current++] = c;
        context->buffer[context->current] = '\0';

        length += 1;
        c = data[length];
    }

    if (length > INT_MAX) {
        return INT_MAX;
    } else {
        return (int) length;
    }
}

enum ConError con_writer_buffer_context(
        struct ConWriterBuffer *context,
        struct ConInterfaceWriter writer,
        char *buffer,
        int buffer_size
) {
    if (context == NULL) { return CON_ERROR_NULL; }
    if (buffer == NULL) { return CON_ERROR_NULL; }
    if (buffer_size <= 1) { return CON_ERROR_BUFFER; }

    context->writer = writer;
    context->buffer = buffer;
    context->buffer_size = buffer_size;
    context->current = 0;

    return CON_ERROR_OK;
}

struct ConInterfaceWriter con_writer_buffer_interface(struct ConWriterBuffer *context) {
    return (struct ConInterfaceWriter) { .context = context, .write = con_writer_buffer_write };
}

int con_writer_buffer_write(void const *void_context, char const *data) {
    assert(void_context != NULL);
    assert(data != NULL);

    struct ConWriterBuffer *context = (struct ConWriterBuffer*) void_context;
    assert(context->buffer != NULL);
    assert(0 <= context->current && context->current < context->buffer_size);

    size_t length = 0;
    char c = data[0];
    while (c != '\0') {
        if (context->current == context->buffer_size - 1) {
            int result = con_writer_buffer_flush(context);
            if (result < 0) { return result; }
        }

        context->buffer[context->current++] = c;

        length += 1;
        c = data[length];
    }

    if (context->current == context->buffer_size - 1) {
        int result = con_writer_buffer_flush(context);
        if (result < 0) { return result; }
    }

    if (length > INT_MAX) {
        return INT_MAX;
    } else {
        return (int) length;
    }
}

int con_writer_buffer_flush(struct ConWriterBuffer *context) {
    assert(context != NULL);
    assert(context->buffer != NULL);
    assert(0 <= context->current && context->current < context->buffer_size);

    context->buffer[context->current] = '\0';
    context->current = 0;
    return con_writer_write(context->writer, context->buffer);
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

static inline int con_serialize_writer_indent_whitespace(struct ConWriterIndent *context) {
    int result = con_writer_write(context->writer, "\n");
    if (result < 0) { return result; }

    for (size_t i = 0; i < context->depth; i++) {
        result = con_writer_write(context->writer, "  ");
        if (result < 0) { return result; }
    }

    return 1;
}

int con_writer_indent_write(void const *void_context, char const *data) {
    assert(void_context != NULL);
    assert(data != NULL);

    struct ConWriterIndent *context = (struct ConWriterIndent*) void_context;
    assert(0 < context->state && context->state < INDENT_MAX);

    size_t length = 0;
    char c = data[0];
    char write_char[2];

    write_char[0] = c;
    write_char[1] = '\0';
    while (c != '\0') {
        bool in_string = context->state == INDENT_IN_STRING || context->state == INDENT_ESCAPE;
        bool normal = context->state == INDENT_FIRST_ITEM || context->state == INDENT_NORMAL;

        if (context->state == INDENT_FIRST_ITEM && c != ']' && c != '}') {
            int result = con_serialize_writer_indent_whitespace(context);
            if (result < 0) { return result; }

            context->state = INDENT_NORMAL;
        }

        if (normal && (c == ']' || c == '}') && context->depth > 0) {
            context->depth -= 1;

            if (context->state != INDENT_FIRST_ITEM) {
                int result = con_serialize_writer_indent_whitespace(context);
                if (result < 0) { return result; }
            }

            context->state = INDENT_NORMAL;
        }

        if (normal && (c == '[' || c == '{')) {
            context->state = INDENT_FIRST_ITEM;

            if (context->depth > SIZE_MAX - 1) {
                return EOF;
            }

            context->depth += 1;
        }

        int result = con_writer_write(context->writer, write_char);
        if (result < 0) { return result; }

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
            int result = con_writer_write(context->writer, " ");
            if (result < 0) { return result; }
        }

        if (c == ',' && !in_string) {
            int result = con_serialize_writer_indent_whitespace(context);
            if (result < 0) { return result; }
        }

        length += 1;
        c = data[length];
        write_char[0] = c;
    }

    if (length > INT_MAX) {
        return INT_MAX;
    } else {
        return (int) length;
    }
}
