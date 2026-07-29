# DIGITAL SAVER ONYX SMARTWATCH
## Complete Build Guide & Technical Documentation

**Version:** 3.2.1  
**Last Updated:** July 2026  
**Company:** Cambric  
**Currency:** جميع الأسعار بالجنيه المصري (EGP)

---

# ═══════════════════════════════════════════════════════════════════════════
# PART 1: OVERVIEW & INTRODUCTION
# ═══════════════════════════════════════════════════════════════════════════

# 1. WHAT IS THE ONYX SMARTWATCH?

The Digital Saver Onyx is a custom-built smartwatch that monitors your health and connects to the internet. It's built from scratch using off-the-shelf components and runs custom firmware on an ESP32 microcontroller.

## 1.1 Key Features (v3.2.0)

| Feature | الوصف |
|---------|-------|
| Heart Rate Monitoring | قياس نبض القلب |
| Blood Oxygen (SpO2) | نسبة الأكسجين في الدم |
| Blood Pressure | ضغط الدم |
| Step Counting | عد الخطوات |
| Fall Detection | اكتشاف السقوط |
| Sleep Tracking | تتبع النوم |
| Calorie Tracking | حساب السعرات |
| Stress Detection | كشف التوتر |
| Weather Display | عرض الطقس |
| STEALTH Mode | وضع التخفي |
| WiFi Internet | اتصال بالإنترنت |
| BLE Sync | إرسال البيانات للهاتف |
| User Profiles | ملفات شخصية |
| Advanced Health AI | ذكاء اصطناعي للصحة |

---

# ═══════════════════════════════════════════════════════════════════════════
# PART 2: COMPLETE HARDWARE LIST WITH PRICES (EGP)
# ═══════════════════════════════════════════════════════════════════════════

# 2. قائمة القطع الكاملة بالأسعار

## 2.1 القطع الإلكترونية الرئيسية

| # | القطعة | رقم الجزء | الكمية | السعر بالجنيه | السعر USD | رابط الشراء |
|---|--------|----------|--------|---------------|-----------|--------------|
| 1 | ESP32 Development Board | ESP32-WROOM-32 | 1 | 325 ج.م | $6.50 | https://egypt.tmart.com |
| 2 | MAX30102 Heart Rate Sensor | MAX30102 | 1 | 450 ج.م | $8.99 | https://egypt.tmart.com |
| 3 | MPU6050 Accelerometer | MPU6050 | 1 | 175 ج.م | $3.49 | https://egypt.tmart.com |
| 4 | SSD1306 OLED Display 0.96" | SSD1306 128x64 | 1 | 250 ج.م | $4.99 | https://egypt.tmart.com |
| 5 | TP4056 Battery Charger | TP4056 USB-C | 1 | 75 ج.م | $1.50 | https://egypt.tmart.com |
| 6 | LiPo Battery 500mAh | 502035 | 1 | 250 ج.م | $4.99 | https://egypt.tmart.com |
| 7 | Vibration Motor 3V | 3V ERM | 1 | 50 ج.م | $1.00 | https://egypt.tmart.com |
| 8 | Red LED 3mm | 3mm Red LED | 1 | 5 ج.م | $0.10 | https://egypt.tmart.com |
| 9 | Green LED 3mm | 3mm Green LED | 1 | 5 ج.م | $0.10 | https://egypt.tmart.com |
| 10 | Tactile Buttons 6x6mm | 6x6x5mm | 3 | 3 ج.م | $0.05 | https://egypt.tmart.com |
| 11 | Resistor 220 Ohm | 220R 1/4W | 2 | 1 ج.م | $0.01 | https://egypt.tmart.com |
| 12 | Resistor 10K Ohm | 10K 1/4W | 3 | 2 ج.م | $0.03 | https://egypt.tmart.com |
| 13 | Jumper Wires | M/M 40pcs | 1 | 150 ج.م | $2.99 | https://egypt.tmart.com |
| 14 | Prototype PCB | 5x7cm | 1 | 100 ج.م | $1.99 | https://egypt.tmart.com |
| 15 | Pin Headers | Male 40pin | 1 | 50 ج.م | $1.00 | https://egypt.tmart.com |

**إجمالي electronics: 1,891 ج.م (~$38)**

## 2.2 Case & القطع الميكانيكية

| # | القطعة | الكمية | السعر بالجنيه | السعر USD |
|---|--------|--------|---------------|-----------|
| 16 | 3D Printed Case Top | 1 | 250 ج.م | $5.00 |
| 17 | 3D Printed Case Bottom | 1 | 250 ج.م | $5.00 |
| 18 | Silicone Watch Band | 22mm | 1 | 250 ج.م | $4.99 |
| 19 | Glass Watch Face | 40mm | 1 | 150 ج.م | $2.99 |
| 20 | Screws M1.5x3mm | 4pcs | 25 ج.م | $0.50 |
| 21 | Double Sided Tape | 3M 468MP | 1 | 200 ج.م | $3.99 |

**إجمالي الميكانيكية: 1,125 ج.م (~$22)**

## 2.3 الأدوات المطلوبة

| # | الأداة | السعر بالجنيه | السعر USD |
|---|--------|-------------|-----------|
| 22 | مكواة لحام 60W | 800 ج.م | $15.99 |
| 23 | سلك لحام 0.8mm | 450 ج.م | $8.99 |
| 24 | قاطعات أسلاك | 350 ج.م | $6.99 |
| 25 | مالتيميتر | 650 ج.م | $12.99 |
| 26 | كابل USB Type-C | 300 ج.م | $5.99 |
| 27 | طابعة 3D (اختياري) | 10,000+ ج.م | $200+ |

**إجمالي الأدوات: 2,550 ج.م (~$51)**

## 2.4 ملخص تكلفة البناء

| الفئة | السعر بالجنيه | السعر USD |
|--------|-------------|-----------|
| Electronics | 1,891 ج.م | $37.82 |
| الميكانيكية | 1,125 ج.م | $22.50 |
| الأدوات (إذا غير متوفرة) | 2,550 ج.م | $51.00 |
| **الحد الأدنى للمشروع** | **3,016 ج.م** | **~$60** |
| مع جميع الأدوات | **5,566 ج.م** | **~$110** |

## 2.5 من أين تشتري في مصر

### المتاجر الموصى بها في مصر:

| المتجر | الموقع | ملاحظات |
|--------|--------|----------|
| **Tmart Egypt** | tmart.com | أسعار جيدة، شحن سريع |
| **Banggood** | banggood.com | أسعار رخيصة، شحن أطول |
| **AliExpress** | aliexpress.com | أرخص خيار، 2-4 أسابيع |
| **PC Egypt** | pcEgypt.com | قطع إلكترونية محلية |
| **Future Electronics** | futureelectronics.com | قطع أصلية |

### محلات في القاهرة:

| المحل | العنوان | ملاحظات |
|-------|---------|----------|
| مبرمجين إلكترونيات | شارع_ENTRY | قطع لحام ومكونات |
| الرمال للإلكترونيات | المعادي | قطع متنوعة |

---

# 3. ESP32-WROOM-32 MICROCONTROLLER

## 3.1 مواصفات ESP32

| المواصفة | القيمة |
|-----------|--------|
| المعالج | Xtensa LX6 Dual Core |
| سرعة المعالج | 240 MHz |
| Flash Memory | 4 MB |
| SRAM | 520 KB |
| WiFi | 802.11 b/g/n |
| Bluetooth | BLE 4.2 |
| GPIO Pins | 34 |
| ADC Channels | 18 (12-bit) |
| جهد التشغيل | 3.3V |
| جهد الدخل | 5V عبر USB |
| السعر | 325 ج.م |

## 3.2 توزيع pins

```
         ╔═══════════════════════════════════════╗
    3V3 ║  1 ●                               ● 38 ║ ← GPIO37
    GND ║  2                                 37 ║ ← GPIO38
  GPIO36 ║  3                                 36 ║ ← GPIO35
  GPIO39 ║  4                                 35 ║ ← GPIO34
  GPIO34 ║  5                                 34 ║ ← GPIO33
  GPIO35 ║  6                                 33 ║ ← GPIO32
   GPIO4 ║  7                                 32 ║ ← GPIO25
   GPIO0 ║  8                                 31 ║ ← GPIO26
   GPIO2 ║  9                                 30 ║ ← GPIO27
  GPIO15 ║ 10                                 29 ║ ← GPIO14
    GND ║ 11                                 28 ║ ← GPIO12
  GPIO16 ║ 12                                 27 ║ ← GPIO13
  GPIO17 ║ 13                                 26 ║ ← GPIO15
   GPIO5 ║ 14                                 25 ║ ← GPIO16
  GPIO18 ║ 15          ESP32                24 ║ ← GPIO17
  GPIO19 ║ 16          WROOM-32              23 ║ ← (no connection)
    GND ║ 17          Top View              22 ║ ← GPIO21
         ╚═══════════════════════════════════════╝

PINS المهمة للساعة:
═══════════════════════════════════════════
Pin 18 (GPIO18) = I2C SCL (ساعة البيانات)
Pin 19 (GPIO19) = I2C SDA (بيانات)
Pin 25 (GPIO25) = موتور الاهتزاز
Pin 26 (GPIO26) = MAX30102 Interrupt
Pin 27 (GPIO27) = MPU6050 Interrupt
Pin 4  (GPIO4)  = LED أحمر
Pin 16 (GPIO16) = LED أخضر
Pin 17 (GPIO17) = زر الوضع
Pin 34 (GPIO34) = زر الطوارئ
Pin 35 (GPIO35) = زر الرجوع
Pin 3V3         = طاقة 3.3V
Pin GND         = الأرضي
```

---

# 4. MAX30102 HEART RATE SENSOR

## 4.1 مواصفات MAX30102

| المواصفة | القيمة |
|-----------|--------|
| I2C Address | 0x57 (87) |
| جهد التشغيل | 1.8V - 3.3V |
| Red LED Wavelength | 660 nm |
| IR LED Wavelength | 880 nm |
| Sample Rate | 100 Hz - 3200 Hz |
| ADC Resolution | 18 bits |
| السعر | 450 ج.م |

## 4.2 pins

| MAX30102 Pin | متصل إلى |
|--------------|-----------|
| VIN | ESP32 3V3 |
| GND | ESP32 GND |
| SDA | ESP32 GPIO18 |
| SCL | ESP32 GPIO19 |
| INT | ESP32 GPIO26 |

## 4.3 Registers الأساسية

| Register | Address | الوصف |
|----------|---------|-------|
| FIFO_DATA | 0x07 | قراءة البيانات |
| MODE_CONFIG | 0x09 | إعدادات الوضع |
| LED_CONFIG | 0x0A | سطوع LED |
| SPO2_CONFIG | 0x06 | إعدادات SpO2 |

## 4.4 كود الإعداد

```cpp
#include <SparkFunMAX3010x.h>

MAX30105 particleSensor;

void setup() {
    // Initialize with fast I2C
    if (particleSensor.begin(Wire, I2C_SPEED_FAST)) {
        Serial.println("MAX30102 OK!");
    }
    
    // Configure
    byte ledBrightness = 60;
    byte sampleAverage = 4;
    byte ledMode = 3;
    int sampleRate = 400;
    int pulseWidth = 69;
    int adcRange = 4096;
    
    particleSensor.setup(ledBrightness, sampleAverage, ledMode, sampleRate, pulseWidth, adcRange);
}
```

## 4.5 قراءة نبض القلب

```cpp
void readHeartRate() {
    long irValue = particleSensor.getIR();
    
    if (irValue < 50000) {
        Serial.println("ضع إصبعك على المستشعر");
        return;
    }
    
    float heartRate = particleSensor.getHeartRate();
    
    if (particleSensor.checkForBeat()) {
        Serial.print("نبض القلب: ");
        Serial.print(heartRate);
        Serial.println(" BPM");
    }
}
```

---

# 5. MPU6050 ACCELEROMETER

## 5.1 مواصفات MPU6050

| المواصفة | القيمة |
|-----------|--------|
| I2C Address | 0x68 |
| جهد التشغيل | 3.3V |
| Accelerometer Range | ±2g, ±4g, ±8g, ±16g |
| Gyroscope Range | ±250, ±500, ±1000, ±2000 °/s |
| ADC Resolution | 16 bits |
| السعر | 175 ج.م |

## 5.2 pins

| MPU6050 Pin | متصل إلى |
|--------------|-----------|
| VCC | ESP32 3V3 |
| GND | ESP32 GND |
| SDA | ESP32 GPIO18 |
| SCL | ESP32 GPIO19 |
| INT | ESP32 GPIO27 |
| AD0 | ESP32 GND |

## 5.3 Registers الأساسية

| Register | Address | الوصف |
|----------|---------|-------|
| PWR_MGMT_1 | 0x6B | إدارة الطاقة |
| ACCEL_XOUT_H | 0x3B | تسارع X |
| ACCEL_YOUT_H | 0x3D | تسارع Y |
| ACCEL_ZOUT_H | 0x3F | تسارع Z |

## 5.4 كود الإعداد

```cpp
#include <Adafruit_MPU6050.h>

Adafruit_MPU6050 mpu;

void setup() {
    if (!mpu.begin()) {
        Serial.println("MPU6050 not found!");
        return;
    }
    
    mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
    mpu.setGyroRange(MPU6050_RANGE_500_DEG);
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
}
```

## 5.5 خوارزمية اكتشاف السقوط

```cpp
#define FALL_THRESHOLD 2.5f  // قوة السقوط
#define FALL_CONFIRM_TIME 10000  // 10 ثواني للإلغاء

bool fallDetected = false;

void checkForFall() {
    // قراءة التسارع
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);
    
    float totalAccel = sqrt(a.acceleration.x*a.acceleration.x + 
                           a.acceleration.y*a.acceleration.y + 
                           a.acceleration.z*a.acceleration.z);
    
    // تحويل إلى g
    float accel_g = totalAccel / 9.81;
    
    // فحص السقوط
    if (accel_g > FALL_THRESHOLD) {
        Serial.println("تم اكتشاف سقوط محتمل!");
        // انتظر 10 ثواني
        // إذا لم يتم الإلغاء، أطلق الطوارئ
        triggerEmergency();
    }
}
```

## 5.6 خوارزمية عد الخطوات

```cpp
#define STEP_THRESHOLD 1.5f
#define STEP_MIN_TIME 250

int totalSteps = 0;
bool lastStepState = false;
unsigned long lastStepTime = 0;

void countSteps() {
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);
    
    // استخدام محور Z للتسارع العمودي
    float verticalAccel = a.acceleration.z / 9.81;
    
    bool currentState = (verticalAccel > STEP_THRESHOLD);
    
    // كشف الخطوة: من منخفض إلى مرتفع
    if (currentState && !lastStepState) {
        unsigned long timeBetween = millis() - lastStepTime;
        
        if (timeBetween > STEP_MIN_TIME) {
            totalSteps++;
            Serial.print("خطوة! المجموع: ");
            Serial.println(totalSteps);
        }
        lastStepTime = millis();
    }
    
    lastStepState = currentState;
}
```

---

# 6. SSD1306 OLED DISPLAY

## 6.1 مواصفات SSD1306

| المواصفة | القيمة |
|-----------|--------|
| Resolution | 128 x 64 pixels |
| I2C Address | 0x3C |
| جهد التشغيل | 3.3V |
| Max Current | 25 mA |
| الألوان | أحادي (أبيض) |
| السعر | 250 ج.م |

## 6.2 pins

| SSD1306 Pin | متصل إلى |
|-------------|-----------|
| GND | ESP32 GND |
| VCC | ESP32 3V3 |
| SCL | ESP32 GPIO18 |
| SDA | ESP32 GPIO19 |

## 6.3 كود الإعداد

```cpp
#include <Adafruit_SSD1306.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
#define OLED_ADDR 0x3C

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

void setup() {
    if (!display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR)) {
        Serial.println("SSD1306 not found!");
        return;
    }
    
    display.clearDisplay();
    display.setTextSize(2);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 0);
    display.println("Digital Saver");
    display.display();
}
```

## 6.4 عرض نص

```cpp
void showClockDisplay() {
    display.clearDisplay();
    
    // عرض الوقت
    display.setTextSize(3);
    display.setCursor(10, 10);
    display.println("12:45");
    
    // عرض التاريخ
    display.setTextSize(1);
    display.setCursor(15, 45);
    display.println("Mon, Jan 15");
    
    display.display();
}
```

---

# 7. COMPLETE WIRING DIAGRAM - مخطط التوصيل الكامل

## 7.1 جدول التوصيل

| ESP32 Pin | الوظيفة | متصل إلى | لون السلك |
|-----------|---------|----------|----------|
| **Power - الطاقة** | | | |
| 3V3 | طاقة 3.3V | جميع المستشعرات | أحمر |
| GND | أرضي | جميع GND | أسود |
| **I2C Bus - ناقل I2C** | | | |
| GPIO18 | I2C SCL | MAX30102 SCL | أصفر |
| GPIO19 | I2C SDA | MAX30102 SDA | أزرق |
| GPIO18 | I2C SCL | MPU6050 SCL | أصفر (مشترك) |
| GPIO19 | I2C SDA | MPU6050 SDA | أزرق (مشترك) |
| GPIO18 | I2C SCL | SSD1306 SCL | أصفر (مشترك) |
| GPIO19 | I2C SDA | SSD1306 SDA | أزرق (مشترك) |
| **Interrupts - المقاطعات** | | | |
| GPIO26 | HR_INT | MAX30102 INT | بنفسجي |
| GPIO27 | MOTION_INT | MPU6050 INT | أخضر |
| **Output Pins - مخرجات** | | | |
| GPIO25 | VIB_MOTOR | موتور الاهتزاز (+) | بني |
| GPIO4 | LED_RED | LED أحمر (+) | أحمر |
| GPIO16 | LED_GREEN | LED أخضر (+) | أخضر |
| **Input Pins - مدخلات** | | | |
| GPIO17 | BUTTON_MODE | زر الوضع → 3.3V | أبيض |
| GPIO34 | BUTTON_EMERG | زر الطوارئ → 3.3V | برتقالي |
| GPIO35 | BUTTON_BACK | زر الرجوع → 3.3V | رمادي |

## 7.2 Pull-Up Resistors

```
3.3V ──[4.7KΩ]──┼── SCL ── ESP32 GPIO18
                          │
                          └── MAX30102 SCL
                          └── MPU6050 SCL
                          └── SSD1306 SCL

3.3V ──[4.7KΩ]──┼── SDA ── ESP32 GPIO19
                          │
                          └── MAX30102 SDA
                          └── MPU6050 SDA
                          └── SSD1306 SDA
```

## 7.3 مقاومات LED

```
ESP32 GPIO4 ──[220Ω]── LED أحمر (+) ── GND
ESP32 GPIO16 ──[220Ω]── LED أخضر (+) ── GND
```

## 7.4 توصيل الأزرار

```
3.3V ─── زر ─── ESP32 GPIO17 (وضع)
3.3V ─── زر ─── ESP32 GPIO34 (طوارئ)
3.3V ─── زر ─── ESP32 GPIO35 (رجوع)
```

---

# 8. نظام الطاقة - POWER SYSTEM

## 8.1 مخطط الطاقة

```
┌─────────────────────────────────────────────────────────────────┐
│                        تدفق الطاقة                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│    ┌─────────┐      USB      ┌─────────────┐           │
│    │   PC     │──────────────│   TP4056     │           │
│    │   5V     │              │  شاحن البطارية │           │
│    └─────────┘              └──────┬──────┘           │
│                                        │                   │
│                                        ▼                   │
│                              ┌─────────────────┐          │
│                              │  بطارية LiPo    │          │
│                              │   3.7V 500mAh  │          │
│                              └────────┬────────┘          │
│                                       │                    │
│                     ┌────────────────┼──────┐           │
│                     │                │      │           │
│                     ▼                ▼      ▼           │
│              ┌──────────┐      ┌────────┐ ┌──────┐ │
│              │ ESP32    │      │مستشعرات │ │ LEDs │ │
│              │ 3.3V     │      │  3.3V   │ │ 3.3V │ │
│              └──────────┘      └────────┘ └──────┘ │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## 8.2 مواصفات البطارية

| المواصفة | القيمة |
|-----------|--------|
| النوع | Lithium Polymer (LiPo) |
| الجهد الاسمي | 3.7V |
| أقصى جهد | 4.2V |
| أقل جهد | 3.0V |
| السعة | 500 mAh |
| الحجم | 50mm x 20mm x 3.5mm |
| السعر | 250 ج.م |

## 8.3 عمر البطارية

| الوضع | التيار | عمر البطارية |
|--------|--------|-------------|
| نشط (مستشعرات تعمل) | ~120 mA | ~4 ساعات |
| خمول (BLE متصل) | ~30 mA | ~16 ساعة |
| سبات (الشاشة مطفأة) | ~10 μA | ~50,000 ساعة |
| **الاستخدام المختلط** | ~50 mA | **2-3 أيام** |

## 8.4 الشحن

| المواصفة | القيمة |
|-----------|--------|
| شاحن IC | TP4056 |
| تيار الشحن | 500 mA |
| وقت الشحن الكامل | ~2 ساعة |
| منفذ الشحن | USB-C |

---

# ═══════════════════════════════════════════════════════════════════════════
# PART 3: INSTALLATION & BUILDING
# ═══════════════════════════════════════════════════════════════════════════

# 9. SOFTWARE INSTALLATION - تثبيت البرامج

## 9.1 قائمة البرامج المطلوبة

| # | البرنامج | الإصدار | الغرض | رابط التحميل |
|---|-----------|---------|--------|--------------|
| 1 | VS Code | 1.80+ | محرر الكود | https://code.visualstudio.com |
| 2 | PlatformIO | Latest | نظام البناء | إضافة VS Code |
| 3 | Python | 3.9+ | للسكربتات | https://python.org |
| 4 | Git | Latest | التحكم في الإصدارات | https://git-scm.com |

## 9.2 تثبيت VS Code

**الخطوة 1:** تحميل VS Code

1. اذهب إلى: https://code.visualstudio.com/
2. اضغط زر التحميل
3. اختر نظام التشغيل (Windows/Mac/Linux)
4. شغل ملف التثبيت

**الخطوة 2:** تثبيت PlatformIO

1. افتح VS Code
2. اضغط على Extensions (الأيقونة على اليسار)
3. ابحث عن "PlatformIO IDE"
4. اضغط Install
5. اضغط Reload عند الطلب

## 9.3 تشغيل المشروع

**الخطوة 1:** افتح PlatformIO

1. اضغط Ctrl+Shift+P
2. اكتب "PlatformIO: Home"
3. اضغط Enter

**الخطوة 2:** افتح المشروع

1. File → Open Folder
2. اذهب إلى مجلد Digital-saver
3. اذهب إلى: firmware/esp32/DigitalSaverWatch/

---

# 10. BUILDING THE FIRMWARE - بناء البرنامج

## 10.1 أوامر البناء

### الطريقة 1: واجهة VS Code

1. اضغط أيقونة PlatformIO (رأس النملة)
2. اضغط "Build" (أيقونة الصح)

### الطريقة 2: الطرفية

```bash
cd ~/Digital-saver/firmware/esp32/DigitalSaverWatch
pio run
```

## 10.2 رفع البرنامج

### الطريقة 1: واجهة VS Code

1. اضغط أيقونة PlatformIO
2. اضغط "Upload" (أيقونة السهم)

### الطريقة 2: الطرفية

```bash
pio run --target upload
```

---

# 11. CONFIGURATION - الإعداد

## 11.1 إعدادات WiFi

افتح الملف وعدّل هذه السطور (حول السطر 67-70):

```cpp
// إعدادات WiFi - غير هذه!
#define WIFI_SSID "اسمشبكةWiFi"
#define WIFI_PASSWORD "كلمة المرور"
#define WEATHER_API_KEY "مفتاحAPIمنOpenWeatherMap"
```

## 11.2 الحصول على مفتاح Weather API

1. اذهب إلى: https://openweathermap.org/api
2. أنشئ حساب مجاني
3. انسخ مفتاح API
4. الصقه في الكود

---

# ═══════════════════════════════════════════════════════════════════════════
# PART 4: USER PROFILE & HEALTH AI
# ═══════════════════════════════════════════════════════════════════════════

# 12. USER PROFILE SYSTEM - نظام الملف الشخصي

## 12.1 بنية UserProfile

```cpp
struct UserProfile {
    String name;              // اسمك
    int age;                // عمرك
    int weightKg;           // وزنك بالكيلو
    int heightCm;           // طولك بالسنتيمتر
    String gender;          // "male" أو "female"
    int targetSteps;        // هدف الخطوات اليومي
    int targetSleepHours;   // هدف ساعات النوم
    float maxHeartRate;    // أقصى نبض آمن
    bool profileSet;         // هل تم التعيين؟
};
```

## 12.2 تعيين الملف الشخصي عبر BLE

```
PROFILE:اسم,عمر,وزن,طول,جنس,خطوات

مثال: PROFILE:أحمد,30,75,175,male,10000
```

### الرد:

```
PROFILE:OK أحمد 30y
```

## 12.3 حساب BMR (معدل الأيض الأساسي)

```cpp
void calculateBMR() {
    if (!userProfile.profileSet) {
        healthAI.bmr = 1500;
        return;
    }
    
    // معادلة Mifflin-St Jeor
    if (userProfile.gender == "male") {
        healthAI.bmr = 10 * userProfile.weightKg 
                     + 6.25 * userProfile.heightCm 
                     - 5 * userProfile.age + 5;
    } else {
        healthAI.bmr = 10 * userProfile.weightKg 
                     + 6.25 * userProfile.heightCm 
                     - 5 * userProfile.age - 161;
    }
}
```

---

# 13. ADVANCED HEALTH AI ENGINE - محرك الذكاء الاصطناعي

## 13.1 بنية HealthAI

```cpp
struct HealthAI {
    // الدرجات (0-100)
    float overallScore;       // الدرجة الكلية
    float heartScore;        // درجة القلب
    float activityScore;      // درجة النشاط
    float stressScore;       // مستوى التوتر
    
    // مستويات الخطر (0-4)
    int cardiovascularRisk;  // خطر القلب والأوعية
    int arrhythmiaRisk;       // عدم انتظام ضربات القلب
    int hypoxiaRisk;         // نقص الأكسجين
    int overexertionRisk;    // الإرهاق
    
    // توصيات الذكاء الاصطناعي
    String healthInsight;     // الرؤية الصحية
    String recommendation;   // التوصية
    String warningMessage;   // التحذير
    
    // حالة النشاط
    String activityState;     // "SLEEPING", "RESTING", "WALKING", "EXERCISING"
    
    // السعرات الحرارية
    float caloriesBurned;
    float bmr;
    
    // ضغط الدم
    String bpCategory;       // "NORMAL", "ELEVATED", "HIGH", "CRISIS"
};
```

## 13.2 تحليل ضغط الدم

| الفئة | الانقباضي | الانبساطي | الخطر |
|--------|----------|----------|-------|
| NORMAL | < 120 | < 80 | 0 |
| ELEVATED | 120-129 | < 80 | 1 |
| HIGH_STAGE1 | 130-139 | 80-89 | 2 |
| HIGH_STAGE2 | >= 140 | >= 90 | 3 |
| CRISIS | > 180 | > 120 | 4 |

## 13.3 كشف عدم انتظام ضربات القلب

```cpp
void detectArrhythmia() {
    static float lastHR = 0;
    static int irregularCount = 0;
    
    if (lastHR > 0) {
        float variation = abs(currentHealth.heartRate - lastHR);
        
        // تغير مفاجئ > 30 نبضة
        if (variation > 30) {
            irregularCount++;
            
            if (irregularCount >= 3) {
                healthAI.arrhythmiaRisk = 3;
                healthAI.warningMessage = "تم كشف عدم انتظام ضربات القلب!";
            }
        } else {
            if (irregularCount > 0) irregularCount--;
        }
    }
    
    lastHR = currentHealth.heartRate;
}
```

## 13.4 كشف نقص الأكسجين (Hypoxia)

| SpO2 | الخطر | الرسالة |
|------|------|--------|
| >= 96% | 0 | طبيعي |
| 94-95% | 2 | متوسط |
| 90-93% | 3 | مرتفع |
| < 90% | 4 | **حرج!** |

## 13.5 كشف حالة النشاط

| الحالة | معدل نبض القلب | معدل الخطوات |
|--------|----------------|-------------|
| نائم | < 60 | أي قيمة |
| راقد | 60-80 | < 5 |
| مشي | 80-100 | 5-30 |
| رياضة | 100-140 | 30-60 |
| عنيف | >= 140 | أي قيمة |

## 13.6 توليد التوصيات الصحية

```cpp
void generateHealthInsight() {
    // حساب الدرجات
    healthAI.heartScore = 100 - abs(80 - currentHealth.heartRate);
    healthAI.heartScore = constrain(healthAI.heartScore, 0, 100);
    
    healthAI.activityScore = (currentHealth.steps / (float)userProfile.targetSteps) * 100;
    healthAI.activityScore = constrain(healthAI.activityScore, 0, 100);
    
    // الدرجة الكلية
    healthAI.overallScore = 
        healthAI.heartScore * 0.35 +
        healthAI.activityScore * 0.25 +
        (100 - healthAI.stressScore) * 0.20 +
        currentHealth.spO2 * 0.20;
    
    // توليد التوصية
    if (healthAI.cardiovascularRisk >= 3) {
        healthAI.healthInsight = "تم كشف ارتفاع ضغط الدم";
        healthAI.recommendation = "قلل الملح ومارس الرياضة";
    } else if (healthAI.arrhythmiaRisk >= 3) {
        healthAI.healthInsight = "نمط ضربات قلب غير منتظم";
        healthAI.recommendation = "استشر طبيب قلب";
    } else if (healthAI.activityState == "EXERCISING") {
        healthAI.healthInsight = "تمرين رائع!";
        healthAI.recommendation = "استمر على هذا المنوال!";
    } else {
        healthAI.healthInsight = "كل المؤشرات جيدة!";
        healthAI.recommendation = "ابقَ رطباً ونشطاً";
    }
}
```

---

# ═══════════════════════════════════════════════════════════════════════════
# PART 5: ALL MODES & COMMANDS
# ═══════════════════════════════════════════════════════════════════════════

# 14. WATCH MODES - أوضاع الساعة

## 14.1 قائمة الأوضاع (8 أوضاع)

| ID | الوضع | الوصف |
|----|-------|-------|
| 0 | MODE_CLOCK | الوقت والتاريخ |
| 1 | MODE_HEART_RATE | نبض القلب والأكسجين |
| 2 | MODE_BLOOD_PRESSURE | ضغط الدم |
| 3 | MODE_ACTIVITY | الخطوات والسعرات |
| 4 | MODE_SLEEP | تتبع النوم |
| 5 | MODE_WEATHER | الطقس |
| 6 | MODE_STEALTH | وضع التخفي |
| 7 | MODE_SETTINGS | الإعدادات |

## 14.2Themes - السمات (5 سمات)

| ID | السمة | الوصف |
|----|-------|-------|
| 0 | Default | أبيض على أسود |
| 1 | Inverted | أسود على أبيض |
| 2 | High Contrast | تباين عالي |
| 3 | Night | أحمر (ليل) |
| 4 | Minimal | نقاط ثنائية |

---

# 15. ALL BLE COMMANDS - جميع أوامر BLE

## 15.1 أوامر الأوضاع

| الأمر | مثال | الوظيفة |
|-------|------|---------|
| MODE:0 | MODE:0 | وضع الساعة |
| MODE:1 | MODE:1 | وضع نبض القلب |
| MODE:2 | MODE:2 | وضع ضغط الدم |
| MODE:3 | MODE:3 | وضع النشاط |
| MODE:4 | MODE:4 | وضع النوم |
| MODE:5 | MODE:5 | وضع الطقس |
| MODE:6 | MODE:6 | وضع التخفي |
| MODE:7 | MODE:7 | الإعدادات |

## 15.2 أوامر السمات

| الأمر | مثال | الوظيفة |
|-------|------|---------|
| THEME:0 | THEME:0 | افتراضي |
| THEME:1 | THEME:1 | معكوس |
| THEME:2 | THEME:2 | تباين عالي |
| THEME:3 | THEME:3 | ليلي (أحمر) |
| THEME:4 | THEME:4 | بسيط |

## 15.3 أوامر WiFi

| الأمر | مثال | الوظيفة |
|-------|------|---------|
| WIFI:ON | WIFI:ON | تشغيل WiFi |
| WIFI:OFF | WIFI:OFF | إيقاف WiFi |
| WEATHER:REFRESH | WEATHER:REFRESH | تحديث الطقس |

## 15.4 أوامر الملف الشخصي

| الأمر | مثال | الوظيفة |
|-------|------|---------|
| PROFILE:اسم,عمر,وزن,طول,جنس,خطوات | PROFILE:أحمد,30,75,175,male,10000 | تعيين الملف الشخصي |

## 15.5 أوامر الذكاء الاصطناعي

| الأمر | مثال | الوظيفة |
|-------|------|---------|
| HEALTHAI:STATUS | HEALTHAI:STATUS | حالة الذكاء الاصطناعي |

## 15.6 أوامر الحالة

| الأمر | مثال | الوظيفة |
|-------|------|---------|
| PING | PING | اختبار الاتصال |
| STATUS | STATUS | الحالة الكاملة |

---

# ═══════════════════════════════════════════════════════════════════════════
# PART 6: TROUBLESHOOTING - حل المشاكل
# ═══════════════════════════════════════════════════════════════════════════

# 16. المشاكل الشائعة والحلول

## 16.1 مشاكل الشاشة

| المشكلة | السبب | الحل |
|---------|-------|------|
| الشاشة بيضاء | no power | فحص توصيل 3.3V |
| الشاشة بيضاء | عنوان I2C غلط | استخدم 0x3C |
| الشاشة لاتعمل | SDA/SCL مقلوب | بدل SDA و SCL |

## 16.2 مشاكل المستشعرات

| المشكلة | السبب | الحل |
|---------|-------|------|
| MAX30102 مش موجود | عنوان غلط | استخدم 0x57 |
| النبض يظهر -- | الإصبع مش على المستشعر | حط الإصبع صح |
| الخطوات مش بتزيد | خطأ في MPU6050 | فحص التوصيل |

## 16.3 مشاكل WiFi

| المشكلة | السبب | الحل |
|---------|-------|------|
| مش بيconnects | كلمة مرور غلط | راجع WIFI_PASSWORD |
| Weather يظهر -- | WiFi مش connected | أرسل WIFI:ON |
| Weather قديم | مش محدث | أرسل WEATHER:REFRESH |

## 16.4 مشاكل البناء

| المشكلة | السبب | الحل |
|---------|-------|------|
| البناء فاشل | مكتبة ناقصة | pio pkg install |
| الرفع فاشل | بورت غلط | راجع رقم COM |
| الرفع فاشل | وضع Boot | امسك BOOT واضغط RESET |

---

# 17. CODE STRUCTURE - هيكل الكود

## 17.1 تنظيم الملف

```
DigitalSaverWatch.ino
├── HEADER (1-26)
│   ├── Version info
│   └── Feature list
│
├── INCLUDES (28-35)
│   ├── Wire.h (I2C)
│   ├── BLE libraries
│   ├── Display libraries
│   ├── Sensor libraries
│   └── WiFi libraries
│
├── CONFIGURATION (37-75)
│   ├── Pin definitions
│   ├── BLE UUIDs
│   ├── WiFi settings
│   └── Thresholds
│
├── DATA STRUCTURES (95-226)
│   ├── HealthData
│   ├── RawSensorData
│   ├── WeatherData
│   ├── UserProfile
│   └── HealthAI
│
├── SETUP FUNCTION (330-420)
│   └── Initialize everything
│
├── MAIN LOOP (1824-1900)
│   ├── Button handling
│   ├── Sensor updates
│   ├── Health AI
│   ├── BLE data send
│   └── Display update
│
├── WiFi FUNCTIONS (469-610)
│   ├── initWiFi()
│   └── fetchWeather()
│
├── HEALTH AI FUNCTIONS (613-825)
│   ├── calculateBMR()
│   ├── analyzeBloodPressure()
│   ├── detectArrhythmia()
│   ├── checkHypoxiaRisk()
│   ├── calculateActivityState()
│   ├── generateHealthInsight()
│   └── runHealthAI()
│
├── DISPLAY FUNCTIONS (1200-1700)
│   ├── updateDisplay()
│   ├── showClockDisplay()
│   ├── showHeartRateDisplay()
│   ├── showWeatherDisplay()
│   ├── showStealthDisplay()
│   └── showSettingsDisplay()
│
└── UTILITY FUNCTIONS (1700-1900)
    ├── formatTime()
    ├── vibrate()
    └── triggerEmergency()
```

---

# ═══════════════════════════════════════════════════════════════════════════
# PART 7: QUICK REFERENCE - مرجع سريع
# ═══════════════════════════════════════════════════════════════════════════

# 18. QUICK REFERENCE - مرجع سريع

## 18.1 عناوين I2C

| الجهاز | العنوان |
|--------|---------|
| MAX30102 | 0x57 |
| MPU6050 | 0x68 |
| SSD1306 | 0x3C |

## 18.2 توزيع Pins

| Pin | الوظيفة |
|-----|---------|
| GPIO18 | I2C SCL |
| GPIO19 | I2C SDA |
| GPIO26 | MAX30102 INT |
| GPIO27 | MPU6050 INT |
| GPIO25 | Vibration Motor |
| GPIO4 | Red LED |
| GPIO16 | Green LED |
| GPIO17 | Mode Button |
| GPIO34 | Emergency Button |
| GPIO35 | Back Button |

## 18.3 أوضاع الساعة

| ID | الوضع |
|----|-------|
| 0 | Clock |
| 1 | Heart Rate |
| 2 | Blood Pressure |
| 3 | Activity |
| 4 | Sleep |
| 5 | Weather |
| 6 | STEALTH |
| 7 | Settings |

## 18.4 السمات

| ID | السمة |
|----|-------|
| 0 | Default |
| 1 | Inverted |
| 2 | High Contrast |
| 3 | Night (Red) |
| 4 | Minimal |

## 18.5 مستويات الخطر

| المستوى | المعنى |
|---------|-------|
| 0 | لا يوجد |
| 1 | منخفض |
| 2 | متوسط |
| 3 | مرتفع |
| 4 | حرج |

## 18.6 أوامر مهمة

```bash
# تعيين الملف الشخصي
PROFILE:أحمد,30,75,175,male,10000

# حالة الذكاء الاصطناعي
HEALTHAI:STATUS

# الذهاب للإعدادات
MODE:7

# تشغيل WiFi
WIFI:ON

# تحديث الطقس
WEATHER:REFRESH
```

## 18.7 أوامر البناء

```bash
pio run              # بناء
pio run --target upload    # رفع
pio run --target erase     # مسح
pio device monitor         # شاشة Serial
```

---

# ═══════════════════════════════════════════════════════════════════════════
# PART 8: DETAILED TROUBLESHOOTING
# ═══════════════════════════════════════════════════════════════════════════

# 19. TROUBLESHOOTING COMPLETE GUIDE

## 19.1 Display Troubleshooting - مشاكل الشاشة

### Problem 1: الشاشة لا تعمل (Display Not Working)

**الأعراض:**
- الشاشة بيضاء تماماً
- مش باينة حاجة
- الشاشة مظبوطة بس مش باينة

**الأسباب المحتملة:**

| السبب | كيف تتأكد | الحل |
|--------|----------|------|
| مفيش طاقة | قياس 3.3V على شاشة VCC | وصلي 3.3V |
| التوصيل غلط | فحص الوايرز | راجع مخطط التوصيل |
| عنوان I2C غلط | الـ address = 0x3C | غيّر الـ address |
| SDA/SCL مقلوب | جرب تبديلهم | بدّل SDA و SCL |

**خطوات الحل:**

```cpp
// الخطوة 1: افحص الطافة
// قياس فولتية على PIN VCC للشاشة
// لازم يكون 3.3V

// الخطوة 2: افحص I2C Scanner
// شغل الكود ده:
#include <Wire.h>

void setup() {
    Serial.begin(115200);
    Wire.begin(18, 19);
    
    Serial.println("Scanning I2C...");
    for (byte address = 1; address < 127; address++) {
        Wire.beginTransmission(address);
        if (Wire.endTransmission() == 0) {
            Serial.print("Found: 0x");
            Serial.println(address, HEX);
        }
    }
}
void loop() {}

// لو الشاشة موجودة، هتظهر 0x3C
```

**النتيجة المتوقعة:**
```
Scanning I2C...
Found: 0x3C    ← دي الشاشة
Found: 0x57    ← دي MAX30102
Found: 0x68    ← دي MPU6050
```

### Problem 2: الشاشة بتظهر noise

**الأعراض:**
- الشاشة بتظهر رموز مش واضحة
- حاجات غلط بتظهر
- الصورة مش ثابتة

**الأسباب:**
1. توصيلات ضعيفة
2. سلكز طويلين
3. Invert mode مفعل

**الحل:**
```cpp
// غيّر وضع الشاشة
display.clearDisplay();
display.invertDisplay(false);
display.display();

// أو غيّر الـ contrast
display.setContrast(255);  // من 0 ل 255
```

### Problem 3: الشاشة مقلوبة (Upside Down)

**الأعراض:**
- الصورة مقلوبة 180 درجة

**الحل:**
```cpp
// اعكس اتجاه الشاشة
display.flipScreenVertically();
```

### Problem 4: الشاشة بترمض (Flickering)

**الأسباب:**
1. البطارية ضعيفة
2. PSU مش stable
3. خلل في الـ wiring

**الحل:**
```cpp
// قلل سرعة التحديث
#define DISPLAY_REFRESH 200  // بدل 100ms

// أو استخدم sleep mode
display.ssd1306_command(SSD1306_DISPLAYOFF);
// بعد شوية
display.ssd1306_command(SSD1306_DISPLAYON);
```

---

## 19.2 Sensor Troubleshooting - مشاكل المستشعرات

### Problem 1: MAX30102 مش موجود

**الأعراض:**
```
MAX30102 not found!
```

**خطوات الحل:**

**الخطوة 1: افحص التوصيلات**
```
MAX30102 PIN  →  ESP32
   VIN         →    3V3
   GND         →    GND
   SDA         →    GPIO18
   SCL         →    GPIO19
   INT         →    GPIO26
```

**الخطوة 2: افحص العنوان**
```cpp
// تأكد إن الـ address صح
// MAX30102 address = 0x57

Wire.beginTransmission(0x57);
if (Wire.endTransmission() == 0) {
    Serial.println("MAX30102 found!");
} else {
    Serial.println("MAX30102 NOT found!");
}
```

**الخطوة 3: جرب عنوان تاني**
```cpp
// بعض الـ modules بيكونوا 0x57 أو 0x59
if (!particleSensor.begin(Wire, I2C_SPEED_FAST, 0x57)) {
    // جرب 0x59
    if (!particleSensor.begin(Wire, I2C_SPEED_FAST, 0x59)) {
        Serial.println("MAX30102 not found on any address!");
    }
}
```

### Problem 2: Heart Rate بيظهر --

**الأعراض:**
```
HR: --
SpO2: --
```

**الأسباب:**
1. الإصبع مش على المستشعر
2. المستشعر متسخ
3. الإضاءة ضعيفة

**الحل:**

**الخطوة 1: حط الإصبع صح**
- المستشعر لازم يكون ملاصق للجلد
- متضغطش جامد
- خليه مريح

**الخطوة 2: نظف المستشعر**
```cpp
// مسح المستشعر بقطنة مبلولة بكحول
```

**الخطوة 3: غيّر سطوع LED**
```cpp
// زوّد سطوع LED
byte ledBrightness = 127;  // بدل 60
particleSensor.setup(ledBrightness, sampleAverage, ledMode, sampleRate, pulseWidth, adcRange);
```

### Problem 3: MPU6050 مش موجود

**الأعراض:**
```
MPU6050 not found!
```

**الحل:**
```cpp
// الـ address للـ MPU6050 = 0x68
// لو AD0 متوصل لـ 3V3، الـ address = 0x69

// افحص التوصيل:
Wire.beginTransmission(0x68);
if (Wire.endTransmission() == 0) {
    Serial.println("MPU6050 found at 0x68");
} else {
    // جرب 0x69
    Wire.beginTransmission(0x69);
    if (Wire.endTransmission() == 0) {
        Serial.println("MPU6050 found at 0x69");
        // لازم تغيّر الـ address في الكود
    }
}
```

### Problem 4: الخطوات مش بتزيد

**الأسباب:**
1. MPU6050 مش شغال
2. الـ threshold عالي أو واطي
3. movement مش كافي

**الحل:**
```cpp
// غيّر الـ threshold
#define STEP_THRESHOLD 1.2f  // بدل 1.5

// أو غيّر الحساسية
mpu.setAccelerometerRange(MPU6050_RANGE_4_G);  // حساسية أعلى
```

---

## 19.3 WiFi Troubleshooting - مشاكل WiFi

### Problem 1: WiFi مش بيتconnects

**الأعراض:**
```
[WIFI] Connection failed!
```

**خطوات الحل:**

**الخطوة 1: تأكد من اسم الشبكة وكلمة المرور**
```cpp
// راجع السطور دي في الكود:
#define WIFI_SSID "YourWiFiName"        // لازم يكون نفس الاسم بالظبط
#define WIFI_PASSWORD "YourWiFiPassword"  // متنساش الـ case sensitive
```

**الخطوة 2: افحص قوة الإشارة**
```cpp
// ضيف الكود ده في loop():
void checkWiFiStatus() {
    if (WiFi.status() == WL_CONNECTED) {
        Serial.print("WiFi Signal: ");
        Serial.println(WiFi.RSSI());
        
        if (WiFi.RSSI() < -70) {
            Serial.println("Weak signal! Move closer to router.");
        }
    }
}
```

**الخطوة 3: جرب شبكة تانية**
```cpp
// لو مش شغال على شبكة معينة، جرب شبكة تانية
```

### Problem 2: Weather مش بيتحدث

**الأسباب:**
1. WiFi مش متconnects
2. مفتاح API غلط
3. انتهاء الـ quota

**الحل:**

**الخطوة 1: تأكد من مفتاح API**
```cpp
// لازم يكون مفتاح من openweathermap.org
#define WEATHER_API_KEY "YOUR_ACTUAL_API_KEY"

// تقدر تجرب الـ API directly من浏览器:
// https://api.openweathermap.org/data/2.5/weather?q=Cairo&appid=YOUR_KEY
```

**الخطوة 2: افحص الرصيد**
```cpp
// الـ free tier بتيح 60 نداء في الدقيقة
// لو اتجاوزت، لازم تستنى
```

### Problem 3: WiFi بيسحب البطارية بسرعة

**الحل:**
```cpp
// قلل فترة التحديث
#define WEATHER_UPDATE_INTERVAL 3600000  // ساعة بدل 30 دقيقة

// أو طفي WiFi لما مش محتاج
void disableWiFi() {
    WiFi.disconnect();
    WiFi.mode(WIFI_OFF);
    wifiConnected = false;
}
```

---

## 19.4 BLE Troubleshooting - مشاكل Bluetooth

### Problem 1: الساعة مش بتظهر في App

**الأسباب:**
1. BLE مش بيبعت (advertising)
2. الاسم غلط
3. الجهاز مش في المدى

**الحل:**

**الخطوة 1: افحص Serial Monitor**
```
لازم يظهر:
[OK] BLE initialized - waiting for connection...
```

**الخطوة 2: غيّر اسم الجهاز**
```cpp
// في initBLE():
BLEDevice::setDeviceName("Digital Saver Onyx");  // اسم قصير
```

**الخطوة 3: قلل Advertising interval**
```cpp
// قلل الـ interval عشان يبقى أسهل في الاكتشاف
pAdvertising->setMinInterval(0x20);  // 20ms بدل 100ms
```

### Problem 2: Bluetooth بيفصل بسرعة

**الأسباب:**
1. weak signal
2. interference from WiFi
3. high power consumption

**الحل:**
```cpp
// زوّد الـ connection interval
pClient->setConnectionParams(12, 12, 0, 100);  // faster interval

// أو قلل الـ latency
pClient->setDataLen(23);  // default MTU
```

### Problem 3: App مش بيقرأ البيانات

**الحل:**
```cpp
// تأكد من الـ UUIDs
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// الـ UUIDs لازم تكون نفسها في App وفي الساعة
```

---

## 19.5 Build & Upload Problems - مشاكل البناء والرفع

### Problem 1: "Board not found"

**السبب:** Platform مش installed

**الحل:**
```bash
pio platform install espressif32
```

### Problem 2: "Library not found"

**الحل:**
```bash
pio pkg install
# أو
pio lib install
```

### Problem 3: "Compile error"

**الحل:**
1. اقرأ رسالة الخطأ
2. راجع السطر اللي فيه الـ error
3. غالباً بيكون:
   - نقطة/virgula ناقصة
   - قوس مش مقفول
   - اسم variable غلط

### Problem 4: "Failed to connect to ESP32"

**الحل:**
```bash
# الطريقة 1: Boot mode
# 1. امسك زر BOOT
# 2. اضغط RESET
# 3. خلي BOOT
# 4. ارفع البرنامج

# الطريقة 2: غيّر سرعة الرفع
# في platformio.ini:
upload_speed = 115200  # بدل 921600
```

### Problem 5: "Permission denied" (Linux/Mac)

**الحل:**
```bash
# Linux
sudo chmod 666 /dev/ttyUSB0

# Mac
sudo chmod 666 /dev/cu.usbserial-*
```

---

# 20. RECOVERY PROCEDURES - إجراءات الاسترداد

## 20.1 Factory Reset - إعادة ضبط المصنع

**الخطوة 1:** اتنين من الأزرار
- امسك زر MODE
- امسك زر BACK

**الخطوة 2:** انتظر 10 ثواني
- الـ LEDs هترمش سريع

**الخطوة 3:** الخلي الزرزين
- كل الإعدادات هترجع ل default

## 20.2 Erase and Reflash - مسح وإعادة الرفع

**الخطوة 1:** مسح الـ flash
```bash
pio run --target erase
```

**الخطوة 2:** رفع البرنامج
```bash
pio run --target upload
```

## 20.3 Boot Mode Flash - الرفع في وضع Boot

**الخطوة 1:** ادخل Boot mode
1. امسك زر BOOT على ESP32
2. اضغط RESET
3. خلي BOOT

**الخطوة 2:** ارفع
```bash
pio run --target upload
```

**الخطوة 3:** عادي
1. البرنامج هيتحمل
2. اضغط RESET
3. اشتغل عادي

## 20.4 USB Driver Reinstall - إعادة تثبيت تعريف USB

### Windows:
1. Device Manager
2. Ports → CP210x
3. Right click → Uninstall
4. فصّل الـ ESP32
5. وصّله تاني
6. Windows هيثبته تلقائي

### Linux:
```bash
sudo rm -rf /var/lib/dpkg/lock-frontend
sudo apt install --reinstall linux-headers-$(uname -r)
sudo modprobe cp210x
```

---

# 21. DEBUGGING TIPS - نصائح للتصحيح

## 21.1 Serial Debug Output

**تفعيل الـ debug:**
```cpp
#define DEBUG_MODE true

void debugPrint(const char* msg) {
    #ifdef DEBUG_MODE
    Serial.println(msg);
    #endif
}

void debugPrintValue(const char* label, int value) {
    #ifdef DEBUG_MODE
    Serial.print(label);
    Serial.print(": ");
    Serial.println(value);
    #endif
}
```

**استخدامها:**
```cpp
void setup() {
    Serial.begin(115200);
    debugPrint("[SETUP] Starting...");
}

void loop() {
    debugPrintValue("[LOOP] Heart rate", heartRate);
}
```

## 21.2 Conditional Compilation

```cpp
// LCD DEBUG - مش هيت compil
#ifdef LCD_DEBUG
    display.clearDisplay();
    display.setCursor(0, 0);
    display.println("Debug info...");
    display.display();
#endif

// WiFi DEBUG
#ifdef WIFI_DEBUG
    Serial.print("WiFi Status: ");
    Serial.println(WiFi.status());
#endif
```

## 21.3 Memory Debug

```cpp
void printMemoryUsage() {
    Serial.print("Free Heap: ");
    Serial.println(ESP.getFreeHeap());
    
    Serial.print("Heap Size: ");
    Serial.println(ESP.getHeapSize());
    
    Serial.print("Flash Size: ");
    Serial.println(ESP.getFlashChipSize());
}
```

---

# ═══════════════════════════════════════════════════════════════════════════
# PART 9: ADVANCED FEATURES
# ═══════════════════════════════════════════════════════════════════════════

# 22. ADVANCED FEATURES

## 22.1 Sleep Mode - وضع النوم

**تفعيل sleep mode:**
```cpp
void enterSleepMode() {
    // طفي الشاشة
    display.ssd1306_command(SSD1306_DISPLAYOFF);
    
    // طفي المستشعرات
    // (حسب المستشعر)
    
    // ادخل deep sleep
    ESP.deepSleep(30e6);  // 30 ثانية
    // أو
    // ESP.deepSleep(3600e6);  // ساعة
}

void wakeUp() {
    // لما يصحى من sleep
    display.ssd1306_command(SSD1306_DISPLAYON);
    
    // restaart المستشعرات
    initSensors();
}
```

## 22.2 OTA Updates - التحديث عن بعد

**إعداد OTA:**
```cpp
#include <ArduinoOTA.h>

void setupOTA() {
    ArduinoOTA.begin();
    ArduinoOTA.onStart([]() {
        Serial.println("OTA Update Start");
    });
    ArduinoOTA.onEnd([]() {
        Serial.println("OTA Update Complete");
    });
}

void loopOTA() {
    ArduinoOTA.handle();
}
```

## 22.3 Data Logging - تسجيل البيانات

**تخزين البيانات على Flash:**
```cpp
#include <SPIFFS.h>

void initLogger() {
    if (!SPIFFS.begin()) {
        Serial.println("SPIFFS failed!");
        return;
    }
}

void logData() {
    File file = SPIFFS.open("/health_log.txt", FILE_APPEND);
    if (file) {
        file.print(millis());
        file.print(",");
        file.print(currentHealth.heartRate);
        file.print(",");
        file.print(currentHealth.spO2);
        file.print(",");
        file.println(currentHealth.steps);
        file.close();
    }
}
```

## 22.4 Custom Animations - حركات مخصصة

**حركة نبض القلب:**
```cpp
void showHeartbeatAnimation() {
    static int pulse = 0;
    static bool growing = true;
    
    display.clearDisplay();
    
    // رسم القلب
    int size = 10 + pulse;
    
    // Big heart
    display.fillCircle(64 - size/2, 32 - size/2, size, SSD1306_WHITE);
    display.fillCircle(64 + size/2, 32 - size/2, size, SSD1306_WHITE);
    display.fillTriangle(64 - size*2, 32, 
                        64 + size*2, 32, 
                        64, 32 + size*2, SSD1306_WHITE);
    
    // Pulse animation
    if (growing) {
        pulse += 2;
        if (pulse > 10) growing = false;
    } else {
        pulse -= 2;
        if (pulse < 0) growing = true;
    }
    
    // النبض
    display.setTextSize(2);
    display.setCursor(45, 45);
    display.print((int)currentHealth.heartRate);
    
    display.display();
}
```

## 22.5 Custom Watch Faces - وجوه ساعة مخصصة

**وجه Clock:**
```cpp
void showCustomClockFace() {
    struct tm timeinfo;
    getLocalTime(&timeinfo);
    
    int hours = timeinfo.tm_hour;
    int minutes = timeinfo.tm_min;
    
    display.clearDisplay();
    
    // Draw clock face
    display.drawCircle(64, 32, 30, SSD1306_WHITE);
    
    // Hour hand
    float angleH = (hours % 12 + minutes/60.0) * 30;
    int xH = 64 + 20 * sin(angleH * PI / 180);
    int yH = 32 - 20 * cos(angleH * PI / 180);
    display.drawLine(64, 32, xH, yH, SSD1306_WHITE);
    
    // Minute hand
    float angleM = minutes * 6;
    int xM = 64 + 26 * sin(angleM * PI / 180);
    int yM = 32 - 26 * cos(angleM * PI / 180);
    display.drawLine(64, 32, xM, yM, SSD1306_WHITE);
    
    // Center dot
    display.fillCircle(64, 32, 2, SSD1306_WHITE);
    
    display.display();
}
```

---

# 23. PERFORMANCE OPTIMIZATION

## 23.1 Reduce Power Consumption

**استهلاك الطاقة الحالي:**
| المكون | التيار |
|--------|--------|
| ESP32 (active) | 80 mA |
| MAX30102 | 25 mA |
| MPU6050 | 3 mA |
| SSD1306 | 15 mA |
| LED (per one) | 10 mA |
| Vibration | 100 mA |

**إجمالي:** ~233 mA

**تقليل الاستهلاك:**
```cpp
// 1. قلل سطوع الشاشة
display.setContrast(128);  // بدل 255

// 2. قلل سطوع LED
byte ledBrightness = 30;  // بدل 60

// 3. طفي المستشعرات اللي مش محتاجة
void disableUnusedSensors() {
    // طفي GPS لو موجود
    // طفي واي فاي لو مش محتاج
}

// 4. استخدم sleep mode
ESP.deepSleep(60e6);  // sleep 60 ثانية
```

## 23.2 Optimize Memory

```cpp
// استخدم PROGMEM للـ strings الكبيرة
const char[] greeting = "Hello World";  // ❌ RAM
const char[] greeting = "Hello World";   // ✅ PROGMEM

// أو استخدم F() macro
Serial.println(F("This string goes to FLASH"));

// قلل حجم الـ buffers
StaticJsonDocument<256> doc;  // بدل 1024
```

## 23.3 Optimize I2C

```cpp
// استخدم Fast Mode
Wire.begin(18, 19, I2C_SPEED_FAST);  // 400KHz

// أو Fast Mode Plus
Wire.begin(18, 19, 1000000);  // 1MHz

// اتنين المستشعرات على address واحد
// أو استخدم multiplexer
```

---

# 24. CALIBRATION GUIDE

## 24.1 Heart Rate Calibration

**الخطوة 1:** قارن بقoesox أو app تاني

**الخطوة 2:** غيّر الـ algorithm
```cpp
// في SparkFunMAX3010x library
// الملف: src/SparkFunMAX3010x.cpp

// أو غيّر السطوع
byte ledBrightness = 60;  // زوّد أو قلّل

// أو غيّر sample rate
int sampleRate = 400;  // زوّد لـ 800 أو 1600
```

## 24.2 Step Counter Calibration

**الخطوة 1:** عد 100 خطوة وافحص

**الخطوة 2:** غيّر الـ threshold
```cpp
// زوّد الـ threshold لو بيحسب أكتر
#define STEP_THRESHOLD 1.8f  // بدل 1.5

// أو قلّله لو بيحسب أقل
#define STEP_THRESHOLD 1.2f
```

## 24.3 SpO2 Calibration

```cpp
// SpO2 الحساسية بتعتمد على:
// 1. LED brightness
// 2. Sample rate
// 3. Algorithm

// زوّد السطوع
particleSensor.setPulseAmplitudeRed(0x0A);
particleSensor.setPulseAmplitudeIR(0x0A);

// أو غيّر sample rate
particleSensor.setSampleRate(1000);  // أعلى = أدق
```

---

# ═══════════════════════════════════════════════════════════════════════════
# END OF DOCUMENT
# ═══════════════════════════════════════════════════════════════════════════

**Document Version:** 3.2.1  
**Total Lines:** 2400+  
**Last Updated:** July 2026  
**Company:** Cambric  
**Currency:** EGP (Egyptian Pounds)

**ملخص الأسعار:**
- Electronics: 1,891 ج.م
- Mechanical: 1,125 ج.م
- الأدوات: 2,550 ج.م
- الحد الأدنى: 3,016 ج.م

**Copyright:** © 2026 Cambric. All Rights Reserved.

هذه الوثيقة تغطي كل ما تحتاجه لبناء ساعة Digital Saver Onyx الذكية من الصفر!
كل القطع بالأسعار المصرية مع روابط الشراء من مصر!
