#ifndef CON_INTERFACE_READER_H
#define CON_INTERFACE_READER_H
#include <assert.h>
#include <stddef.h>

typedef int (ConRead)(void const *context, char *buffer, int buffer_size);

struct ConInterfaceReader {
    void const *context;
    ConRead *read;
};

static inline int con_reader_read(struct ConInterfaceReader reader, char *buffer, int buffer_size) {
    assert(reader.read != NULL);
    return reader.read(reader.context, buffer, buffer_size);
}

#endif
