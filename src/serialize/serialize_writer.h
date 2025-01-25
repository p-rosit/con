#ifndef CON_SERIALIZE_WRITER_H
#define CON_SERIALIZE_WRITER_H
#include "serialize.h"

struct ConWriterIndent {
    void const *write_context;
    ConWrite *write;
    size_t depth;
    char state;
};

struct ConWriterIndent con_serialize_writer_indent(void const *write_context, ConWrite *write);
int con_serialize_writer_indent_write(void const *writer, char const *data);

#endif
