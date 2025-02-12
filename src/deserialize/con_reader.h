#ifndef CON_READER_H
#define CON_READER_H
#include <stdbool.h>
#include <stdio.h>
#include <con_error.h>
#include <con_interface_reader.h>


struct ConReaderFile {
    FILE *file;
};

enum ConError con_reader_file(struct ConReaderFile *context, FILE *file);
struct ConInterfaceReader con_reader_file_interface(struct ConReaderFile *context);

struct ConReaderString {
    char const *buffer;
    int buffer_size;
    int current;
};

enum ConError con_reader_string(
    struct ConReaderString *context,
    char const *buffer,
    int buffer_size
);

struct ConInterfaceReader con_reader_string_interface(struct ConReaderString *context);

struct ConReaderBuffer {
    struct ConInterfaceReader reader;
    char *buffer;
    int buffer_size;
    int current;
    int length_read;
};

enum ConError con_reader_buffer(
    struct ConReaderBuffer *context,
    struct ConInterfaceReader reader,
    char *buffer,
    int buffer_size
);

struct ConInterfaceReader con_reader_buffer_interface(struct ConReaderBuffer *context);

struct ConReaderComment {
    struct ConInterfaceReader reader;
    char buffer_char;
    bool in_string;
};

enum ConError con_reader_comment(
    struct ConReaderComment *context,
    struct ConInterfaceReader reader
);

#endif
