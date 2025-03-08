#ifndef CON_DESERIALIZE_H
#define CON_DESERIALIZE_H
#include <con_error.h>
#include <con_interface_writer.h>
#include <con_interface_reader.h>

// Represents token types
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

// Context struct representing a single JSON element. All characters are read
// from the `reader` one at a time. With one `struct ConDeserialize` only a
// single element may be read, if one attempts to read invalid JSON or multiple
// elements errors will be raised (returned).
//
// Fields:
//  reader:             A valid reader, see `con_reader.h`.
//  depth:              Current depth of nested containers.
//  depth_buffer:       Pointer to at least as many items as specified by
//                      `depth_buffer_size`, owned by this struct.
//  depth_buffer_size:  A non-negative number specifying at most how many items
//                      `depth_buffer` points to to.
//  buffer_char:        Character read from the `reader` which has not yet been
//                      consumed. Does not contain a character if value is EOF.
//  state:              Keeps track of the current state of the parsing.
//  found_comma:        Remembers if a comma was found for the next entry.
//
// Invariants:
//  depth:              0 <= depth <= depth_buffer_size
//  depth_buffer:       If depth_buffer_size > 0:
//                          Non-null, points to at least as many items as
//                          specified by `depth_buffer_size`
//                      If `depth_buffer_size` == 0:
//                          May be null or even invalid, will never be read from
//                          or written to.
//  depth_buffer_size:  0 <= `depth_buffer_size`.
//  buffer_char:        Contains EOF if empty, otherwise a character that has
//                      not been consumed.
//  state:              Managed internally, do not modify.
//  found_comma:        Valid to read of `buffer_char` is not EOF.
struct ConDeserialize {
    struct ConInterfaceReader reader;
    size_t depth;
    char *depth_buffer;
    int depth_buffer_size;
    int buffer_char;
    char state;
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
