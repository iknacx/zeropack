idf_component_register(
  SRCS "firmware.c"
  INCLUDE_DIRS "."
  REQUIRES
    nvs_flash esp_event
    lwip esp_wifi esp_netif
    zeropack)
