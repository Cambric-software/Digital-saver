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
- [x] **3.2 Interaction harness.** Rendering and behaviour are both verified.
      One shared rig in `test/support/app_harness.dart` supplies the providers,
      the two viewports and the finders the suite needs; 74 interaction tests in
      `test/interaction/` drive the controls on all twenty screens at 390px and
      1440px, and each effect is checked against the service or store that owns
      it rather than only against the pixels. The pass found and fixed a dead
      dashboard data-source icon, Sleep's endless spinner on an unreadable log,
      the wellness emergency dialog disposing its controllers mid-animation, and
      three AI settings dropdowns clipping at 390px. `docs/INTERACTION-TESTS.md`
      records the control-by-control coverage, those findings, and what is not
      exercised and why (real Bluetooth, OS installers, the update download).
      Pipeline: 346 tests green, analyzer 0 errors.

### Phase 4 — Veyro product

- [x] **4.1 Document both firmware targets.** Done in `docs/FIRMWARE.md`, built on
      2026-10-21 rather than read. The prototype (`firmware/esp32`, v4.1.0) now
      **builds** — Flash 62.0%, RAM 12.6% — and did not before, because
      `max()` mixed `uint32_t` with `unsigned long`; its BLE `face` command also
      wrapped at 4 of the 8 screens, so the app could not select screens 4–7.
      The ESP32-S3 target (`firmware/esp32s3`, v5.0.0) **does not build**: it
      declares three I2C buses on a chip with two (`I2C_NUM_2`), registers no
      GATT service (the UUIDs were declared and unused), and leaves
      `display_set_watchface`/`display_set_theme` as stubs. Its committed
      sdkconfig had Bluetooth off and 2 MB flash; it was replaced with
      `sdkconfig.defaults`. Both targets are real; only one runs.
- [x] **4.2 Rewrite `docs/`.** Done 2026-10-21. All ten numbered documents are
      deleted (9,435 lines, ~1.2 MB, 92–95% of each file a repeated checklist).
      The surviving set — `README`, `HARDWARE`, `SYSTEM`, `APP_GUIDE`,
      `FIRMWARE`, `FIRMWARE_FEATURES`, `UPGRADE_GUIDE`, `INTERACTION-TESTS`,
      `ROADMAP`, production spec — is under 2,000 lines. `manual.md`,
      `MASTER_GUIDE.md`, `GUIDE.md` and `company-manual.md` were folded in and
      deleted. **The original “nothing may be left UNKNOWN” rule was wrong for
      this repository**: where no datasheet, measurement or decision exists, the
      documents say UNKNOWN or MUST MEASURE instead of inventing a value.
- [x] **4.3 Verify every fact** in `docs/` and `firmware/`, for the parts the
      repository can settle. Done 2026-10-21: the prototype builds (Flash 62.0%,
      RAM 12.6%), the S3 target fails on `I2C_NUM_2`, and the app runs 346 tests
      with 0 analyzer errors. The commercial spec's contradictions are removed
      (LVGL 8.3.11, N16R8, VC31B, MCP73831-class charger) and it is marked as an
      input to 4.5. Datasheet and bench facts remain UNKNOWN/MUST MEASURE until
      the 4.5 part selection chooses parts — see `docs/HARDWARE.md` §7.
- [ ] **4.4 Expand the firmware** to the documented feature set on the decided
      target, and make it build clean. The S3 blockers recorded in 4.1 come
      first: settle the third I2C bus against the schematic (share a bus, add a
      mux, or bit-bang), write the NimBLE GATT service table so the app can
      read anything, implement the five faces and six themes, then hardware-test
      the result. Do not flash the S3 image until the bus question is answered.
- [ ] **4.5 Redesign the hardware system for the 7,500 EGP product.** The
      mission, stated 2026-10-21: a watch that competes on a shelf with the
      Apple Watch and its peers at about 7,500 EGP — touchscreen, a large custom
      operating system with its own system apps, internet and Bluetooth, and
      features that serve any age, language, interest and job. This supersedes
      patching the S3's three-bus pin map: the electronics get designed around
      the product, not the other way round.
      The proposal is `docs/HARDWARE_DESIGN.md`: RV1106G3 Linux application
      processor plus an ESP32-C6 companion, a 1.43″ 466×466 AMOLED, and a
      1,000/10,000-unit bill of materials. It is a sourced proposal, not a built
      device — nothing has been ordered, measured or certified.
      4.4 is paused until 4.5b is approved, because the bus question is answered
      by the new architecture.
  - [x] **4.5a Write the sourced hardware design.** Done 2026-10-21: three
        compute options compared (MCU + RTOS, Linux AP + companion MCU,
        wearable Android SoC), one recommended; every part, price and datasheet
        value carries a source and access date; unknowns are marked UNKNOWN or
        MUST MEASURE. The three-I2C-bus problem is resolved by design: the
        RV1106 has five I2C masters and the IMU moves to the companion, so no
        mux and no collision. The design does not claim a built device.
  - [ ] **4.5b Owner approves the architecture and the price.** Choose between
        Linux at a higher retail price, Option A (RTOS, no Linux) at a lower
        BOM, and committing to 10,000 units. The arithmetic is in
        `HARDWARE_DESIGN.md` §9 and `11_PRODUCTION_WATCH_SPEC.md` §2: at 1,000
        units the present BOM loses 145 EGP gross per watch at 7,500 EGP.
  - [ ] **4.5c Build an EVT unit and measure it.** Order the 1,000-piece parts,
        lay out the board and run the gates in `HARDWARE_DESIGN.md` §10 and
        `11_PRODUCTION_WATCH_SPEC.md` §6. Until then the power, thermal, optical
        and ingress figures are MUST MEASURE, not specifications.

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
