#include <stdint.h>
#include <stdbool.h>
#include <limits.h>
#include "writer.h"

int con_writer_file_write(void const *context, char const *data);
int con_writer_string_write(void const *context, char const *data);
int con_writer_buffer_write(void const *context, char const *data);
int con_writer_indent_write(void const *writer_context, char const *data);

enum ConSerializeError con_writer_file(struct ConWriterFile *writer, FILE *file) {
    if (writer == NULL) { return CON_ERROR_NULL; }

    writer->file = NULL;
    if (file == NULL) { return CON_ERROR_NULL; }

    writer->v_table.write = con_writer_file_write;
    writer->file = file;
    return CON_ERROR_OK;
}

int con_writer_file_write(void const *context, char const *data) {
    assert(context != NULL);
    assert(data != NULL);
    struct ConWriterFile *writer = (struct ConWriterFile*) context;
    return fputs(data, writer->file);
}

enum ConSerializeError con_writer_string(
    struct ConWriterString *writer,
    char *buffer,
    int buffer_size
) {
    if (writer == NULL) { return CON_ERROR_NULL; }

    writer->buffer = NULL;
    if (buffer == NULL) { return CON_ERROR_NULL; }
    if (buffer_size <= 0) { return CON_ERROR_BUFFER; }

    writer->v_table.write = con_writer_string_write;
    writer->buffer = buffer;
    writer->buffer_size = buffer_size;
    writer->current = 0;

    return CON_ERROR_OK;
}

int con_writer_string_write(void const *context, char const *data) {
    assert(context != NULL);
    assert(data != NULL);

    struct ConWriterString *writer = (struct ConWriterString*) context;
    assert(writer->buffer != NULL);
    assert(0 <= writer->current && writer->current < writer->buffer_size);

    char c = data[0];
    size_t length = 0;
    while (c != '\0') {
        if (writer->current >= writer->buffer_size - 1) {
            return EOF;
        }

        writer->buffer[writer->current++] = c;
        writer->buffer[writer->current] = '\0';

        length += 1;
        c = data[length];
    }

    if (length > INT_MAX) {
        return INT_MAX;
    } else {
        return (int) length;
    }
}

enum ConSerializeError con_writer_buffer(
        struct ConWriterBuffer *writer,
        void const *inner_writer,
        char *buffer,
        int buffer_size
) {
    if (writer == NULL) { return CON_ERROR_NULL; }
    if (inner_writer == NULL) { return CON_ERROR_NULL; }
    if (buffer == NULL) { return CON_ERROR_NULL; }
    if (buffer_size <= 1) { return CON_ERROR_BUFFER; }

    writer->v_table.write = con_writer_buffer_write;
    writer->writer = inner_writer;
    writer->buffer = buffer;
    writer->buffer_size = buffer_size;
    writer->current = 0;

    return CON_ERROR_OK;
}

int con_writer_buffer_write(void const *context, char const *data) {
    assert(context != NULL);
    assert(data);

    struct ConWriterBuffer *writer = (struct ConWriterBuffer*) context;
    assert(writer->buffer != NULL);
    assert(0 <= writer->current && writer->current < writer->buffer_size);

    size_t length = 0;
    char c = data[0];
    while (c != '\0') {
        if (writer->current == writer->buffer_size - 1) {
            int result = con_writer_buffer_flush(writer);
            if (result < 0) { return result; }
        }

        writer->buffer[writer->current++] = c;

        length += 1;
        c = data[length];
    }

    if (writer->current == writer->buffer_size - 1) {
        int result = con_writer_buffer_flush(writer);
        if (result < 0) { return result; }
    }

    if (length > INT_MAX) {
        return INT_MAX;
    } else {
        return (int) length;
    }
}

int con_writer_buffer_flush(struct ConWriterBuffer *writer) {
    assert(writer != NULL);
    assert(writer->buffer != NULL);
    assert(0 <= writer->current && writer->current < writer->buffer_size);

    writer->buffer[writer->current] = '\0';
    writer->current = 0;
    return con_writer_write(writer->writer, writer->buffer);
}

enum StateIndent {
    INDENT_UNKNOWN      = 0,
    INDENT_NORMAL       = 1,
    INDENT_FIRST_ITEM   = 2,
    INDENT_IN_STRING    = 3,
    INDENT_ESCAPE       = 4,
    INDENT_MAX,
};

enum ConSerializeError con_writer_indent(
    struct ConWriterIndent *writer,
    void const *inner_writer
) {
    if (writer == NULL) { return CON_ERROR_NULL; }
    if (inner_writer == NULL) { return CON_ERROR_NULL; }

    writer->v_table.write = con_writer_indent_write;
    writer->writer = inner_writer;
    writer->depth = 0;
    writer->state = INDENT_NORMAL;

    return CON_ERROR_OK;
}

static inline int con_serialize_writer_indent_whitespace(struct ConWriterIndent *writer) {
    int result = con_writer_write(writer->writer, "\n");
    if (result < 0) { return result; }

    for (size_t i = 0; i < writer->depth; i++) {
        result = con_writer_write(writer->writer, "  ");
        if (result < 0) { return result; }
    }

    return 1;
}

int con_writer_indent_write(void const *writer_context, char const *data) {
    assert(writer_context != NULL);

    struct ConWriterIndent *writer = (struct ConWriterIndent*) writer_context;
    assert(0 < writer->state && writer->state < INDENT_MAX);

    size_t length = 0;
    char c = data[0];
    char write_char[2];

    write_char[0] = c;
    write_char[1] = '\0';
    while (c != '\0') {
        bool in_string = writer->state == INDENT_IN_STRING || writer->state == INDENT_ESCAPE;
        bool normal = writer->state == INDENT_FIRST_ITEM || writer->state == INDENT_NORMAL;

        if (writer->state == INDENT_FIRST_ITEM && c != ']' && c != '}') {
            int result = con_serialize_writer_indent_whitespace(writer);
            if (result < 0) { return result; }

            writer->state = INDENT_NORMAL;
        }

        if (normal && (c == ']' || c == '}') && writer->depth > 0) {
            writer->depth -= 1;

            if (writer->state != INDENT_FIRST_ITEM) {
                int result = con_serialize_writer_indent_whitespace(writer);
                if (result < 0) { return result; }
            }

            writer->state = INDENT_NORMAL;
        }

        if (normal && (c == '[' || c == '{')) {
            writer->state = INDENT_FIRST_ITEM;

            if (writer->depth > SIZE_MAX - 1) {
                return EOF;
            }

            writer->depth += 1;
        }

        int result = con_writer_write(writer->writer, write_char);
        if (result < 0) { return result; }

        if (c == '"' && in_string && writer->state != INDENT_ESCAPE) {
            writer->state = INDENT_NORMAL;
        } else if (c == '"' && !in_string) {
            writer->state = INDENT_IN_STRING;
        }

        if (c == '\\' && writer->state == INDENT_IN_STRING) {
            writer->state = INDENT_ESCAPE;
        } else if (in_string && writer->state == INDENT_ESCAPE) {
            writer->state = INDENT_IN_STRING;
        }

        if (c == ':' && !in_string) {
            int result = con_writer_write(writer->writer, " ");
            if (result < 0) { return result; }
        }

        if (c == ',' && !in_string) {
            int result = con_serialize_writer_indent_whitespace(writer);
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
