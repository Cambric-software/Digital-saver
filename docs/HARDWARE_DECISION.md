# Veyro 4.5b — architecture, price and unit economics

Status: **recommendation for owner sign-off**, written 2026-11-07.
This document decides item 4.5b in [ROADMAP.md](ROADMAP.md). It does not order
parts and it does not certify anything. Every input is either sourced in
[HARDWARE_DESIGN.md](HARDWARE_DESIGN.md) §9/§12, an arithmetic result, or an
assumption labelled **ASSUMPTION**. Where a number needs a supplier quote it
says **QUOTE**, not a guessed fact.

## 1. What the owner approved

The approved feature set is: touch screen, health tracking with algorithms,
internet, Bluetooth, internal memory, a large square screen, an update system,
alarms, "thousands of features", and a profit on every unit after tax, store
cut, certification and shipping.

That list does **not** require Linux, a GPU or third-party apps. The earlier
mission text in ROADMAP 4.5 did. This is the central trade-off in 4.5b:

| Requirement | ESP32-S3 (Option A) | RV1106 Linux (Option B) |
|---|---|---|
| Approved feature list | Yes | Yes |
| Linux / multi-process OS | No | Yes |
| Third-party app ecosystem | No | No (no store, no runtime) |
| Battery class | Best | 1.0–2.9 days |
| Unit cost at 10,000 | Lower | Higher |
| Fundable from 18,500 EGP | No, but closer | No |

If Linux is non-negotiable, only Option B qualifies. If the approved list is
the contract, Option A is the cheaper way to meet it. The numbers below show
that Option B cannot be made profitable at 7,500 EGP through a retailer, and
that Option A can.

## 2. The capital constraint is the first fact

The owner has **18,500 EGP** and an Egyptian debit card that cannot pay
international suppliers. That is not enough to order a certified batch of
either architecture. It is enough for **one or two EVT prototypes** built from
development boards: [VEYRO_DEMO_BOM.md](VEYRO_DEMO_BOM.md) prices a single demo
unit at about **9,500 EGP** all-in.

Consequences, stated plainly:

1. A 1,000-unit batch is a **preorder- or investor-funded project**, not a
   purchase from savings. Goods alone are about 3.5 million EGP (Option A).
2. Certification is a **fixed cost per model**. At 100 units it is thousands of
   EGP per watch; at 10,000 it is a few hundred. A 100-unit "test batch" cannot
   carry certification honestly.
3. International payment must be solved before any part is ordered. Options:
   an Egyptian distributor that imports, a manufacturing partner, or a company
   account that can pay abroad. **This is unsolved and must not be assumed.**

## 3. Recommendation

**Build v1 on the ESP32-S3 with a large square/rectangular AMOLED, sell direct
first at 8,900 EGP, and target 10,000 units. Defer the RV1106 Linux product to
v2, funded by v1 revenue.**

Reasons:

- At 10,000 units, Option A at 8,900 EGP direct contributes **3,168 EGP per
  watch (35.6%)** after VAT, gateway, shipping, returns, warranty, duty and
  amortised tooling/certification. That is a real per-unit profit.
- The same price through a retailer contributes only **1,277 EGP (14.3%)**.
  Retail is viable only at 9,900 EGP or above.
- Option B at 7,500 EGP through a retailer **loses 354 EGP per watch** even at
  10,000 units. It needs 9,900 EGP direct to contribute 3,178 EGP (32.1%).
- The S3 firmware already exists, builds clean, and speaks the app's protocol.
  The RV1106 has no board, no BSP work and no firmware in this repository.

## 4. Model inputs

| Input | Value | Basis |
|---|---:|---|
| FX rate | 54.49 EGP/USD | Derived from the 7,500 EGP / 137.64 USD line in HARDWARE_DESIGN §9.1; not a live quote |
| VAT | 14% | Egypt standard rate, HARDWARE_DESIGN [S32] |
| Inbound freight | 4% of goods | HARDWARE_DESIGN §9.3 |
| Duty | 30% of CIF | HARDWARE_DESIGN §9.3; HS classification **UNKNOWN** |
| Payment gateway | 2.5% of ex-VAT | **ASSUMPTION** |
| Warranty reserve | 3% of ex-VAT | **ASSUMPTION** |
| Returns | 2% of ex-VAT | **ASSUMPTION** |
| Retailer cut | 25% of ex-VAT | **ASSUMPTION**; 20–35% is the normal band |
| Last-mile shipping, direct | 60 EGP/unit | **ASSUMPTION** |
| One-time tooling | 45,000 USD | **ASSUMPTION**: case moulds, fixtures, test station |
| One-time certification | 35,000 USD | **ASSUMPTION**: NTRA, CE/RED, FCC, UN38.3, IEC 62133, EMC pre-scan; all fees **QUOTE** |
| Amortised one-time total | 80,000 USD | Arithmetic |

VAT is collected from the customer and remitted. It is not revenue, but it is
cash the company holds until filing; a launch plan must not spend it.

## 5. Bill of materials

### 5.1 Option A — ESP32-S3, large square AMOLED

| Line | 1,000 USD | 10,000 USD | Basis |
|---|---:|---:|---|
| ESP32-S3-WROOM-1-N16R8 | 3.55 | 3.55 | HARDWARE_DESIGN [S22] @1,300 |
| Large square AMOLED + touch | 15.00 | 11.00 | **QUOTE**; 1.6–1.8″ class, $2–5 over the round panel |
| 500 mAh cell | 7.95 | 4.00 | HARDWARE_DESIGN [S25] |
| MAX30101 PPG | 6.09 | 4.50 | HARDWARE_DESIGN [S14] |
| BMI270 IMU | 1.40 | 1.30 | HARDWARE_DESIGN [S16] |
| BMP581 pressure | 1.53 | 1.45 | HARDWARE_DESIGN [S18] |
| STTS22H temperature | 1.32 | 1.20 | HARDWARE_DESIGN [S19] |
| DRV2605L + LRA | 1.29 | 1.20 | HARDWARE_DESIGN [S21][S34] |
| MAX98357A + SPH0645 | 2.27 | 2.08 | HARDWARE_DESIGN [S27][S28] |
| 6-layer HDI PCB | 3.50 | 2.50 | **ALLOWANCE** |
| Passives, connectors, ESD | 3.00 | 2.50 | **ALLOWANCE** |
| Case, glass, gasket, strap | 9.00 | 7.00 | **ALLOWANCE** |
| Packaging, cable, docs | 3.00 | 2.50 | **ALLOWANCE** |
| Assembly, test, calibration | 5.00 | 3.50 | **ALLOWANCE** |
| **Total** | **63.90** | **48.28** | |

The 1,000-unit column mixes 1,300-piece and 100-piece prices. It is conservative
and not a quote. The 10,000-unit column is a negotiation target.

### 5.2 Option B — RV1106G3 + ESP32-C6

The sourced BOM in [HARDWARE_DESIGN.md](HARDWARE_DESIGN.md) §9.2 is
**91.27 USD at 1,000** and **59.17 USD at 10,000**. It uses the 1.43″ round
panel. A large square panel would add roughly the same $2–5 as in Option A, so
these totals are a lower bound for the approved screen.

## 6. Landed cost

| | A @1k | A @10k | B @1k | B @10k |
|---|---:|---:|---:|---:|
| Goods USD | 63.90 | 48.28 | 91.27 | 59.17 |
| Freight 4% | 2.56 | 1.93 | 3.65 | 2.37 |
| CIF | 66.46 | 50.21 | 94.92 | 61.54 |
| Duty 30% | 19.94 | 15.06 | 28.48 | 18.46 |
| Landed USD | 86.39 | 65.27 | 123.40 | 80.00 |
| Landed EGP | 4,708 | 3,557 | 6,724 | 4,359 |
| One-time per unit EGP | 4,359 | 436 | 4,359 | 436 |
| **Fully loaded EGP** | **9,067** | **3,993** | **11,083** | **4,795** |

"Fully loaded" includes the 80,000 USD tooling and certification pool. It is
the number a retail price has to beat.

## 7. Channel math

Revenue is decomposed as: retail incl. VAT → ex-VAT → channel costs → net →
minus fully loaded cost. Store cut and gateway are both charged because card
fees are paid even when a retailer collects.

### 7.1 Option A at 10,000 units

| Retail EGP | Channel | Ex-VAT | Store + fees | Net | Contribution | % of retail |
|---:|---|---:|---:|---:|---:|---:|
| 7,500 | Direct | 6,579 | 553 | 6,026 | **2,032** | 27.1% |
| 7,500 | Retail | 6,579 | 2,138 | 4,441 | **448** | 6.0% |
| 8,900 | Direct | 7,807 | 646 | 7,161 | **3,168** | 35.6% |
| 8,900 | Retail | 7,807 | 2,537 | 5,270 | **1,277** | 14.3% |
| 9,900 | Direct | 8,684 | 711 | 7,973 | **3,980** | 40.2% |
| 9,900 | Retail | 8,684 | 2,822 | 5,862 | **1,869** | 18.9% |
| 11,900 | Direct | 10,439 | 843 | 9,596 | **5,603** | 47.1% |
| 11,900 | Retail | 10,439 | 3,393 | 7,046 | **3,053** | 25.7% |

### 7.2 Option A at 1,000 units

| Retail EGP | Direct contribution | Retail contribution |
|---:|---:|---:|
| 7,500 | **−3,041** | −4,626 |
| 9,900 | **−1,094** | −3,205 |
| 11,900 | **529** | −2,021 |

At 1,000 units the one-time pool is 4,359 EGP per watch. That is why a small
batch cannot be priced at 7,500 and cannot carry certification.

### 7.3 Option B

| Volume | Retail | Direct | Retail channel |
|---|---:|---:|---:|
| 10,000 | 7,500 | **1,230** (16.4%) | −354 |
| 10,000 | 9,900 | **3,178** (32.1%) | 1,067 (10.8%) |
| 1,000 | 7,500 | **−5,058** | −6,643 |
| 1,000 | 11,900 | **−1,488** | −3,073 |

Option B needs about **14,000 EGP** at 1,000 units to break even. That is
outside the 7,500 EGP mission by a wide margin.

## 8. Break-even units on the one-time pool

Break-even units = 4,359,200 EGP (80,000 USD) ÷ contribution before the pool.

| Architecture | Price | Channel | Contribution/unit | Units to recover pool |
|---|---:|---|---:|---:|
| A | 7,500 | Direct | 2,468 | **1,766** |
| A | 8,900 | Direct | 3,604 | **1,209** |
| A | 9,900 | Direct | 4,416 | **987** |
| A | 7,500 | Retail | 884 | 4,934 |
| A | 9,900 | Retail | 2,305 | 1,892 |
| B | 7,500 | Direct | 1,666 | 2,616 |
| B | 9,900 | Direct | 3,614 | 1,206 |

A 10,000-unit plan clears the pool comfortably. A 1,000-unit plan does not at
7,500, and only does at 11,900 direct.

## 9. Cash to deliver the first batch

Option A, 1,000 units:

| Item | EGP |
|---|---:|
| Goods (63.90 USD × 1,000 × 54.49) | 3,481,911 |
| Freight and duty | 1,225,753 |
| Tooling and certification | 4,359,200 |
| **Cash before marketing and salaries** | **9,066,864** |

Revenue at 7,500 is 7,500,000 EGP; at 9,900 it is 9,900,000 EGP. A 50% deposit
campaign at 9,900 raises 4,950,000 EGP, which covers goods but not tooling and
certification. The batch therefore needs **full prepayment, supplier credit, or
an investor**. This is the single most important number in the document.

## 10. What the recommendation asks the owner to approve

1. **Architecture:** ESP32-S3 for v1, RV1106 Linux deferred to v2. Say no if
   Linux is a launch requirement; then the price and funding in §9 change.
2. **Screen:** a large square/rectangular AMOLED in the 1.6–1.8″ class, not the
   1.43″ round panel. The exact panel is **QUOTE**. The firmware faces now
   scale from their 360×360 baseline, so the chosen resolution needs its vendor
   init table and pin map, not a new layout.
3. **Price and channel:** 8,900 EGP direct at launch, with 7,500 EGP as a
   limited early-bird. No retail below 9,900 EGP.
4. **Funding:** do not order a 1,000-unit batch from savings. Build one or two
   EVT units first (about 9,500 EGP each), then use them to raise preorders or
   investment. If neither is available, the project stays at EVT.

## 11. What is still unknown

| Question | State |
|---|---|
| Square panel part, resolution, driver, MOQ, price | **QUOTE** |
| NTRA type-approval fee and duration | **UNKNOWN** |
| CE/RED, FCC, UN38.3, IEC 62133 quotes | **QUOTE** |
| Customs classification and duty | **UNKNOWN**; 30% used as a sensitivity |
| 1,000-piece S3 and sensor quotes | **QUOTE**; current numbers are web tiers |
| Enclosure supplier, tooling and finish | **QUOTE** |
| Factory test fixture and calibration | **QUOTE** |
| International payment route from Egypt | **UNSOLVED** |
| Battery runtime on the square panel | **MUST MEASURE** on EVT |

## 12. Sources

Part prices, datasheets and the duty reference are cited line by line in
[HARDWARE_DESIGN.md](HARDWARE_DESIGN.md) §12. This document adds no new
supplier claim; it only recombines those inputs and labels the new assumptions.
