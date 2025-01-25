#include <assert.h>
#include <stdint.h>
#include <limits.h>
#include "serialize_writer.h"

int con_serialize_writer_file_write(void const *context, char const *data) {
    assert(context != NULL);
    assert(data != NULL);
    ConWriterFile *writer = (ConWriterFile*) context;
    return fputs(data, writer);
}

enum ConSerializeError con_serialize_writer_string(
    struct ConWriterString *writer,
    char *buffer,
    int buffer_size
) {
    if (writer == NULL) { return CON_SERIALIZE_NULL; }
    if (buffer == NULL) { return CON_SERIALIZE_NULL; }
    if (buffer_size <= 1) { return CON_SERIALIZE_BUFFER; }

    writer->buffer = buffer;
    writer->buffer_size = buffer_size;
    writer->current = 0;

    return CON_SERIALIZE_OK;
}

int con_serialize_writer_string_write(void const *context, char const *data) {
    assert(context != NULL);
    assert(data != NULL);

    struct ConWriterString *writer = (struct ConWriterString*) context;
    assert(writer->buffer != NULL);
    assert(0 <= writer->current && writer->current < writer->buffer_size);

    char c = data[0];
    int length = 0;
    while (c != '\0') {
        if (writer->current >= writer->buffer_size - 1) {
            return -1;
        }

        writer->buffer[writer->current++] = c;

        length += 1;
        c = data[length];
    }

    return 1;
}

enum ConSerializeError con_serialize_writer_buffer(
        struct ConWriterBuffer *writer,
        void const *write_context,
        ConWrite *write,
        char *buffer,
        int buffer_size
) {
    if (writer == NULL) { return CON_SERIALIZE_NULL; }
    if (write == NULL) { return CON_SERIALIZE_WRITER; }
    if (buffer == NULL) { return CON_SERIALIZE_NULL; }
    if (buffer_size <= 1) { return CON_SERIALIZE_BUFFER; }

    writer->write_context = write_context;
    writer->write = write;
    writer->buffer = buffer;
    writer->buffer_size = buffer_size;
    writer->current = 0;

    return CON_SERIALIZE_OK;
}

int con_serialize_writer_buffer_write(void const *context, char const *data) {
    assert(context != NULL);
    assert(data);

    struct ConWriterBuffer *writer = (struct ConWriterBuffer*) context;
    assert(writer->buffer != NULL);
    assert(0 <= writer->current && writer->current < writer->buffer_size);

    int length = 0;
    char c = data[0];
    while (c != '\0') {
        if (writer->current == writer->buffer_size - 1) {
            int result = con_serialize_writer_buffer_flush(writer);
            if (result < 0) { return result; }
        }

        writer->buffer[writer->current++] = c;

        if (length > INT_MAX - 1) { return -1; }
        length += 1;
        c = data[length];
    }

    return length;
}

int con_serialize_writer_buffer_flush(struct ConWriterBuffer *writer) {
    assert(writer != NULL);
    assert(writer->buffer != NULL);
    assert(0 <= writer->current && writer->current < writer->buffer_size);

    writer->buffer[writer->current] = '\0';
    writer->current = 0;
    return writer->write(writer->write_context, writer->buffer);
}

enum StateIndent {
    INDENT_UNKNOWN      = 0,
    INDENT_NORMAL       = 1,
    INDENT_FIRST_ITEM   = 2,
    INDENT_IN_STRING    = 3,
    INDENT_ESCAPE       = 4,
    INDENT_MAX,
};

struct ConWriterIndent con_serialize_writer_indent(void const *write_context, ConWrite *write) {
    return (struct ConWriterIndent) {
        .write_context = write_context,
        .write = write,
        .depth = 0,
        .state = INDENT_NORMAL,
    };
}

static inline int con_serialize_writer_indent_whitespace(struct ConWriterIndent *writer) {
    int result = writer->write(writer->write_context, "\n");
    if (result != 1) { return result; }

    for (size_t i = 0; i < writer->depth; i++) {
        result = writer->write(writer->write_context, "  ");
        if (result != 2) { return result; }
    }

    return 1;
}

int con_serialize_writer_indent_write(void const *writer_context, char const *data) {
    assert(writer_context != NULL);

    struct ConWriterIndent *writer = (struct ConWriterIndent*) writer_context;
    assert(writer->write != NULL);
    assert(0 < writer->state && writer->state < INDENT_MAX);

    char c = data[0];
    char write_char[2];
    int length = 0;

    write_char[0] = c;
    write_char[1] = '\0';
    while (c != '\0' && length < INT_MAX) {
        bool in_string = writer->state == INDENT_IN_STRING || writer->state == INDENT_ESCAPE;
        bool normal = writer->state == INDENT_FIRST_ITEM || writer->state == INDENT_NORMAL;

        if (writer->state == INDENT_FIRST_ITEM && c != ']' && c != '}') {
            int result = con_serialize_writer_indent_whitespace(writer);
            if (result <= 0) { return result; }

            writer->state = INDENT_NORMAL;
        }

        if (normal && (c == ']' || c == '}') && writer->depth > 0) {
            writer->depth -= 1;

            if (writer->state != INDENT_FIRST_ITEM) {
                int result = con_serialize_writer_indent_whitespace(writer);
                if (result <= 0) { return result; }
            }

            writer->state = INDENT_NORMAL;
        }

        if (normal && (c == '[' || c == '{')) {
            writer->state = INDENT_FIRST_ITEM;

            if (writer->depth > SIZE_MAX - 1) {
                return -1;
            }

            writer->depth += 1;
        }

        int result = writer->write(writer->write_context, write_char);
        if (result != 1) { return result; }

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
            int result = writer->write(writer->write_context, " ");
            if (result != 1) { return result; }
        }

        if (c == ',' && !in_string) {
            int result = con_serialize_writer_indent_whitespace(writer);
            if (result != 1) { return result; }
        }

        length += 1;
        c = data[length];
        write_char[0] = c;
    }

    if (length == INT_MAX) { return 0; }
    return length;
}
