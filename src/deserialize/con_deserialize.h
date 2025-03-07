#ifndef CON_DESERIALIZE_H
#define CON_DESERIALIZE_H
#include <con_error.h>
#include <con_interface_writer.h>
#include <con_interface_reader.h>

enum ConDeserializeType {
    CON_DESERIALIZE_TYPE_UNKNOWN        = 0,
    CON_DESERIALIZE_TYPE_NUMBER         = 1,
    CON_DESERIALIZE_TYPE_STRING         = 2,
    CON_DESERIALIZE_TYPE_BOOL           = 3,
    CON_DESERIALIZE_TYPE_NULL           = 4,
    CON_DESERIALIZE_TYPE_ARRAY_OPEN     = 5,
    CON_DESERIALIZE_TYPE_ARRAY_CLOSE    = 6,
    CON_DESERIALIZE_TYPE_DICT_OPEN      = 7,
    CON_DESERIALIZE_TYPE_DICT_CLOSE     = 8,
    CON_DESERIALIZE_TYPE_DICT_KEY       = 9,
    CON_DESERIALIZE_TYPE_MAX,
};

struct ConDeserialize {
    struct ConInterfaceReader reader;
    size_t depth;
    char *depth_buffer;
    int depth_buffer_size;
    char state;
    int buffer_char;
    bool found_comma;
};

enum ConError con_deserialize_init(
    struct ConDeserialize *context,
    struct ConInterfaceReader reader,
    char *depth_buffer,
    int depth_buffer_size
);

enum ConError con_deserialize_next(
    struct ConDeserialize *context,
    enum ConDeserializeType *type
);

enum ConError con_deserialize_array_open(struct ConDeserialize *context);
enum ConError con_deserialize_array_close(struct ConDeserialize *context);

enum ConError con_deserialize_dict_open(struct ConDeserialize *context);
enum ConError con_deserialize_dict_close(struct ConDeserialize *context);
enum ConError con_deserialize_dict_key(struct ConDeserialize *context, struct ConInterfaceWriter writer);

enum ConError con_deserialize_number(struct ConDeserialize *context, struct ConInterfaceWriter writer);
enum ConError con_deserialize_string(struct ConDeserialize *context, struct ConInterfaceWriter writer);
enum ConError con_deserialize_bool(struct ConDeserialize *context, bool *value);
enum ConError con_deserialize_null(struct ConDeserialize *context);

#endif
