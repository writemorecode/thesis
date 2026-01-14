// BTH Thesis Template (Typst port)
// Template version 4.1 (ported January 2026)

// -----------------------------
// Thesis metadata (edit these)
// -----------------------------
#let thesis-degree = "Degree name"
#let thesis-month = "Month"
#let thesis-year = "Year"
#let faculty = "Faculty"
#let thesis-weeks = "Weeks"
#let thesis-title = "Efficient offline job scheduling in private clouds"
#let thesis-subtitle = ""
#let author-first = "Gustav Karlsson"
#let author-first-mail = "...@student.bth.se"
#let author-second = ""
#let author-second-mail = "...@student.bth.se"
#let supervisor = "Title Firstname Lastname"
#let supervisor-affiliation = "Department"

#let bth-logo = "bthnotext.pdf"

// -----------------------------
// Global document settings
// -----------------------------
#let base-margin = (top: 2.9cm, bottom: 2.9cm, left: 2.95cm, right: 2.95cm)
#let front-margin = (top: 2.0cm, bottom: 1.5cm, left: 2.5cm, right: 2.0cm)

#set page(
  paper: "a4",
  margin: base-margin,
  numbering: none,
)
#set text(font: "New Computer Modern", size: 12pt)
#set par(justify: true, first-line-indent: 1.2em)

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

// Simple inline todo note (Typst does not include LaTeX's todonotes)
#import "macros.typ": todo

// Helper for unnumbered front-matter headings
#let front-heading(title) = heading(level: 1, numbering: none)[#title]

// Start next content on a right-hand page (LaTeX cleardoublepage)
#let cleardoublepage() = pagebreak(to: "odd", weak: true)

// Running header state (main matter)
#let chapter-title = state("chapter-title", "")
#let chapter-number = state("chapter-number", "")
#let chapter-prefix = state("chapter-prefix", "Chapter")
#let section-title = state("section-title", "")
#let section-number = state("section-number", "")

// Chapter heading style (matches BTH LaTeX template)
#show heading.where(level: 1): it => [
  #counter(math.equation).update(0)
  #if it.numbering != none [
    #pagebreak(to: "odd", weak: true)
  ]
  #let number = if it.numbering == none { none } else { counter(heading).display() }
  #if number == none [
    #chapter-number.update("")
  ] else [
    #chapter-number.update(number)
  ]
  #chapter-title.update(it.body)
  #section-title.update("")
  #section-number.update("")
  #counter(figure).update(0)

  #v(18pt)
  #if number != none [
    #text(size: 14pt, weight: "bold")[#chapter-prefix.get() #number]
    #v(4pt)
  ] else [
    #v(14pt)
  ]
  #line(length: 100%, stroke: 1pt)
  #v(4pt)
  #align(right)[#text(size: 17pt, weight: "bold")[#it.body]]
  #if number != none [
    #v(5 * 14pt)
  ] else [
    #v(4 * 14pt)
  ]
]

// Track current section for running headers
#show heading.where(level: 2): it => [
  #section-title.update(it.body)
  #section-number.update(counter(heading).display())
  #it
]

// Running header for main matter pages (odd/even)
#let running-header = context [
  #let page-num = counter(page).get().first()
  #let page-label = counter(page).display()
  #let even = calc.rem(page-num, 2) == 0

  #if even [
    #page-label
    #h(1fr)
    #text(style: "italic")[
      #if chapter-number.get() == "" [
        #chapter-title.get()
      ] else [
        #chapter-prefix.get() #chapter-number.get(). #chapter-title.get()
      ]
    ]
  ] else [
    #if section-title.get() == "" [
      #h(1fr)
      #page-label
    ] else [
      #text(style: "italic")[#section-number.get(). #section-title.get()]
      #h(1fr)
      #page-label
    ]
  ]
]

// -----------------------------
// Front page (no page number)
// -----------------------------
#set page(margin: front-margin)

#grid(
  columns: (1fr, auto),
  row-gutter: 0.2cm,
  column-gutter: 1cm,
  [#thesis-degree],
  [#image(bth-logo, width: 3cm)],
  [#(thesis-month + " " + thesis-year)],
  [],
)

#v(7.5cm)
#align(center)[#text(size: 24pt, weight: "bold")[#thesis-title]]
#if thesis-subtitle != "" [
  #v(0.5cm)
  #align(center)[#text(size: 16pt, weight: "bold")[#thesis-subtitle]]
]
#v(2cm)
#align(center)[#text(size: 16pt, weight: "bold")[#author-first]]
#if author-second != "" [
  #v(0.3cm)
  #align(center)[#text(size: 16pt, weight: "bold")[#author-second]]
]
#v(1fr)
#line(length: 100%, stroke: 1pt)
Faculty of #faculty, Blekinge Institute of Technology, 371 79 Karlskrona, Sweden

#pagebreak()

// -----------------------------
// Inner page (no page number)
// -----------------------------
#set page(margin: front-margin)
#text(size: 9pt)[
  This thesis is submitted to the Faculty of #faculty at Blekinge Institute
  of Technology in partial fulfillment of the requirements for the degree of
  #thesis-degree. The thesis is equivalent to #thesis-weeks weeks of full-time studies.

  #linebreak()
  #linebreak()
  The authors declare that they are the sole authors of this thesis and that they have
  not used any sources other than those listed in the bibliography and identified as references.
  They further declare that they have not submitted this thesis at any other institution to
  obtain a degree.
]

#v(6cm)

#par(first-line-indent: 0pt)[
  *Contact Information:*#linebreak()
  Author(s):#linebreak()
  #author-first#linebreak()
  E-mail: #author-first-mail#linebreak()
  #linebreak()
  #if author-second != "" [
    #author-second#linebreak()
    E-mail: #author-second-mail
  ]
]

#v(1.5cm)

#par(first-line-indent: 0pt)[
  University advisor:#linebreak()
  #supervisor#linebreak()
  Department of #supervisor-affiliation
]

#v(2cm)

#grid(
  columns: (1fr, auto, auto, auto),
  column-gutter: 0.4cm,
  row-gutter: 0.1cm,
  [Faculty of #faculty], [Internet], [:], [www.bth.se],
  [Blekinge Institute of Technology], [Phone], [:], [+46 455 38 50 00],
  [SE--371 79 Karlskrona, Sweden], [Fax], [:], [+46 455 38 50 57],
)

#pagebreak()

// -----------------------------
// Front matter (roman page numbers)
// -----------------------------
#set page(
  margin: base-margin,
  numbering: "i",
)
#set heading(numbering: none)
#counter(page).update(1)

// ABSTRACT IN ENGLISH
#front-heading("Abstract")
#todo[Add abstract.]

#v(1cm)
#par(first-line-indent: 0pt)[
  *Keywords:*
]

#cleardoublepage()

// ABSTRACT IN SWEDISH
#front-heading("Sammanfattning")
#todo[An abstract in Swedish is only needed for "civilingenjör" theses.]

#v(1cm)
#par(first-line-indent: 0pt)[
  *Nyckelord:*
]

#cleardoublepage()

// ACKNOWLEDGEMENTS
#front-heading("Acknowledgments")
#todo[Add acknowledgments.]

#cleardoublepage()

// TABLE OF CONTENTS
#heading(level: 1, numbering: none, outlined: false)[Contents]
#outline(title: none, depth: 3)
// Uncomment if you need them:
// #outline(target: figure.where(kind: "figure")) // List of figures
// #outline(target: figure.where(kind: "table"))  // List of tables

#cleardoublepage()

// -----------------------------
// Main matter (arabic page numbers)
// -----------------------------
#set page(numbering: "1", header: running-header)
#counter(page).update(1)
#counter(heading).update(0)
#set heading(numbering: "1.1")
#chapter-prefix.update("Chapter")
#chapter-title.update("")
#chapter-number.update("")
#section-title.update("")
#section-number.update("")
#let chapter-figure-numbering(number) = numbering("1.1", counter(heading).get().first(), number)
#set figure(numbering: chapter-figure-numbering)

#include "chapters/introduction.typ"
#include "chapters/theory.typ"
#include "chapters/problem_description.typ"
#include "chapters/related_work.typ"
#include "chapters/method.typ"
#include "chapters/experimental_method.typ"
#include "chapters/results.typ"
#include "chapters/analysis.typ"
#include "chapters/conclusion.typ"

// Bibliography
#cleardoublepage()
#bibliography("references.bib", style: "ieee", title: "References")

// -----------------------------
// Final page with BTH logo
// -----------------------------
#pagebreak(to: "even")
#set page(numbering: none, header: none, margin: front-margin)
#align(center)[#image(bth-logo, width: 3cm)]
#v(0.5cm)
#line(length: 100%, stroke: 1pt)
Faculty of #faculty, Blekinge Institute of Technology, 371 79 Karlskrona, Sweden
