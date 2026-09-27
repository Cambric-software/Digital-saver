# Veyro Production Watch Specification (Cambric Flagship Edition)

## 1. Commercial Target & Financial Model

This document governs the transition from the benchtop ESP32 DevKit prototype to the commercial store-grade **Veyro Flagship Smartwatch**.

### 7,500 EGP Retail Unit Economics
The retail price is fixed at **7,500 EGP** per unit. All component choices, enclosure tooling, tax liabilities, and warranty reserves must conform to this margin structure:

| Cost Element | Allocation (EGP) | % of Retail | Engineering / Operational Target |
| :--- | :--- | :--- | :--- |
| **Electronics BOM (PCBA)** | 1,850 EGP | 24.7% | ESP32-S3 module, Round Touch Display, PMIC, Sensors, Passives, 4-layer PCB |
| **Enclosure & Glass** | 450 EGP | 6.0% | CNC anodized aluminum chassis, 2.5D curved tempered glass, gasket seal |
| **Strap & Magnetic Charger** | 300 EGP | 4.0% | Fluoroelastomer quick-release band + 2-pin magnetic pogo USB charging cable |
| **Assembly, Calibration & Yield** | 400 EGP | 5.3% | Optical sensor bench calibration, leak testing, 5% scrap/yield loss reserve |
| **Packaging & Documentation** | 200 EGP | 2.7% | Custom matte rigid box, molded EVA insert, printed compliance guide |
| **Taxes & Payment Processing** | 1,200 EGP | 16.0% | Egyptian VAT / Commercial Tax (14%) + Payment Gateway fees (~2%) |
| **Warranty & Support Reserve** | 300 EGP | 4.0% | Hardware replacement buffer (1-year limited warranty) |
| **Net Gross Profit** | **3,000 EGP** | **40.0%** | **Reinvestment into Cambric R&D & operating reserves** |
| **Total Consumer Retail** | **7,500 EGP** | **100.0%** | **Commercial store-ready price** |

---

## 2. Hardware Architecture & Component Upgrades

To justify the 7,500 EGP price point against mass-market alternatives, the watch abandons breadboard DevKits and loose breakout modules in favor of an integrated multi-layer carrier:

| Subsystem | Prototype (DevKit) | Production Flagship (7,500 EGP) | Justification & Specifications |
| :--- | :--- | :--- | :--- |
| **Compute Core** | ESP32-WROOM-32 (240MHz, no PSRAM) | **ESP32-S3-MINI-1-N8R8** | Dual-core Xtensa LX7 @ 240MHz with vector instructions for on-device DSP/AI, 8MB Octal Flash, 8MB Octal PSRAM, BLE 5.0 mesh. |
| **Display Panel** | 0.96" Monochrome SSD1306 (128x64) | **1.28" / 1.43" Circular Touch (GC9A01 or AMOLED)** | Full 240x240 or 466x466 color, 16-bit RGB565, 60 FPS capable, 450+ nits daylight readability, bonded capacitive touch. |
| **Motion Tracking** | MPU6050 (High power draw) | **Bosch BMI270 or QST QMI8658C** | Ultra-low power 6-axis IMU (<15 µA in step-detector mode), hardware wake-on-wrist-raise interrupt. |
| **Optical Vitals** | MAX30102 (Breakout board) | **Maxim MAX30101 / Goodix GH3011** | Integrated glass cover cancellation, multi-wavelength (Green, Red, IR) for robust continuous HR and SpO2. |
| **Power Management** | Unregulated TP4056 + ADC divider | **TI BQ25895 / BQ24074 PMIC + MAX17048** | Active I2C fuel gauge, hardware power-path management, controlled thermal regulation, programmable charge currents. |
| **Battery Cell** | Loose 3.7V LiPo | **Custom 400–500 mAh Li-Po Pouch** | High-density pouch with Seiko hardware protection IC (OVP, UVP, OCP), guaranteed 3-5 days continuous runtime. |
| **Haptic Feedback** | Direct GPIO transistor drive | **TI DRV2605L + Linear Resonant Actuator (LRA)** | Crisp, haptic clicks rather than buzzing motor vibration (Apple-grade haptic feel). |
| **Charging Interface** | Exposed Micro-USB / Type-C | **Gold-Plated 2-Pin Magnetic Pogo Interface** | Completely sealed rear casing with reverse-polarity magnetic alignment; prevents moisture ingress. |

---

## 3. Industrial Design & Mechanical Standards

A premium feel is achieved through tight mechanical tolerances and authentic materials:
1. **Chassis**: Sandblasted, bead-blasted 6000-series anodized aluminum bezel and rim (Space Gray / Matte Black).
2. **Crystal Lens**: Chemically strengthened 2.5D curved tempered glass with oleophobic anti-fingerprint coating.
3. **Rear Sensor Pod**: Polished optical-grade polycarbonate window with flush bezel-less skin contact.
4. **Water Resistance**: Internal silicone compression gaskets designed for IP67 / 3 ATM water resistance (splash, rain, shallow immersion).
5. **Strap System**: Standard 20mm quick-release spring bars paired with custom Cambric-branded fluoroelastomer or silicone bands.

---

## 4. Software & Embedded UI Engine

1. **Graphics Engine**: Fully migrated to **LVGL 9.x (Light and Versatile Graphics Library)** running on FreeRTOS tasks.
2. **Display Abstraction**: Double-buffered DMA transfers over SPI with partial display refresh for smooth 60 FPS dial rendering.
3. **Circular Watch Faces**:
   - Analog Chronograph face with sweeping second hands.
   - Minimalist digital dashboard with live heart rate, daily step ring, and battery arcs.
   - High-contrast emergency / medical glance face.
4. **Offline Memory System**:
   - 60-day LittleFS circular buffer recording 1-minute vitals epochs.
   - Zero data loss during phone disconnection.
5. **Veyro Protocol v2**:
   - High-speed BLE 5.0 attribute MTU negotiation (up to 512 bytes) for instantaneous history sync.
   - Real-time OTA firmware update verification with cryptographic SHA256 checksums and automatic rollback.

---

## 5. Production Acceptance Gates

Every watch unit sold at 7,500 EGP must pass the following factory quality test before packaging:
1. **Sleep Current**: System quiescent sleep current must measure under 80 µA with display off and motion-wake armed.
2. **Touch Calibration**: 9-point capacitive touch verification with zero ghost touches.
3. **Optical SNR**: Green/IR signal-to-noise ratio verified on optical fixture.
4. **Thermal Dissipation**: Casing surface temperature must not exceed 38°C during fast charging.
5. **Water Seal Integrity**: Vacuum decay pressure test to confirm IP67 gasket sealing.
