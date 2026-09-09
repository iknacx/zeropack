#set document(
  author: "Ignacio Antonio Ibarra Barrios",
  description: "Diseño de protocolo binario de transferencia optimizado para dispositivos con memoria limitada",
)

#set page(margin: 1in, numbering: "1", number-align: right)

#set par(leading: 1.5em, justify: true, spacing: 2em)
#set text(lang: "es", size: 12pt, font: "Arial")
#set heading(numbering: "1.")


#show heading: it => [
  #v(1em)
  #it
  #v(0.8em)
]

#show table: it => [
  #set par(leading: 1em, justify: false)
  #it
]

// TODO: originalidad y propiedad, dedicatoria

#include "frontmatter/portada.typ"
#include "frontmatter/indices.typ"
#include "frontmatter/resumen.typ"

#counter(heading).update(0)

#include "capitulos/introduccion.typ"
#include "capitulos/problema.typ"
#include "capitulos/metodologia.typ"

#bibliography("references.bib", style: "apa")

