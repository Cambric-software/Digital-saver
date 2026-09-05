/**
 * Veyro firmware 4.0.0 — Cambric
 * Local-only: no Wi-Fi, no cloud. Logs live on LittleFS for 60 days, then
 * the file for that day is deleted. Phone reads the log over BLE.
 *
 * Board: ESP32-WROOM-32 DevKit (4MB flash, no PSRAM).
 * Sensors: MAX30102 (I2C), MPU6050 (I2C), SSD1306 128x64 (I2C).
 *
 * This is wellness hardware, not a medical device.
 */

#include <Arduino.h>
#include <Wire.h>
#include <LittleFS.h>
#include <Preferences.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <BLESecurity.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <MAX30105.h>
#include <heartRate.h>
#include <ArduinoJson.h>

#ifndef VEYRO_FW_VERSION
#define VEYRO_FW_VERSION "4.0.0"
#endif
#include "pins.h"
#include "protocol.h"

Adafruit_SSD1306 display(OLED_W, OLED_H, &Wire, -1);
Adafruit_MPU6050 mpu;
MAX30105 ppg;
Preferences prefs;

BLEServer *bleServer = nullptr;
BLECharacteristic *liveChar = nullptr;
BLECharacteristic *histChar = nullptr;
BLECharacteristic *infoChar = nullptr;
BLECharacteristic *cmdChar = nullptr;

bool bleConnected = false;
bool hasOled = false;
bool hasMpu = false;
bool hasPpg = false;
bool paired = false;
char pinCode[7] = "000000";

uint32_t unixTime = 0;  // set by phone via TIME command; else millis/1000
uint32_t bootMs = 0;

float hrBpm = 0;
float spo2 = 0;
int bpSys = 0;
int bpDia = 0;
float hrvMs = 0;
uint32_t steps = 0;
bool fall = false;
int batteryPct = 0;
float ax = 0, ay = 0, az = 1;

uint32_t lastBeat = 0;
float lastIr = 0;
uint8_t rrCount = 0;
uint16_t rrBuf[20];

uint32_t lastLive = 0;
uint32_t lastSample = 0;
uint32_t lastPrune = 0;
uint32_t lastDisp = 0;
uint32_t lastSosDown = 0;
bool sosTriggered = false;
int face = 0;  // 0 clock 1 hr 2 steps

bool histSending = false;
File histFile;
String dumpFiles[62];
int dumpFileCount = 0;
int dumpFileIdx = 0;

uint32_t nowUnix() {
  if (unixTime == 0) return 1700000000UL + (millis() / 1000);
  return unixTime + ((millis() - bootMs) / 1000);
}

int readBattery() {
  int raw = analogRead(PIN_BAT_ADC);
  if (raw < 80) return 0;  // divider not wired
  // 2:1 divider, 3.3V ADC, 12-bit. Full ~4.2V => ~2600, empty ~3.3V => ~2048
  float v = (raw / 4095.0f) * 3.3f * 2.0f;
  int pct = (int)((v - 3.30f) / (4.15f - 3.30f) * 100.0f);
  if (pct < 0) pct = 0;
  if (pct > 100) pct = 100;
  return pct;
}

void vibe(int ms) {
  digitalWrite(PIN_VIBE, HIGH);
  delay(ms);
  digitalWrite(PIN_VIBE, LOW);
}

void makePin() {
  uint32_t n = (uint32_t)esp_random() % 900000UL + 100000UL;
  snprintf(pinCode, sizeof(pinCode), "%06lu", (unsigned long)n);
}

String dayPath(uint32_t t) {
  time_t tt = (time_t)t;
  struct tm tm;
  gmtime_r(&tt, &tm);
  char buf[32];
  snprintf(buf, sizeof(buf), "/d/%04d%02d%02d.csv", tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday);
  return String(buf);
}

void pruneOld() {
  File root = LittleFS.open("/d");
  if (!root || !root.isDirectory()) return;
  char cutoffKey[9] = "00000000";
  time_t cutoff = (time_t)nowUnix() - (time_t)RETAIN_DAYS * 86400;
  struct tm cutoffTm;
  gmtime_r(&cutoff, &cutoffTm);
  snprintf(cutoffKey, sizeof(cutoffKey), "%04d%02d%02d",
           cutoffTm.tm_year + 1900, cutoffTm.tm_mon + 1, cutoffTm.tm_mday);
  File f = root.openNextFile();
  while (f) {
    String name = String(f.name());
    f.close();
    // name like /d/20260827.csv
    int slash = name.lastIndexOf('/');
    String base = slash >= 0 ? name.substring(slash + 1) : name;
    if (base.length() >= 8) {
      int y = base.substring(0, 4).toInt();
      int m = base.substring(4, 6).toInt();
      int d = base.substring(6, 8).toInt();
      char fileKey[9];
      snprintf(fileKey, sizeof(fileKey), "%04d%02d%02d", y, m, d);
      if (strcmp(fileKey, cutoffKey) < 0) {
        LittleFS.remove(name.startsWith("/") ? name : String("/d/") + base);
      }
    }
    f = root.openNextFile();
  }
}

void appendSample() {
  if (!LittleFS.exists("/d")) LittleFS.mkdir("/d");
  String path = dayPath(nowUnix());
  File f = LittleFS.open(path, FILE_APPEND);
  if (!f) f = LittleFS.open(path, FILE_WRITE);
  if (!f) return;
  // unix,hr,spo2,sys,dia,hrv,steps,fall,bat
  char line[96];
  snprintf(line, sizeof(line), "%lu,%d,%d,%d,%d,%d,%lu,%d,%d\n",
           (unsigned long)nowUnix(),
           (int)hrBpm, (int)spo2, bpSys, bpDia, (int)hrvMs,
           (unsigned long)steps, fall ? 1 : 0, batteryPct);
  f.print(line);
  f.close();
}

int countSamples() {
  int n = 0;
  File root = LittleFS.open("/d");
  if (!root) return 0;
  File f = root.openNextFile();
  while (f) {
    if (!f.isDirectory()) {
      while (f.available()) {
        if (f.read() == '\n') n++;
      }
    }
    f.close();
    f = root.openNextFile();
  }
  return n;
}

void setInfo() {
  StaticJsonDocument<256> doc;
  doc["v"] = VEYRO_PROTO;
  doc["fw"] = VEYRO_FW_VERSION;
  doc["name"] = VEYRO_NAME;
  doc["paired"] = paired;
  doc["samples"] = countSamples();
  doc["retain_d"] = RETAIN_DAYS;
  doc["free_kb"] = (int)(LittleFS.totalBytes() - LittleFS.usedBytes()) / 1024;
  doc["bat"] = batteryPct;
  String out;
  serializeJson(doc, out);
  infoChar->setValue(out.c_str());
}

class ServerCb : public BLEServerCallbacks {
  void onConnect(BLEServer *) override {
    bleConnected = true;
    digitalWrite(PIN_LED_GREEN, HIGH);
  }
  void onDisconnect(BLEServer *) override {
    bleConnected = false;
    histSending = false;
    digitalWrite(PIN_LED_GREEN, LOW);
    bleServer->startAdvertising();
  }
};

void buildDumpList() {
  dumpFileCount = 0;
  dumpFileIdx = 0;
  File root = LittleFS.open("/d");
  if (!root) return;
  File f = root.openNextFile();
  while (f && dumpFileCount < 62) {
    if (!f.isDirectory()) {
      dumpFiles[dumpFileCount++] = String(f.name());
    }
    f.close();
    f = root.openNextFile();
  }
}

void handleCmd(const String &raw) {
  StaticJsonDocument<192> doc;
  if (deserializeJson(doc, raw)) return;
  const char *op = doc["op"] | "";
  if (strcmp(op, "pair") == 0) {
    const char *pin = doc["pin"] | "";
    if (strcmp(pin, pinCode) == 0) {
      paired = true;
      prefs.putBool("paired", true);
      setInfo();
      vibe(80);
    }
    return;
  }
  if (!paired) return;
  if (strcmp(op, "time") == 0) {
    unixTime = doc["unix"] | 0;
    bootMs = millis();
    return;
  }
  if (strcmp(op, "sync") == 0) {
    if (!paired) return;
    if (histFile) histFile.close();
    buildDumpList();
    dumpFileIdx = 0;
    histSending = true;
    if (dumpFileCount == 0) {
      histChar->setValue("{\"v\":1,\"done\":1}");
      histChar->notify();
      histSending = false;
      return;
    }
    histFile = LittleFS.open(dumpFiles[0], FILE_READ);
    sendHistLine();
    return;
  }
  if (strcmp(op, "next") == 0) {
    sendHistLine();
    return;
  }
  if (strcmp(op, "prune") == 0) {
    pruneOld();
    setInfo();
    return;
  }
}

void sendHistLine() {
  if (!histSending) return;
  while (true) {
    if (!histFile) {
      dumpFileIdx++;
      if (dumpFileIdx >= dumpFileCount) {
        histSending = false;
        histChar->setValue("{\"v\":1,\"done\":1}");
        histChar->notify();
        return;
      }
      histFile = LittleFS.open(dumpFiles[dumpFileIdx], FILE_READ);
      if (!histFile) continue;
    }
    String line = histFile.readStringUntil('\n');
    line.trim();
    if (line.length() == 0) {
      histFile.close();
      histFile = File();
      continue;
    }
    StaticJsonDocument<192> doc;
    doc["v"] = VEYRO_PROTO;
    doc["row"] = line;
    String out;
    serializeJson(doc, out);
    histChar->setValue(out.c_str());
    histChar->notify();
    return;
  }
}

class CmdCb : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *c) override {
    handleCmd(String(c->getValue().c_str()));
  }
};

void initBle() {
  BLEDevice::init(VEYRO_NAME);
  // Require an encrypted Secure Connections link using the displayed watch PIN.
  BLESecurity *security = new BLESecurity();
  security->setStaticPIN(strtoul(pinCode, nullptr, 10));
  bleServer = BLEDevice::createServer();
  bleServer->setCallbacks(new ServerCb());
  BLEService *svc = bleServer->createService(SERVICE_UUID);

  liveChar = svc->createCharacteristic(CHAR_LIVE_UUID, BLECharacteristic::PROPERTY_NOTIFY);
  liveChar->addDescriptor(new BLE2902());

  histChar = svc->createCharacteristic(CHAR_HIST_UUID, BLECharacteristic::PROPERTY_NOTIFY);
  histChar->addDescriptor(new BLE2902());

  infoChar = svc->createCharacteristic(CHAR_INFO_UUID, BLECharacteristic::PROPERTY_READ);

  cmdChar = svc->createCharacteristic(CHAR_CMD_UUID, BLECharacteristic::PROPERTY_WRITE);
  cmdChar->setCallbacks(new CmdCb());

  svc->start();
  BLEAdvertising *adv = BLEDevice::getAdvertising();
  adv->addServiceUUID(SERVICE_UUID);
  adv->setScanResponse(true);
  BLEDevice::startAdvertising();
  setInfo();
}

void sendLive() {
  StaticJsonDocument<192> doc;
  doc["v"] = VEYRO_PROTO;
  doc["hr"] = (int)hrBpm;
  doc["spo2"] = (int)spo2;
  doc["bps"] = bpSys;
  doc["bpd"] = bpDia;
  doc["hrv"] = (int)hrvMs;
  doc["steps"] = steps;
  doc["fall"] = fall ? 1 : 0;
  doc["bat"] = batteryPct;
  doc["ts"] = nowUnix();
  String out;
  serializeJson(doc, out);
  liveChar->setValue(out.c_str());
  if (bleConnected) liveChar->notify();
}

void readMpu() {
  if (!hasMpu) return;
  sensors_event_t a, g, t;
  mpu.getEvent(&a, &g, &t);
  ax = a.acceleration.x / 9.81f;
  ay = a.acceleration.y / 9.81f;
  az = a.acceleration.z / 9.81f;
  float mag = sqrtf(ax * ax + ay * ay + az * az);
  static float lastMag = 1;
  // Cheap step: crossing ~1.2g
  if (lastMag < 1.15f && mag > 1.25f) steps++;
  lastMag = mag;
  // Fall: free-fall then spike (very rough, many false positives)
  static uint32_t lowAt = 0;
  if (mag < 0.4f) {
    if (lowAt == 0) lowAt = millis();
  } else {
    if (lowAt > 0 && millis() - lowAt > 80 && mag > 2.4f) {
      fall = true;
      vibe(400);
      digitalWrite(PIN_LED_RED, HIGH);
    }
    lowAt = 0;
  }
}

void readPpg() {
  if (!hasPpg) return;
  long ir = ppg.getIR();
  if (checkForBeat(ir)) {
    uint32_t now = millis();
    uint32_t dt = now - lastBeat;
    lastBeat = now;
    if (dt > 300 && dt < 2000) {
      hrBpm = 0.8f * hrBpm + 0.2f * (60000.0f / dt);
      if (rrCount < 20) rrBuf[rrCount++] = (uint16_t)dt;
      else {
        for (int i = 1; i < 20; i++) rrBuf[i - 1] = rrBuf[i];
        rrBuf[19] = (uint16_t)dt;
      }
      if (rrCount >= 5) {
        float s = 0;
        int n = rrCount > 20 ? 20 : rrCount;
        for (int i = 1; i < n; i++) {
          float d = (float)rrBuf[i] - (float)rrBuf[i - 1];
          s += d * d;
        }
        hrvMs = sqrtf(s / (n - 1));
      }
    }
  }
  // SpO2 needs red+IR buffers; use SparkFun helper when IR is strong
  if (ir > 50000) {
    // Rough PI-based placeholder: real SpO2 needs the official algorithm buffers.
    // We keep a conservative estimate so we never claim clinical accuracy.
    uint32_t red = ppg.getRed();
    float ratio = (red > 0) ? ((float)ir / (float)red) : 0;
    float est = 110.0f - 12.0f * ratio;
    if (est < 85) est = 85;
    if (est > 100) est = 100;
    spo2 = 0.9f * spo2 + 0.1f * est;
    // PTT-style BP estimate is not reliable on MAX30102 alone.
    bpSys = 0;
    bpDia = 0;
  } else {
    hrBpm = 0;
    spo2 = 0;
  }
  lastIr = (float)ir;
}

void draw() {
  if (!hasOled) return;
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.print(VEYRO_NAME);
  display.print(" ");
  display.print(batteryPct > 0 ? String(batteryPct) + "%" : "--%");
  if (!paired) {
    display.setCursor(0, 16);
    display.print("PIN ");
    display.setTextSize(2);
    display.setCursor(0, 32);
    display.print(pinCode);
    display.display();
    return;
  }
  display.setCursor(0, 12);
  if (face == 0) {
    uint32_t t = nowUnix() % 86400;
    char buf[16];
    snprintf(buf, sizeof(buf), "%02lu:%02lu", (unsigned long)(t / 3600), (unsigned long)((t % 3600) / 60));
    display.setTextSize(2);
    display.println(buf);
    display.setTextSize(1);
    display.print(bleConnected ? "phone OK" : "no phone");
  } else if (face == 1) {
    display.setTextSize(2);
    display.print((int)hrBpm);
    display.setTextSize(1);
    display.println(" bpm");
    display.print("SpO2 ");
    display.print((int)spo2);
    display.println("%");
    if (spo2 > 0 && spo2 < 90) display.println("low O2 est.");
  } else {
    display.setTextSize(2);
    display.println(steps);
    display.setTextSize(1);
    display.println("steps");
  }
  if (fall) {
    display.setCursor(0, 56);
    display.print("FALL? hold SOS");
  }
  display.display();
}

void setup() {
  Serial.begin(115200);
  pinMode(PIN_VIBE, OUTPUT);
  pinMode(PIN_LED_RED, OUTPUT);
  pinMode(PIN_LED_GREEN, OUTPUT);
  pinMode(PIN_BTN_MODE, INPUT_PULLUP);
  pinMode(PIN_BTN_SOS, INPUT_PULLUP);
  analogReadResolution(12);

  Wire.begin(I2C_SDA, I2C_SCL);
  Wire.setClock(400000);

  hasOled = display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR);
  if (hasOled) {
    display.clearDisplay();
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 24);
    display.println("Veyro boot");
    display.display();
  }

  hasMpu = mpu.begin();
  if (hasMpu) {
    mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
  }

  hasPpg = ppg.begin(Wire, I2C_SPEED_FAST);
  if (hasPpg) {
    ppg.setup();
    ppg.setPulseAmplitudeRed(0x1F);
    ppg.setPulseAmplitudeIR(0x1F);
    ppg.setPulseAmplitudeGreen(0);
  }

  if (!LittleFS.begin(true)) {
    Serial.println("LittleFS fail");
  } else {
    LittleFS.mkdir("/d");
  }

  prefs.begin("veyro", false);
  paired = prefs.getBool("paired", false);
  String saved = prefs.getString("pin", "");
  if (saved.length() == 6) {
    strncpy(pinCode, saved.c_str(), 6);
    pinCode[6] = 0;
  } else {
    makePin();
    prefs.putString("pin", pinCode);
  }

  initBle();
  pruneOld();
  bootMs = millis();
  Serial.printf("Veyro %s PIN %s PPG=%d MPU=%d OLED=%d\n", VEYRO_FW_VERSION, pinCode, hasPpg, hasMpu, hasOled);
}

void loop() {
  uint32_t ms = millis();
  batteryPct = readBattery();
  readMpu();
  readPpg();

  if (digitalRead(PIN_BTN_MODE) == LOW) {
    delay(40);
    if (digitalRead(PIN_BTN_MODE) == LOW) {
      face = (face + 1) % 3;
      while (digitalRead(PIN_BTN_MODE) == LOW) delay(10);
    }
  }
  if (digitalRead(PIN_BTN_SOS) == LOW) {
    if (lastSosDown == 0) lastSosDown = ms;
    if (!sosTriggered && ms - lastSosDown > 2000) {
      fall = true;
      vibe(600);
      sosTriggered = true;
    }
  } else {
    lastSosDown = 0;
    sosTriggered = false;
  }

  if (ms - lastLive >= LIVE_EVERY_MS) {
    lastLive = ms;
    sendLive();
    setInfo();
  }
  if (ms - lastSample >= SAMPLE_EVERY_MS) {
    lastSample = ms;
    if (hrBpm > 30 || steps > 0) appendSample();
    fall = false;
    digitalWrite(PIN_LED_RED, LOW);
  }
  if (ms - lastPrune >= 3600000UL) {
    lastPrune = ms;
    pruneOld();
  }
  if (ms - lastDisp >= 200) {
    lastDisp = ms;
    draw();
  }
}
