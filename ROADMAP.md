# Cambric — Master Work Order

This file is the durable order of work for the Cambric products. It exists so the
order survives between sessions instead of living only in a conversation.

**Read this file before starting any Cambric work.** Work top to bottom. Do not
start a lower phase while a higher phase has an open item, unless the user says
otherwise.

The same file is kept in `Digital-saver/ROADMAP.md` so whichever product is open,
the plan is visible.

---

## The principle

**Cambric for all, to all.**

Products are flexible and customisable, and they are built around a small number
of things a person actually does every day. Three features used daily beat a
hundred that are opened once. Every feature must be explained well enough that
anyone can use it — any age, any language, any job.

Trust comes before features. A number shown as a measurement must be measured.
A button that exists must do something. A claim in a document must be true.

---

## Order of work

### Phase 0 — Trust: remove what is wrong, dead, or unreadable

Nothing below this matters if the product tells lies or has dead controls.

- [x] **0.1 Max Tools — dead UI.** The home screen's "Cambric Setup" card opens
      the first-run wizard as a dialog and does nothing useful on a configured
      machine. **Decided: rebuild it as a real Cambric screen** showing this
      product, the other Cambric products found on the machine, their
      versions and install locations, update status, and the licence.
- [x] **0.2 Max Tools — template text.** Settings says "About — Cambric
      application template". Also `main.dart` still names the root widget
      `CambricTemplateApp`. Replace with real product information.
- [x] **0.3 Max Tools — copyright.** The app credits Cambric nowhere. Add a
      visible copyright and licence line.
- [x] **0.4 Digital Saver — outstanding fabricated data.** `github_services.dart`
      returns a hardcoded `'v1.0.3-beta'` version on network failure, and
      `dashboard_screen.dart` / `web_landing_page.dart` display it. A version
      number that was invented is worse than no version number.
- [x] **0.5 Digital Saver — the two hanging screens.** `wellness_tools` and
      `ai_assistant` both hung for the full 25s test timeout at 390px (they
      rendered at 1440px). Two separate faults, both now fixed:
      - `wellness_tools`: a `Row` of two buttons needed 341px where the card
        offers 318, so it overflowed by 11px. It is a `Wrap` now, so "Reset
        Today" drops to its own line on a phone.
      - `ai_assistant`: the app-bar title row overflowed by 48px because the
        two title lines were a bare `Column`. It is `Expanded` and ellipsised.
      - The harness was hiding both faults. It installed a custom
        `FlutterError.onError`, then asserted *before* restoring it, and restored
        `FlutterError.presentError` rather than the binding's handler. The
        binding's own assertion then left the test hung until timeout instead of
        reporting the overflow. It now saves and restores the real handler, and
        restores it before asserting, so a failure is reported immediately and
        names the widget and source line.
      - All 39 screen checks now pass in 8s; the full Digital Saver suite is 130
        tests passing in 14s, with zero analyzer errors.
- [x] **0.6 Both — encoding corruption.** Mojibake (`?`, `�`, `�??`) has been
      found in Dart source, HTML, Markdown and C comments. Sweep and fix.

### Phase 1 — Core paths that do not work yet

- [x] **1.1 Max Tools — download page downloads in place.** Clicking the main
      button navigates to GitHub. Downloads must start while the reader stays on
      the page.
- [x] **1.2 Digital Saver — download page rebuilt to match Max Tools exactly.**
      Same palette, same shapes, same structure. Currently a different design in
      different fonts.
- [ ] **1.3 Max Tools — the tool system is remade.** 106 tools were registered and
      most were internal plumbing (cache, csv, json, retry, timeout, checksum…)
      dressed up as user tools. **Decided: the approved set is listed at the end
      of this file.** All 106 descriptors, the six catalog files and the 88-file
      plumbing library are deleted. Rebuilt so far (each a real screen that
      explains itself, `flutter analyze` clean, 265 tests pass):
      Antivirus & scan, Wealth, Developer toolkit, Hash & checksum, Unit
      converter, Text & documents, Colour & design, Disk analyser, Duplicate
      finder, HTTP / API tester. **Remaining: the other ten from the approved
      set.** The command palette now opens a tool's
      own screen instead of filling in a generated form, and the palette's
      plain-English parser is tested against a fixture catalog rather than
      against whichever tools happen to ship.
- [x] **1.4 Max Tools — settings rebuilt.** Real settings with real effect, not
      four cards of template text.
- [x] **1.5 Digital Saver — settings load path** hardened so a failure explains
      itself. *(done — verify only)*

### Phase 2 — Licence

- [x] **2.1 Digital Saver — licence rewritten** to the Max Tools proprietary
      structure, plus the extra clauses health data and a wellness device
      require. **Decided: proprietary, matching the Max Tools structure exactly,
      plus medical, biometric-data and safety clauses.**
- [ ] **2.2 Max Tools — licence** reviewed against the current app.

### Phase 3 — Digital Saver interface

- [ ] **3.1 Rebuild the remaining screens** on the design system. Done:
      dashboard, heart, activity, sleep, vitals. Remaining: bp, insights,
      health_hub, health_trends, health_tips, fitness_tools, lifestyle_tools,
      achievements, memory, device_diagnostics, watch_simulator, settings.
- [ ] **3.2 Interaction harness.** Rendering is verified; *behaviour* is not.
      Every button, tab, form and dialog must be exercised at 390px and 1440px,
      and its effect asserted.

### Phase 4 — Veyro product

- [ ] **4.1 Document both firmware targets.** Two exist: the ESP32-WROOM-32
      DevKit prototype (v4.1.0, SSD1306, MAX30102/MPU6050) that `docs/`
      describes, and `firmware/esp32s3` (v5.0.0, ESP32-S3, AMOLED, VC31B,
      QMI8658C, BMP581, STTS22H, DRV2605L, BQ25895, FT6336G, ESP-IDF + FreeRTOS
      + LVGL) which matches the 7,500 EGP production spec. **Decided: both are real and both get full
      treatment, documented separately.**
- [ ] **4.2 Rewrite `docs/`.** All ten numbered documents are ~940 lines of which
      most is generated checkerboard — one file repeats "acceptance:" 860 times.
      Replace the padding with real procedures written as Step 1, Step 2 …
      so that following one document end to end produces a working watch.
      **Nothing may be left UNKNOWN** — every step carries its answer and
      the datasheet or resource that answer came from.
- [ ] **4.3 Verify every fact** in `docs/` and `firmware/` against the component
      datasheets. Mark UNKNOWN where a datasheet cannot settle it. Remove the
      commercial spec's contradictions (the spec says LVGL 9.x; the build uses
      LVGL 8.3.11).
- [ ] **4.4 Expand the firmware** to the documented feature set on the decided
      target, and make it build clean.

### Phase 5 — Customisation and polish

- [ ] **5.1 "For all to all":** themes, sizes, languages, and per-person defaults
      in both products.
- [ ] **5.2 Max Tools — interactivity and responsiveness** pass.
- [ ] **5.3 Digital Saver — commit the `linux/` project** rather than generating
      it in CI on every build.
- [ ] **5.4 Max Tools — guard against the duplicate-`core` layout** returning.

---

## Standing rules

- Verify before claiming done. `flutter analyze` for errors; `flutter test` for
  behaviour; the UI capture harness for both widths.
- Never present a computed value as a measurement.
- Screens rendered inside the shared page shell must not carry their own
  `Scaffold`.
- A reading of zero means "no reading" and renders as `--`, never as a number.
- Health status is always a label and an icon as well as a colour.


---

## Approved tool set — Max Tools

Replacing all 106 registered tools. Each is a small app that explains itself in
plain language, works for any age and any language, and does one job properly.
Nothing that is not a tool is allowed to look like one: the plumbing library was
deleted along with the descriptors that dressed it up.

**Done (10 of 20):** Antivirus & scan, Hash & checksum verifier, Disk analyser,
Duplicate finder, HTTP / API tester, Document & text toolkit, Code/data
converters and regex (as Developer toolkit), Wealth, Unit converter, Colour &
design toolkit.

**Still to build (10 of 20):**

1. ~~Antivirus & scan~~ ✔
2. Password vault
3. File shredder
4. ~~Disk analyser~~ ✔
5. ~~Duplicate finder~~ ✔
6. Archive (zip)
7. File encryption
8. ~~Hash & checksum verifier~~ ✔
9. Image compress / convert / resize
10. PDF toolkit
11. ~~Document & text toolkit~~ ✔
12. ~~Code formatter~~ ✔ (folded into Developer toolkit)
13. ~~Developer data converters (Base64, JSON, CSV, UUID, timestamp, regex)~~ ✔
14. ~~HTTP / API tester~~ ✔
15. ~~Wealth (money, budgets, investments, calculators, charts)~~ ✔
16. ~~Unit converter~~ ✔
17. QR & barcode toolkit
18. ~~Colour & design toolkit~~ ✔
19. Notes vault
20. Accessibility & reading aid

A tool is only listed in the catalog once it works. The catalog therefore grows
one honest entry at a time rather than returning to a hundred placeholders.
