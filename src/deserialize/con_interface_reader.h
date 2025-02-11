#ifndef CON_INTERFACE_READER_H
#define CON_INTERFACE_READER_H
#include <assert.h>
#include <stddef.h>

typedef int (ConRead)(void const *context, char *buffer, int buffer_size);

struct ConReader {
    ConRead *read;
};

static inline int con_reader_read(void const *reader, char *buffer, int buffer_size) {
    assert(reader != NULL);

    struct ConReader const *v_table = (struct ConReader const*) reader;

    assert(v_table->read != NULL);
    return v_table->read(reader, buffer, buffer_size);
}

#endif
