# ES-03 -- remove or implement: an assessment for the package owner

**Status: a recommendation, not a change.** No parameter named in this note has
been touched. The decision is the owner's; what follows is the scope, cost and
consequence of each way of taking it.

Audit row: `audit/orchestra_fitness_2026-08-25/per_package/effectsurf.md`, ES-03
(D2, CRITICAL), with ES-24 (dead code) attached to the same surface.

---

## 1. What is actually the case

Every statement here was read off the current source or probed against the
installed toolchain, not carried over from the audit.

| Claim | Where | Verified |
|---|---|---|
| `plot.effectsurf()` declares `wireframe`, `show_data`, `fmt`, `width`, `height` and documents all five | R/render-surface.R:34-47, :77-83 | yes |
| `wireframe`, `width`, `height`, `fmt` are forwarded to both renderers and read by neither | R/render-surface.R:94-102 into :262-265 and :315-318; no other occurrence in either body | yes |
| `show_data` is **not** forwarded at all | occurs exactly twice in `R/`: its roxygen line and its formal | yes -- the audit says all five are passed down; four are |
| `camera` is the one forwarded argument that is read | `build_scene()`, R/render-surface.R:383-397 | yes |
| `label_format()` is exported, indexed, and its consumers are unreachable | NAMESPACE; `_pkgdown.yml:47`; `apply_format()`, `build_hovertemplate()`, `resolve_hover_fmt()` at R/label-format.R:58-123 call only each other, with no caller in `R/`, `tests/` or `vignettes/` | yes |
| The documentation states the return value is used by `plot.effectsurf()` | man/label_format.Rd:35 | yes |
| A vignette teaches `wireframe = TRUE` as the publication mode | vignettes/stratified-surfaces.Rmd:200-207, repeated at :311 | yes; the chunk is `eval = FALSE`, so the vignette renders clean either way |
| `...` is declared and never read, and unused arguments are not checked | R/render-surface.R:84, absent from the body | yes -- this is load-bearing for section 4 |
| The object carries `model_info` only, not the model and not the training data | `extract_model_info()`, R/utils.R:168-185 | yes -- load-bearing for `show_data` |
| plotly can express what would be needed | `plotly::schema()` on plotly 4.12.1: the `surface` trace exposes `hidesurface`, `contours$x/y/z` (`show`, `color`, `width`) and `hovertemplate`; scene axes expose `tickformat` | yes |

The one thing none of the five costs today is correctness of a *number*. A user
who passes `wireframe = TRUE` gets the surface they would have got anyway. The
defect is that the documentation, the exported helper and a vignette all assert
a capability the renderer does not have.

---

## 2. Option A -- implement all five

**A1. `width` / `height`.** Pass into the `plot_ly()` constructor in both
renderers. The contract is unambiguous (pixels; `NULL` is auto). Roughly six
lines and two tests reading the returned widget's dimensions. Doing it also
forces the removal of the duplicated `plot_ly()` call at R/render-surface.R:281
and :283, which is ES-24's other half. **Under an hour.**

**A2. `wireframe`.** `hidesurface = TRUE` plus
`contours = list(x = list(show = TRUE, color = ...), y = list(show = TRUE, ...))`
on each `add_surface()`. The single-surface renderer can take the colour from
the colourscale; the stratified renderer must take it from `colours[k]`, or the
strata become indistinguishable the moment the fill is hidden. The CI envelope
surfaces need a decision of their own -- a wireframe inside a wireframe is not
readable, so they should stay filled or be suppressed in this mode. Roughly
thirty lines across the two renderers, three or four tests asserting the trace
attributes, and the vignette's claim that this "avoids transparency artefacts
entirely" becomes true. **Half a day.**

**A3. `fmt`.** Two halves, and only one of them is reachable through a
hovertemplate.

- *Precision.* `build_hovertemplate()` and `resolve_hover_fmt()` already extract
  the digit count from a `sprintf` string. Attaching the result as
  `hovertemplate =` per trace and `tickformat =` per scene axis is about forty
  lines of wiring over code that exists. Half a day.
- *The function form and the unit suffix.* `label_format()` documents and its
  own example teaches a function (man/label_format.Rd:50-52), and a format
  string with a unit (`"%.0f kg/ha"`). Neither survives a hovertemplate: the
  template is evaluated in the browser by d3-format, so an R function cannot
  run, and `resolve_hover_fmt()` keeps the precision and drops the unit. Both
  require pre-computing a character matrix per trace and rendering `%{text}` --
  a different mechanism, roughly eighty lines with tests. **One to two days.**

Implementing only the precision half leaves the exported helper's own example
inert, which is the same defect in a smaller box.

**A4. `show_data`.** Not a wiring job. `plot.effectsurf()` receives the surface
object and nothing else, and the object holds a class name, an observation
count, a formula string and a call string. Three ways to get the data to the
renderer, all of them design changes:

1. carry a subset of the training data into the object at construction, which
   means `new_effectsurf()` and the seven `surf_*()` constructors, and grows
   every object and every `surf_export()` HTML file by the data;
2. add a `data =` argument to `plot()`, which puts the burden on the caller and
   admits data that disagrees with the surface;
3. keep the fitted model in the object, which makes objects large and, for many
   model classes, unreliable to serialise across sessions.

Then the overlay: `add_trace(type = "scatter3d")`, clipped to the grid's x and y
range, split by the `by` stratum and coloured to match it. **One to two days**
including the constructor change, and it commits the package to carrying data it
currently does not carry.

**Option A total: three to five days, and it changes what an effectsurf object
contains.** ES-24's dead code is absorbed rather than deleted.

---

## 3. Option B -- remove all five

Scope, in one commit:

- drop the five formals from `plot.effectsurf()` (R/render-surface.R:77-83) and
  from both renderer signatures (:262-265, :315-318), with their five `@param`
  blocks (:34-47);
- delete R/label-format.R in full -- with `fmt` gone, all four functions in it
  are unreachable -- and with it the `label_format()` export, its NAMESPACE
  entry, `_pkgdown.yml:47`, the `@seealso` at R/render-surface.R:52-53 and
  man/label_format.Rd;
- rewrite the vignette's "Wireframe" paragraph (vignettes/stratified-surfaces.Rmd:200-207)
  and its summary-table row (:311);
- add the `...` guard of section 4, without which the removal is invisible;
- tests that the removed arguments now error.

**Two to three hours.** Clears ES-24's label-format half outright.

---

## 4. What breaks for users, either way

Neither option breaks a call that works today, and the reason is worth stating
plainly: `plot.effectsurf()` declares `...` and never reads it, so after removal
`plot(es, wireframe = TRUE)` does not error -- the argument lands in `...` and is
discarded without a word. Removal on its own therefore trades a *documented*
no-op for an *undocumented* one, which is the same class of defect as ES-03, one
level quieter.

**So, under every option including deferring the five: make `...` fail.** Five
lines in `plot.effectsurf()` -- if `...length()` is non-zero, `cli_abort()`
naming the arguments. This also catches misspellings (`colorscale` for
`colourscale`) that are silently ignored today. It is the single highest-value
line-per-line change on this surface, and it is independent of the five.

With that guard in place:

| | Option A | Option B |
|---|---|---|
| A call that errors afterwards | none | `label_format()` (the object it built was inert) |
| A call whose output changes | `plot(es, wireframe = TRUE)` renders differently; `show_data = TRUE` draws points; saved HTML and any snapshots regenerate | none |
| Object contract | changes under A4(i): objects and exported HTML carry training data | unchanged |
| Documentation | catches up by gaining behaviour | catches up by losing claims |

---

## 5. Recommendation

**Split the five by whether the plotly surface trace can honour the contract as
documented.** This is not a half-state: each of the five ends either implemented
and tested, or absent from the signature, the documentation and the vignette.

**Implement (A1 + A2): `width`, `height`, `wireframe`.** `wireframe` is the only
one of the five with a stated use case in the package's own documentation, it is
the mode a vignette recommends for publication, and plotly expresses it directly.
`width` and `height` are unambiguous and cost under an hour. Roughly half a day
with tests.

**Remove: `show_data`, `fmt`, and the `label_format()` export.** `show_data`
needs data the object does not carry, and carrying it is a contract decision.
`fmt`'s documented function form cannot reach a browser-side hovertemplate at
all. Both are feature designs that were never done, not wiring that was
forgotten, and they should be reopened by a user asking for them rather than
left standing as formals. Roughly two hours, and it clears ES-24's dead
label-format block.

**Add the `...` guard** (section 4) in the same commit.

**Net: under one day.** The option I would not take is A in full: A4 alone buys a
diagnostic overlay at the price of changing what an effectsurf object contains,
and that price should be paid when a user asks for the overlay, not to retire a
formal that was written and never wired. If the decision has to close in a single
sitting instead, take Option B entire -- including the `label_format()`
retirement and the vignette rewrite -- and let `wireframe` come back later as a
feature with its own tests.
