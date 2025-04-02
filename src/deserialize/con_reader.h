#ifndef CON_READER_H
#define CON_READER_H
#include <gci_interface_reader.h>
#include <con_common.h>

struct ConReaderComment {
    struct GciInterfaceReader reader;
    struct ConStateChar state;
    int buffer_char;
    bool in_comment;
};

enum ConError con_reader_comment_init(
    struct ConReaderComment *context,
    struct GciInterfaceReader reader
);

struct GciInterfaceReader con_reader_comment_interface(struct ConReaderComment *context);

#endif
