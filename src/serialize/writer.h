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

// Calls the associated write function of a writer. The passed in pointer,
// `writer`, must satisfy the writer protocol. It must be a struct where
// the first field is a `struct ConWriter` which contains the associated
// write function.
//
// Params:
//  writer: A writer.
//  data:   Null-terminated string to write.
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

// A writer that writes to a file, use `con_writer_file` to initialize.
struct ConWriterFile {
    struct ConWriter v_table;
    FILE *file;
};

// Initializes a `struct ConWriterFile`.
//
// Params:
//  writer: Single item pointer to `struct ConWriterFile`.
//  file:   Single item pointer to file, if call succeeds owned by `writer`.
//
// Error:
//  CON_ERROR_OK: Call succeeded
//  CON_ERROR_NULL: Returned in the following situations:
//      1. `writer` is null.
//      2. `file` is null.
enum ConSerializeError con_writer_file(struct ConWriterFile *writer, FILE *file);

// A writer that writes to a null-terminated char buffer.
struct ConWriterString {
    struct ConWriter v_table;
    char *buffer;
    int buffer_size;
    int current;
};

// Initializes a `struct ConWriterString`.
//
// Params:
//  writer:         Single item pointer to `struct ConWriterString`.
//  buffer:         Pointer to at least as many items as specified by
//                  `buffer_size`, owned by `writer` if call succeeds.
//  buffer_size:    Specifies at most how many items `buffer` points to.
//
// Error:
//  CON_ERROR_OK:       Call succeeded.
//  CON_ERROR_NULL:     Returned in the following situations:
//      1. `writer` is null.
//      2. `buffer` is null.
//  CON_ERROR_BUFFER:   `buffer_size` <= 0.
enum ConSerializeError con_writer_string(
    struct ConWriterString *writer,
    char *buffer,
    int buffer_size
);

// A writer that buffers any calls to an internal writer.
struct ConWriterBuffer {
    struct ConWriter v_table;
    void const *writer;
    char *buffer;
    int buffer_size;
    int current;
};

// Initializes a `struct ConWriterBuffer`
//
// Params:
//  writer:         Single item pointer to `struct ConWriterBuffer`.
//  inner_writer:   Single item pointer to a writer, owned by `writer` if call
//                  succeeds.
//  buffer:         Pointer to at least as many items as specified by
//                  `buffer_size`, owned by `writer` if call succeeds.
//  buffer_size:    Specifies at most how many items `buffer` points to.
//
// Error:
//  CON_ERROR_OK:       Call succeeded.
//  CON_ERROR_NULL:     Returned in the following situations:
//      1. `writer` is null.
//      2. `inner_writer` is null.
//      3. `buffer` is null.
//  CON_ERROR_BUFFER:   `buffer_size` <= 1.
enum ConSerializeError con_writer_buffer(
        struct ConWriterBuffer *writer,
        void const *inner_writer,
        char *buffer,
        int buffer_size
);

// Flushes the internal buffer by writing everything in it to the internal writer.
int con_writer_buffer_flush(struct ConWriterBuffer *writer);

// A writer that converts minfied JSON to indented JSON. Note that this writer
// will destroy any buffering since every write will be broken up into single
// writes. Therefore this should not be the inner writer to a buffered writer,
// the inner writer of this writer should be buffered if anything.
struct ConWriterIndent {
    struct ConWriter v_table;
    void const *writer;
    size_t depth;
    char state;
};

// Initializes a `struct ConWriterIndent`
//
// Params:
//  writer:         Single items pointer to `struct ConWriterIndent`.
//  inner_writer:   Single item pointer to a writer, owned by `writer` if call
//                  succeeds.
//
// Error:
//  CON_ERROR_OK:   Call succeeded.
//  CON_ERROR_NULL: Returned in the following situations:
//      1. `writer` is null.
//      2. `inner_writer` is null.
enum ConSerializeError con_writer_indent(
    struct ConWriterIndent *writer,
    void const *inner_writer
);

#endif
