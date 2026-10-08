#include "zeropack.h"

#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <sys/unistd.h>

#include "cc.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/idf_additions.h"
#include "lwip/inet.h"
#include "lwip/sockets.h"
#include "portmacro.h"

#define ZP_STACK_SIZE 4096
#define ZP_BUFFER_SIZE 256

static const char* TAG = "ZP";

static StackType_t zp_rx_stack[ZP_STACK_SIZE];
static StaticTask_t zp_rx_tcb;
static uint8_t zp_rx_buffer[ZP_BUFFER_SIZE] __attribute__((aligned(4)));

static int s_sock = -1;
static struct {
    struct sockaddr_in addr;
    uint16_t pool_size;
    const zp_schema_t* schema;
} s_cfg;

void send_handshake(int sock, uint16_t pool_size, const zp_schema_t* schema) {
    zp_handshake_t hs = {0};
    hs.magic = 'Z';
    hs.byteord = (__BYTE_ORDER__ == __ORDER_BIG_ENDIAN__);
    hs.reserved = 0b101000;
    hs.pool_size = pool_size;
    hs.type_count = schema->type_count;
    hs.action_count = schema->action_count;

    send(sock, &hs, sizeof(hs), 0);
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

    for (int i = 0; i < schema->action_count; i++) {
        const action_desc_t* a = &schema->actions[i];

        send(sock, &a->type, sizeof(a->type), 0);
        send(sock, &a->is_array, sizeof(a->is_array), 0);
        send(sock, a->name, strlen(a->name) + 1, 0);
    }
}

#define ZP_PRIM_SIZE(type) sizeof(type),
static const uint8_t s_prim_sizes[] = {0, ZP_PRIMITIVES(ZP_PRIM_SIZE)};

static size_t get_type_size(uint8_t type_id) {
    if (type_id == 0) return 0;
    if (type_id < sizeof(s_prim_sizes)) return s_prim_sizes[type_id];

    uint8_t idx = type_id - sizeof(s_prim_sizes) - 1;
    if (s_cfg.schema && idx < s_cfg.schema->type_count)
        return s_cfg.schema->types[idx].size;

    return 0;
}

static void zp_rx_task(void* pvParameters) {
    (void)pvParameters;

    bool waiting_logged = false;
    while (1) {
        int sock = socket(AF_INET, SOCK_STREAM, IPPROTO_IP);
        if (sock < 0) {
            ESP_LOGE(TAG, "Could not open socket: %d", sock);
            vTaskDelay(pdMS_TO_TICKS(1500));
            continue;
        }

        if (connect(sock, (struct sockaddr*)&s_cfg.addr, sizeof(s_cfg.addr)) !=
            0) {
            if (!waiting_logged) {
                ESP_LOGW(TAG, "Waiting for server..");
                waiting_logged = true;
            }
            close(sock);
            vTaskDelay(pdMS_TO_TICKS(1500));
            continue;
        }

        waiting_logged = false;

        s_sock = sock;
        send_handshake(sock, s_cfg.pool_size, s_cfg.schema);

        size_t buffered = 0;
        ESP_LOGI(TAG, "Listening to packets from socket %u", sock);

        while (1) {
            ssize_t len = recv(
                sock, zp_rx_buffer + buffered, ZP_BUFFER_SIZE - buffered, 0
            );

            if (len < 0) {
                ESP_LOGE(TAG, "recv error: errno %d", errno);
                break;
            } else if (len == 0) {
                ESP_LOGW(TAG, "Server disconnected");
                break;
            }

            buffered += (size_t)len;

            while (buffered >= sizeof(zp_header_t)) {
                const zp_header_t* hdr = (const zp_header_t*)zp_rx_buffer;

                if (!s_cfg.schema ||
                    hdr->action >= s_cfg.schema->action_count) {
                    ESP_LOGW(TAG, "Invalid action: %u", hdr->action);
                    buffered = 0;
                    break;
                }

                const action_desc_t* act = &s_cfg.schema->actions[hdr->action];
                size_t payload_len =
                    act->is_array
                        ? (size_t)hdr->array_len * get_type_size(act->type)
                        : get_type_size(act->type);

                size_t total_packet_len = sizeof(zp_header_t) + payload_len;

                if (total_packet_len > ZP_BUFFER_SIZE) {
                    ESP_LOGE(TAG, "Packet exceeds ZP_BUFFER_SIZE");
                    buffered = 0;
                    break;
                }

                if (buffered < total_packet_len) break;

                const uint8_t* payload = zp_rx_buffer + sizeof(zp_header_t);
                if (!s_cfg.schema->dispatch(hdr, payload, payload_len)) {
                    ESP_LOGW(
                        TAG,
                        "Action '%s' (ID: %u) received, but no hook registered",
                        act->name,
                        act->type
                    );
                }

                size_t remaining = buffered - total_packet_len;
                if (remaining > 0)
                    memmove(
                        zp_rx_buffer, zp_rx_buffer + total_packet_len, remaining
                    );

                buffered = remaining;
            }
        }

        s_sock = -1;
        close(sock);
        vTaskDelay(pdMS_TO_TICKS(1500));
    }
}

int zp_start(
    const char* ip, uint16_t port, uint16_t pool_size, const zp_schema_t* schema
) {
    s_cfg.addr = (struct sockaddr_in){
        .sin_family = AF_INET,
        .sin_port = htons(port),
        .sin_addr.s_addr = inet_addr(ip),
    };
    s_cfg.pool_size = pool_size;
    s_cfg.schema = schema;

    xTaskCreateStatic(
        zp_rx_task, "zp_rx", ZP_STACK_SIZE, NULL, 5, zp_rx_stack, &zp_rx_tcb
    );

    return 0;
}

ssize_t zp_send(
    uint8_t action,
    uint8_t type_id,
    uint16_t len,
    const void* payload,
    size_t size
) {
    if (s_sock < 0) return -1;

    zp_header_t hdr = {
        .action = action,
        .type_id = type_id,
        .is_array = (len > 0) ? 1 : 0,
        .array_len = len,
    };

    if (payload == NULL || size == 0) {
        return send(s_sock, &hdr, sizeof(zp_header_t), 0);
    }

    struct iovec iov[2] = {
        {.iov_base = &hdr, .iov_len = sizeof(zp_header_t)},
        {.iov_base = (void*)payload, .iov_len = size},
    };

    return lwip_writev(s_sock, iov, 2);
}
