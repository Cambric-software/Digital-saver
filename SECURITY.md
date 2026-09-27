# Security Policy & Privacy Architecture

## 1. Scope & Ecosystem
This policy covers the **Digital Saver & Veyro Smartwatch Ecosystem**:
- Production ESP32-S3 firmware (`firmware/esp32s3`)
- Evaluation ESP32-WROOM firmware (`firmware/esp32`)
- Flutter companion application (`app/`)
- Onboard flash storage and BLE GATT protocol

---

## 2. Security & Privacy Tenets
- **Local-First & Offline Privacy**: All biometric telemetry (heart rate, SpO2, HRV, steps, fall detection) is logged locally to onboard flash and the companion device. There is no unauthorized cloud exfiltration.
- **BLE Transport Security**: Pairing PIN verification is required. In production firmware v2, BLE security mode incorporates pairing passkey validation to prevent unauthorized eavesdropping.
- **Encrypted Local Storage**: The Flutter companion app stores day telemetry under sandboxed application directories and encrypts user profile / emergency contact records.
- **Firmware Signing & Dual-OTA Protection**: The production S3 partition scheme provisions dual 3.2MB OTA slots (`ota_0`, `ota_1`) with hash validation to prevent bricking from corrupted transfers.

---

## 3. Threat Model & Known Constraints
- **BLE Proximity**: Unbonded BLE connections in legacy firmware v1 can read live telemetry if nearby. Upgrading to protocol v2 enforces handshake verification.
- **Medical Disclaimer**: The platform is an experimental consumer wellness device and not a certified clinical or life-support system. Do not rely on automated fall/SOS detection as the sole emergency mechanism.
- **Physical Tampering**: Flash storage on bare development boards can be read via direct serial access. Production boards must enable ESP32-S3 flash encryption and secure boot prior to commercial deployment.

---

## 4. Reporting a Vulnerability
We welcome security researchers to inspect our codebase and report potential issues responsibly.

- **Email**: Report vulnerabilities directly to `asser.k.dev@gmail.com`.
- **Response Timeline**: Acknowledgment within 48 hours; assessment and remediation advisory within 7 business days.
- **Disclosure Policy**: Please do not publish security issues publicly until a patch or mitigation has been released.
