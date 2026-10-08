#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

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

typedef bool (*zp_dispatch_fn_t)(
    const zp_header_t* hdr, const uint8_t* payload, size_t len
);

typedef struct {
    const struct_desc_t* types;
    uint16_t type_count;
    const action_desc_t* actions;
    uint16_t action_count;
    zp_dispatch_fn_t dispatch;
} zp_schema_t;

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
#define ZP_DECLARE_ACTION_IDS(ActionsMacro)                       \
    typedef enum {                                                \
        ActionsMacro(GEN_ACTION_ID, GEN_ACTION_ID, GEN_ACTION_ID) \
            ACTION_ID_MAX                                         \
    } action_id_t;

#define ZP_CB_TYPE_V(name) typedef void (*zp_cb_##name##_t)(void);
#define ZP_CB_TYPE_T(name, type) \
    typedef void (*zp_cb_##name##_t)(const type* data);
#define ZP_CB_TYPE_A(name, type) \
    typedef void (*zp_cb_##name##_t)(const type* data, uint16_t len);

#define ZP_DECLARE_CALLBACKS(ActionsMacro)       \
    ActionsMacro(                                \
        ZP_CB_TYPE_V, ZP_CB_TYPE_T, ZP_CB_TYPE_A \
    ) extern void (*__zp_callbacks[ACTION_ID_MAX])(void);

#define ZP_INLINE __attribute__((unused, always_inline)) static inline
#define ZP_SEND_FN_V(name)                              \
    ZP_INLINE ssize_t __zp_emit_##name(void) {          \
        return zp_send(name, TYPE_ID_NONE, 0, NULL, 0); \
    }

#define ZP_SEND_FN_T(name, type)                                     \
    ZP_INLINE ssize_t __zp_emit_##name(const type* data) {           \
        return zp_send(name, TYPE_ID_##type, 0, data, sizeof(type)); \
    }

#define ZP_SEND_FN_A(name, type)                                         \
    ZP_INLINE ssize_t __zp_emit_##name(const type* data, uint16_t len) { \
        return zp_send(                                                  \
            name, TYPE_ID_##type, len, data, (size_t)len * sizeof(type)  \
        );                                                               \
    }
#define ZP_DECLARE_SENDERS(ActionsMacro) \
    ActionsMacro(ZP_SEND_FN_V, ZP_SEND_FN_T, ZP_SEND_FN_A)

#define ZP_DECLARE(TypesMacro, ActionsMacro) \
    ZP_DECLARE_STRUCTS(TypesMacro)           \
    ZP_DECLARE_TYPE_IDS(TypesMacro)          \
    ZP_DECLARE_ACTION_IDS(ActionsMacro)      \
    ZP_DECLARE_CALLBACKS(ActionsMacro)       \
    ZP_DECLARE_SENDERS(ActionsMacro)

#define zp_on_action(action_name, fn)                       \
    do {                                                    \
        zp_cb_##action_name##_t _chk = (fn);                \
        __zp_callbacks[action_name] = (void (*)(void))_chk; \
    } while (0)

#define FIELD_DESC(S, type, name) {TYPE_ID_##type, offsetof(S, name), 0, #name},
#define ARRAY_DESC(S, type, name, len) \
    {TYPE_ID_##type, offsetof(S, name), len, #name},

#define MAKE_STRUCT_META(StructName, FieldsMacro)                 \
    {.id = TYPE_ID_##StructName,                                  \
     .size = sizeof(StructName),                                  \
     .count = sizeof((const field_desc_t[]){                      \
                  FieldsMacro(StructName, FIELD_DESC, ARRAY_DESC) \
              }) /                                                \
              sizeof(field_desc_t),                               \
     .name = #StructName,                                         \
     .fields = (const field_desc_t[]){                            \
         FieldsMacro(StructName, FIELD_DESC, ARRAY_DESC)          \
     }},

#define ACTION_V(name) {TYPE_ID_NONE, 0, #name},
#define ACTION_T(name, type) {TYPE_ID_##type, 0, #name},
#define ACTION_A(name, type) {TYPE_ID_##type, 1, #name},

#define ZP_DISPATCH_V(name)                             \
    case name:                                          \
        if (__zp_callbacks[name]) {                     \
            ((zp_cb_##name##_t)__zp_callbacks[name])(); \
            return true;                                \
        }                                               \
        return false;

#define ZP_DISPATCH_T(name, type)                                           \
    case name:                                                              \
        if (__zp_callbacks[name] && len >= sizeof(type)) {                  \
            ((zp_cb_##name##_t)__zp_callbacks[name])((const type*)payload); \
            return true;                                                    \
        }                                                                   \
        return false;

#define ZP_DISPATCH_A(name, type)                           \
    case name:                                              \
        if (__zp_callbacks[name] &&                         \
            len >= (size_t)hdr->array_len * sizeof(type)) { \
            ((zp_cb_##name##_t)__zp_callbacks[name])(       \
                (const type*)payload, hdr->array_len        \
            );                                              \
            return true;                                    \
        }                                                   \
        return false;

// clang-format off
#define ZP_GENERATE_SCHEMA(TypesMacro, ActionsMacro)                    \
    void (*__zp_callbacks[ACTION_ID_MAX])(void) = {0};                  \
                                                                        \
    static bool __zp_dispatch(                                          \
        const zp_header_t* hdr, const uint8_t* payload, size_t len      \
    ) {                                                                 \
        switch (hdr->action) {                                          \
            ActionsMacro(ZP_DISPATCH_V, ZP_DISPATCH_T, ZP_DISPATCH_A)   \
            default:                                                    \
                return false;                                           \
        }                                                               \
    }                                                                   \
                                                                        \
    static const struct_desc_t __zp_types[] = {                         \
      TypesMacro(MAKE_STRUCT_META)                                      \
    };                                                                  \
    static const action_desc_t __zp_actions[] = {                       \
        ActionsMacro(ACTION_V, ACTION_T, ACTION_A)                      \
    };                                                                  \
                                                                        \
    const zp_schema_t zp_schema = {                                     \
        .types = __zp_types,                                            \
        .type_count = sizeof(__zp_types) / sizeof(__zp_types[0]),       \
        .actions = __zp_actions,                                        \
        .action_count = sizeof(__zp_actions) / sizeof(__zp_actions[0]), \
        .dispatch = __zp_dispatch,                                      \
    };
// clang-format on

#define zp_emit(action_name, ...) __zp_emit_##action_name(__VA_ARGS__)

int zp_start(
    const char* ip, uint16_t port, uint16_t pool_size, const zp_schema_t* schema
);

ssize_t zp_send(
    uint8_t action,
    uint8_t type_id,
    uint16_t len,
    const void* payload,
    size_t size
);
