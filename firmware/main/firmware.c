#include <stdint.h>
#include <string.h>
#include <unistd.h>

#include "cc.h"
#include "esp_err.h"
#include "esp_event.h"
#include "esp_event_base.h"
#include "esp_log.h"
#include "esp_netif.h"
#include "esp_netif_ip_addr.h"
#include "esp_netif_types.h"
#include "esp_wifi.h"
#include "esp_wifi_types_generic.h"
#include "freertos/idf_additions.h"
#include "freertos/projdefs.h"
#include "lwip/inet.h"
#include "lwip/sockets.h"
#include "nvs.h"
#include "nvs_flash.h"
#include "portmacro.h"
#include "sdkconfig.h"
#include "zeropack.h"

// Tipo de prueba
#define TYPE_FIELDS(S, F, A) \
    F(S, u32, f1)            \
    F(S, u8, f2)             \
    A(S, u16, f3, 16)

// Lista de tipos para usar
#define TYPES(X) X(test_type_t, TYPE_FIELDS)

// Acciones del microcontrolador
#define ACTIONS(V, T, A) \
    V(ACTION_LED_ON)     \
    V(ACTION_LED_OFF)    \
    A(ACTION_ECHO, u8, 16)

// Finalizar con la creación de los tipos y acciones
ZP_DECLARE(TYPES, ACTIONS)
ZP_GENERATE_SCHEMA(TYPES, ACTIONS)

// FIXME: buscar una mejor manera de guardar esto
#define ADDR "192.168.100.2"
#define PORT 1234

static EventGroupHandle_t s_wifi_event_group;
#define WIFI_CONNECTED_BIT BIT0

static void event_handler(void* arg, esp_event_base_t event_base, int32_t event_id, void* data) {
    static const char* TAG = "event";
    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
        ESP_LOGI(TAG, "Wi-Fi started, connecting..");
        esp_wifi_connect();
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
        ESP_LOGW(TAG, "Wi-Fi disconnected, reconnecting..");
        esp_wifi_connect();
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        ip_event_got_ip_t* event = data;
        ESP_LOGI(TAG, "Got IP address: " IPSTR, IP2STR(&event->ip_info.ip));
        xEventGroupSetBits(s_wifi_event_group, WIFI_CONNECTED_BIT);
    }
}

void wifi_init_sta(void) {
    s_wifi_event_group = xEventGroupCreate();
    esp_netif_create_default_wifi_sta();

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));

    wifi_config_t wifi_config = {
        .sta.ssid = CONFIG_WIFI_SSID,
        .sta.password = CONFIG_WIFI_PASS,
        .sta.threshold.authmode = WIFI_AUTH_WPA2_PSK,
    };

    esp_event_handler_instance_register(WIFI_EVENT, ESP_EVENT_ANY_ID, &event_handler, NULL, NULL);
    esp_event_handler_instance_register(IP_EVENT, IP_EVENT_STA_GOT_IP, &event_handler, NULL, NULL);

    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &wifi_config));
    ESP_ERROR_CHECK(esp_wifi_start());

    xEventGroupWaitBits(s_wifi_event_group, WIFI_CONNECTED_BIT, pdFALSE, pdFALSE, portMAX_DELAY);
}

void tcp_connection(void) {
    static const char* TAG = "tcp_conn";
    int sock = socket(AF_INET, SOCK_STREAM, IPPROTO_IP);
    if (sock < 0) {
        ESP_LOGE(TAG, "Could not open socket: %d", sock);
        return;
    }

    struct sockaddr_in addr;
    addr.sin_addr.s_addr = inet_addr(ADDR);
    addr.sin_family = AF_INET;
    addr.sin_port = htons(PORT);

    if (connect(sock, (struct sockaddr*)&addr, sizeof(addr)) != 0) {
        ESP_LOGE(TAG, "Could not connect to %s:%d", ADDR, PORT);
        close(sock);
        return;
    }

    send_handshake(sock, 0, &zp_schema);

    close(sock);
}

void app_main(void) {
    static const char* TAG = "main";

    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    ESP_ERROR_CHECK(esp_netif_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());

    wifi_init_sta();

    ESP_LOGI(TAG, "type count: %d", zp_schema.type_count);
    for (int i = 0; i < zp_schema.type_count; i++) {
        const struct_desc_t* t = &zp_schema.types[i];
        ESP_LOGI(TAG, "type %s (ID: %d)", t->name, t->id);
        for (int j = 0; j < t->count; j++) {
            const field_desc_t* f = &t->fields[j];
            ESP_LOGI(TAG, "\tfield %s", f->name);
        }
    }

    for (int i = 0; i < zp_schema.action_count; i++) {
        const action_desc_t* a = &zp_schema.actions[i];
        ESP_LOGI(TAG, "action %s (payload type: %d, array?: %d)", a->name, a->type, a->is_array);
    }

    tcp_connection();
}
