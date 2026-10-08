idf_component_register(
  SRCS
    "src/firmware.c"
    "src/wifi.c"
  INCLUDE_DIRS "include"
  REQUIRES
    nvs_flash esp_event
    lwip esp_wifi esp_netif
    zeropack)
