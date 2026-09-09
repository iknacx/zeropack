#import "@preview/timeliney:0.4.0"

#show figure: set block(breakable: true)

#let w(n) = align(center)[#text(size: 8pt)[#n]]
#let r(text) = table.cell(fill: red.lighten(60%))[#text];
#let g(text) = table.cell(fill: green.lighten(60%))[#text];
#let y(text) = table.cell(fill: yellow.lighten(60%))[#text];

= Metodología

== Comparación de Metodologías

El desarrollo de este proyecto, al ser una investigación técnica a bajo nivel (I+D) ejecutada por un único autor, impone restricciones operativas que las metodologías de software tradicionales no suelen contemplar. Para definir el marco de trabajo adecuado, se contrastaron tres enfoques estándar de la industria (Cascada, Iterativo e Incremental, y Kanban) a través de dos matrices, ponderando factores críticos como la adaptabilidad frente al hardware y la sobrecarga administrativa.

#figure(
  table(
    columns: 5,
    align: left,
    table.header([*Factor de Selección*], [*Peso*], [*Cascada*], [*Iterativo/Incremental*], [*Kanban*]),

    [*Adaptabilidad ante hallazgos técnicos* (pivoteo)], [0.3], [1], [3], [3],
    [*Baja sobrecarga administrativa* (trabajo individual)], [0.3], [2], [3], [3],
    [*Control temporal mediante hitos* (ciclos de prueba)], [0.2], [1], [3], [1],
    [*Gestión visual del flujo de trabajo*], [0.2], [1], [1], [3],
    [*Puntaje Ponderado Total*], [1.0], [1.0], [2.6], [2.6],
  ),
  caption: [Matriz cuantitativa de selección de metodologías],
)

#figure(
  table(
    columns: 4,
    align: left,
    table.header([*Criterio*], [*Cascada*], [*Iterativo/Incremental*], [*Kanban*]),

    [*Definición de requisitos*], r[Rígida y secuencial.], g[Evolutiva por cada iteración.], g[Evolutiva y constante.],

    [*Cadencia de trabajo*],
    r[Inexistente; ciclo único largo.],
    g[Iteraciones fijas (ej. 2 semanas).],
    r[Flujo continuo sin cortes temporales.],

    [*Gestión de tareas*],
    y[Documentación pesada.],
    y[Enfoque en hitos y entregables.],
    g[Tablero visual y límites WIP.],

    [*Sobrecarga de gestión*],
    y[Alta burocracia de informes.],
    g[Baja; sin ceremonias grupales.],
    g[Mínima; ideal para un solo desarrollador.],
  ),
  caption: [Matriz cualitativa de selección de metodologías],
)

=== Justificación de la selección (Iterativo-Incremental + Kanban)

La evaluación de las metodologías reveals que ninguna resuelve el problema de forma aislada: Cascada es demasiado rígida, Kanban carece de fechas de corte forzosas, y los enfoques iterativos a menudo carecen de herramientas de gestión visual diaria. Además, los marcos corporativos exigen ceremonias inviables para un proyecto individual.

Frente a este escenario, se adoptó una metodología híbrida minimalista. En lugar de implementar un marco de trabajo corporativo completo, se extrajeron y ensamblaron únicamente los componentes estrictamente necesarios para el desarrollo del protocolo:

- *Desarrollo Iterativo e Incremental (Timeboxing e Hitos de Control):* Se adoptan iteraciones fijas de dos semanas. Se descartan por completo los roles corporativos y las reuniones de coordinación. Estos ciclos funcionan exclusivamente como bloques de tiempo temporales (*timeboxing*) donde el código debe compilarse y probarse para generar un incremento funcional del que se extraen métricas empíricas de memoria y red.
- *Kanban (Flujo visual y Límites WIP):* El desarrollo se gestiona mediante un tablero continuo (_To Do, Doing, Testing, Done_). Se aplican Límites de Trabajo en Progreso (WIP) estrictos para evitar la dispersión técnica, obligando al autor a estabilizar un módulo (ej. el serializador) antes de escribir el código del siguiente (ej. sockets de red).

Esta reestructuración garantiza un ritmo de validación empírica constante, adaptándose perfectamente al trabajo de un desarrollador en solitario y enfocando todo el esfuerzo de ingeniería en la eficiencia del protocolo binario.

== Herramientas y ambiente de desarrollo

Para la implementación y validación del protocolo binario propuesto, el entorno
de desarrollo se ha estructurado en tres categorías principales (hardware,
software y herramientas de instrumentación), asegurando control absoluto sobre
los recursos a bajo nivel.

*Materiales (Hardware de pruebas)*
- *Microcontrolador objetivo:* dispositivo con arquitectura de 32 bits, y
  memoria SRAM limitada, que actuará como el nodo transmisor para las pruebas de
  fragmentación y latencia.

- *Servidor local (Backend):* computador de propósito general encargado de
  recibir los datos, ejecutar el entorno de telemetría y almacenar las métricas.

*Lenguajes y software base*
- *C:* lenguaje de programación de sistemas estándar de la industria de
  dispositivos embebidos. Se selecciona por su alta estabilidad, su nula
  dependencia de recolección de basura y su capacidad nativa de gestión manual y
  determinista de la memoria a bajo nivel.

- *Svelte:* framework UI y lenguaje para diseñar páginas web que se compila a
  javascript, usado para crear el dashboard de telemetría.

- *Node.js / Typescript:* entorno de ejecución para el servidor backend que
  actuará como receptor de datos de telemetría, controlador de base de datos.

*Herramientas y métodos de instrumentación*
- *Git:* sistema de control de versiones para gestionar incrementos del código.
- *Wireshark (analizador de paquetes de red):* utilizado para inspeccionar el
  tamaño real del payload a nivel de red, y verificar la ausencia de sobrecarga
  durante la transmisión.

== Plan de gestión de riesgos

#figure(
  table(
    columns: (1.5fr, 2fr, 2fr),
    align: left,
    [*Tipo de riesgo*], [*Descripción del riesgo*], [*Mitigación*],

    [Técnico (Hardware)],
    [
      Desbordamiento de memoria (OOM) o fragmentación al integrar la capa de red
      con el protocolo
    ],
    [
      Evitar completamente el uso de memoria dinámica, usar búferes lineales
      de tamaño definido cuando sea necesario
    ],

    [Técnico (Medición)],
    [
      La herramienta de medición interfiere con la velocidad real de
      procesamiento, alterando los resultados
    ],
    [
      Utilizar contadores de ciclos de reloj nativos del hardware en lugar de
      librerías de alto nivel para medir la latencia con impacto cero en el
      procesador
    ],

    [Gestión (Tiempo)],
    [
      Retraso en la codificación de un módulo, comprometiendo las fechas de
      los hitos de la carta gantt
    ],
    [
      Aplicar estrictamente los límites WIP de Kanban. Si un módulo se retrasa,
      se detiene el desarrollo de otras funcionalidades hasta solucionar el
      problema
    ],
  ),

  kind: table,
  caption: [Matriz de identificación y mitigación de riesgos],
)

== Plan de gestión de calidad y testing

Para garantizar que el protocolo binario cumpla con los criterios de éxito
estipulados frente a formatos estándar (JSON, Protobuf, CBOR), se realizarán
pruebas de calidad divididas en tres niveles:

1. *Pruebas unitarias (Unit Testing):* se implementarán pruebas aisladas
  directamente en el código fuente para verificar que las funciones de
  serialización y deserialización funcionen con un 100% de precisión y sin fugas
  de memoria.

2. *Pruebas de integración:* se validará la comunicación entre el
  microprocesador (cliente) y el backend (servidor), asegurando que los sockets
  TCP/UDP transmitan la trama binaria sin corrupción de datos.

3. *Pruebas de rendimiento (Benchmarking):* es el núcleo de la validación. Se
  ejecutarán ciclos de estrés procesando miles de estructuras de datos para
  capturar el delta de memoria RAM y los ciclos de CPU, comparando los
  resultados del protocolo propuesto contra las librerías estándar.


== Propuesta de controles y evidencia

Para dar trazabilidad al proyecto y demostrar la eficacia de la solución
propuesta se implementarán los siguientes controles y artefactos de evidencia
a lo largo del flujo del trabajo:

- *Control de versiones y código fuente:* Repositorio de código será publicado
  en GitHub como evidencia de las iteraciones de desarrollo, mostrando los
  commits asociados a cada incremento de la metodología.

- *Reportes de profiling:* Archivos de registro generados por el microprocesador
  durante la fase de mediciones, detallando los bytes exactos utilizados en el
  heap y los microsegundos consumidos por cada formato de serialización
  evaluado.

- *Dashboard de Telemetría*: Capturas de pantalla y registros de la base de
  datos del backend, evidenciando la recepción y correcta interpretación del
  payload recibido en tiempo real.

=== Incrementos de desarrollo

- *Fase de Diseño y Arquitectura (Pre-desarrollo):* Correspondiente a la actividad de Cap. III y Diseño Protocolo. Bloque de fundamentación teórica orientado al diseño estructural de cabeceras, modelado de tipos fijos y preparación del firmware base sin interactuar con la red.

- *Incremento 1: Implementación Protocolo*
  Desarrollo técnico en C nativo enfocado en los algoritmos críticos de codificación y decodificación binaria _zero-copy_ a través del uso estricto de punteros fijos.

- *Incremento 2: Integración Sockets TCP*
  Despliegue e integración del núcleo del protocolo dentro del ecosistema del microcontrolador físico mediante el framework ESP-IDF, FreeRTOS y el stack de red LwIP.

- *Incremento 3: Backend JS y BD*
  Construcción del entorno de servidor receptor asíncrono utilizando Node.js con TypeScript, activando canales de escucha TCP/HTTP puros y almacenamiento en base de datos SQLite.

- *Incremento 4: Dashboard Frontend*
  Programación de la interfaz gráfica web modular mediante Svelte encargada de procesar, computar y renderizar visualmente las métricas operativas de latencia y red.

- *Incremento 5: JSON vs Binario*
  Inclusión de los entornos de serialización y empaquetado comparativos (JSON, CBOR, Protobuf, MessagePack) dentro del firmware del dispositivo IoT para pruebas bajo un mismo payload.

- *Incremento 6: Captura de Métricas (Hito 2)*
  Ejecución sistemática de ciclos de estrés del hardware con el fin de adquirir de manera empírica las constantes del heap, perfilado de memoria y consumo de reloj de la CPU.

=== Product backlog

#figure(
  table(
    columns: (auto, 1.4fr, 3fr, auto),
    align: left,
    [*ID*], [*Fase*], [*Descripción de tarea técnica*], [*Incremento*],
    [T01], [Diseño y Arquitectura], [Definir especificación de cabeceras y tipos de datos del protocolo], [—],
    [T02], [Diseño y Arquitectura], [Escribir pruebas unitarias locales para validar alineamiento de memoria], [—],
    [T03], [Diseño y Arquitectura], [Diseño de arquitectura algorítmica], [—],
    [T04], [Desarrollo], [Programar funciones de serialización y deserialización _zero-copy_], [Inc. 1],
    [T05], [Desarrollo], [Ejecutar validación completa vía pruebas unitarias], [Inc. 1],
    [T06], [Desarrollo], [Configurar entorno ESP-IDF y rutinas de conexión Wi-Fi (LwIP)], [Inc. 2],
    [T07], [Desarrollo], [Implementar cliente TCP mediante tareas estáticas de FreeRTOS], [Inc. 2],
    [T08],
    [Plataforma de telemetría (Demostración de Protocolo)],
    [Crear servidor TCP/HTTP receptor en Node.js],
    [Inc. 3],

    [T09], [Plataforma de telemetría (Demostración de Protocolo)], [Implementar lógica de deserialización], [Inc. 3],
    [T10],
    [Plataforma de telemetría (Demostración de Protocolo)],
    [Definir persistencia en base de datos ligera (SQLite)],
    [Inc. 3],

    [T11],
    [Plataforma de telemetría (Demostración de Protocolo)],
    [Diseñar interfaz de gráficas dinámicas para latencia y tamaño],
    [Inc. 4],

    [T12], [Plataforma de telemetría (Demostración de Protocolo)], [Conectar _dashboard_ dinámico al backend], [Inc. 4],
    [T13], [Benchmarking], [Implementar formatos JSON, CBOR, Protobuf y MessagePack en ESP32], [Inc. 5],
    [T14], [Benchmarking], [Preparar _payload_ estandarizado para pruebas comparativas], [Inc. 5],
    [T15], [Benchmarking], [Implementar mediciones de uso de memoria y ciclos de CPU], [Inc. 6],
    [T16], [Benchmarking], [Ejecutar pruebas de estrés computacional y exportar resultados], [Inc. 6],
    [T17], [Análisis y Cierre], [Analizar registros empíricos y métricas de telemetría], [—],
    [T18], [Análisis y Cierre], [Redactar evaluación comparativa final], [—],
    [T19], [Análisis y Cierre], [Definir conclusiones del proyecto], [—],
  ),
  caption: [Definición del Product Backlog (Alineación Completa)],
)


#pagebreak()

== Arquitectura y Diseño del Protocolo Propuesto

El diseño del protocolo se basa en cuatro mecanismos clave para evitar la fragmentación de memoria y reducir la carga de procesamiento en el microcontrolador:

- *Arquitectura orientada a comandos (OpCodes):* Se reemplaza el envío de árboles de datos complejos por un formato simple de instrucción y carga útil (`OpCode` + `Datos`). Esto permite que el procesador identifique qué estructura viene en el paquete leyendo un solo identificador numérico, enrutando la información de forma inmediata sin tener que analizar texto.
- *Negociación dinámica (Handshake):* Cliente y servidor sincronizan sus estructuras de datos al inicio de la conexión. Esto elimina la necesidad de depender de archivos descriptores externos o precompilados en el dispositivo, manteniendo el sistema ligero y adaptable.
- *Lectura directa por aritmética de punteros (Zero-Copy):* En lugar de usar funciones tradicionales para copiar datos byte a byte hacia nuevas variables, el sistema mapea las estructuras lógicas directamente sobre el búfer de red entrante. Esto permite extraer la información en tiempo $O(1)$, anulando el costo de procesamiento por copiado.
- *Gestión estática de cadenas (String Pool):* Para no utilizar memoria dinámica al transferir textos, las cadenas se almacenan en un bloque de memoria fijo (_Arena Allocator_). El protocolo solo transmite punteros opacos (identificadores validados), lo que asegura una lectura rápida y protege al sistema contra desbordamientos.

== Diseño de Plataforma de Telemetría e Instrumentación

Para medir el rendimiento del protocolo en un entorno real y respaldar los objetivos del proyecto, se construirá una plataforma de telemetría dividida en tres capas:

- *Servidor de recepción (Node.js):* Un servicio asíncrono TCP/HTTP que actuará como punto de recolección. Se encargará de recibir los datos desde el microcontrolador y aplicar la lógica de deserialización para traducir los binarios en métricas legibles.
- *Capa de persistencia (SQLite):* Una base de datos ligera donde se registrará el histórico de las pruebas (ciclos de CPU, uso de RAM y latencia). Esto centraliza la información para realizar el análisis comparativo posterior.
- *Dashboard dinámico (Svelte):* Una interfaz de usuario conectada al servidor para visualizar los datos en tiempo real. Este panel graficará directamente el rendimiento del protocolo binario frente a las transferencias estándar en JSON, sirviendo como evidencia empírica de la eficiencia lograda.


== Diagrama de flujo

#figure(
  image("../assets/flow.png", width: 80%),
  caption: [Diagrama de flujo],
)


#page(flipped: true, margin: (x: 1.5cm, y: 1.5cm))[
  == Cronograma y Plan de Trabajo

  A continuación se presenta la planificación detallada del proyecto. Esta matriz unificada fusiona el control metodológico (recursos y responsables) con la representación temporal (Carta Gantt), garantizando la trazabilidad exacta de cada actividad mediante un modelo en cascada.

  #v(1em)

  #figure(
    text(size: 8pt)[
      #table(
        columns: (1fr, 1.1fr, 2fr, ..array.range(24).map(_ => 12pt)),
        align: left + horizon,
        stroke: 0.5pt + rgb("BFBFBF"),

        // líneas verticales para marcar los Hitos (ajustadas al quitar 1 columna)
        table.vline(x: 11, stroke: 1.5pt + rgb("374151"), start: 0),
        table.vline(x: 19, stroke: 1.5pt + rgb("374151"), start: 0),

        table.header(
          table.cell(rowspan: 2, fill: rgb("BDD7EE"))[*Fase*],
          table.cell(rowspan: 2, fill: rgb("BDD7EE"))[*Incremento*],
          table.cell(rowspan: 2, fill: rgb("BDD7EE"))[*Actividad*],

          // Meses
          table.cell(colspan: 4, fill: rgb("BDD7EE"), align: center)[*Jul*],
          table.cell(colspan: 4, fill: rgb("BDD7EE"), align: center)[*Ago*],
          table.cell(colspan: 4, fill: rgb("BDD7EE"), align: center)[*Sep*],
          table.cell(colspan: 4, fill: rgb("BDD7EE"), align: center)[*Oct*],
          table.cell(colspan: 4, fill: rgb("BDD7EE"), align: center)[*Nov*],
          table.cell(colspan: 4, fill: rgb("BDD7EE"), align: center)[*Dic*],

          // semanas
          ..array
            .range(24)
            .map(i => table.cell(fill: rgb("DDEBF7"), align: center)[#text(size: 5pt)[#(calc.rem(i, 4) + 1)]]),
        ),

        table.cell(rowspan: 3)[Diseño y Arquitectura],
        table.cell(rowspan: 3)[Cap. III y Diseño Protocolo],

        [Definir especificación de cabeceras y tipos de datos del protocolo.],
        table.cell(colspan: 2, fill: rgb("4F46E5"))[],
        ..array.range(22).map(_ => []),

        [Escribir pruebas unitarias locales para validar alineamiento de memoria.],
        ..array.range(2).map(_ => []), table.cell(fill: rgb("4F46E5"))[], ..array.range(21).map(_ => []),

        [Diseño de arquitectura algorítmica.],
        ..array.range(3).map(_ => []), table.cell(fill: rgb("4F46E5"))[], ..array.range(20).map(_ => []),

        table.cell(rowspan: 4)[Desarrollo],
        table.cell(rowspan: 2)[Incremento 1: Implementación Protocolo],

        [Programar funciones de serialización y deserialización _zero-copy_.],
        ..array.range(4).map(_ => []), table.cell(fill: rgb("10B981"))[], ..array.range(19).map(_ => []),

        [Ejecutar validación completa vía pruebas unitarias.],
        ..array.range(5).map(_ => []), table.cell(fill: rgb("10B981"))[], ..array.range(18).map(_ => []),

        table.cell(rowspan: 2)[Incremento 2: Integración Sockets TCP],

        [Configurar entorno ESP-IDF y rutinas de conexión Wi-Fi (LwIP).],
        ..array.range(6).map(_ => []), table.cell(fill: rgb("10B981"))[], ..array.range(17).map(_ => []),

        [Implementar cliente TCP mediante tareas estáticas de FreeRTOS.],
        ..array.range(7).map(_ => []), table.cell(fill: rgb("10B981"))[], ..array.range(16).map(_ => []),

        table.cell(rowspan: 5)[Plataforma de telemetría (Demostración de Protocolo)],
        table.cell(rowspan: 3)[Incremento 3: Backend JS y BD],

        [Crear servidor TCP/HTTP receptor en Node.js.],
        ..array.range(8).map(_ => []), table.cell(fill: rgb("F59E0B"))[], ..array.range(15).map(_ => []),

        [Implementar lógica de deserialización.],
        ..array.range(8).map(_ => []), table.cell(fill: rgb("F59E0B"))[], ..array.range(15).map(_ => []),

        [Definir persistencia en base de datos ligera (SQLite).],
        ..array.range(9).map(_ => []), table.cell(fill: rgb("F59E0B"))[], ..array.range(14).map(_ => []),

        table.cell(rowspan: 2)[Incremento 4: Dashboard Frontend],

        [Diseñar interfaz de gráficas dinámicas para latencia y tamaño.],
        ..array.range(10).map(_ => []), table.cell(fill: rgb("F59E0B"))[], ..array.range(13).map(_ => []),

        [Conectar _dashboard_ dinámico al backend.],
        ..array.range(11).map(_ => []), table.cell(fill: rgb("F59E0B"))[], ..array.range(12).map(_ => []),

        table.cell(rowspan: 4)[Benchmarking],
        table.cell(rowspan: 2)[Incremento 5: JSON vs Binario],

        [Implementar formatos JSON, CBOR, Protobuf y MessagePack en ESP32.],
        ..array.range(12).map(_ => []), table.cell(fill: rgb("EF4444"))[], ..array.range(11).map(_ => []),

        [Preparar _payload_ estandarizado para pruebas comparativas.],
        ..array.range(13).map(_ => []), table.cell(fill: rgb("EF4444"))[], ..array.range(10).map(_ => []),

        table.cell(rowspan: 2)[Incremento 6: Captura de Métricas (Hito 2)],

        [Implementar mediciones de uso de memoria y ciclos de CPU.],
        ..array.range(14).map(_ => []), table.cell(fill: rgb("EF4444"))[], ..array.range(9).map(_ => []),

        [Ejecutar pruebas de estrés computacional y exportar resultados.],
        ..array.range(15).map(_ => []), table.cell(fill: rgb("EF4444"))[], ..array.range(8).map(_ => []),

        table.cell(rowspan: 3)[Análisis y Cierre],
        table.cell(rowspan: 3)[Cap. IV: Resultados y Cap. V: Conclusiones],

        [Analizar registros empíricos y métricas de telemetría.],
        ..array.range(16).map(_ => []), table.cell(colspan: 2, fill: rgb("8B5CF6"))[], ..array.range(6).map(_ => []),

        [Redactar evaluación comparativa final.],
        ..array.range(18).map(_ => []), table.cell(colspan: 4, fill: rgb("8B5CF6"))[], ..array.range(2).map(_ => []),

        [Definir conclusiones del proyecto.],
        ..array.range(22).map(_ => []), table.cell(colspan: 2, fill: rgb("8B5CF6"))[],

        // hitos ajustados
        table.cell(colspan: 11, stroke: none)[],
        table.cell(colspan: 8, stroke: none, align: left)[#text(size: 8pt)[*Hito 1* (Protocolo)]],
        table.cell(colspan: 8, stroke: none, align: left)[#text(size: 8pt)[*Hito 2* (Métricas)]],
      )
    ],
    caption: [Carta Gantt usando metodología de Incremento + Kanban],
  )
]


#pagebreak()
