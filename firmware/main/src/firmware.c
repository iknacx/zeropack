#include <sys/unistd.h>
#include <unistd.h>

#include "esp_log.h"
#include "wifi.h"
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

#define ADDR "192.168.100.2"
#define PORT 1234

void app_main(void) {
    static const char* TAG = "main";

    wifi_init();

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
        ESP_LOGI(
            TAG,
            "action %s (payload type: %d, array?: %d)",
            a->name,
            a->type,
            a->is_array
        );
    }

    zp_start(ADDR, PORT, 0, &zp_schema);
}
