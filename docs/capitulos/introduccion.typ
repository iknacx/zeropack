= Introducción
== Contexto
/* 1 - 1.5 páginas
Dar contexto global al trabajo a realizar, en particular debe ser escrito desde lo
no particular de modo tal que interese al lector.
*/
El desarrollo del Internet de las Cosas (IoT) y los sistemas embebidos ha hecho
que cada vez más dispositivos estén conectados a la red. Muchos de estos
equipos, como microcontroladores que se usan en sensores o en el control de
maquinaria, tienen que enviar y recibir datos constantemente. Para poder
transmitir esta información, los datos se deben convertir a un formato
específico mediante un proceso llamado serialización.

Normalmente, en el desarrollo software se usan formatos basados en texto como
JSON porque son fáciles de leer y de programar. Sin embargo, al ser diseñados
para ser amigables con el humano, cuando se trabaja con dispositivos de
hardware muy limitado, esto se convierte en un problema. Estos equipos operan
con recursos muy ajustados: tienen pocos kilobytes de memoria RAM, espacio
reducido en la memoria Flash (ROM) y procesadores lentos comparado con uno
usado por ejemplo en un laptop. Por esto, la forma en que se empaquetan y
transmiten los datos afecta directamente el rendimiento del dispositivo y la
cantidad de memoria que le queda disponible para funcionar.

== Importancia del problema
/* 1 - 2 páginas
Responder al menos a la pregunta: ¿Por qué es importante resolver el
problema que se propone considerar?
*/
Solucionar el problema de la serialización en dispositivos pequeños es
importante porque el uso de formatos inadecuados causa fallos de rendimiento
y de estabilidad. Formatos como JSON agregan muchos caracteres que no son el
dato en sí (como llaves, comillas, nombres de variables que se repiten en cada
mensaje), lo que hace que el *payload* sea más pesado de lo necesario. Esto
gasta más ancho de banda y consume la batería más rápido al momento de
transmitir por radio.

Por otro lado, leer formatos basados en texto exige bastante procesamiento y
normalmente obliga a usar memoria dinámica. En un microcontrolador, que debe
pasar meses sin apagarse, estar asignando y liberando memoria dinámica
constantemente provoca la fragmentación del *Heap*. A la larga esto causa que
el dispositivo funcione más lento, se quede sin memoria RAM (fallos de
*Out Of Memory*) y se reinicie. Incluso algunos formatos binarios siguen siendo
problemáticos porque necesitan librerías muy pesadas que no caben en la Flash
del dispositivo. Resolver esto permite que los sistemas embebidos sean más
estables, gasten menos batería y aprovechen mejor sus escasos recursos.

== Breve discusión bibliográfica
/* 2 - 3 páginas
Utilizando varias fuentes de información (por ejemplo, 5 artículos o papers
diferentes) construir una discusión referenciando autores y sus aseveraciones,
de forma tal que se consideren los principales lineamientos y soluciones que la
literatura indica respecto del tema.
*/

Varios autores han abordado el problema de la transmisión de datos en redes de
dispositivos con pocos recursos. Diversos trabajos y especificaciones técnicas
han señalado que JSON no resulta eficiente para entornos IoT debido a la alta
carga de procesamiento y uso de memoria que implica el análisis de texto
@json @jackson2024streaming.

Como alternativa se suele recomendar el uso de formatos binarios. Protocol
Buffers (Protobuf) de Google es uno de los más populares. Según @protobuf,
Protobuf mejora los tiempos de procesamiento y reduce el tamaño de los datos al
usar esquemas predefinidos. Sin embargo, otras implementaciones indican que el
código generado y las librerías necesarias para usar Protobuf pueden ocupar un
espacio considerable en la memoria Flash, limitando su uso en microcontroladores
más pequeños @nanopb.

Otra opción es CBOR, un estándar creado por el IETF, pensado específicamente
para Internet de las Cosas. Estudios comparativos
de formatos como CBOR y MessagePack muestran que estos logran reducir bastante
el tamaño de los mensajes a comparación con JSON @cbor @messagepack. Además, su
uso en propuestas como los manifiestos SUIT demuestra su aplicabilidad en
sistemas embebidos reales @moran2020concise. En esta misma línea, trabajos como
@luis2021pson proponen formatos orientados principalmente a la conversión
eficiente de estructuras JSON a representaciones binarias.
Estos formatos tienen la ventaja de ser auto-descriptivos,
cualidad que también comparte la solución propuesta en este
proyecto. El problema radica en cómo implementan esa auto-descripción: al
soportar una variedad amplia de tipos dinámicos y estructuras complejas, obligan
a que el código que recibe los datos tenga que usar lógica de procesamiento más compleja durante
la deserialización @jackson2024streaming. Esto deja un espacio abierto para un
protocolo que mantenga la ventaja de ser auto-descriptivo, pero que lo haga de
forma mucho más austera y determinista, eliminando el riesgo de fragmentar la
RAM.

En resumen, aunque está claro que los formatos binarios rinden mejor que los de
texto en hardware limitado, las opciones actuales siguen siendo muy pesadas con
el tamaño de librería o demasiado dinámicas, dejando un espacio para soluciones
más ajustadas a la memoria del microcontrolador e implementadas.

== Contribución del trabajo
El aporte de este proyecto es el diseño de un protocolo de serialización binario
pensado estrictamente desde las limitaciones del hardware. A diferencia de otros
formatos que se adaptan desde la web hacia los sistemas embebidos, esta
propuesta intenta buscar evitar por completo la asignación de memoria dinámica
y reducir al máximo el trabajo del procesador. Además, el proyecto entrega una
evaluación práctica (benchmark) que aporta datos concretos sobre el gasto real
de memoria, tamaño de datos y tiempos de procesamiento, permitiendo comparar
esta solución contra las alternativas más usadas en la industria.

== Trabajo a realizar
El proyecto consiste en diseñar e implementar un protocolo binario optimizado para microcontroladores con recursos limitados, priorizando un bajo consumo de memoria. Para validar su funcionamiento, se desarrollará un sistema de telemetría que transmitirá los datos desde el dispositivo hacia un servidor backend para su almacenamiento. Finalmente, se ejecutará una evaluación comparativa empírica (*benchmarking*) para medir la eficiencia de esta propuesta frente a formatos estándar de la industria, contrastando el tamaño de los datos, los tiempos de procesamiento y el uso real de memoria RAM.


== Organización del documento

Este documento se estructura en los siguientes capítulos:

En el Capítulo II se presenta la identificación del problema, abordando su descripción cualitativa y cuantitativa, junto con el análisis de sus causas mediante herramientas de ingeniería.

En el Capítulo III se describe la metodología del proyecto, incluyendo el diseño del protocolo propuesto y el enfoque de evaluación comparativa.

En el Capítulo IV se presentan los resultados obtenidos a partir de la implementación y evaluación del sistema, junto con su análisis en función de las métricas definidas.

Finalmente, se exponen las conclusiones del trabajo y se proponen recomendaciones y posibles líneas de desarrollo futuro.

#pagebreak()
