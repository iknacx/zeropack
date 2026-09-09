#import "@preview/bytefield:0.0.8": *

= Diseño de protocolo

== Handshake

Al iniciar la conexión con el microprocesador, este mandará toda la información
que está programada en él, como acciones, IDs de tipos de datos definidos, etc.

Una idea de lo que sería el handshake es esta:

#bytefield(
  // Config the header
  bitheader(
    "bytes",

    text-size: 8pt, // length (default: global header_font_size or 9pt)
  ),
  // Add data fields (bit, bits, byte, bytes) and notes
  // A note always aligns on the same row as the start of the next data field.
  bits(6, "version"),
  flag(text(8pt, "ORD")),
  flag(text(8pt, "DYN")),
  byte[ID],

  bytes(2, "cant. de acciones"),
  bytes(2, "cant. de tipos"),
  bytes(2, "tamaño de pool"),
  bytes(4, "Acciones ..."),
  bytes(4, "Descripción de tipos ..."),
)

Luego de los 6 bits de la versión se encuentran:
- *ORD*: el orden de los bytes (`little endian = 0`, `big endian = 1`)
- *DYN*: indica que el dispositivo puede usar memoria dinámica

== Paquetes

=== Header

Para identificar cada paquete, se usará un encabezado el que incluye la
siguiente información:

- *action*: comando enviado desde otro dispositivo para que el microprocesador
  haga cierta acción, definida por el mismo.
- *is_struct*: tipo booleano que indica que el tipo de dato en la transferencia
  es un `struct` definido con una ID.
- *type*: indica la ID del `struct` si `is_struct` es `1`, sino, la ID del tipo
  de dato nativo.
- *is_array*: tipo booleano que indica si el tipo es un arreglo
- *length*: si el tipo es un arreglo (`is_array = 1`), indica cuantos datos de
  tipo `type` contiene, la cantidad máxima es de `32767` debido a que son 15
  bits, este atributo es 0 cuando el tipo no es arreglo.

#bytefield(
  bitheader(
    "bytes",
    text-size: 8pt, // length (default: global header_font_size or 9pt)
  ),
  bytes(1, "acción"),
  flag(text(8pt, "STR")),
  bits(7, "id del tipo"),
  flag(text(8pt, "ARR")),
  bits(15, "tamaño del array"),
)

Así es como se ve el header, al que lo acompaña el payload

```c
typedef union {
    uint32_t raw;

    struct {
        uint32_t action     : 8;
        uint32_t is_struct  : 1;
        uint32_t type       : 7;
        uint32_t is_array   : 1;
        uint32_t length     : 15;
    } __attribute__((packed));
} Header;
```




