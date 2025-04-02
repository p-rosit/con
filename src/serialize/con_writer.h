#ifndef CON_WRITER_H
#define CON_WRITER_H
#include <gci_interface_writer.h>
#include <con_common.h>

// A writer that converts minfied JSON to indented JSON. Note that this writer
// will destroy any buffering since every write will be broken up into single
// writes. Therefore this should not be the inner writer to a buffered writer,
// the inner writer of this writer should be buffered if anything.
struct ConWriterIndent {
    struct GciInterfaceWriter writer;
    struct ConStateChar state;
    size_t depth;
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
    struct GciInterfaceWriter writer
);

// Makes a writer interface from an already initialized `struct ConWriterIndent`
// the returned writer owns the passed in `context`.
struct GciInterfaceWriter con_writer_indent_interface(struct ConWriterIndent *context);

#endif
