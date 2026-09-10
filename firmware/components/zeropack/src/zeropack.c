#include "zeropack.h"

#include <string.h>

#include "esp_log.h"
#include "lwip/sockets.h"

static const char* TAG = "ZP";

void send_handshake(int sock, uint16_t pool_size, const zp_schema_t* schema) {
    zp_handshake_t hs = {0};
    hs.magic = 'Z';
    hs.byteord = (__BYTE_ORDER__ == __ORDER_BIG_ENDIAN__);
    hs.reserved = 0b101000;
    hs.pool_size = pool_size;
    hs.type_count = schema->type_count;
    hs.action_count = schema->action_count;

    send(sock, &hs, sizeof(hs), 0);
    ESP_LOGI(TAG, "Handshake header sent");

    for (int i = 0; i < schema->type_count; i++) {
        const struct_desc_t* t = &schema->types[i];

        send(sock, &t->id, sizeof(t->id), 0);
        send(sock, &t->count, sizeof(t->count), 0);
        send(sock, &t->size, sizeof(t->size), 0);
        send(sock, t->name, strlen(t->name) + 1, 0);

        for (int j = 0; j < t->count; j++) {
            const field_desc_t* f = &t->fields[j];

            send(sock, &f->type, sizeof(f->type), 0);
            send(sock, &f->offset, sizeof(f->offset), 0);
            send(sock, &f->length, sizeof(f->length), 0);
            send(sock, f->name, strlen(f->name) + 1, 0);
        }
    }

    ESP_LOGI(TAG, "Types sent");

    for (int i = 0; i < schema->action_count; i++) {
        const action_desc_t* a = &schema->actions[i];

        send(sock, &a->type, sizeof(a->type), 0);
        send(sock, &a->is_array, sizeof(a->is_array), 0);
        send(sock, a->name, strlen(a->name) + 1, 0);
    }
}
