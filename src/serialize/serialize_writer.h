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
    void const *context;
    ConWrite *write;
};

struct ConWriter con_writer(void const *context, ConWrite *write);
int con_writer_write(struct ConWriter writer, char const *data);

typedef FILE ConWriterFile;
int con_writer_file_write(void const *writer, char const *data);

struct ConWriterString {
    char *buffer;
    int buffer_size;
    int current;
};

enum ConWriterError con_writer_string(
    struct ConWriterString *writer,
    char *buffer,
    int buffer_size
);
int con_writer_string_write(void const *writer, char const *data);

struct ConWriterBuffer {
    struct ConWriter writer;
    char *buffer;
    int buffer_size;
    int current;
};

enum ConWriterError con_writer_buffer(
        struct ConWriterBuffer *writer,
        struct ConWriter inner_writer,
        char *buffer,
        int buffer_size
);
int con_writer_buffer_write(void const *writer, char const *data);
int con_writer_buffer_flush(struct ConWriterBuffer *writer);

struct ConWriterIndent {
    struct ConWriter writer;
    size_t depth;
    char state;
};

enum ConWriterError con_writer_indent(
    struct ConWriterIndent *writer,
    struct ConWriter inner_writer
);
int con_writer_indent_write(void const *writer, char const *data);

#endif
