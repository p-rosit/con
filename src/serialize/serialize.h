#ifndef CON_SERIALIZE_H
#define CON_SERIALIZE_H
#include <stddef.h>
#include <stdbool.h>
#include <con_error.h>

struct ConSerialize {
    void const *writer;
    size_t depth;
    char *depth_buffer;
    int depth_buffer_size;
    char state;
};

// Initializes a serialization context which can then be used to write JSON
// with `con_serialize_array_open`, `con_serialize_number` and similar.
//
// Params:
//  context:            Valid pointer to single item.
//  writer:             Valid pointer to single item that satisfies writer
//                      protocol specified in `writer.h`. If call succeeds
//                      this pointer is owned by `context`.
//  depth_buffer:       May be null if `depth_buffer_size` is 0, must otherwise
//                      be valid pointer to as many items (or more) as specified
//                      by `depth_buffer_size`. If call succeeds this pointer
//                      is owned by `context`.
//  depth_buffer_size:  must be equal to or smaller than actual length
//                      of passed in parameter `depth_buffer`
//
// Error:
//  CON_SERIALIZE_OK:       Call succeded
//  CON_SERIALIZE_NULL:     May be returned in of the following situations
//      1. `context` is null
//      2. `writer` is null
//      3. `depth_buffer` is null
//  CON_SERIALIZE_BUFFER:   `depth_buffer_size` is negative
enum ConSerializeError con_serialize_init(
    struct ConSerialize *context,
    void const *writer,
    char *depth_buffer,
    int depth_buffer_size
);

enum ConSerializeError con_serialize_array_open(struct ConSerialize *context);
enum ConSerializeError con_serialize_array_close(struct ConSerialize *context);

enum ConSerializeError con_serialize_dict_open(struct ConSerialize *context);
enum ConSerializeError con_serialize_dict_close(struct ConSerialize *context);
enum ConSerializeError con_serialize_dict_key(struct ConSerialize *context, char const *key);

enum ConSerializeError con_serialize_number(struct ConSerialize *context, char const *number);
enum ConSerializeError con_serialize_string(struct ConSerialize *context, char const *string);
enum ConSerializeError con_serialize_bool(struct ConSerialize *context, bool value);
enum ConSerializeError con_serialize_null(struct ConSerialize *context);

#endif
