#ifndef CON_SERIALIZE_WRITER_H
#define CON_SERIALIZE_WRITER_H
#include <stdio.h>
#include "serialize.h"

typedef FILE ConWriterFile;
int con_serialize_writer_file_write(void const *writer, char const *data);

struct ConWriterString {
    char *buffer;
    int buffer_size;
    int current;
};

enum ConSerializeError con_serialize_writer_string(
    struct ConWriterString *writer,
    char *buffer,
    int buffer_size
);
int con_serialize_writer_string_write(void const *writer, char const *data);

struct ConWriterBuffer {
    void const *write_context;
    ConWrite *write;
    char *buffer;
    int buffer_size;
    int current;
};

enum ConSerializeError con_serialize_writer_buffer(
        struct ConWriterBuffer *writer,
        void const *write_context,
        ConWrite *write,
        char *buffer,
        int buffer_size
);
int con_serialize_writer_buffer_write(void const *writer, char const *data);
int con_serialize_writer_buffer_flush(struct ConWriterBuffer *writer);

struct ConWriterIndent {
    void const *write_context;
    ConWrite *write;
    size_t depth;
    char state;
};

struct ConWriterIndent con_serialize_writer_indent(void const *write_context, ConWrite *write);
int con_serialize_writer_indent_write(void const *writer, char const *data);

#endif
