#include <limits.h>
#include "reader.h"

int con_reader_file_read(void const *context, char *buffer, int buffer_size);

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
