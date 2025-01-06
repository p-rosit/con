#include <assert.h>
#include "serialize.h"

enum ConSerializeError con_serialize_context_init(struct ConSerialize *context) {
    assert(context != NULL);
    return CON_SERIALIZE_OK;
}
