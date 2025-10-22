#set text(font: "New Computer Modern")

#set page(numbering: "1")

#set heading(numbering: "1.")
#show heading.where(level: 1): it => {
  counter(math.equation).update(0)
  it
}

#set math.equation(
  numbering: it => {
    let count = counter(heading.where(level: 1)).at(here()).first()
    if count > 0 {
      numbering("(1.1)", count, it)
    } else {
      numbering("(1)", it)
    }
  },
)

#let title = [Efficient offline job scheduling in private clouds]
#let author = [Gustav Karlsson]

#align(center, text(17pt)[
  *#title*
])
#align(center, text(14pt)[
  #author
])

#pagebreak()
#outline()
#pagebreak()

#include "chapters/introduction.typ"
#pagebreak()
#include "chapters/theory.typ"
#pagebreak()
#include "chapters/problem_description.typ"
#pagebreak()
#include "chapters/related_work.typ"
#pagebreak()
#include "chapters/method.typ"
#pagebreak()
#include "chapters/results.typ"
#pagebreak()
#include "chapters/analysis.typ"
#pagebreak()
#include "chapters/discussion.typ"
#pagebreak()
#include "chapters/conclusion.typ"

#pagebreak()

#bibliography("references.bib")
