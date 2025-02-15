#ifndef CON_INTERFACE_READER_H
#define CON_INTERFACE_READER_H
#include <assert.h>
#include <stddef.h>
#include <stdbool.h>

struct ConReadResult {
    bool error;
    size_t length;
};

typedef struct ConReadResult (ConRead)(void const *context, char *buffer, size_t buffer_size);

struct ConInterfaceReader {
    void const *context;
    ConRead *read;
};

static inline struct ConReadResult con_reader_read(struct ConInterfaceReader reader, char *buffer, size_t buffer_size) {
    assert(reader.read != NULL);
    return reader.read(reader.context, buffer, buffer_size);
}

#endif
