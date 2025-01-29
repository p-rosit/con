#ifndef CON_WRITER_H
#define CON_WRITER_H
#include <assert.h>
#include <stdio.h>
#include <con_error.h>

typedef int (ConWrite)(void const *context, char const *data);

// WARNING: to implement this writer protocol any writer must be something that
// starts with a v-table (the below type, `struct ConWriter`). To call a writer
// the write field (`write` below) must be filled with the associated function
//
// For examples of writers, see `struct ConWriterString` and others below.
struct ConWriter {
    ConWrite *write;
};

static inline int con_writer_write(void const *writer, char const *data) {
    assert(writer != NULL);

    // This cast is valid according to the standard since the first field
    // is guaranteed to start (without padding) at the same address as
    // its containing struct. If all custom writers have a v-table as
    // their first field the below cast will unpack the correct associated
    // function.
    struct ConWriter const *v_table = (struct ConWriter const*) writer;

    assert(v_table->write != NULL);
    return v_table->write(writer, data);
}

struct ConWriterFile {
    struct ConWriter v_table;
    FILE *file;
};
enum ConSerializeError con_writer_file(struct ConWriterFile *writer, FILE *file);
int con_writer_file_write(void const *writer, char const *data);

struct ConWriterString {
    struct ConWriter v_table;
    char *buffer;
    int buffer_size;
    int current;
};

enum ConSerializeError con_writer_string(
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

enum ConSerializeError con_writer_buffer(
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

enum ConSerializeError con_writer_indent(
    struct ConWriterIndent *writer,
    void const *inner_writer
);

#endif
