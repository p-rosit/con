#ifndef CON_READER_H
#define CON_READER_H
#include <assert.h>
#include <stdio.h>
#include <con_error.h>

typedef int (ConRead)(void const *context, char *buffer, int buffer_size);

struct ConReader {
    ConRead *read;
};

static inline int con_reader_read(void const *reader, char *buffer, int buffer_size) {
    assert(reader != NULL);

    struct ConReader const *v_table = (struct ConReader const*) reader;

    assert(v_table->read != NULL);
    return v_table->read(reader, buffer, buffer_size);
}

struct ConReaderFile {
    struct ConReader v_table;
    FILE *file;
};

enum ConError con_reader_file(struct ConReaderFile *reader, FILE *file);

struct ConReaderString {
    struct ConReader v_table;
    const char *buffer;
    int buffer_size;
    int current;
};

enum ConError con_reader_string(
    struct ConReaderString *reader,
    const char *buffer,
    int buffer_size
);

struct ConReaderBuffer {
    struct ConReader v_table;
    void const *reader;
    char *buffer;
    int buffer_size;
    int current;
};

enum ConError con_reader_buffer(
    struct ConReaderBuffer *reader,
    void const *inner_writer,
    char *buffer,
    int buffer_size
);

#endif
