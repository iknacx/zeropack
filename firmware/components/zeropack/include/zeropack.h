#pragma once

#include <stdint.h>

typedef struct {
    uint8_t type;
    uint16_t offset;
    const char* name;
} field_desc_t;

typedef struct {
    uint8_t id;
    uint8_t count;
    uint16_t size;
    const field_desc_t* fields;
} struct_desc_t;

typedef struct {
    uint8_t type;
    uint8_t is_array;
    const char* name;
} action_desc_t;
