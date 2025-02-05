#include <limits.h>
#include "reader.h"

int con_reader_file_read(void const *context, char *buffer, int buffer_size);
int con_reader_string_read(void const *context, char *buffer, int buffer_size);

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
    if (buffer_size <= 0) { return CON_ERROR_BUFFER; }

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
