# Veyro Production Watch — Manufacturing and Engineering Manual
**Cambric · Revision 3.0 · September 2026**

This manual produces a finished, market-grade Veyro smartwatch. It is written for three audiences: Cambric engineers, contracted PCB manufacturers, and production line operators. Every section states exactly what to do, what component to use, what tool to use, and what result to expect. There are no UNKNOWN items and no placeholders — everything required to complete each step is stated in the step itself.

This is the v2.0 hardware revision. It upgrades every major component from the v1.0 spec: AMOLED 360×360 display, VC31B wrist PPG sensor, BMP581 pressure sensor, STTS22H skin temperature sensor, 600 mAh battery, and a polished PVD-coated metal case with knurled crown.

---

## What this manual produces

A Veyro v2.0 production smartwatch with:
- 46 mm PVD-coated zinc alloy or CNC aluminum case, brushed metal bezel ring, knurled crown
- 1.43 inch AMOLED 360×360 round display, true black background, 600 nit brightness
- FT6336G capacitive multi-touch controller
- ESP32-S3-MINI-1U-N16R8 MCU (dual-core 240 MHz, 16 MB flash, 8 MB PSRAM)
- VC31B wrist PPG sensor — HR, SpO2, HRV with on-chip AGC
- QMI8658C 6-axis IMU with hardware pedometer
- BMP581 barometric pressure and altitude sensor
- STTS22H skin temperature sensor (±0.5 °C)
- BQ25895RTWR PMIC with USB-C 5 V charging and power path
- 600 mAh protected 1S LiPo battery (GREPOW 654040)
- DRV2605LYZF4 haptic controller with LRA motor
- IP67 water resistance (IEC 60529 tested)
- 7–10 day battery life at normal use
- BLE 5.0 with bonding persistence (no re-pair after reboot)
- Digital Saver app with Gemini AI, health engine, and productivity tools
- Custom background images, 4 themes, 8 watch faces, swipe navigation

---

## Stage 0 — Visual Design and Aesthetics

This stage defines what the watch looks like. Every decision here affects tooling, packaging, and marketing. Finalise Stage 0 before ordering tooling or components.

### 0.1 Case options

Two case options. Choose one per SKU. Both use the same PCB, battery, and display.

**Option A — Standard (ZA-8 die-cast)**
- Material: Zinc alloy ZA-8 die-cast
- Surface: PVD (Physical Vapor Deposition) coating — more durable than anodizing, scratch-resistant
- Tooling cost: $800–1200 (one-time per color)
- Unit cost at 1000 pcs: $4–7 each
- Colors: Midnight Black (black PVD), Cloud Silver (silver PVD)
- Source: Shenzhen watch case CM via Alibaba — search "46mm smartwatch case ZA-8 PVD custom tooling"

**Option B — Premium (CNC aluminum)**
- Material: CNC machined 6061-T6 aluminum
- Surface: micro-bead blasted finish + PVD coating
- Tooling cost: $200–400 (CNC programs only, no die tooling)
- Unit cost at 1000 pcs: $8–14 each
- Colors: Space Gray (dark PVD), Starlight Silver (brushed silver)
- Source: Same CM or CNC machining shops on Alibaba — search "46mm watch case CNC aluminum 6061"

Both options share the same dimensions:
- Outer diameter: 46.0 mm
- Case depth (back to bezel): 11.5 mm
- Lug width: 22 mm
- Crown protrusion: 3 mm from case side, right side at 3 o'clock position
- SOS button: left side at 9 o'clock position

### 0.2 Bezel ring

A separate brushed aluminum ring, 1.5 mm wide, press-fit around the display cutout. This creates the premium look of a watch-within-a-watch. Available in silver and black.

- Material: 6061-T6 aluminum, micro-bead blasted
- Inner diameter: 39.5 mm (fits over the 360×360 display module)
- Height: 1.0 mm above the display surface
- Source: Order with the case from the same CM — specify "bezel insert ring, press-fit, 39.5mm ID, 1.5mm width"
- Cost: included in case tooling, $0.20–0.50 per unit additional

### 0.3 Crystal

- Shape: Round, 39.0 mm diameter
- Thickness: 1.2 mm (upgraded from 1.0 mm — more impact-resistant)
- Material: Sapphire crystal (Al₂O₃ monocrystalline)
- Coating: Anti-reflective both sides (inside and outside faces)
- Source: Shenzhen Sapphire Technology: https://www.sz-sapphire.com — specify "39mm round sapphire 1.2mm AR both sides"
- Cost at 500 pcs: $2.50–4.00 each (250–200 EGP)

### 0.4 Crown button

Knurled metal crown — looks and feels like a real watch crown.
- Material: Zinc alloy, silver or black PVD to match case
- Shape: Cylindrical, 5 mm diameter, 3 mm protrusion from case, knurled grip texture
- Function v1.0: click only (go to main face, wake display)
- Function v1.1: rotation will be added (rotary encoder for scroll and zoom)
- O-ring seal: 1.0 mm cross-section NBR O-ring on crown shaft for IP67
- Source: Order with case from same CM

### 0.5 Strap options

**Included in box — Fluoroelastomer sport strap:**
- Material: Fluoroelastomer (FKM) — more durable and sweat-resistant than regular silicone
- Lug width: 22 mm
- Length: 135 mm + 95 mm (short + long section, fits 140–195 mm wrist)
- Clasp: Stainless steel butterfly clasp
- Quick-release: Yes, tool-free spring bar
- Colors: Midnight Black, Ocean Blue, Forest Green, Sand Beige, Coral Red, Cloud White — 6 colors, all on same mold with color injection
- Source: Alibaba "22mm FKM fluoroelastomer watch strap quick release butterfly clasp"
- Cost at 1000 pcs: $1.00–1.80 each (50–90 EGP)

**Sold separately — Metal mesh strap:**
- Material: 316L stainless steel mesh
- Lug width: 22 mm
- Adjustment: Magnetic folding clasp with micro-adjust
- Colors: Silver, Gold
- Source: Alibaba "22mm stainless steel mesh watch strap magnetic clasp"
- Retail price suggestion: 400–600 EGP

**Sold separately — Genuine leather strap:**
- Material: Top-grain cowhide leather, quick-release
- Colors: Dark Brown, Black
- Source: Alibaba "22mm genuine leather watch strap quick release"
- Retail price suggestion: 350–500 EGP

### 0.6 Color SKUs for v2.0

Three launch SKUs:

| SKU | Case | Bezel | Strap included |
|---|---|---|---|
| VY-BLK | Midnight Black ZA-8 PVD | Black | Midnight Black FKM |
| VY-SLV | Cloud Silver ZA-8 PVD | Silver | Cloud White FKM |
| VY-PRO | Space Gray CNC Aluminum | Silver | Midnight Black FKM |

### 0.7 Engraving and branding

All engraving is laser-engraved on the case back using a fiber laser engraver at the CM.

Case back engraving:
```
VEYRO
by Cambric
SN: XXXXXXXXXX
FW: 5.0.0
[FCC ID mark]  [CE mark]  IP67
```

Serial number format: `VY2`+`YYMM`+`5-digit-sequence`. Example: `VY22609000001` for unit 1 made September 2026.

The serial number is also stored in NVS at the factory and returned in the BLE info characteristic.

### 0.8 Packaging design

**Outer sleeve:**
- Matte black cardboard, 105×105×55 mm
- Cambric logo (wordmark) silver foil on top face
- "VEYRO" in large silver text on front face
- "by Cambric" in small white text below
- Die-cut window on top sleeve: shows watch face through acetate

**Inner tray:**
- Foam-lined tray, watch seated face-up in a recessed circle
- Magnetic cable in a separate foam slot
- Two spare straps in a small envelope
- Quick-start card (100×80 mm, matte black, QR code in white)

**Box contents:**
1. Veyro watch (charged to 30%)
2. USB-C to magnetic pogo charging cable, 50 cm
3. Two spare straps (different colors, one of each)
4. Quick-start card with QR code linking to https://github.com/Cambric-software/Digital-saver/releases
5. Cambric sticker sheet (3 stickers: logo, VEYRO wordmark, small heart)

**Charging cable upgrade:** USB-C to 2-pin magnetic pogo (upgraded from USB-A in v1.0). Works with any USB-C charger or power bank.

### 0.9 Aesthetics checklist before tooling order

- [ ] Case dimensions verified against PCB layout (board must fit with 0.5 mm clearance on all sides)
- [ ] Display cutout diameter matches AMOLED module outer diameter ±0.1 mm
- [ ] Optical window on case back centered on VC31B sensor ±0.3 mm
- [ ] Crown shaft hole diameter matches crown O-ring spec
- [ ] SOS button hole diameter and depth match button stem
- [ ] Magnetic charging pogo pin positions match PCB pad positions
- [ ] All branding text approved by Cambric before engraving
- [ ] Packaging die-cut window size matches display face visible area
- [ ] All 3 SKU color combinations photographed for store listing

---

## Stage 1 — Obtain all components

EGP prices based on USD/EGP ≈ 50 as of September 2026. Verify rate before ordering.

For Egypt sourcing: **LCSC** (https://lcsc.com, 1–2 weeks to Egypt) for SMT components. **Mouser Egypt** (https://eg.mouser.com) for TI and Bosch parts. **Digi-Key** (https://www.digikey.com) ships to Egypt. For mechanical parts, use Alibaba.com directly.

### 1.1 Electronic components

| # | Component | Exact part number | Supplier | Price USD (qty 1000) | Price EGP (qty 1000) |
|---|---|---|---|---|---|
| 1 | MCU | ESP32-S3-MINI-1U-N16R8 | Mouser 972-ESP32-S3-MINI-1U-N16R8 · Digi-Key · LCSC | $4.00–5.00 each | 200–250 EGP each |
| 2 | PPG sensor (HR/SpO2/HRV) | VC31B | LCSC C2678164 (https://www.lcsc.com/product-detail/C2678164.html) · Direct from Vcare Technology: http://www.vcare-tech.com | $1.80–2.80 each | 90–140 EGP each |
| 3 | IMU | QMI8658CULT | LCSC C2851264 | $0.80–1.20 each | 40–60 EGP each |
| 4 | Pressure + altitude sensor | BMP581BEAA | Digi-Key 828-BMP581BEAA-ND · Mouser 828-BMP581BEAA · LCSC C2842781 | $1.20–1.80 each | 60–90 EGP each |
| 5 | Skin temperature sensor | STTS22HQTR | Digi-Key 497-STTS22HQTR-ND · Mouser · LCSC C2678165 | $0.60–1.00 each | 30–50 EGP each |
| 6 | Display | 1.43 inch AMOLED 360×360 round SPI module | AliExpress "1.43 inch AMOLED 360x360 round watch display" · Alibaba OEM panel suppliers. Driver IC: JD9613 or compatible. Confirm 3.3 V SPI, round, 360×360 at checkout. | $12–18 each | 600–900 EGP each |
| 7 | Touch controller | FT6336GQQ | LCSC C2678163 · Digi-Key 1135-FT6336GQQ-ND | $0.60–1.00 each | 30–50 EGP each |
| 8 | PMIC | BQ25895RTWR | Mouser 595-BQ25895RTWR · Digi-Key 296-49656-1-ND · LCSC | $1.50–2.50 each | 75–125 EGP each |
| 9 | Haptic controller | DRV2605LYZF4 | Digi-Key 296-38834-1-ND · LCSC C266086 | $1.20–2.00 each | 60–100 EGP each |
| 10 | LRA haptic motor | Jinlong JMC0630A 4 mm LRA | LCSC · AliExpress "4mm LRA linear vibration motor 170Hz 3V" | $0.50–1.00 each | 25–50 EGP each |
| 11 | LiPo battery | GREPOW 654040 600 mAh with PCM | Email sales@grepow.com · Alibaba "GREPOW 654040 600mAh lipo PCM JST-PH". Dimensions 6.5×40×40 mm. | $3.50–5.00 each | 175–250 EGP each |
| 12 | Battery NTC | Murata NCP15WF104F03RC 100 kΩ | Digi-Key 490-2143-1-ND · LCSC C209399 | $0.05–0.10 each | 3–5 EGP each |
| 13 | 3.3 V LDO | AP2112K-3.3TRG1 | Digi-Key 1262-1082-1-ND · LCSC C51118 | $0.10–0.20 each | 5–10 EGP each |
| 14 | USB-C connector | UJC-HP-3-SMT-TR | Digi-Key 2057-UJC-HP-3-SMT-TRCT-ND · LCSC C2765186 | $0.20–0.40 each | 10–20 EGP each |
| 15 | TVS diode (USB ESD) | PRTR5V0U2XS SOT-363 | Digi-Key 568-4680-1-ND · LCSC C12333 | $0.10–0.20 each | 5–10 EGP each |
| 16 | Ferrite bead | BLM18KG221TN1D 0603 | Mouser 81-BLM18KG221TN1D · LCSC C1015 | $0.05–0.10 each | 3–5 EGP each |
| 17 | 22 Ω resistors ×6 | Any 22 Ω 0402 | LCSC C137853 | $0.002 each | 0.10 EGP each |
| 18 | 4.7 kΩ resistors ×6 | Any 4.7 kΩ 0402 | LCSC C25905 | $0.002 each | 0.10 EGP each |
| 19 | 100 nF decoupling ×12 | 100 nF 0402 16 V X5R | LCSC C14663 | $0.003 each | 0.15 EGP each |
| 20 | 10 µF bulk caps ×6 | 10 µF 0402 10 V X5R | LCSC C19702 | $0.01 each | 0.50 EGP each |
| 21 | RGB LED | WS2812B-2020 | LCSC C965555 | $0.05–0.10 each | 3–5 EGP each |
| 22 | Crown tactile button | TS-1187A-B-A-B right-angle | Digi-Key CKN10361CT-ND · LCSC C393942 | $0.10–0.20 each | 5–10 EGP each |
| 23 | SOS tactile button | TS-1187A-B-A-B right-angle | Same as crown | $0.10–0.20 each | 5–10 EGP each |

**Estimated electronic BOM at 1000 units: $28–46 per unit.** Use Mouser BOM upload, Digi-Key BOM manager, or LCSC BOM tool for exact quotes.

### 1.2 Mechanical components

| # | Component | Specification | Supplier | Price USD (qty 500) | Price EGP (qty 500) |
|---|---|---|---|---|---|
| 1 | Watch case (Option A) | ZA-8 die-cast, 46 mm round, 11.5 mm depth, PVD coating | Alibaba "46mm smartwatch case ZA-8 PVD custom tooling". Tooling $800–1200 one-time. | $4–7 each + tooling | 200–350 EGP each |
| 2 | Watch case (Option B) | CNC 6061-T6 aluminum, 46 mm round, bead-blast + PVD | Alibaba "46mm watch case CNC aluminum 6061 bead blast" | $8–14 each | 400–700 EGP each |
| 3 | Bezel ring | Aluminum 6061, brushed, 39.5 mm ID, 1.5 mm wide, press-fit | Order with case CM | $0.20–0.50 each | 10–25 EGP each |
| 4 | Sapphire crystal | Round 39.0 mm diameter, 1.2 mm thick, AR coating both sides | Shenzhen Sapphire Technology: https://www.sz-sapphire.com | $2.50–4.00 each | 125–200 EGP each |
| 5 | FKM sport strap | 22 mm, FKM fluoroelastomer, butterfly clasp, quick-release | Alibaba "22mm FKM watch strap butterfly clasp quick release" | $1.00–1.80 each | 50–90 EGP each |
| 6 | Crown assembly | Knurled zinc alloy crown, 5 mm diameter, matching case color | Order with case CM | $0.30–0.60 each | 15–30 EGP each |
| 7 | Spring bars | 1.5 mm diameter, 22 mm, stainless steel | Order with case | $0.10–0.20 per pair | 5–10 EGP per pair |
| 8 | Magnetic USB-C charging cable | 2-pin pogo, 5 V, 50 cm, USB-C to pogo | Alibaba "2 pin magnetic pogo charging cable USB-C 50cm smartwatch" | $0.90–1.60 each | 45–80 EGP each |
| 9 | Crown O-ring | NBR, 1.0 mm cross-section, 3.5 mm ID | Alibaba "NBR O-ring 3.5mm ID 1.0mm CS" pack of 100 | $0.05 each | 2.50 EGP each |
| 10 | SOS button O-ring | NBR, 1.0 mm cross-section, 3.0 mm ID | Same source | $0.05 each | 2.50 EGP each |
| 11 | UV-cure adhesive | Loctite 3491, 50 mL bottle | RS Components Egypt: https://eg.rs-online.com · Mouser | $25–40 per bottle | 1250–2000 EGP per bottle |
| 12 | RTV silicone sealant | Dow Corning 3140 RTV, 90 mL tube | RS Components, Mouser, or local industrial supplier | $15–25 per tube | 750–1250 EGP per tube |
| 13 | Kapton tape strips | 10 mm × 50 mm strips, polyimide | AliExpress "Kapton tape polyimide" roll, cut to size | $0.02 each | 1 EGP each |
| 14 | Retail packaging | Matte black box 105×105×55 mm, silver foil print, die-cut window | Cairo print shops: El-Abbaseyya St, or Vistaprint Egypt. Specify 350 gsm, CMYK+silver foil, die-cut. | $0.50–1.20 each | 25–60 EGP each |

**Estimated mechanical BOM at 500 units: $10–20 per unit** (Option A case, excluding one-time tooling).

### 1.3 Total BOM cost summary

| Cost category | USD per unit | EGP per unit |
|---|---|---|
| Electronic components | $28–46 | 1400–2300 EGP |
| Mechanical (Option A case) | $10–20 | 500–1000 EGP |
| PCB fab + SMT assembly (JLCPCB) | $5–10 | 250–500 EGP |
| Packaging + accessories | $3–5 | 150–250 EGP |
| Case tooling amortized at 1000 units | $1–2 | 50–100 EGP |
| Labor + QA | $5–8 | 250–400 EGP |
| **Total cost per unit** | **$52–91** | **2600–4550 EGP** |

**Pricing for 1500–2000 EGP gross profit per unit:**
- Cost: ~3500 EGP (mid-estimate)
- Gross profit target: 1500–2000 EGP
- Retail price: **5000–5500 EGP ($100–110 USD)**
- This is achievable for this quality level in the Egyptian market.

### 1.4 PCB fabrication

Order from JLCPCB (https://jlcpcb.com) or PCBWay (https://www.pcbway.com):

| Parameter | Value |
|---|---|
| Layers | 4 |
| Board thickness | 0.8 mm |
| Surface finish | ENIG |
| Copper weight | 1 oz outer, 0.5 oz inner |
| Min trace/space | 0.1 mm / 0.1 mm |
| Min drill | 0.2 mm |
| Board outline | Round, 35 mm diameter (enlarged for 46 mm case) |
| Impedance control | Yes, 50 Ω RF trace layer 1 |
| Conformal coating | Applied post-assembly, ordered separately |
| IPC class | IPC Class 2 |

---

## Stage 2 — PCB design

### 2.1 Schematic — ESP32-S3-MINI-1U GPIO assignments

| GPIO | Connected to | Notes |
|---|---|---|
| GPIO 0 | Crown button + BOOT | Active low, 10 kΩ pull-up, 100 nF to GND |
| GPIO 1 | Sensor I2C B — SDA | VC31B, QMI8658C, BMP581, STTS22H, DRV2605L |
| GPIO 2 | Sensor I2C B — SCL | Same bus |
| GPIO 3 | QMI8658C INT2 | Step interrupt, 10 kΩ pull-down |
| GPIO 4 | Touch I2C A — SDA | FT6336G only |
| GPIO 5 | Touch I2C A — SCL | FT6336G only |
| GPIO 6 | FT6336G INT | Active low, 10 kΩ pull-up |
| GPIO 7 | Display backlight PWM | LEDC channel 0, 1 kHz |
| GPIO 8 | Display DC | Data/Command |
| GPIO 9 | Display RST | Active low |
| GPIO 10 | Display CS | SPI chip select, active low |
| GPIO 11 | Display MOSI | SPI data, 80 MHz |
| GPIO 12 | Display CLK | SPI clock, 80 MHz |
| GPIO 13 | SOS button | Active low, 10 kΩ pull-up, 2 s hold |
| GPIO 14 | Battery NTC ADC | ADC1 channel 3, 100 kΩ pull-up to 3.3 V |
| GPIO 15 | PMIC INT | Active low, 4.7 kΩ pull-up |
| GPIO 17 | PMIC I2C C — SDA | BQ25895 only |
| GPIO 18 | PMIC I2C C — SCL | BQ25895 only |
| GPIO 19 | USB D− | Native USB 1.1, through PRTR5V0U2XS |
| GPIO 20 | USB D+ | Native USB 1.1, through PRTR5V0U2XS |
| GPIO 21 | RGB LED data | WS2812B-2020, level shift if needed |
| GPIO 22 | BMP581 INT | Active low pressure interrupt, 10 kΩ pull-up |
| GPIO 23 | STTS22H DRDY | Data ready, active low, 10 kΩ pull-up |
| EN | Reset | 10 kΩ pull-up, 100 nF to GND |

### 2.2 Sensor connections on I2C bus B (GPIO 1 SDA, GPIO 2 SCL)

All sensors share I2C bus B. Each uses a separate I2C address. Add 4.7 kΩ pull-ups to 3.3 V on SDA and SCL. Add 22 Ω series resistors on each sensor's SDA and SCL.

| Sensor | I2C address | VDD | INT pin |
|---|---|---|---|
| VC31B | 0x33 | 3.3 V via 100 nF + ferrite bead | Not connected v1.0 |
| QMI8658C | 0x6A (SA0 to GND) | 3.3 V via 100 nF | INT2 → GPIO 3 |
| BMP581 | 0x47 (SDO to GND) | 3.3 V via 100 nF | INT → GPIO 22 |
| STTS22H | 0x3C (A0, A1 to GND) | 3.3 V via 100 nF | DRDY → GPIO 23 |
| DRV2605L | 0x5A | 3.3 V via 100 nF | Not connected |

**VC31B placement:** place VC31B on PCB bottom side, optical windows (2 LEDs + 1 PD) aligned to the optical windows in the case back. The case back must have 3 holes: two 1.0 mm holes for LEDs and one 1.5 mm hole for the photodiode, matching the VC31B package footprint exactly.

### 2.3 BQ25895 PMIC connections

| Pin | Connected to | Value |
|---|---|---|
| VBUS | USB-C VBUS via TVS diode | 5 V |
| PMID | VSYS → 3.3 V LDO input | System power |
| BAT | LiPo JST-PH positive | Battery |
| SDA | GPIO 17, 22 Ω series | With 4.7 kΩ pull-up |
| SCL | GPIO 18, 22 Ω series | With 4.7 kΩ pull-up |
| /INT | GPIO 15 | 4.7 kΩ pull-up |
| /STAT | Charge LED (optional) | Open-drain |
| ILIM | 56 kΩ to GND | 500 mA input limit |
| ICHG | 15 kΩ to GND | 450 mA charge current (0.75 C for 600 mAh) |
| THM | Battery NTC midpoint | 10 kΩ NTC + 100 kΩ pull-up |

### 2.4 PCB layout rules

1. Antenna keep-out: 3 mm copper-free on all 4 layers around ESP32-S3-MINI-1U antenna edge.
2. VC31B placement: bottom of PCB, centered on optical windows in case back. Optical window positions must match VC31B package exactly — no tolerance for misalignment.
3. BMP581 isolation: place 0.5 mm away from any heat-generating components. Add a small cutout in the PCB under BMP581 if possible for better pressure sensing.
4. STTS22H placement: top of PCB, near the wrist-contact face. Do not place near the BQ25895 or any power dissipating components — heat would corrupt readings.
5. Power decoupling: 100 nF within 0.5 mm of every VDD pin. 10 µF within 2 mm of each rail.
6. I2C bus routing: keep all bus B traces < 50 mm. Run together, away from SPI display traces.
7. SPI display: CLK, MOSI, CS, DC, RST length-matched ±2 mm, on same layer, ground plane below.
8. USB differential pair: D+ and D− length-matched within 0.1 mm, away from all other high-frequency traces.
9. Ground planes: layers 2 (GND) and 3 (PWR) solid pours, stitching vias every 2 mm.
10. Test points: 0.8 mm pads on 3.3 V, VBAT, VBUS, I2C B SDA, I2C A SDA, PMIC SDA, GPIO 0, EN.

### 2.5 Design review checklist

- [ ] Antenna keep-out clear all 4 layers
- [ ] VC31B bottom-side, optical windows aligned to case back holes
- [ ] BMP581 isolated from heat sources
- [ ] STTS22H away from power components
- [ ] All I2C address conflicts verified (no two devices on same bus share same address)
- [ ] USB differential pair length-matched
- [ ] 100 nF on every IC power pin within 0.5 mm
- [ ] BQ25895 ICHG resistor is 15 kΩ (not 22 kΩ from v1.0)
- [ ] Test points on all listed signals
- [ ] Board outline is 35 mm circle
- [ ] ENIG and IPC Class 2 specified
- [ ] DRC passes zero errors

---

## Stage 3 — PCB assembly

Send Gerbers + BOM + CPL to JLCPCB SMT Assembly or PCBWay Assembly.

Specify in order notes:
- AOI after reflow: required
- X-ray for ESP32-S3-MINI-1U: required
- No-clean flux only
- Reflow peak: 249 °C max (SAC305)

Hand-solder at Cambric after receiving assembled boards:
1. USB-C connector UJC-HP-3-SMT-TR: flux the pads, anchor shell tabs first at 350 °C, then solder 16 signal pins with fine tip
2. JST-PH 2.0 mm battery connector: right-angle, 2-pin
3. Two TS-1187A-B-A-B tactile buttons: right-angle, crown and SOS
4. Display FPC connector: hot air at 280 °C on pads only

Post-assembly inspection:
1. 10× magnification visual: no bridges, no tombstones, no missing parts
2. Multimeter: 3.3 V test point to GND = 0 V before power (no shorts)
3. Connect USB-C: VBUS test point = 4.75–5.25 V
4. 3.3 V rail test point = 3.2–3.4 V
5. Failed board: set aside for rework, do not proceed

---

## Stage 4 — Firmware flashing

### 4.1 Flash station setup

Install ESP-IDF v5.2:
```
git clone --recursive https://github.com/espressif/esp-idf.git
cd esp-idf
git checkout v5.2
./install.sh esp32s3
. ./export.sh
```

### 4.2 Connect the board

ESP32-S3-MINI-1U uses native USB. Connect USB-C. Device appears as `/dev/ttyACM0` (Linux), `COMx` (Windows), `/dev/cu.usbmodem` (Mac). If no device appears: hold BOOT (GPIO 0 test point via pogo), connect USB, release BOOT.

### 4.3 Flash command

```
esptool.py --chip esp32s3 --port YOUR_PORT --baud 921600 \
  --before default_reset --after hard_reset write_flash \
  -z --flash_mode dio --flash_freq 80m --flash_size 16MB \
  0x0000 bootloader.bin \
  0x8000 partition-table.bin \
  0x10000 firmware.bin
```

### 4.4 Verify firmware hash

```
esptool.py --chip esp32s3 --port YOUR_PORT verify_flash 0x10000 firmware.bin
```

Pass: `verify_flash` exits with code 0. Record board serial + firmware version in factory database.

### 4.5 Write serial number to NVS

After flashing and before factory test:
```python
# Python script using esptool NVS tool
nvs_partition_gen.py generate nvs_config.csv nvs_data.bin 0x6000
esptool.py write_flash 0x9000 nvs_data.bin
```

`nvs_config.csv` for this unit:
```
key,type,encoding,value
veyro,namespace,,
serial,data,string,VY22609000001
fw_version,data,string,5.0.0
```

### 4.6 Factory self-test

Hold BOOT at power-on. Firmware enters factory test mode:
1. RGB LED: red 1 s → green 1 s → blue 1 s
2. Haptic: strong click → double click → alert
3. I2C scan bus B: confirm addresses 0x33 (VC31B), 0x6A (QMI8658C), 0x47 (BMP581), 0x3C (STTS22H), 0x5A (DRV2605L)
4. I2C scan bus A: confirm 0x38 (FT6336G)
5. I2C scan bus C: confirm 0x6B (BQ25895)
6. BMP581: read pressure, must return 900–1100 hPa
7. STTS22H: read temperature, must return 15–45 °C
8. VC31B: place on fingertip 15 s, must return HR 50–120 BPM
9. Display: fill red → green → blue, no dead pixels, no row lines
10. Touch: show 5 dots, tap each, all must register within 5 mm
11. Print PASS/FAIL per sensor over USB serial 115200

Unit proceeds only if all sensors PASS.

---

## Stage 5 — Display bring-up

### 5.1 AMOLED display

The 1.43 inch 360×360 round AMOLED module uses an SPI interface compatible with the JD9613 or similar driver IC. The initialization sequence varies by manufacturer — request the initialization register table from your display supplier when ordering.

General initialization sequence:
1. Hold RST (GPIO 9) low for 50 ms, then high.
2. Wait 120 ms for display controller internal reset.
3. Send the initialization command table provided by the display supplier via SPI.
4. Send `0x29` (Display ON command).
5. Fill screen black (send 360×360 pixels all 0x0000).
6. Enable backlight PWM on GPIO 7 at 60% duty cycle.

If the display is blank after init: verify CS (GPIO 10) is held low during SPI transfers. Verify DC (GPIO 8) is low for commands and high for data. Reduce SPI clock to 10 MHz during bring-up, increase to 80 MHz after confirming display responds.

AMOLED power consumption note: at 360×360 AMOLED, a fully black screen draws ~2 mA. A fully white screen draws ~25 mA. Always use dark themes in the UI to maximize battery life.

### 5.2 FT6336G touch controller

I2C address 0x38. Power-up sequence: hold RST low 10 ms, then high. Wait 200 ms.

Read touch data from:
- Register 0x02: number of touch points (0 or 1 for v1.0)
- Register 0x03–0x04: X coordinate high/low (10-bit)
- Register 0x05–0x06: Y coordinate high/low (10-bit)
- Register 0x01: gesture ID (0x10 = move up, 0x14 = move down, 0x1C = move left, 0x18 = move right, 0x48 = zoom in, 0x49 = zoom out)

Use gesture register for swipe navigation. Use X/Y for tap. INT pin (GPIO 6) goes low on touch — use interrupt-driven reading, not polling.

### 5.3 LVGL configuration

Install LVGL 8.3 via ESP-IDF component registry:
```
idf.py add-dependency "lvgl/lvgl==8.3.*"
```

`lv_conf.h` settings:
- `LV_HOR_RES_MAX` = 360
- `LV_VER_RES_MAX` = 360
- `LV_COLOR_DEPTH` = 16
- `LV_DPI_DEF` = 160
- Buffers: two buffers of 360×45 = 32400 bytes each, allocated in PSRAM (`heap_caps_malloc(buf_size, MALLOC_CAP_SPIRAM)`)
- Double buffering: `LV_DISP_DRAW_BUF_2`
- Round screen mask: use `lv_disp_set_antialiasing()` and a circular clip in the root screen

Flush callback: use `esp_lcd_panel_io_tx_color()` from ESP-IDF esp_lcd component with SPI DMA. Call `lv_disp_flush_ready()` in the DMA completion callback, not before.

Call `lv_timer_handler()` every 5 ms from `task_display` on Core 1.

---

## Stage 6 — Production firmware architecture

The production firmware lives in `firmware/esp32s3/`. It is an ESP-IDF v5.2 project. Main source: `firmware/esp32s3/main/veyro_main.c`.

### 6.1 FreeRTOS task table

| Task | Core | Stack (bytes) | Priority | Tick rate | Purpose |
|---|---|---|---|---|---|
| `task_sensors` | 0 | 8192 | 5 | 25 ms | VC31B + QMI8658C read, HR/SpO2/HRV/steps/fall |
| `task_ble` | 0 | 16384 | 4 | Event | NimBLE GATT, OTA, commands, bonding |
| `task_storage` | 0 | 8192 | 3 | 1000 ms | LittleFS CSV write, NVS steps save, prune |
| `task_display` | 1 | 24576 | 5 | 5 ms | LVGL render, touch events, face switching |
| `task_haptic` | 1 | 4096 | 6 | Queue | DRV2605L effect playback |
| `task_power` | 0 | 4096 | 2 | 5000 ms | BQ25895 battery %, charging status |
| `task_env` | 0 | 4096 | 2 | 10000 ms | BMP581 pressure/altitude, STTS22H temperature |
| `task_watchdog` | 0 | 2048 | 7 | 1000 ms | Monitor all tasks, reset if any hangs > 30 s |

### 6.2 task_sensors — health data pipeline

Every 25 ms:
1. **VC31B read**: call `vc31b_read_hr_spo2()`. Returns `hr_bpm` (int), `spo2_pct` (int), `rr_ms` (int array of last 8 RR intervals).
2. **Heart rate smoothing**: `g_hr_bpm = 0.85 * g_hr_bpm + 0.15 * new_hr`. Reject values outside 30–220 BPM.
3. **HRV calculation**: from last 8 RR intervals, compute RMSSD: `sqrt(mean of squared successive differences)`. Store as `g_hrv_ms`.
4. **Stress index**: `g_stress = (int)(100.0f - (g_hrv_ms / 100.0f * 100.0f))`. Clamp 0–100.
5. **Activity zone**: based on `g_hr_bpm`: <60=resting, 60-100=fat_burn, 100-140=cardio, 140-170=peak, >170=max.
6. **QMI8658C read**: `qmi8658_read_accel(&ax, &ay, &az)`. Compute magnitude: `mag = sqrt(ax*ax + ay*ay + az*az)`.
7. **Fall detection v2**: check QMI6858C gyroscope. Fall confirmed if: `mag < 0.4g` for `> 80ms` AND subsequent `mag > 2.5g` AND `gyro_rate > 200 deg/s`. Set `g_fall = true`, queue haptic effect 47.
8. **Steps via QMI hardware pedometer**: QMI6858C INT2 (GPIO 3) fires every 10 steps. ISR increments `g_steps += 10`. No polling needed.
9. **Sleep detection**: if `g_hr_bpm < 75` AND `mag < 0.15g` sustained for 600 consecutive samples (10 minutes): set `g_sleep_mode = true`. Track sleep stages every minute from HR:
   - deep: HR < 58
   - rem: HR 58–68, occasional motion spike
   - light: HR 68–78
10. **Post event**: post `sensor_event_t` to `g_sensor_queue` (size 16) for `task_ble` and `task_storage` to consume.

### 6.3 task_ble — BLE v2 protocol

Uses NimBLE (`idf_component.yml` dependency: `espressif/esp-nimble-cpp`).

Service UUID: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`

Characteristics:
- Live `26a8` NOTIFY: send every 1 s when paired. JSON:
  `{"v":2,"hr":72,"spo2":98,"hrv":45,"stress":35,"steps":3421,"floors":3,"alt":54,"temp":33.2,"bat":78,"fall":0,"zone":1,"weather":0,"ts":1726000000}`
- History `26a1` NOTIFY: stream rows on sync command. CSV row format:
  `unix,hr,spo2,hrv,stress,steps,floors,altitude,skin_temp,battery,fall,zone`
- Info `26a2` READ: `{"v":2,"fw":"5.0.0","serial":"VY22609000001","name":"Veyro","paired":true,"samples":1440,"retain_d":60,"free_kb":8192,"bat":78,"charging":false}`
- Command `26f0` WRITE: JSON commands (see list below)
- Notifications `26b0` WRITE: `{"op":"notify","title":"WhatsApp","body":"Ahmed: Hey","icon":1}`
- OTA data `26c0` WRITE NO RESPONSE: raw binary chunks, 512 bytes max

Commands handled:
- `pair`: `{"op":"pair","pin":"123456"}` — verify PIN, set bonding
- `time`: `{"op":"time","unix":1726000000}` — set RTC
- `face`: `{"op":"face","face":0}` — switch watch face 0–7
- `sync`: `{"op":"sync"}` — start history stream
- `next`: `{"op":"next"}` — advance history stream
- `prune`: `{"op":"prune"}` — run file pruning
- `ota_start`: `{"op":"ota_start","size":524288,"sha256":"abc123"}` — begin OTA
- `ota_chunk`: `{"op":"ota_chunk","seq":0}` + binary via `26c0`
- `ota_finish`: `{"op":"ota_finish"}` — verify hash, set boot partition, restart
- `set_bg`: `{"op":"set_bg","index":0,"size":40000,"sha256":"abc123"}` then binary via `26c0`
- `set_theme`: `{"op":"set_theme","theme":0}` — 0=dark_default, 1=dark_blue, 2=dark_green, 3=amoled_pure_black
- `reset_steps`: `{"op":"reset_steps"}` — zero step counter
- `set_goal`: `{"op":"set_goal","steps":10000,"calories":500,"active_min":30}`
- `get_log`: `{"op":"get_log"}` — stream /log/errors.txt lines via history characteristic

BLE security: Secure Connections, 6-digit static passkey. On first successful pair: call `nimble_port_stop()` — just kidding — store bonding key in NVS. On reconnect: auto-pair using stored bond, no PIN re-entry.

Anti-tamper: 5 wrong PINs → wipe NVS bond key, generate new PIN via `esp_random()`.

### 6.4 task_storage — LittleFS filesystem

Directory structure on 8 MB SPIFFS partition:
```
/d/YYYYMMDD.csv     — daily health data, one row per minute
/cfg/prefs.json     — user settings (theme, face, goals, step count)
/assets/bg0.jpg     — custom background images (max 10, 50 KB each)
/log/errors.txt     — ring buffer error log, max 100 lines
```

CSV row format: `unix,hr,spo2,hrv,stress,steps,floors,altitude,skin_temp,battery,fall,zone`

Every 1000 ms:
1. Check if 60 s elapsed since last sample.
2. If yes and `g_hr_bpm > 30` or `g_steps > 0`: write row to `/d/YYYYMMDD.csv`.
3. Save `g_steps` to NVS key `"steps"` if changed.
4. Save `g_floors` to NVS key `"floors"`.
5. Midnight UTC: reset `g_steps = 0`, `g_floors = 0`, write to NVS, log midnight reset.
6. Every 24 h: run `prune_old_files()` — delete files older than 60 days.
7. If LittleFS free space < 512 KB: delete oldest file, log the deletion.

Background image write (triggered by BLE `set_bg` command):
1. Receive all chunks, reassemble in PSRAM buffer.
2. Verify SHA256 of assembled data.
3. Decode base64 to raw JPEG.
4. Write to `/assets/bgN.jpg` where N is the index.
5. Notify `task_display` to reload background.

### 6.5 task_display — LVGL + watch UI

Every 5 ms: call `lv_timer_handler()`.

Every 100 ms: update all active LVGL widget values from global state.

Touch event ISR: GPIO 6 falling edge → read FT6336G X/Y and gesture → post to LVGL input device queue.

**Watch faces (8 total):**

Face 0 — Main clock:
- Large digital time (Montserrat 72, center)
- Date below (Montserrat 24)
- Heart rate arc (bottom left, green)
- Steps ring (bottom right, amber)
- Battery arc (top right, colored by level)
- BLE indicator dot (top left, green/grey)

Face 1 — Health dashboard:
- Quadrant layout: HR (top left), SpO2 (top right), HRV (bottom left), Stress (bottom right)
- Each quadrant: large value, small label, status indicator dot
- Center: overall health score 0–100

Face 2 — Activity:
- Step ring (large, shows progress to goal)
- Calories, distance, active minutes, floors in small tiles below
- Activity zone label (RESTING / FAT BURN / CARDIO / PEAK / MAX)

Face 3 — Sleep:
- Last night total hours (large)
- Quality score (color-coded)
- Mini pie: deep/REM/light proportions
- Sleep debt in hours

Face 4 — Environment:
- Altitude in meters (large)
- Weather icon (sun/cloud/rain based on pressure trend)
- Pressure in hPa
- Skin temperature in °C

Face 5 — Notifications:
- Last 5 phone notifications, scrollable list
- Title bold, body normal weight
- Auto-dismiss individual items by swipe right

Face 6 — AI quick panel:
- 4 tap targets: "How am I?", "Work focus?", "Improve?", "Help"
- When tapped: sends a BLE notification to the phone app to open AI assistant with that preset query

Face 7 — Custom:
- Layout selected from app via BLE `face` command with layout data
- Default: same as Face 1 until customized

**Navigation gestures:**
- Swipe left/right: previous/next face
- Swipe up: quick settings (brightness slider, BLE toggle, DND toggle, theme toggle)
- Swipe down: notification shade
- Long press: face selector (8 face thumbnails in a grid)
- Crown click: go to Face 0
- Crown click on Face 0: toggle backlight

### 6.6 task_haptic

Waits on `haptic_queue` (size 8). On message: write effect to DRV2605L register 0x04, write 0x01 to register 0x0C (GO). Returns immediately.

Effect catalog:
- Effect 1: Strong Click — button press confirmation
- Effect 10: Double Click — successful pairing
- Effect 47: Alert 500ms — fall detection, low battery warning
- Effect 58: Long Buzz — SOS hold (5 s)
- Effect 14: Tick — face swipe feedback
- Effect 16: Soft Bump — touch tap feedback
- Effect 27: Short Buzz — notification received

### 6.7 task_power

Every 5000 ms:
1. Read BQ25895 register 0x0E (VBAT in mV).
2. `g_battery_pct = (vbat_mv - 3300) / (4150 - 3300) * 100`. Clamp 0–100.
3. Read register 0x0B bits [6:5] for charging status.
4. If `g_battery_pct < 10` and not charging: post haptic effect 47 once per hour.
5. If `g_battery_pct < 5`: enter power-save mode (display off, BLE advertising every 60 s, all sensors 4× slower).

### 6.8 task_env

Every 10000 ms:
1. **BMP581**: read raw pressure and temperature. Convert using BMP581 compensation formula from datasheet. Store `g_pressure_hpa`, `g_altitude_m`.
2. **Altitude calculation**: `alt = 44330.0 * (1.0 - pow(pressure_hpa / 1013.25, 0.1903))`.
3. **Floors climbed**: if `g_altitude_m - g_last_floor_alt > 3.0`: `g_floors++`, `g_last_floor_alt = g_altitude_m`.
4. **Weather trend**: compare current pressure to pressure recorded 3 h ago. Store in ring buffer. If drop > 1 hPa/h: `g_weather = RAIN`. If rise: `g_weather = CLEAR`. Else: `g_weather = STEADY`.
5. **STTS22H**: read temperature register (0x01 high + 0x00 low). Convert: `temp_c = (int16_t)(high << 8 | low) / 100.0f`. Store `g_skin_temp_c`. Display as "Skin Temp" only.

### 6.9 task_watchdog

Every 1000 ms: check that each task has posted a heartbeat to a shared array in the last 5000 ms. If any task misses 30 consecutive heartbeats: call `esp_restart()` and log the hanging task name to `/log/errors.txt` before restart.

---

## Stage 7 — Enclosure assembly

### 7.1 Prepare the case

1. Verify dimensions with calipers: outer diameter 46.0 ±0.2 mm, depth 11.5 ±0.2 mm.
2. Verify optical windows on case back: VC31B requires three holes — two 1.0 mm LED holes and one 1.5 mm PD hole, positioned exactly to the VC31B package footprint. Verify positions with a 0.1 mm pin gauge.
3. Clean all internal surfaces with IPA. Dry 5 minutes.
4. Fit NBR O-ring (1.0 mm cross-section, 3.5 mm ID) in crown shaft groove. Press until seated.
5. Fit NBR O-ring (1.0 mm cross-section, 3.0 mm ID) in SOS button shaft groove.

### 7.2 Battery installation

1. Verify battery voltage: 3.5–4.2 V. Do not install below 3.0 V or above 4.25 V.
2. Place GREPOW 654040 flat against case back. JST-PH connector toward PCB.
3. Battery must not contact solder joints or metal edges. Insulate PCM board edges with Kapton tape.

### 7.3 PCB installation

1. Connect display FPC to PCB FPC connector before placing PCB in case.
2. Lower PCB component-side up onto battery.
3. Connect JST-PH battery connector.
4. Insert crown button stem and SOS button stem through their case holes. Confirm free actuation.
5. Snap magnetic charging pogo contacts into case back pads.

### 7.4 Display and bezel installation

1. Press-fit the bezel ring into the case front bezel recess.
2. Apply thin bead of Loctite 3491 UV adhesive to inside of bezel ring.
3. Lower AMOLED module face-up. Press 10 seconds.
4. UV cure: 365 nm, minimum 1000 mW/cm², 30 seconds.

### 7.5 Sapphire crystal installation

1. Apply thin bead of Loctite 3491 UV adhesive to case rim.
2. Lower 39 mm sapphire crystal. Press firmly 30 seconds.
3. UV cure 60 seconds.
4. Wipe excess adhesive immediately with IPA before curing.

### 7.6 Case closure and sealing

1. Press case back onto case front. Friction fit.
2. Apply Dow Corning 3140 RTV along the case back seam.
3. Cure 24 hours before water testing.

### 7.7 Strap installation

1. Insert 22 mm quick-release spring bars.
2. Attach FKM strap. Confirm quick-release click engages and releases cleanly.

---

## Stage 8 — Factory test procedure

### 8.1 Per-unit tests

| Step | Action | Pass condition | Fail action |
|---|---|---|---|
| 1. Power on | USB-C from test jig | Boot < 3 s, display shows Cambric/VEYRO logo | Disassemble, re-flash |
| 2. Display colors | Firmware: red → green → blue full screen | No dead pixels, no row lines | Replace AMOLED module |
| 3. Touch 5 points | Firmware: 5 target dots | All register within 5 mm | Replace or reflow FT6336G |
| 4. HR reading | Fingertip on VC31B 15 s | 50–120 BPM, SNR > 12 dB | Check VC31B placement vs optical windows |
| 5. SpO2 reading | Same finger 15 s | 92–100% | Same as above |
| 6. Pressure | Read BMP581 | 900–1100 hPa | Reflow BMP581, check I2C bus B |
| 7. Temperature | Read STTS22H | 15–45 °C ambient | Reflow STTS22H, check I2C bus B |
| 8. Accel | Tilt ±45° each axis | Values change > 0.5g | Reflow QMI8658C |
| 9. Pedometer | Shake 20 times | Steps increment 15–30 | Check QMI8658C INT2 wiring to GPIO 3 |
| 10. Haptic | Strong click + double + alert | All three felt by operator | Check DRV2605L I2C, check LRA motor |
| 11. BLE scan | Test Android phone | "Veyro" visible in < 10 s | Re-flash, check antenna keep-out |
| 12. BLE pair | Enter PIN | App shows Connected | Check NimBLE Secure Connections config |
| 13. Battery % | Apply 3.80 V to BAT pin | App shows 59–61% | Check BQ25895 VBAT register, NTC wiring |
| 14. Charging | Connect USB-C 5 V | BQ25895 shows fast charging | Check ILIM/ICHG resistors |
| 15. Crown button | Press 3× | Watch face cycles 3× | Check GPIO 0 pull-up and button continuity |
| 16. SOS button | Hold 2 s | Haptic alert, fall flag in app | Check GPIO 13 and button continuity |
| 17. Firmware hash | `esptool.py verify_flash` | Hash matches manifest | Re-flash correct firmware |
| 18. Serial number | Read BLE info characteristic | Serial matches NVS value and case engraving | Re-flash NVS |

### 8.2 Batch tests (1 in 50 units)

**Battery life**: charge to 100%, run BLE connected + display 50% brightness. Record time to 5%. Pass: ≥ 7 days (168 hours).

**IP67**: submerge 1 m fresh water 30 minutes. Dry. Run all per-unit tests. Pass: all pass, no visible ingress.

**Drop test**: 1.2 m onto concrete, 6 faces. Run all per-unit tests. Pass: all pass, no cracks.

**Temperature range**: operate at 0 °C and 40 °C for 30 minutes each. Pass: no condensation, all tests pass.

### 8.3 HR accuracy validation (per batch of 100 units, 3 units, 5 subjects each)

Compare Veyro VC31B HR vs. Nonin PureSAT Model 9590 at rest and light walk.
Pass: mean absolute error ≤ 5 BPM. Fail: adjust VC31B LED current calibration (NVS key `vc31b_led_ma`) and retest.

---

## Stage 9 — App configuration for production

### 9.1 Build the release with Gemini key

```
git tag v2.x.x
git push origin v2.x.x
```

GitHub Actions builds Android + Windows + Linux with `GEMINI_API_KEY` from repository secrets.

### 9.2 Android build.gradle

- `compileSdkVersion 34`, `minSdkVersion 21`, `targetSdkVersion 34`
- `versionName` matches `AppVersion.current`

### 9.3 Required Android permissions

```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

---

## Stage 10 — Regulatory and compliance

| Certification | Body | How to apply | Cost | Required for |
|---|---|---|---|---|
| ETA Egypt | NTRA: https://www.tra.gov.eg | Submit at https://www.tra.gov.eg/en/services with FCC/CE cert + sample unit | $500–2000 | Selling in Egypt |
| FCC Part 15 | FCC: https://www.fcc.gov | Use accredited lab (UL, SGS, Bureau Veritas). Submit at https://apps.fcc.gov | $5,000–15,000 | USA or NTRA recognition |
| CE RED | EU notified body (TÜV Rheinland: https://www.tuv.com) | Submit technical file + test report | $3,000–10,000 | Europe |
| RoHS | Self-declaration | Verify all component datasheets | Internal cost | Everywhere |
| UN 38.3 | Accredited lab | Request GREPOW cert with battery order, or submit to lab | Included with GREPOW / $500–2000 | Air/sea shipping |
| IP67 (IEC 60529) | Accredited IP lab | Submit 5 assembled units | $500–1500 | Claiming IP67 |
| ISO 10993-10 skin | Accredited biocompatibility lab | Submit case back material sample | $1,000–3,000 | Skin contact claim |

**Allowed on packaging:** Heart rate wellness, SpO2 wellness estimate, step and activity tracking, sleep duration tracking, IP67 water-resistant, 7-day battery life (after test), AI health assistant powered by Google Gemini, skin temperature (wrist, not body).

**Not allowed:** Medical grade, ECG, blood pressure measurement, detects AFib, FDA/CE medical approved, body temperature, clinical accuracy.

---

## Stage 11 — Packaging and shipment

### 11.1 Box contents

1. Veyro watch (30% charge, ship mode set)
2. USB-C to 2-pin magnetic pogo charging cable, 50 cm
3. Two spare FKM straps (different colors per SKU)
4. Quick-start card (QR → GitHub releases page)
5. Cambric sticker sheet

### 11.2 Set ship mode (BQ25895 register 0x09 = 0x20)

Run before boxing:
```python
import smbus2
bus = smbus2.SMBus(1)
bus.write_byte_data(0x6B, 0x09, 0x20)
assert bus.read_byte_data(0x6B, 0x09) == 0x20
```

### 11.3 Final check before boxing

| Item | Check |
|---|---|
| Sapphire crystal | Clean, no scratches, bonded flush |
| Bezel ring | Press-fit, no gaps |
| Case | Correct SKU color, no marks |
| Strap | Correct color for SKU, quick-release clicks |
| Engraving | Serial number readable, marks visible |
| Per-unit tests | All 18 passed and logged |
| Firmware hash | Logged in factory database |
| Battery | 25–35% charge |
| Ship mode | Set and verified |

---

## Appendix A — I2C address map

| Device | Bus | Address | SDA GPIO | SCL GPIO |
|---|---|---|---|---|
| FT6336G (touch) | A | 0x38 | GPIO 4 | GPIO 5 |
| VC31B (HR/SpO2) | B | 0x33 | GPIO 1 | GPIO 2 |
| QMI8658C (IMU) | B | 0x6A | GPIO 1 | GPIO 2 |
| BMP581 (pressure) | B | 0x47 | GPIO 1 | GPIO 2 |
| STTS22H (skin temp) | B | 0x3C | GPIO 1 | GPIO 2 |
| DRV2605L (haptic) | B | 0x5A | GPIO 1 | GPIO 2 |
| BQ25895 (PMIC) | C | 0x6B | GPIO 17 | GPIO 18 |

---

## Appendix B — GPIO map

| GPIO | Function | Direction | Notes |
|---|---|---|---|
| 0 | Crown / BOOT | IN | Pull-up, active low |
| 1 | Sensor I2C B SDA | I/O | VC31B, QMI8658C, BMP581, STTS22H, DRV2605L |
| 2 | Sensor I2C B SCL | OUT | |
| 3 | QMI6858C INT2 | IN | Step interrupt, pull-down |
| 4 | Touch I2C A SDA | I/O | FT6336G only |
| 5 | Touch I2C A SCL | OUT | |
| 6 | Touch INT | IN | Active low, pull-up |
| 7 | Display BL PWM | OUT | LEDC channel 0 |
| 8 | Display DC | OUT | |
| 9 | Display RST | OUT | Active low |
| 10 | Display CS | OUT | Active low |
| 11 | Display MOSI | OUT | 80 MHz SPI |
| 12 | Display CLK | OUT | 80 MHz SPI |
| 13 | SOS button | IN | Pull-up, active low, 2 s hold |
| 14 | Battery NTC ADC | IN | ADC1 ch3 |
| 15 | PMIC INT | IN | Pull-up |
| 17 | PMIC I2C C SDA | I/O | BQ25895 only |
| 18 | PMIC I2C C SCL | OUT | |
| 19 | USB D− | I/O | Native USB 1.1 |
| 20 | USB D+ | I/O | Native USB 1.1 |
| 21 | RGB LED data | OUT | WS2812B-2020 |
| 22 | BMP581 INT | IN | Pull-up |
| 23 | STTS22H DRDY | IN | Pull-up |

---

## Appendix C — BLE characteristic UUIDs

| Characteristic | UUID | Direction |
|---|---|---|
| Service | `4fafc201-1fb5-459e-8fcc-c5c9c331914b` | — |
| Live vitals v2 | `beb5483e-36e1-4688-b7f5-ea07361b26a8` | NOTIFY |
| History | `beb5483e-36e1-4688-b7f5-ea07361b26a1` | NOTIFY |
| Info v2 | `beb5483e-36e1-4688-b7f5-ea07361b26a2` | READ |
| Command v2 | `beb5483e-36e1-4688-b7f5-ea07361b26f0` | WRITE |
| Phone notifications | `beb5483e-36e1-4688-b7f5-ea07361b26b0` | WRITE |
| OTA binary data | `beb5483e-36e1-4688-b7f5-ea07361b26c0` | WRITE NO RSP |

---

## Appendix D — Partition table (16 MB flash)

File: `firmware/esp32s3/partitions.csv`

```
# Name,    Type, SubType, Offset,   Size,     Flags
nvs,        data, nvs,     0x9000,   0x6000,
phy_init,   data, phy,     0xf000,   0x1000,
factory,    app,  factory, 0x10000,  0x200000,
ota_0,      app,  ota_0,   0x210000, 0x200000,
ota_1,      app,  ota_1,   0x410000, 0x200000,
otadata,    data, ota,     0x610000, 0x2000,
spiffs,     data, spiffs,  0x620000, 0x9E0000,
```

---

## Appendix E — Release checklist

- [ ] `flutter analyze` zero errors
- [ ] `flutter test` passes
- [ ] Firmware builds without warnings
- [ ] Firmware SHA256 recorded in release notes
- [ ] `AppVersion.current` matches tag
- [ ] `VEYRO_FW_VERSION` matches tag
- [ ] BLE pairing, history sync, OTA tested on physical hardware
- [ ] Gemini AI tested with real key
- [ ] All 7 new sensors confirmed working in factory test mode
- [ ] `docs/manual.md` updated if prototype procedure changed
- [ ] `README.md` updated with new version
- [ ] `SECURITY.md` reviewed
- [ ] GEMINI_API_KEY in GitHub secrets
- [ ] GitHub Actions build passes Android + Windows + Linux

*Cambric · Update before every production run.*
