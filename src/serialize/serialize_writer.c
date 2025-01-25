#include <stdint.h>
#include <limits.h>
#include "serialize_writer.h"

enum StateIndent {
    INDENT_NORMAL = 0,
    INDENT_FIRST_ITEM = 1,
    INDENT_IN_STRING = 2,
    INDENT_ESCAPE = 3,
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
    struct ConWriterIndent *writer = (struct ConWriterIndent*) writer_context;
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
