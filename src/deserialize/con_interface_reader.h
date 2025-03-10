#ifndef CON_INTERFACE_READER_H
#define CON_INTERFACE_READER_H
#include <assert.h>
#include <stddef.h>
#include <stdbool.h>

typedef size_t (ConRead)(void const *context, char *buffer, size_t buffer_size);

struct ConInterfaceReader {
    void const *context;
    ConRead *read;
};

static inline size_t con_reader_read(struct ConInterfaceReader reader, char *buffer, size_t buffer_size) {
    assert(reader.read != NULL);
    return reader.read(reader.context, buffer, buffer_size);
}

#endif
