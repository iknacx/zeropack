#heading(level: 1, numbering: none)[Resumen Ejecutivo]

Este trabajo aborda la ineficiencia en la serialización de datos en dispositivos con recursos limitados, como microcontroladores utilizados en sistemas IoT. El uso de formatos ampliamente adoptados, como JSON, introduce sobrecarga en el tamaño de los datos y en el procesamiento requerido, afectando el rendimiento, el uso de memoria y la estabilidad del sistema.

En este contexto, se plantea la siguiente pregunta de investigación: ¿es posible diseñar un protocolo de serialización que reduzca el uso de memoria y el costo de procesamiento en comparación con formatos existentes, manteniendo un comportamiento determinista en hardware restringido?

El objetivo de este trabajo es diseñar y evaluar un protocolo binario orientado a este tipo de dispositivos. Para ello, se desarrolla un sistema de prueba que permite la transmisión, recepción y almacenamiento de datos, sobre el cual se realiza una evaluación comparativa con otros formatos de serialización, considerando métricas como tamaño del payload, tiempo de procesamiento y uso de memoria.

Se espera que los resultados permitan analizar la viabilidad del protocolo propuesto y su posible aplicación en sistemas embebidos donde la eficiencia en memoria y procesamiento sea crítica.

#v(1fr)

*Palabras clave:* serialización de datos, sistemas embebidos, IoT, protocolos binarios, eficiencia en memoria.

#pagebreak()

#heading(level: 1, numbering: none)[Abstract]

This work addresses the inefficiency of data serialization in resource-constrained devices, such as microcontrollers used in IoT systems. Widely adopted formats like JSON introduce overhead in both data size and processing requirements, negatively affecting performance, memory usage, and system stability.

In this context, the following research question arises: is it possible to design a serialization protocol that reduces memory usage and processing cost compared to existing formats, while maintaining deterministic behavior in constrained hardware environments?



The objective of this work is to design and evaluate a binary protocol tailored to these conditions. To validate the proposal, a testing system is developed for data transmission, reception, and storage, enabling a comparative evaluation against other serialization formats using metrics such as payload size, processing time, and memory usage.

The results are expected to provide insight into the feasibility of the proposed protocol and its potential application in embedded systems where memory and processing efficiency are critical.

#v(1fr)

*Keywords:* data serialization, embedded systems, IoT, binary protocols, memory efficiency.

#pagebreak()
