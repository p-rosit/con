#include <assert.h>
#include "con_writer.h"
#include "con_deserialize.h"

enum ConError con_deserialize_init(struct ConDeserialize *context, struct ConInterfaceReader reader) {
    if (context == NULL) { return CON_ERROR_NULL; }

    context->reader = reader;
    return CON_ERROR_OK;
}
