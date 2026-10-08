#include <stdint.h>
#include <sys/unistd.h>
#include <unistd.h>

#include "driver/rmt_tx.h"
#include "driver/rmt_types.h"
#include "esp_err.h"
#include "esp_log.h"
#include "esp_log_buffer.h"
#include "soc/clk_tree_defs.h"
#include "wifi.h"
#include "zeropack.h"

#define ADDR "192.168.100.2"
#define PORT 1234

#define COLOR_FIELDS(S, F, A) \
    F(S, u8, r)               \
    F(S, u8, g)               \
    F(S, u8, b)

// Lista de tipos para usar
#define TYPES(X) X(color_t, COLOR_FIELDS)

// Acciones del microcontrolador
#define ACTIONS(V, T, A)         \
    V(ACTION_LED_ON)             \
    V(ACTION_LED_OFF)            \
    T(ACTION_LED_COLOR, color_t) \
    A(ACTION_ECHO, u8, 16)

// Finalizar con la creación de los tipos y acciones
ZP_DECLARE(TYPES, ACTIONS)
ZP_GENERATE_SCHEMA(TYPES, ACTIONS)

static const char* TAG = "app";

static rmt_channel_handle_t s_led_chan = NULL;
static rmt_encoder_handle_t s_led_encoder = NULL;

static color_t s_color = {0};

static void init_rgb_led(void) {
    rmt_tx_channel_config_t cfg = {
        .clk_src = RMT_CLK_SRC_DEFAULT,
        .gpio_num = 8,
        .mem_block_symbols = 64,
        .resolution_hz = 10 * 1000 * 1000,
        .trans_queue_depth = 4,
    };

    ESP_ERROR_CHECK(rmt_new_tx_channel(&cfg, &s_led_chan));

    rmt_bytes_encoder_config_t enc_cfg = {
        .bit0 = {.level0 = 1, .duration0 = 4, .level1 = 0, .duration1 = 8},
        .bit1 = {.level0 = 1, .duration0 = 8, .level1 = 0, .duration1 = 4},
        .flags.msb_first = 1,
    };
    ESP_ERROR_CHECK(rmt_new_bytes_encoder(&enc_cfg, &s_led_encoder));
    ESP_ERROR_CHECK(rmt_enable(s_led_chan));
}

static void set_color(color_t color) {
    uint8_t grb[3] = {color.g, color.r, color.b};
    rmt_transmit_config_t cfg = {.loop_count = 0};
    rmt_transmit(s_led_chan, s_led_encoder, grb, sizeof(grb), &cfg);
    rmt_tx_wait_all_done(s_led_chan, -1);
}

static void handle_led_on(void) {
    ESP_LOGI(TAG, "LED ON (R:%u G:%u B:%u)", s_color.r, s_color.g, s_color.b);
    set_color(s_color);
}

static void handle_led_off(void) {
    ESP_LOGI(TAG, "LED OFF");
    set_color((color_t){0});
}

static void handle_led_color(const color_t* color) {
    s_color = *color;
    ESP_LOGI(
        TAG, "Nuevo color -> R:%u G:%u B:%u", color->r, color->g, color->b
    );
    set_color(s_color);
}

static void handle_echo(const uint8_t* data, uint16_t len) {
    ESP_LOGI(TAG, "echo (%u bytes):", len);
    ESP_LOG_BUFFER_HEX(TAG, data, len);

    zp_emit(ACTION_ECHO, data, len);
}

void app_main(void) {
    init_rgb_led();
    wifi_init();

    zp_on_action(ACTION_LED_ON, handle_led_on);
    zp_on_action(ACTION_LED_OFF, handle_led_off);
    zp_on_action(ACTION_LED_COLOR, handle_led_color);
    zp_on_action(ACTION_ECHO, handle_echo);

    zp_start(ADDR, PORT, 0, &zp_schema);
}
