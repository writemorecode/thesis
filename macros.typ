// Shared helpers used across included files.

// Simple inline todo note (Typst does not include LaTeX's todonotes)
#let todo(body) = block(
  fill: rgb(90%, 95%, 100%),
  inset: (x: 10pt, y: 8pt),
  radius: 2pt,
  stroke: (paint: rgb(50%, 60%, 90%), thickness: 0.5pt),
)[
  #text(size: 9pt)[
    *TODO:* #body
  ]
]

