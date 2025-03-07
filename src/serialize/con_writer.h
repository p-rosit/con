#ifndef CON_WRITER_H
#define CON_WRITER_H
#include <stdbool.h>
#include <stdio.h>
#include <con_error.h>
#include <con_interface_writer.h>

// A writer that writes to a file, use `con_writer_file` to initialize.
struct ConWriterFile {
    FILE *file;
};

// Initializes a `struct ConWriterFile`.
//
// Params:
//  context:    Single item pointer to `struct ConWriterFile`.
//  file:       Single item pointer to file, if call succeeds owned by `writer`.
//
// Return:
//  CON_ERROR_OK: Call succeeded
//  CON_ERROR_NULL: `file` is null.
enum ConError con_writer_file_init(struct ConWriterFile *context, FILE *file);

// Makes a writer interface from an already initialized `struct ConWriterFile`
// the returned writer owns the passed in `context`.
struct ConInterfaceWriter con_writer_file_interface(struct ConWriterFile *context);

// A writer that writes to a char buffer. The `current` field keeps track
// of how many bytes have been written so far
struct ConWriterString {
    char *buffer;
    size_t buffer_size;
    size_t current;
};

// Initializes a `struct ConWriterString`.
//
// Params:
//  context:        Single item pointer to `struct ConWriterString`.
//  buffer:         Pointer to at least as many items as specified by
//                  `buffer_size`, owned by `writer` if call succeeds.
//  buffer_size:    Specifies at most how many items `buffer` points to.
//
// Return:
//  CON_ERROR_OK:       Call succeeded.
//  CON_ERROR_NULL:     `buffer` is null.
enum ConError con_writer_string_init(
    struct ConWriterString *context,
    char *buffer,
    size_t buffer_size
);

// Makes a writer interface from an already initialized `struct ConWriterString`
// the returned writer owns the passed in `context`.
struct ConInterfaceWriter con_writer_string_interface(struct ConWriterString *context);

// A writer that buffers any calls to an internal writer.
struct ConWriterBuffer {
    struct ConInterfaceWriter writer;
    char *buffer;
    size_t buffer_size;
    size_t current;
};

// Initializes a `struct ConWriterBuffer`
//
// Params:
//  context:        Single item pointer to `struct ConWriterBuffer`.
//  writer:         Valid write struct, owned by `context` if call succeeds.
//  buffer:         Pointer to at least as many items as specified by
//                  `buffer_size`, owned by `writer` if call succeeds.
//  buffer_size:    Specifies at most how many items `buffer` points to.
//
// Return:
//  CON_ERROR_OK:       Call succeeded.
//  CON_ERROR_NULL:     Returned in the following situations:
//      1. `context` is null.
//      2. `buffer` is null.
//  CON_ERROR_BUFFER:   `buffer_size` <= 0.
enum ConError con_writer_buffer_init(
    struct ConWriterBuffer *context,
    struct ConInterfaceWriter writer,
    char *buffer,
    size_t buffer_size
);

// Makes a writer interface from an already initialized `struct ConWriterBuffer`
// the returned writer owns the passed in `context`.
struct ConInterfaceWriter con_writer_buffer_interface(struct ConWriterBuffer *context);

// Flushes the internal buffer by writing everything in it to the internal writer.
// Returns true if the call succeded and false if call failed.
bool con_writer_buffer_flush(struct ConWriterBuffer *context);

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
//  context:    Single items pointer to `struct ConWriterIndent`.
//  writer:     Valid write struct, owned by `context` if call succeeds.
//
// Return:
//  CON_ERROR_OK:   Call succeeded.
//  CON_ERROR_NULL: `context` is null.
enum ConError con_writer_indent_init(
    struct ConWriterIndent *context,
    struct ConInterfaceWriter writer
);

// Makes a writer interface from an already initialized `struct ConWriterIndent`
// the returned writer owns the passed in `context`.
struct ConInterfaceWriter con_writer_indent_interface(struct ConWriterIndent *context);

#endif
