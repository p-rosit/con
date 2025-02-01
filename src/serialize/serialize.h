#ifndef CON_SERIALIZE_H
#define CON_SERIALIZE_H
#include <stddef.h>
#include <stdbool.h>
#include <con_error.h>

// Context struct representing a single JSON element. Any items are written
// immediately to the `writer` (which is assumed to satisfy the writer
// protocol specified in `writer.h`). With one `struct ConSerialize` only
// a single element may be written, if one attempts to write invalid JSON
// or multiple elements errors will be raised (returned).
//
// Only writes minified JSON, to write un-minified JSON one can use the
// specific writer `struct ConWriterIndent`.
//
// Fields:
//  writer:             Single item pointer owned by this struct that satisfies
//                      writer protocol specified in `writer.h`.
//  depth:              Current depth of nested containers.
//  depth_buffer:       Pointer to at least as many items as specified by
//                      `depth_buffer_size`, owned by this struct.
//  depth_buffer_size:  A non-negative number specifying at most how many items
//                      `depth_buffer` points to.
//
// Invariants:
//  writer:             Non-null, must point to writer (see `writer.h`).
//  depth:              0 <= depth <= depth_buffer_size
//  depth_buffer:       If depth_buffer_size > 0:
//                          Non-null, points to at least as many items as
//                          specified by `depth_buffer_size`
//                      If `depth_buffer_size` == 0:
//                          May be null or even invalid, will never be read from
//                          or written to.
//  depth_buffer_size:  0 <= `depth_buffer_size`.
//  state:              Managed internally, do not modify.
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
//  writer:             Valid pointer to single item that satisfies writer.
//                      protocol specified in `writer.h`. If call succeeds
//                      this pointer is owned by `context`.
//  depth_buffer:       May be null if `depth_buffer_size` is 0, must otherwise
//                      be valid pointer to as many items (or more) as specified.
//                      by `depth_buffer_size`. If call succeeds this pointer
//                      is owned by `context`.
//  depth_buffer_size:  must be equal to or smaller than actual length
//                      of passed in parameter `depth_buffer`.
//
// Error:
//  CON_ERROR_OK:       Call succeeded.
//  CON_ERROR_NULL:     Returned in the following situations:
//      1. `context` is null.
//      2. `writer` is null.
//      3. `depth_buffer` is null.
//  CON_ERROR_BUFFER:   `depth_buffer_size` is negative.
enum ConSerializeError con_serialize_init(
    struct ConSerialize *context,
    void const *writer,
    char *depth_buffer,
    int depth_buffer_size
);

// Error:
//  CON_ERROR_OK:       Call succeeded.
//  CON_ERROR_WRITER:   Failed to write data.
//  CON_ERROR_TOO_DEEP: Opened too many containers.
//  CON_ERROR_COMPLETE: JSON already complete.
//  CON_ERROR_KEY:      Missing dictionary key before this element.
enum ConSerializeError con_serialize_array_open(struct ConSerialize *context);

// Error:
//  CON_ERROR_OK:               Call succeeded.
//  CON_ERROR_WRITER:           Failed to write data.
//  CON_ERROR_CLOSED_TOO_MANY:  Closed too many containers.
//  CON_ERROR_NOT_ARRAY:        Current container is not an array.
enum ConSerializeError con_serialize_array_close(struct ConSerialize *context);

// Error:
//  CON_ERROR_OK:       Call succeeded.
//  CON_ERROR_WRITER:   Failed to write data.
//  CON_ERROR_TOO_DEEP: Opened too many containers.
//  CON_ERROR_COMPLETE: JSON already complete.
//  CON_ERROR_KEY:      Missing dictionary key before this element.
enum ConSerializeError con_serialize_dict_open(struct ConSerialize *context);

// Error:
//  CON_ERROR_OK:               Call succeeded.
//  CON_ERROR_WRITER:           Failed to write data.
//  CON_ERROR_CLOSED_TOO_MANY:  Closed too many containers.
//  CON_ERROR_NOT_DICT:         Current container is not a dict.
enum ConSerializeError con_serialize_dict_close(struct ConSerialize *context);

// Error:
//  CON_ERROR_OK:       Call succeeded.
//  CON_ERROR_NULL:     `key` is null.
//  CON_ERROR_WRITER:   Failed to write data.
//  CON_ERROR_VALUE:    Key has already been written, expected a value.
//  CON_ERROR_NOT_DICT: Current container is not a dict.
enum ConSerializeError con_serialize_dict_key(struct ConSerialize *context, char const *key);

// Error:
//  CON_ERROR_OK:           Call succeeded.
//  CON_ERROR_NULL:         `number` is null.
//  CON_ERROR_WRITER:       Failed to write data.
//  CON_ERROR_COMPLETE:     JSON already complete.
//  CON_ERROR_KEY:          Missing dictionary key before this element.
//  CON_ERROR_NOT_NUMBER:   `number` is an empty string.
enum ConSerializeError con_serialize_number(struct ConSerialize *context, char const *number);

// Error:
//  CON_ERROR_OK:       Call succeeded.
//  CON_ERROR_NULL:     `string` is null.
//  CON_ERROR_WRITER:   Failed to write data.
//  CON_ERROR_COMPLETE: JSON already complete.
//  CON_ERROR_KEY:      Missing dictionary key before this element.
enum ConSerializeError con_serialize_string(struct ConSerialize *context, char const *string);

// Error:
//  CON_ERROR_OK:       Call succeeded.
//  CON_ERROR_WRITER:   Failed to write data.
//  CON_ERROR_COMPLETE: JSON already complete.
//  CON_ERROR_KEY:      Missing dictionary key before this element.
enum ConSerializeError con_serialize_bool(struct ConSerialize *context, bool value);

// Error:
//  CON_ERROR_OK:       Call succeeded.
//  CON_ERROR_WRITER:   Failed to write data.
//  CON_ERROR_COMPLETE: JSON already complete.
//  CON_ERROR_KEY:      Missing dictionary key before this element.
enum ConSerializeError con_serialize_null(struct ConSerialize *context);

#endif
