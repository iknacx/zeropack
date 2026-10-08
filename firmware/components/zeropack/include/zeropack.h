#pragma once

#include <stddef.h>
#include <stdint.h>

// clang-format off
typedef int8_t   s8;
typedef uint8_t  u8;
typedef int16_t  s16;
typedef uint16_t u16;
typedef int32_t  s32;
typedef uint32_t u32;
typedef int64_t  s64;
typedef uint64_t u64;
typedef float    f32;
typedef double   f64;
typedef char*    poolstr_t;
#define ZP_PRIMITIVES(X) \
    X(u8) X(u16) X(u32) X(u64) \
    X(s8) X(s16) X(s32) X(s64) \
    X(f32) X(f64) X(bool) X(poolstr_t)
// clang-format on

typedef struct {
    uint8_t type;
    uint16_t offset;
    uint16_t length;
    const char* name;
} field_desc_t;

typedef struct {
    uint8_t id;
    uint8_t count;
    uint16_t size;
    const char* name;
    const field_desc_t* fields;
} struct_desc_t;

typedef struct {
    uint8_t type;
    uint8_t is_array;
    const char* name;
} action_desc_t;

typedef struct {
    const struct_desc_t* types;
    uint16_t type_count;
    const action_desc_t* actions;
    uint16_t action_count;
} zp_schema_t;

typedef struct __attribute__((packed)) {
    uint8_t magic;
    uint8_t byteord : 1;
    uint8_t reserved : 7;

    uint16_t pool_size;
    uint16_t type_count;
    uint16_t action_count;
} zp_handshake_t;

typedef struct __attribute__((packed)) {
    uint8_t action;
    uint8_t type_id;
    uint16_t is_array : 1;
    uint16_t array_len : 15;
} zp_header_t;

#define MAKE_FIELD(S, type, name) type name;
#define MAKE_ARRAY(S, type, name, len) type name[len];
#define DEFINE_TYPE(StructName, FieldsMacro)            \
    typedef struct StructName {                         \
        FieldsMacro(StructName, MAKE_FIELD, MAKE_ARRAY) \
    } StructName;

#define ZP_DECLARE_STRUCTS(TypesMacro) TypesMacro(DEFINE_TYPE)

#define GEN_TYPE_ID(name, ...) TYPE_ID_##name,
#define ZP_DECLARE_TYPE_IDS(TypesMacro)           \
    typedef enum {                                \
        TYPE_ID_NONE = 0,                         \
        ZP_PRIMITIVES(GEN_TYPE_ID) TYPE_ID_START, \
        TypesMacro(GEN_TYPE_ID) TYPE_ID_MAX,      \
    } type_id_t;

#define GEN_ACTION_ID(name, ...) name,
#define ZP_DECLARE_ACTION_IDS(ActionsMacro)                                     \
    typedef enum {                                                              \
        ActionsMacro(GEN_ACTION_ID, GEN_ACTION_ID, GEN_ACTION_ID) ACTION_ID_MAX \
    } action_id_t;

#define ZP_DECLARE(TypesMacro, ActionsMacro) \
    ZP_DECLARE_STRUCTS(TypesMacro)           \
    ZP_DECLARE_TYPE_IDS(TypesMacro)          \
    ZP_DECLARE_ACTION_IDS(ActionsMacro)

#define FIELD_DESC(S, type, name) {TYPE_ID_##type, offsetof(S, name), 0, #name},
#define ARRAY_DESC(S, type, name, len) {TYPE_ID_##type, offsetof(S, name), len, #name},

#define MAKE_STRUCT_META(StructName, FieldsMacro)                                               \
    {.id = TYPE_ID_##StructName,                                                                \
     .size = sizeof(StructName),                                                                \
     .count = sizeof((const field_desc_t[]){FieldsMacro(StructName, FIELD_DESC, ARRAY_DESC)}) / \
              sizeof(field_desc_t),                                                             \
     .name = #StructName,                                                                       \
     .fields = (const field_desc_t[]){FieldsMacro(StructName, FIELD_DESC, ARRAY_DESC)}},

#define ACTION_V(name) {TYPE_ID_NONE, 0, #name},
#define ACTION_T(name, type) {TYPE_ID_##type, 0, #name},
#define ACTION_A(name, type, ...) {TYPE_ID_##type, 1, #name},
// clang-format off
#define ZP_GENERATE_SCHEMA(TypesMacro, ActionsMacro)                    \
    __attribute__((unused))                                             \
    static inline void __zp_require_top_level(void) {}                  \
                                                                        \
    static const struct_desc_t __zp_types[] = {                         \
        TypesMacro(MAKE_STRUCT_META)                                    \
    };                                                                  \
    static const action_desc_t __zp_actions[] = {                       \
        ActionsMacro(ACTION_V, ACTION_T, ACTION_A)                      \
    };                                                                  \
                                                                        \
    const zp_schema_t zp_schema = {                                     \
        .types = __zp_types,                                            \
        .type_count = sizeof(__zp_types) / sizeof(__zp_types[0]),       \
        .actions = __zp_actions,                                        \
        .action_count = sizeof(__zp_actions) / sizeof(__zp_actions[0])  \
    };
// clang-format on

int zp_start(const char* ip, uint16_t port, uint16_t pool_size, const zp_schema_t* schema);
