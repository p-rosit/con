#ifndef CON_INTERFACE_WRITER_H
#define CON_INTERFACE_WRITER_H
#include <assert.h>
#include <stddef.h>

typedef size_t (ConWrite)(void const *context, char const *data, size_t data_size);

// A writer interface, a valid writer will have some optional context
// (in `context`) and a non-null `write` function.
//
// The write function must satisfy the following contract:
//
// Params:
//  context:    The `context` in this struct.
//  data:       Some bytes to be written.
//  data_size:  The length of `data` in bytes.
//
// Returns:
//  The amount of characters written, less than `data_size` if an error occured.
struct ConInterfaceWriter {
    void const *context;
    ConWrite *write;
};

// Calls the associated write function of a writer.
//
// Params:
//  writer:     A writer interface
//  data:       The bytes to write.
//  data_size:  The length of `data` in bytes.
//
// Returns:
//  The amount of characters written, less than `data_size` if an error occured.
static inline size_t con_writer_write(struct ConInterfaceWriter writer, char const *data, size_t data_size) {
    assert(writer.write != NULL);
    return writer.write(writer.context, data, data_size);
}

#endif
