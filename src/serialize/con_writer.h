#ifndef CON_WRITER_H
#define CON_WRITER_H
#include <assert.h>
#include <stdio.h>
#include <con_error.h>

typedef int (ConWrite)(void const *context, char const *data);

struct ConInterfaceWriter {
    const void *context;
    ConWrite *write;
};

// Calls the associated write function of a writer. The passed in pointer,
// `writer`, must satisfy the writer protocol. It must be a struct where
// the first field is a `struct ConWriter` which contains the associated
// write function.
//
// Params:
//  writer: A writer interface
//  data:   Null-terminated string to write.
static inline int con_writer_write(struct ConInterfaceWriter writer, char const *data) {
    assert(writer.write != NULL);
    return writer.write(writer.context, data);
}

// A writer that writes to a file, use `con_writer_file` to initialize.
struct ConWriterFile {
    FILE *file;
};

// Initializes a `struct ConWriterFile`.
//
// Params:
//  writer: Single item pointer to `struct ConWriterFile`.
//  file:   Single item pointer to file, if call succeeds owned by `writer`.
//
// Return:
//  CON_ERROR_OK: Call succeeded
//  CON_ERROR_NULL: Returned in the following situations:
//      1. `writer` is null.
//      2. `file` is null.
enum ConError con_writer_file_context(struct ConWriterFile *context, FILE *file);
struct ConInterfaceWriter con_writer_file_interface(struct ConWriterFile *context);

// A writer that writes to a null-terminated char buffer.
struct ConWriterString {
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
// Return:
//  CON_ERROR_OK:       Call succeeded.
//  CON_ERROR_NULL:     Returned in the following situations:
//      1. `writer` is null.
//      2. `buffer` is null.
//  CON_ERROR_BUFFER:   `buffer_size` <= 0.
enum ConError con_writer_string_context(
    struct ConWriterString *context,
    char *buffer,
    int buffer_size
);
struct ConInterfaceWriter con_writer_string_interface(struct ConWriterString *context);

// A writer that buffers any calls to an internal writer.
struct ConWriterBuffer {
    struct ConInterfaceWriter writer;
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
// Return:
//  CON_ERROR_OK:       Call succeeded.
//  CON_ERROR_NULL:     Returned in the following situations:
//      1. `writer` is null.
//      2. `inner_writer` is null.
//      3. `buffer` is null.
//  CON_ERROR_BUFFER:   `buffer_size` <= 1.
enum ConError con_writer_buffer_context(
    struct ConWriterBuffer *context,
    struct ConInterfaceWriter writer,
    char *buffer,
    int buffer_size
);
struct ConInterfaceWriter con_writer_buffer_interface(struct ConWriterBuffer *context);

// Flushes the internal buffer by writing everything in it to the internal writer.
int con_writer_buffer_flush(struct ConWriterBuffer *context);

// A writer that converts minfied JSON to indented JSON. Note that this writer
// will destroy any buffering since every write will be broken up into single
// writes. Therefore this should not be the inner writer to a buffered writer,
// the inner writer of this writer should be buffered if anything.
struct ConWriterIndent {
    struct ConInterfaceWriter writer;
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
// Return:
//  CON_ERROR_OK:   Call succeeded.
//  CON_ERROR_NULL: Returned in the following situations:
//      1. `writer` is null.
//      2. `inner_writer` is null.
enum ConError con_writer_indent_context(
    struct ConWriterIndent *context,
    struct ConInterfaceWriter writer
);
struct ConInterfaceWriter con_writer_indent_interface(struct ConWriterIndent *context);

#endif
