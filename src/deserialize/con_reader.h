#ifndef CON_READER_H
#define CON_READER_H
#include <stdbool.h>
#include <stdio.h>
#include <con_error.h>
#include <con_interface_reader.h>


struct ConReaderFile {
    struct ConReader v_table;
    FILE *file;
};

enum ConError con_reader_file(struct ConReaderFile *reader, FILE *file);

struct ConReaderString {
    struct ConReader v_table;
    char const *buffer;
    int buffer_size;
    int current;
};

enum ConError con_reader_string(
    struct ConReaderString *reader,
    char const *buffer,
    int buffer_size
);

struct ConReaderBuffer {
    struct ConReader v_table;
    void const *reader;
    char *buffer;
    int buffer_size;
    int current;
    int length_read;
};

enum ConError con_reader_buffer(
    struct ConReaderBuffer *reader,
    void const *inner_reader,
    char *buffer,
    int buffer_size
);

struct ConReaderComment {
    struct ConReader v_table;
    void const *reader;
    char buffer_char;
    bool in_string;
};

enum ConError con_reader_comment(
    struct ConReaderComment *reader,
    void const *inner_reader
);

#endif
