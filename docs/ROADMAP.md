# Cambric — Master Work Order

This file is the durable order of work for the Cambric products. It exists so the
order survives between sessions instead of living only in a conversation.

**Read this file before starting any Cambric work.** Work top to bottom. Do not
start a lower phase while a higher phase has an open item, unless the user says
otherwise.

The same file is kept in `Digital-saver/docs/ROADMAP.md` so whichever product is open,
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
- [x] **1.3 Max Tools — the tool system is remade.** 106 tools were registered and
      most were internal plumbing (cache, csv, json, retry, timeout, checksum…)
      dressed up as user tools. **Decided: the approved set is listed at the end
      of this file.** All 106 descriptors, the six catalog files and the 88-file
      plumbing library are deleted. **The full approved set is now built** — 19
      catalog entries covering all 20 approved tools, each a real screen that
      explains itself, `flutter analyze` clean, 324 tests passing:
      Antivirus & scan, Password vault, Wealth, Developer toolkit, Hash &
      checksum, Unit converter, Text & documents, Notes, Accessibility & reading,
      File shredder, File encryption, Archive (zip), Colour & design, Disk
      analyser, Duplicate finder, Image resize & convert, QR & barcode, PDF
      builder, HTTP / API tester.
      The command palette opens a tool's own screen instead of filling in a
      generated form, and the palette's plain-English parser is tested against a
      fixture catalog rather than against whichever tools happen to ship.
- [x] **1.4 Max Tools — settings rebuilt.** Real settings with real effect, not
      four cards of template text.
- [x] **1.5 Digital Saver — settings load path** hardened so a failure explains
      itself. *(done — verify only)*

### Phase 2 — Licence

- [x] **2.1 Digital Saver — licence rewritten** to the Max Tools proprietary
      structure, plus the extra clauses health data and a wellness device
      require. **Decided: proprietary, matching the Max Tools structure exactly,
      plus medical, biometric-data and safety clauses.** Rechecked in 2.2: the
      grant now covers personal use, which the first rewrite did not.
- [x] **2.2 Max Tools — licence** reviewed against the current app. Found and
      fixed a real defect: both repositories are public and both apps are
      downloaded freely, but the grant covered paid clients only, so a person
      who downloaded the app had no licence to run it. Both licences now grant
      free personal, educational and internal use; describe the source as
      publicly readable rather than confidential; and state what the app
      actually does — local data, no telemetry, a GitHub update check, and the
      limits of financial, antivirus and shredding results.

### Phase 3 — Digital Saver interface

- [x] **3.1 Rebuild the remaining screens** on the design system. Every screen is
      now rebuilt: dashboard, heart, activity, sleep, vitals, insights (trends,
      guidance, progress), bp, health_hub, health_trends, health_tips, fitness,
      lifestyle, achievements, memory, device_diagnostics, watch_simulator,
      settings and the app lock. Each carries a top doc comment saying what the
      previous version claimed and what replaced it, and the UI capture harness
      renders every one at 390px and 1440px. Screens that had invented data now
      show an empty state naming what is missing.
- [x] **3.1a Reachability — decided 2026-10-20.** Seven screens were unreachable:
      `bp`, `health_hub` and `watch_simulator` were referenced nowhere in `lib/`,
      and `fitness`, `lifestyle`, `wellness` and `device` were reachable only
      from `health_hub`, which itself was unreachable. The shell also hid `watch`
      on a phone: the bottom bar held five of six destinations, and the rail
      only appears at 1100px. **Done:** a **Health hub** destination joins the
      shell and is the door to the tool suites, blood pressure and the simulator.
      The bar is Today, Vitals, Insights, Coach and **More**, where More lists
      every destination the bar cannot hold. Reachability is tested at both
      widths in `test/widgets/ds_shell_test.dart`.
- [x] **3.1b Unreferenced code — decided 2026-10-20.** Eight files were imported
      by nothing, about 3,500 lines. **Done:** `storage_service` is the typed
      settings and records store behind Settings and fitness;
      `quick_actions_widget` is the Quick actions panel on Today;
      `enhanced_animations` keeps the BPM-driven `HeartPulseRing` used on the
      heart screen; `dynamic_theme_service` is the clock rule behind "Dim after
      dark"; `app_installer_service` verifies a published SHA-256 before
      installing and reports an honest hand-off on Android;
      `health_analysis_service_v2` is `HealthPatternsService`, shown as Patterns
      in Insights; `creative_effects` is the static splash backdrop.
      `glassmorphic_widgets` now supplies [GlassCard] to the web download page,
      whose three download cards became translucent glass panels (decided
      2026-10-21). That page keeps the Max Tools palette, radii and button
      shapes; the glass is the one deliberate departure. The file's glow button,
      glow icon button and pulsing dot ran animations that never stopped and
      duplicated controls the page already had, so they were removed rather than
      left unused.
- [ ] **3.2 Interaction harness.** Rendering is verified; *behaviour* is only
      partly so. Each rebuilt screen has tests for its main path at 390px and
      1440px (hub, settings, lock, memory, wellness, lifestyle, fitness, device,
      simulator, insights, dashboard), but "every button, tab, form and dialog
      exercised, and its effect asserted" is not yet true. The remaining work is
      a per-screen pass over the controls those tests do not touch, including
      dialogs and the disabled-state reasons.

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

**Done (19 catalog entries, all 20 tools):** Antivirus & scan, Hash & checksum
verifier, Disk analyser, Duplicate finder, HTTP / API tester, Document & text
toolkit, Notes, Accessibility & reading aid, File shredder, Password vault, File
encryption, Archive (zip), Colour & design toolkit, Developer toolkit (code
formatter and data converters in one screen), Wealth, Unit converter, Image
resize & convert, QR & barcode, PDF builder.

**Still to build (none):**

1. ~~Antivirus & scan~~ ✔
2. ~~Password vault~~ ✔ — AES-256-GCM, PBKDF2-HMAC-SHA256 (210,000 rounds), no
   recovery if the master password is lost, stated on the screen.
3. ~~File shredder~~ ✔
4. ~~Disk analyser~~ ✔
5. ~~Duplicate finder~~ ✔
6. ~~Archive (zip)~~ ✔ — zips a file or folder, extracts with absolute-path and
   `..` entries refused rather than rewritten.
7. ~~File encryption~~ ✔ — `MTE1` AES-256-GCM format, 128 MB in-memory limit.
8. ~~Hash & checksum verifier~~ ✔
9. ~~Image compress / convert / resize~~ ✔ — JPEG, PNG and WebP, shows the
   before/after size and says when the result got larger.
10. ~~PDF toolkit~~ — shipped as **PDF builder**: creates PDFs from text or
    images. It does not open, merge or edit existing PDFs, and says so.
11. ~~Document & text toolkit~~ ✔
12. ~~Code formatter~~ ✔ (folded into Developer toolkit)
13. ~~Developer data converters (Base64, JSON, CSV, UUID, timestamp, regex)~~ ✔
14. ~~HTTP / API tester~~ ✔
15. ~~Wealth (money, budgets, investments, calculators, charts)~~ ✔
16. ~~Unit converter~~ ✔
17. ~~QR & barcode toolkit~~ ✔ — generates QR, Code 128, EAN-13 and Code 39;
    reads QR codes. Linear barcodes are generated but not decoded, and the
    screen says so.
18. ~~Colour & design toolkit~~ ✔
19. ~~Notes vault~~ — shipped as **Notes**: plain text, searchable, pinned, and
    explicitly not a vault.
20. ~~Accessibility & reading aid~~ —

A tool is only listed in the catalog once it works. The catalog therefore grows
one honest entry at a time rather than returning to a hundred placeholders.
