#include <assert.h>
#include <ctype.h>
#include "con_writer.h"
#include "con_deserialize.h"

enum ConError con_deserialize_init(struct ConDeserialize *context, struct ConInterfaceReader reader, char *depth_buffer, int depth_buffer_size) {
    if (context == NULL) { return CON_ERROR_NULL; }
    if (depth_buffer == NULL && depth_buffer_size > 0) { return CON_ERROR_NULL; }
    if (depth_buffer_size < 0) { return CON_ERROR_BUFFER; }

    context->reader = reader;
    context->depth = 0;
    context->depth_buffer = depth_buffer;
    context->depth_buffer_size = depth_buffer_size;

    return CON_ERROR_OK;
}

enum ConError con_deserialize_next(struct ConDeserialize *context, enum ConDeserializeType *type) {
    assert(context != NULL);
    if (type == NULL) { return CON_ERROR_NULL; }

    char next = ' ';
    while (isspace((unsigned char) next)) {
        struct ConReadResult result = con_reader_read(context->reader, &next, 1);
        if (result.error || result.length != 1) { return CON_ERROR_READER; }

        if (next == ',') {
            // was comma expected?
        }
    }

    if (isdigit((unsigned char) next) || next == '.') {
        // number
        *type = CON_DESERIALIZE_TYPE_NUMBER;
    } else if (next == '"' /* && expecting key */) {
        // key
        *type = CON_DESERIALIZE_TYPE_KEY;
    } else if (next == '"') {
        // string
        *type = CON_DESERIALIZE_TYPE_STRING;
    } else if (next == 't' || next == 'f') {
        // bool
        *type = CON_DESERIALIZE_TYPE_BOOL;
    } else if (next == 'n') {
        // null
        *type = CON_DESERIALIZE_TYPE_NULL;
    } else if (next == '[') {
        // open array
        *type = CON_DESERIALIZE_TYPE_ARRAY_OPEN;
    } else if (next == ']') {
        // close array
        *type = CON_DESERIALIZE_TYPE_ARRAY_CLOSE;
    } else if (next == '{') {
        // open dict
        *type = CON_DESERIALIZE_TYPE_DICT_OPEN;
    } else if (next == '}') {
        // close dict
        *type = CON_DESERIALIZE_TYPE_DICT_CLOSE;
    } else {
        *type = CON_DESERIALIZE_TYPE_UNKNOWN;
        assert(false);
    }

    return CON_ERROR_OK;
}
