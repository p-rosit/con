#ifndef CON_SERIALIZE_WRITER_H
#define CON_SERIALIZE_WRITER_H
#include <stdio.h>

enum ConWriterError {
    CON_WRITER_OK       = 0,
    CON_WRITER_NULL     = 1,
    CON_WRITER_BUFFER   = 4,
};

typedef int (ConWrite)(void const *context, char const *data);

struct ConWriter {
    ConWrite *write;
};

int con_writer_write(void const *writer, char const *data);

struct ConWriterFile {
    struct ConWriter v_table;
    FILE *file;
};
enum ConWriterError con_writer_file(struct ConWriterFile *writer, FILE *file);
int con_writer_file_write(void const *writer, char const *data);

struct ConWriterString {
    struct ConWriter v_table;
    char *buffer;
    int buffer_size;
    int current;
};

enum ConWriterError con_writer_string(
    struct ConWriterString *writer,
    char *buffer,
    int buffer_size
);

struct ConWriterBuffer {
    struct ConWriter v_table;
    void const *writer;
    char *buffer;
    int buffer_size;
    int current;
};

enum ConWriterError con_writer_buffer(
        struct ConWriterBuffer *writer,
        void const *inner_writer,
        char *buffer,
        int buffer_size
);
int con_writer_buffer_flush(struct ConWriterBuffer *writer);

struct ConWriterIndent {
    struct ConWriter v_table;
    void const *writer;
    size_t depth;
    char state;
};

enum ConWriterError con_writer_indent(
    struct ConWriterIndent *writer,
    void const *inner_writer
);

#endif
