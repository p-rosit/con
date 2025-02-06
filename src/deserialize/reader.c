#include <stdbool.h>
#include <limits.h>
#include "reader.h"

int con_reader_file_read(void const *context, char *buffer, int buffer_size);
int con_reader_string_read(void const *context, char *buffer, int buffer_size);
int con_reader_buffer_read(void const *context, char *buffer, int buffer_size);

enum ConError con_reader_file(struct ConReaderFile *reader, FILE *file) {
    if (reader == NULL) { return CON_ERROR_NULL; }

    reader->file = NULL;
    if (file == NULL) { return CON_ERROR_NULL; }

    reader->v_table.read = con_reader_file_read;
    reader->file = file;
    return CON_ERROR_OK;
}

int con_reader_file_read(void const *context, char *buffer, int buffer_size) {
    assert(context != NULL);
    struct ConReaderFile *reader = (struct ConReaderFile*) context;

    assert(buffer != NULL);
    assert(buffer_size >= 0);
    size_t amount_read = fread(buffer, sizeof(char), (size_t) buffer_size, reader->file);

    assert(amount_read <= INT_MAX);
    return (int) amount_read;
}

enum ConError con_reader_string(struct ConReaderString *reader, const char *buffer, int buffer_size) {
    if (reader == NULL) { return CON_ERROR_NULL; }

    reader->buffer = NULL;
    if (buffer == NULL) { return CON_ERROR_NULL; }
    if (buffer_size < 0) { return CON_ERROR_BUFFER; }

    reader->v_table.read = con_reader_string_read;
    reader->buffer = buffer;
    reader->buffer_size = buffer_size;
    reader->current = 0;

    return CON_ERROR_OK;
}

int con_reader_string_read(void const *context, char *buffer, int buffer_size) {
    assert(context != NULL);
    assert(buffer != NULL);
    assert(buffer_size >= 0);

    struct ConReaderString *reader = (struct ConReaderString*) context;
    assert(reader->buffer != NULL);
    assert(0 <= reader->current && reader->current <= reader->buffer_size);

    if (reader->current >= reader->buffer_size) {
        return -1;
    }

    int current = reader->current;
    int length = 0;
    while (length < buffer_size - 1 && current < reader->buffer_size) {
        buffer[length++] = reader->buffer[current++];
    }

    buffer[length] = '\0';
    reader->current = current;
    return length;
}

enum ConError con_reader_buffer(
    struct ConReaderBuffer *reader,
    void const *inner_reader,
    char *buffer,
    int buffer_size
) {
    if (reader == NULL) { return CON_ERROR_NULL; }
    if (inner_reader == NULL) { return CON_ERROR_NULL; }
    if (buffer == NULL) { return CON_ERROR_NULL; }
    if (buffer_size <= 1) { return CON_ERROR_BUFFER; }

    reader->v_table.read = con_reader_buffer_read;
    reader->reader = inner_reader;
    reader->buffer = buffer;
    reader->buffer_size = buffer_size;
    reader->current = buffer_size;
    reader->length_read = 0;

    return CON_ERROR_OK;
}

int con_reader_buffer_read(void const *context, char *buffer, int buffer_size) {
    assert(context != NULL);
    assert(buffer != NULL);
    assert(buffer_size >= 0);

    struct ConReaderBuffer *reader = (struct ConReaderBuffer*) context;
    assert(reader->buffer != NULL);
    assert(0 <= reader->current && reader->current <= reader->buffer_size);

    bool any_read = false;
    int length = 0;
    while (length < buffer_size - 1) {
        if (reader->current >= reader->length_read) {
            reader->length_read = 0;
            int length_read = con_reader_read(reader->reader, reader->buffer, reader->buffer_size);
            if (any_read && length_read <= 0) { break; }
            if (length_read <= 0) { return length_read; }

            reader->current = 0;
            reader->length_read = length_read;
        }

        any_read = true;
        buffer[length++] = reader->buffer[reader->current++];
    }

    buffer[length] = '\0';
    return length;
}
