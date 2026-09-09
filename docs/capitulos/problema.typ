#import "@preview/fletcher:0.5.8": diagram, edge, node, shapes

= Identificación del problema u oportunidad
== Presentación del problema

El diseño de sistemas IoT y redes de sensores se enfrenta a un choque directo entre las prácticas de desarrollo de software modernas y las verdaderas limitaciones físicas del hardware. Por un lado, la industria del software ha estandarizado el uso de formatos basados en texto, principalmente JSON, para el intercambio de información. Esta adopción se debe a que facilitan el desarrollo, la depuración y la integración directa con servicios web y bases de datos. Sin embargo, los dispositivos que operan en el extremo de la red (edge devices) suelen ser microcontroladores diseñados para ser económicos y de bajo consumo energético, no para procesar cadenas de texto complejas.

Este desfase genera un problema técnico evidente. Factores externos, como la necesidad de transmitir datos en tiempo real o casi real a través de redes inalámbricas, imponen cuotas de ancho de banda muy estrictas. Enviar un archivo JSON implica transmitir decenas o cientos de bytes redundantes (como llaves, comillas y espacios) para entregar un dato que a nivel de máquina solo ocupa un par de bytes.

A nivel interno, el problema se agrava. Los microcontroladores típicamente operan con frecuencias de CPU bajas y memorias RAM que se miden en kilobytes. Forzar a este hardware a recibir tramas de texto largo y aplicar rutinas de *parsing* consume ciclos de reloj críticos y obliga al uso de memoria dinámica. Dado que estos dispositivos deben operar de manera continua durante meses sin intervención humana, el uso indiscriminado de memoria dinámica es insostenible. Por lo tanto, el proyecto aborda este conflicto como un problema fundamental de ingeniería: la necesidad de contar con un mecanismo de serialización que respete la arquitectura real del hardware embebido, garantizando la estabilidad operativa a largo plazo.

== Descripción del problema

El primero es el *agotamiento y fragmentación de la memoria*. Cuando un dispositivo recibe una trama de datos variable (como un objeto JSON o estructuras de MessagePack con tipos dinámicos), el firmware generalmente debe usar funciones como `malloc()` para asignar memoria en el *heap* y construir la estructura de datos en tiempo de ejecución. Al liberar esta memoria en distintos momentos, el espacio queda fragmentado. Con el paso del tiempo, aunque exista memoria total disponible, no hay bloques contiguos lo suficientemente grandes, lo que termina en un error de asignación y en el reinicio abrupto del sistema.

El segundo frente es el *desperdicio de ciclos de procesamiento*. Analizar un formato de texto requiere recorrer la cadena de bytes carácter por carácter, buscar delimitadores, aislar los valores y finalmente usar rutinas para convertirlos a formatos binarios útiles para la CPU. Toda esta lógica exige múltiples saltos y condicionales en el código, manteniendo el procesador activo más tiempo del necesario.

Finalmente, el problema afecta el *consumo energético*. El módulo de radio es típicamente el componente que más batería consume en un sistema embebido. Si la serialización genera *payloads* grandes debido a metadatos repetitivos, la radio debe mantenerse encendida por más tiempo para transmitir cada mensaje, lo que reduce drásticamente la autonomía del dispositivo.

La oportunidad de mejora radica en invertir este paradigma. Si se logra pasar de una aproximación donde el dispositivo se adapta al formato, a una donde el formato esté codificado pensando en cómo el microcontrolador gestiona su memoria estática de forma nativa, se puede eliminar la fragmentación y reducir el trabajo de la CPU al mínimo.

== Identificación cuantitativa del problema

Para estructurar el análisis de las causas que generan la insuficiencia en la serialización de datos en dispositivos con memoria limitada, se utiliza un Diagrama de Ishikawa (Diagrama de Causa y Efecto). Esta herramienta permite desglosar el problema principal en categorías específicas, facilitando la comprensión de cómo distintos factores de diseño y del entorno de ejecución contribuyen a la falla del sistema.

=== Diagrama de ishikawa

#figure(
  image("../assets/ishikawa.png"),
  caption: [Diagrama de ishikawa],
)

== Objetivo general

Optimizar la eficiencia computacional y la estabilidad operativa en la transferencia de datos para hardware con restricciones de memoria, mediante el diseño y evaluación de un protocolo binario de lectura directa en un entorno de pruebas en tiempo real.

== Análisis y objetivos específicos por causa

A partir del diagrama de Ishikawa expuesto en la Figura 1, se desglosan las cuatro causas críticas seleccionadas.

#v(0.5em)
#figure(
  table(
    columns: (1.5fr, 3.5fr),
    align: left,
    // fill: (col, row) => if row == 0 { rgb("BDD7EE") } else if calc.odd(row) { rgb("DDEBF7") } else { white },
    // stroke: (col, row) => if row == 0 {
    //   (top: 1.5pt + rgb("5B9BD5"), bottom: 1.5pt + rgb("5B9BD5"), left: none, right: none)
    // } else {
    //   (top: none, bottom: 0.5pt + rgb("E0E0E0"), left: none, right: none)
    // },
    table.cell(colspan: 2)[
      *Causa 1: Formatos binarios ineficientes en entornos limitados (Tecnología)*
    ],
    [*Descripción*],
    [Aunque existen alternativas a los formatos de texto, la mayoría de protocolos binarios estándar fueron diseñados como soluciones de propósito general. Al carecer de codificación compacta y de un alineamiento directo con las estructuras de bajo nivel, obligan al procesador a malgastar ciclos y memoria adaptando abstracciones genéricas.],
    [*Situación actual*],
    [Los dispositivos IoT sufren una alta sobrecarga de procesamiento y memoria al intentar interpretar datos que no coinciden con su arquitectura física reducida.],
    [*Objetivo*],
    [Mitigar de forma casi absoluta la dependencia de memoria dinámica (_heap_) durante el procesamiento de datos, mediante el diseño de una estructura binaria de lectura directa alineada a la arquitectura del hardware.],
    [*Resultado esperado*],
    [Una representación de datos de lectura directa que anule la necesidad de ejecutar rutinas de adaptación pesadas en el microcontrolador.],
    [*Métrica*], [Uso de memoria dinámica (Heap footprint) durante el ciclo de procesamiento.],
    [*Fórmula de cálculo*],
    [Diferencial de memoria estática disponible: $Delta "Heap" = "Heap"_"inicial" - "Heap"_"final"$ (Expresado en Bytes).],
    [*Criterio de éxito*],
    [Garantizar una eficiencia cercana al 100%, admitiendo una tolerancia máxima de entre 0 y 8 bytes de memoria RAM dinámica (`malloc`) por paquete procesado bajo flujos de datos ordinarios.],
  ),
  caption: [Análisis de la Causa 1],
)

#v(0.5em)
#figure(
  table(
    columns: (1.5fr, 3.5fr),
    align: left,
    // fill: (col, row) => if row == 0 { rgb("BDD7EE") } else if calc.odd(row) { rgb("DDEBF7") } else { white },
    // stroke: (col, row) => if row == 0 {
    //   (top: 1.5pt + rgb("5B9BD5"), bottom: 1.5pt + rgb("5B9BD5"), left: none, right: none)
    // } else {
    //   (top: none, bottom: 0.5pt + rgb("E0E0E0"), left: none, right: none)
    // },
    table.cell(colspan: 2)[*Causa 2: Análisis de datos multipaso ralentiza la ejecución del procesador (Métodos)*],
    [*Descripción*],
    [La necesidad de decodificar secuencialmente tipos dinámicos en tiempo de ejecución (como en CBOR o MessagePack) inyecta constantes ramificaciones lógicas en el código.],
    [*Situación actual*],
    [Los procesadores de baja frecuencia en los microcontroladores se saturan interpretando datos, generando cuellos de botella severos en la ejecución del firmware.],
    [*Objetivo*],
    [Disminuir los tiempos de respuesta del microcontrolador logrando una decodificación sustancialmente más rápida que el formato JSON, mediante la implementación de un diseño algorítmico de un solo paso que minimice las ramificaciones lógicas.],
    [*Resultado esperado*],
    [Reducción en los tiempos de respuesta del dispositivo al optimizar la velocidad con la que interpreta la información recibida.],
    [*Métrica*], [Tiempo de deserialización (Medido en ciclos de CPU o microsegundos).],
    [*Fórmula de cálculo*],
    [Diferencial de contadores de reloj del sistema: $Delta "Ciclos" = "Ciclos"_"final" - "Ciclos"_"inicial"$],
    [*Criterio de éxito*],
    [Tiempo de interpretación determinista inferior al requerido por JSON, alcanzando una mejora de rendimiento situada alrededor del 25% al 30% bajo escenarios estandarizados.],
  ),
  caption: [Análisis de la Causa 2],
)

#v(0.5em)
#figure(
  table(
    columns: (1.5fr, 3.5fr),
    align: left,
    // fill: (col, row) => if row == 0 { rgb("BDD7EE") } else if calc.odd(row) { rgb("DDEBF7") } else { white },
    // stroke: (col, row) => if row == 0 {
    //   (top: 1.5pt + rgb("5B9BD5"), bottom: 1.5pt + rgb("5B9BD5"), left: none, right: none)
    // } else {
    //   (top: none, bottom: 0.5pt + rgb("E0E0E0"), left: none, right: none)
    // },
    table.cell(colspan: 2)[*Causa 3: Grandes cantidades de datos por formatos muy detallados (Materiales)*],
    [*Descripción*],
    [Los esquemas de serialización actuales inflan el tamaño de la carga útil al incluir metadatos repetitivos, identificadores redundantes y estructuras de tipo mixto.],
    [*Situación actual*],
    [Saturación rápida del ancho de banda disponible y mayor tiempo de activación del módulo de radio, lo que degrada la autonomía energética del dispositivo.],
    [*Objetivo*],
    [Reducir el tamaño total de la carga útil (_payload_) transmitida en aproximadamente un 30% en comparación con JSON, mediante la implementación de un formato de empaquetado de alta densidad que elimine la redundancia estructural.],
    [*Resultado esperado*],
    [Mensajes de datos significativamente más livianos que conserven la información útil eliminando la redundancia estructural.],
    [*Métrica*], [Tamaño del payload (Cantidad de bytes netos generados).],
    [*Fórmula de cálculo*],
    [Tasa de reducción porcentual respecto a la línea base: $%( "Reducción" ) = (1 - "Bytes"_"Binario" / "Bytes"_"JSON") times 100$],
    [*Criterio de éxito*],
    [Contracción del volumen de datos en torno al 20% y hasta un 40% en el tamaño total del mensaje respecto a la representación equivalente en JSON.],
  ),
  caption: [Análisis de la Causa 3],
)

#v(0.5em)
#figure(
  table(
    columns: (1.5fr, 3.5fr),
    align: left,
    table.cell(colspan: 2)[*Causa 4: Tiempos de transmisión prolongados por payloads pesados (Entorno)*],
    [*Descripción*],
    [El módulo de radio frecuencia (Wi-Fi/BLE) es el componente de mayor consumo eléctrico en un sistema embebido. Transmitir metadatos de texto innecesarios obliga a la antena a permanecer activa por fracciones de segundo adicionales, drenando la capacidad de la batería de forma acumulativa.],
    [*Situación actual*],
    [Autonomía energética severamente degradada en dispositivos IoT de borde debido al tiempo en el aire (_Airtime_) prolongado que exigen los formatos basados en texto.],
    [*Objetivo*],
    [Disminuir el consumo energético operativo del dispositivo reduciendo el tiempo de actividad del módulo de radio, como consecuencia directa de la minimización estructural de la carga útil del protocolo.],
    [*Resultado esperado*],
    [Mayor vida útil de la batería y maximización de los periodos de suspensión profunda (_Deep Sleep_) al acortar drásticamente los ciclos de transmisión de red.],
    [*Métrica*], [Tiempo activo de transmisión o _Airtime_ (Medido en milisegundos por paquete enviado).],
    [*Fórmula de cálculo*],
    [Tiempo de transmisión teórico en función del tamaño del paquete: $t_"tx" = "Tamaño del paquete (bits)" / "Tasa de transferencia (bps)"$],
    [*Criterio de éxito*],
    [Lograr una reducción del tiempo de transmisión directamente proporcional a la compresión del payload (entre un 20% y 40% más rápido que JSON), lo que se traduce en un ahorro energético lineal por cada paquete emitido.],
  ),
  caption: [Análisis de la Causa 4],
)

#pagebreak()

== Limitaciones del proyecto
- Hardware limitado: las pruebas realizadas se limitan a un conjunto específico de dispositivos y entornos de ejecución, por lo que los resultados obtenidos no necesariamente representan el comportamiento del protocolo en la totalidad de las plataformas embebidas existentes.

- Entorno controlado: las condiciones de evaluación tales como el tamaño de los datos, la frecuencia de transmisión y los escenarios de uso considerados, son definidas en un entorno controlado, lo que puede diferir de condiciones reales de operación más complejas o variables.

- Tiempo de desarrollo: el tiempo disponible para desarrollo del proyecto limita la posibilidad de implementar optimizaciones adicionales o evaluar un mayor número de formatos de serialización.

- Precisión de métricas: las herramientas y mecanismos utilizados para la medición de métricas, como el tiempo de procesamiento y el uso de memoria pueden presentar cierto margen de error, especialmente en entorno de bajo nivel o con recursos limitados.

== Alcances del proyecto
- Diseño e implementación: este proyecto tiene como alcance primario la arquitectura, desarrollo algorítmico y evaluación del protocolo binario propuesto para ecosistemas con restricciones de memoria.

- Comparativa de la industria: se contempla la evaluación y el contraste métrico del protocolo contra formatos de serialización dominantes en la industria, específicamente JSON, Protocol Buffers, MessagePack y CBOR.

- Sistema de instrumentación (Telemetría): se considera la implementación de un entorno cliente-servidor funcional. Este incluye un backend con persistencia de datos y un frontend de visualización, cuyo alcance exclusivo es actuar como el instrumento de medición para demostrar empíricamente el rendimiento del protocolo bajo un flujo de datos real.

- Fuera del alcance: No forman parte de este proyecto la estandarización formal (RFC) del protocolo, su despliegue en entornos productivos de grado comercial, ni su certificación en múltiples familias de microcontroladores. Asimismo, se excluye el desarrollo de capas de encriptación o seguridad de red, enfocándose estrictamente en la eficiencia de la serialización.

== Fundamentación Teórica

=== Hardware y Sistemas
- *Sistemas Embebidos:* Sistemas informáticos compuestos por hardware y software diseñados para realizar funciones dedicadas, frecuentemente operando bajo restricciones estrictas de energía y tiempo de respuesta.
- *Microcontrolador (MCU):* Circuito integrado compacto que contiene una unidad central de procesamiento (CPU), memoria y periféricos en un solo chip, utilizado como el núcleo de los sistemas embebidos.
- *Internet de las Cosas (IoT):* Red de dispositivos físicos integrados con sensores, software y conectividad de red, diseñados para recopilar e intercambiar datos a través de Internet.
- *Memoria RAM (Random Access Memory):* Memoria de almacenamiento temporal y volátil donde el microcontrolador guarda variables y datos dinámicos durante la ejecución del firmware.
- *Memoria Flash / ROM:* Memoria de almacenamiento no volátil destinada a guardar de forma permanente el código del programa (firmware) y las librerías del sistema.
- *Heap (Memoria Dinámica):* Región específica de la memoria RAM reservada para la asignación y liberación de estructuras de datos de tamaño variable durante el tiempo de ejecución.
- *Fragmentación de Memoria:* Problema de degradación del *heap* donde el espacio libre se divide en fragmentos pequeños no contiguos. Impide asignar nuevos bloques de memoria, provocando fallos y reinicios del sistema.
- *Alineamiento de Memoria:* En algunas arquitecturas, en especial de los microprocesadores (típicamente ARM) se exige que las direcciones de inicio de ciertos datos sean múltiplos de su propio tamaño, esto optimiza los ciclos de lectura y escritura del procesador.
- *Orden de bytes (Endianness):* Es la forma en que los procesadores almacenan datos de varios bytes en su memoria, existiendo `big-endian` y `little-endian`, representando el número `0x123456` como `12 34 56` (`big-endian`) o `56 34 12` (`little endian`)
- *RTOS (Real-Time Operating System):* Sistema operativo diseñado especificamente para microprocesadores, donde es importante el determinismo, la predictibilidad de las tareas despachadas y la concurrencia.

=== Procesamiento de Datos
- *Serialización:* Proceso algorítmico de convertir estructuras de datos u objetos en memoria a un formato secuencial estandarizado para su transmisión a través de un canal de comunicación.
- *Deserialización:* Proceso inverso a la serialización, donde un flujo de bytes recibido se reconstruye a su formato estructural original dentro de la memoria RAM.
- *Carga Útil (Payload):* La porción de datos de un mensaje transmitido que representa la información real y útil para la aplicación, excluyendo cabeceras, delimitadores y metadatos de control.
- *Sobrecarga (Overhead):* Consumo excedente de recursos computacionales (tiempo de CPU, memoria o ancho de banda) necesario para procesar abstracciones de software o datos estructurales redundantes.
- *Códigos de Operación (Opcodes):* Valores numéricos o patrones binarios específicos asignados para identificar de forma única la instrucción, tipo de dato o comando que debe ser interpretado por el receptor.

=== Protocolos y Estándares
- *JSON (JavaScript Object Notation):* Estándar de intercambio de datos basado en texto @json. Aunque es fácilmente legible por humanos, resulta ineficiente en hardware limitado debido a la sobrecarga de sus caracteres estructurales.
- *Protocol Buffers (Protobuf):* Formato de serialización binaria desarrollado por Google. Utiliza esquemas estáticos predefinidos para compilar y empaquetar datos de forma compacta y rápida.
- *CBOR (Concise Binary Object Representation):* Estándar de serialización binaria @cbor enfocado en ecosistemas IoT. Logra una alta compresión de datos mediante la representación de tipos dinámicos.
- *MessagePack:* Formato de serialización binaria de propósito general. Es similar semánticamente a JSON, pero codificado a nivel de bytes, lo que permite reducir el tamaño del *payload* sin requerir esquemas previos.
- *LwIP (Lightweight IP):* Implementación modular y reducida de TCP/IP, optimizada para minimizar la huella de código en memoria y el uso de memoria RAM.

=== Metodologías de Desarrollo
- *Desarrollo Iterativo e Incremental:* Paradigma de ingeniería de software que divide el ciclo de vida del proyecto en bloques temporales fijos (iteraciones), produciendo entregables funcionales progresivos (incrementos).
- *Kanban:* Marco metodológico de gestión visual que optimiza el flujo de trabajo continuo, equilibrando la carga técnica con la capacidad de desarrollo disponible.
- *Límites WIP (Work In Progress):* Restricción estricta sobre la cantidad máxima de tareas que pueden estar en desarrollo de forma simultánea, utilizada para mitigar cuellos de botella y asegurar el cierre de módulos.
- *Pruebas Unitarias (Unit testing):* Método de validación de software en donde se aislan y verificar de forma individual las funcionalidades del sistema.
- *Perfilado de rendimiento (Profiling):* Técnica de análisis dinámico que mide el uso de recursos del sistema durante la ejecución de un programa en tiempo real.

#pagebreak()
