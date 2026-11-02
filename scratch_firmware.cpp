<USER_REQUEST>
/*
  HAJICARE SMARTBAND PRO — ESP32-S3 SUPER MINI / ATGM336H / BLE / OLED / INMP441
  VERSION: 2.3 — Action Button (1x Next Page, 2x AI Voice, 3s SOS), Stable MAX30102,
                 Immediate Fall Haptic, Dynamic Safe Radius, 3-Axis Wrist Step Counter,
                 & INMP441 I2S Microphone Bridge for AI Voice Assistant (Flutter TTS).

  CONNECTIONS:
    Shared I2C: SDA=GPIO8, SCL=GPIO9
       MAX30102 (0x57), DFRobot MCP9808 (normally 0x1F), MPU6050 (0x68/69),
       0.96-inch SSD1306 128x64 OLED (0x3C/3D)
    GPS ATGM336H TX -> ESP32-S3 GPIO44 (UART1 RX only; GPS RX unconnected)
    INMP441 I2S MIC: SCK=GPIO4, WS=GPIO5, SD=GPIO6, L/R=GND, VDD=3.3V
    ACTION / SOS switch GPIO13 -> GND; INPUT_PULLUP
    Vibration MODULE input GPIO7 (active HIGH by default)

  ACTION BUTTON (GPIO13):
   - Normal Idle + 1x Short Press (<3s) : Pindah halaman OLED berikutnya (+ haptic tap)
   - Normal Idle + 2x Quick Click       : Mulai Rekam Suara AI via INMP441 (maks 5 detik)
   - Saat Rekam AI + 1x Short Press     : Selesai rekam lebih cepat & kirim ke Flutter AI
   - Normal Idle + Hold 3 Detik         : Aktifkan Manual SOS (getar darurat + kirim BLE)
   - Saat Alarm Aktif + 1x Short Press  : Matikan/batalkan getaran alarm lokal (SOS/Fall/Radius)

  BLE COMMANDS (RX on 6e400002-b5a3-f393-e0a9-e50e24dcca9e):
   - Ubah radius dinamis (meter) : "RADIUS:50" atau "{\"safeRadius\":50}"
   - Kirim jarak dari HP (meter) : "DIST:65.4" atau "DIST:65.4,50"
   - Kirim koordinat pendamping  : "COMP:-6.123456,106.123456" atau "COMP:-6.123456,106.123456,50"
   - Trigger alert langsung      : "RADIUS_ALERT:1" (ON) / "RADIUS_ALERT:0" (OFF)
   - Reset hitungan langkah      : "RESET_STEPS" atau "STEPS:0"
   - Tampilkan balasan AI di OLED: "AI:Kondisi stabil (88 BPM). Tenda 45m di Utara."
   - Kontrol mic dari aplikasi   : "AI_LISTEN:1" (Mulai rekam) / "AI_LISTEN:0" (Stop rekam)
*/

#include <Arduino.h>
#include <Wire.h>
#include <math.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <driver/i2s.h>
#include <TinyGPS++.h>
#include "MAX30105.h"
#include "heartRate.h"
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include "HajiCare_IntroFrames.h"

#if !defined(CONFIG_IDF_TARGET_ESP32S3)
  #error "Select Tools > Board > ESP32S3 Dev Module (or your exact ESP32-S3 board)."
#endif

#define BRACELET_ID      "HCG-001"
#define DEVICE_NAME      "HajiCare-Gelang-001"
#define BLE_SERVICE_UUID "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
#define BLE_TX_UUID      "6e400003-b5a3-f393-e0a9-e50e24dcca9e"
#define BLE_RX_UUID      "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
#define BLE_AUDIO_UUID   "6e400004-b5a3-f393-e0a9-e50e24dcca9e" // Karakteristik khusus stream audio PCM 16-bit

constexpr uint8_t PIN_SDA = 8, PIN_SCL = 9, PIN_ACTION = 13, PIN_MOTOR = 7;
constexpr int PIN_GPS_RX = 44, PIN_GPS_TX = -1;
constexpr int PIN_I2S_SCK = 4, PIN_I2S_WS = 5, PIN_I2S_SD = 6;
constexpr uint32_t GPS_BAUD = 9600, SERIAL_BAUD = 115200;
constexpr bool MOTOR_ACTIVE_HIGH = true; // set false HANYA jika modul vibrator active LOW
constexpr bool AUTO_CYCLE_PAGES = false; // false = pindah page via klik tombol Action
constexpr bool DEBUG_RAW_NMEA = false;   // false agar tidak memblokir pembacaan FIFO MAX30102

constexpr uint16_t BLE_LOCAL_MTU = 247;
constexpr uint32_t MPU_PERIOD = 10, TEMP_PERIOD = 1000, OLED_PERIOD = 200;
constexpr uint32_t BLE_PERIOD = 2000, BLE_ALARM_PERIOD = 1000;
constexpr uint32_t SERIAL_PERIOD = 2000, GPS_REPORT_PERIOD = 5000;
constexpr uint32_t INTRO_FRAME_MS = 270, INTRO_FRAMES_TOTAL = 8 * INTRO_FRAME_MS;
constexpr uint32_t PAGE_MS = 6000;
constexpr uint8_t TOTAL_PAGES = 7; // 0:HR, 1:GPS, 2:Temp, 3:Fall, 4:Steps, 5:Safe Radius, 6:AI Voice
constexpr uint8_t PAGE_AI = 6;

HardwareSerial GPSport(1);
TinyGPSPlus gps;
TinyGPSCustom gnFixQuality(gps, "GNGGA", 6);
TinyGPSCustom gnSatsUsed(gps, "GNGGA", 7);
TinyGPSCustom gnHdop(gps, "GNGGA", 8);
TinyGPSCustom gpFixQuality(gps, "GPGGA", 6);
TinyGPSCustom gpSatsUsed(gps, "GPGGA", 7);
TinyGPSCustom gpHdop(gps, "GPGGA", 8);

MAX30105 pulse;
// Gunakan 400kHz pada OLED agar pengiriman frame layar tidak menghambat sampling langkah MPU6050
Adafruit_SSD1306 screen(128, 64, &Wire, -1, 400000UL, 100000UL);

BLEServer *bleServer = nullptr;
BLECharacteristic *txCharacteristic = nullptr;
BLECharacteristic *rxCharacteristic = nullptr;
BLECharacteristic *audioCharacteristic = nullptr;
volatile bool bleConnected = false;
volatile bool bleRestart = false;
volatile uint16_t negotiatedMTU = 23;
volatile bool requestBleNow = false;
uint32_t bleDisconnectedAt = 0;

char pendingJson[512] = {0};
uint16_t pendingJsonLen = 0;
uint8_t pendingSeq = 0, pendingIndex = 0, pendingTotal = 0;
uint8_t pendingDataBytes = 0;
uint32_t lastFragmentAt = 0;
constexpr uint32_t BLE_FRAGMENT_SPACING_MS = 80;

bool oledReady = false, maxReady = false, mcpReady = false, mpuReady = false, micReady = false;
uint8_t oledAddr = 0, mcpAddr = 0, mpuAddress = 0;

// =====================================================
// INMP441 I2S MICROPHONE & AI VOICE ASSISTANT VARIABLES
// =====================================================
constexpr i2s_port_t I2S_PORT = I2S_NUM_0;
constexpr uint32_t AI_SAMPLE_RATE = 8000;      // 8 kHz Mono 16-bit PCM (optimal untuk BLE & Speech-to-Text)
constexpr size_t AI_PCM_SAMPLES_PER_PKT = 110; // 110 sampel x 2 byte = 220 byte per paket BLE (< MTU 244)
constexpr uint32_t AI_MAX_LISTEN_MS = 5000;    // Durasi rekam maksimal 5 detik per pertanyaan
constexpr int AI_DIGITAL_GAIN_SHIFT = 13;      // Geser 32-bit I2S INMP441 ke 16-bit PCM dengan penguatan suara

enum AiState : uint8_t {
  AI_IDLE = 0,
  AI_LISTENING,
  AI_PROCESSING,
  AI_REPLY_SHOWN
};
AiState aiState = AI_IDLE;
bool aiListening = false;
uint32_t aiListenStartAt = 0;
uint32_t aiStateChangedAt = 0;
uint32_t aiBytesSent = 0;
uint8_t aiMicLevel = 0; // 0..100% indikator visual kekuatan suara di OLED
char aiDisplayText[96] = "Klik 2x tombol untuk bicara ke AI HajiCare";
int32_t i2sRawBuffer[AI_PCM_SAMPLES_PER_PKT];
int16_t pcmTxBuffer[AI_PCM_SAMPLES_PER_PKT];

// GPS metadata
bool gpsFix = false;
uint32_t gpsBytes = 0;
uint8_t gpsSatellites = 0;
int gpsQuality = -1, gpsUsed = -1;
float gpsHdop = NAN;
uint32_t gpsQualityUpdatedAt = 0;
char gpsNmeaLine[160] = {0};
size_t gpsNmeaLength = 0;

// Heart rate (MAX30102) dengan hysteresis, debounce kontak, dan penahan BPM stabil
int bpm = 0;
long irRaw = 0;
bool opticalContact = false;
uint32_t contactLostAt = 0;
byte bpmSamples[8] = {0};
uint8_t bpmSampleCount = 0, bpmIndex = 0;
uint32_t lastBeatAt = 0, lastOpticalAt = 0;
constexpr long IR_CONTACT_ON_THRESHOLD  = 14000;
constexpr long IR_CONTACT_OFF_THRESHOLD = 9000;
constexpr uint32_t CONTACT_LOST_GRACE_MS = 2500;
constexpr uint32_t BEAT_HOLD_TIMEOUT_MS  = 10000;

// MCP9808 sensor temperature
float temperatureC = NAN;
uint32_t lastTempOK = 0;

// MPU6050 variables
float ax = 0, ay = 0, az = 1, gx = 0, gy = 0, gz = 0;
float totalG = 1, totalDps = 0;
float gravityX = 0, gravityY = 0, gravityZ = 1;
float refX = 0, refY = 0, refZ = 1;
bool gravityInitialized = false;
uint32_t lastMpuOK = 0;

// =====================================================
// STEP COUNTER (PEDOMETER) 3-AXIS WRIST VARIABLES
// =====================================================
uint32_t stepCount = 0;
float stepDistanceMeters = 0.0f;
constexpr float STRIDE_LENGTH_M         = 0.65f;
constexpr float STEP_TRIGGER_LIN_G      = 0.055f;
constexpr float STEP_RELEASE_LIN_G      = 0.032f;
constexpr float STEP_MIN_DEV_G          = 0.040f;
constexpr float STEP_SWING_GYRO_DPS     = 18.0f;
constexpr uint32_t STEP_MIN_INTERVAL_MS = 300;

float stepBaselineG = 1.0f;
float stepLinFiltered = 0.0f;
float stepWavePrev = 0.0f;
float currentStepPeakG = 0.0f;
bool stepPeakArmed = false;
uint32_t lastStepAt = 0;
uint32_t stepPeakAt = 0;

// Fall state machine
enum FallState : uint8_t {
  FALL_MONITORING, FALL_LOW_G, FALL_POST_IMPACT, FALL_COUNTDOWN, FALL_ALERT, FALL_COOLDOWN
};
FallState fallState = FALL_MONITORING;

// =====================================================
// FALL DETECTION - NORMAL / MODERATE SENSITIVITY
// =====================================================
constexpr float FREEFALL_THRESHOLD_G = 0.60f;
constexpr float IMPACT_THRESHOLD_G   = 2.00f;
constexpr float STRONG_IMPACT_G      = 3.20f;

constexpr float IMPACT_ROTATION_DPS  = 150.0f;
constexpr float POSTURE_CHANGE_DEG   = 50.0f;

constexpr float STILL_GYRO_DPS       = 25.0f;
constexpr float STILL_MIN_G          = 0.75f;
constexpr float STILL_MAX_G          = 1.25f;

constexpr uint32_t LOWG_TO_IMPACT_MS = 1200;
constexpr uint32_t AFTER_IMPACT_MS   = 6000;
constexpr uint32_t STILL_REQUIRED_MS = 1000;

constexpr uint32_t CANCEL_WINDOW_MS = 10000;
constexpr uint32_t FALL_COOLDOWN_MS = 8000;

uint32_t lowGAt = 0;
uint32_t impactAt = 0;
uint32_t stillAt = 0;
uint32_t countdownAt = 0;
uint32_t cooldownAt = 0;

float peakG = 0;
float peakDps = 0;

bool hadLowG = false;

// Safe Radius state (Dinamis dari Aplikasi Pendamping)
float safeRadiusMeters = 50.0f;
float currentDistanceM = NAN;
double companionLat = NAN;
double companionLon = NAN;
uint32_t companionUpdatedAt = 0;
bool safeRadiusEnabled = true;
bool appForcedRadiusAlert = false;
bool radiusAlertActive = false;
uint32_t radiusSnoozeUntil = 0;
constexpr uint32_t RADIUS_SNOOZE_MS = 30000;

// Action Button (Single-Click, Double-Click AI, & 3s Hold SOS)
bool sosActive = false;
uint32_t buttonDebounceAt = 0, buttonDownAt = 0;
bool buttonRawLast = HIGH, buttonStable = HIGH, buttonLongHandled = false;
bool pendingSingleClick = false;
uint32_t lastClickReleaseAt = 0;
constexpr uint32_t BUTTON_DEBOUNCE_MS = 40;
constexpr uint32_t DOUBLE_CLICK_MS    = 280;  // Jendela waktu klik 2x untuk mengaktifkan Mic AI
constexpr uint32_t SOS_HOLD_MS        = 3000;
uint32_t alertEventSequence = 0;
uint32_t activeEventId = 0;
uint32_t alertSince = 0;

// Haptic sequencer non-blocking
enum HapticPattern : uint8_t {
  HAPTIC_NONE = 0,
  HAPTIC_TAP,
  HAPTIC_CONFIRM,
  HAPTIC_WARNING,
  HAPTIC_SAFE_RADIUS,
  HAPTIC_EMERGENCY
};
HapticPattern hapticPattern = HAPTIC_NONE;
uint8_t pulseNumber = 0;
bool motorOn = false;
uint32_t motorStageAt = 0;

// UI state
uint32_t bootAt = 0, lastPageAt = 0, lastOledAt = 0;
uint8_t currentPage = 0;
bool bootFinished = false;
uint32_t lastMpuAt = 0, lastTempAt = 0, lastBleAt = 0, lastSerialAt = 0, lastGpsReportAt = 0;

// Forward declarations
void sendSoon();
void vibrate(HapticPattern requested);
void motorWrite(bool on);
void startAiListening();
void stopAiListening(bool notifyComplete);

// ====================================================================
// INMP441 I2S MICROPHONE DRIVER & AI STREAMING
// ====================================================================
void initMicrophone() {
  i2s_config_t i2s_config = {
    .mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_RX),
    .sample_rate = AI_SAMPLE_RATE,
    .bits_per_sample = I2S_BITS_PER_SAMPLE_32BIT,
    .channel_format = I2S_CHANNEL_FMT_ONLY_LEFT,
    .communication_format = I2S_COMM_FORMAT_STAND_I2S,
    .intr_alloc_flags = ESP_INTR_FLAG_LEVEL1,
    .dma_buf_count = 6,
    .dma_buf_len = 256,
    .use_apll = false,
    .tx_desc_auto_clear = false,
    .fixed_mclk = 0
  };

  i2s_pin_config_t pin_config = {
    .bck_io_num = PIN_I2S_SCK,
    .ws_io_num = PIN_I2S_WS,
    .data_out_num = I2S_PIN_NO_CHANGE,
    .data_in_num = PIN_I2S_SD
  };

  if (i2s_driver_install(I2S_PORT, &i2s_config, 0, NULL) == ESP_OK &&
      i2s_set_pin(I2S_PORT, &pin_config) == ESP_OK) {
    i2s_zero_dma_buffer(I2S_PORT);
    micReady = true;
    Serial.printf("[MIC] INMP441 I2S READY (SCK=GPIO%d, WS=GPIO%d, SD=GPIO%d, %lu Hz)\n",
                  PIN_I2S_SCK, PIN_I2S_WS, PIN_I2S_SD, (unsigned long)AI_SAMPLE_RATE);
  } else {
    micReady = false;
    Serial.println("[ERROR] Gagal inisialisasi mikrofon INMP441!");
  }
}

void startAiListening() {
  if (!micReady) {
    currentPage = PAGE_AI;
    bootFinished = true;
    snprintf(aiDisplayText, sizeof(aiDisplayText), "ERR: Modul Mic INMP441 tidak terdeteksi!");
    vibrate(HAPTIC_WARNING);
    return;
  }

  i2s_zero_dma_buffer(I2S_PORT);
  aiListening = true;
  aiState = AI_LISTENING;
  aiListenStartAt = millis();
  aiStateChangedAt = aiListenStartAt;
  aiBytesSent = 0;
  aiMicLevel = 0;
  currentPage = PAGE_AI;
  bootFinished = true;
  lastPageAt = aiListenStartAt;
  pendingJsonLen = 0; // Kosongkan antrean fragmen JSON agar jalur BLE fokus ke suara

  snprintf(aiDisplayText, sizeof(aiDisplayText), "Silakan bicara di dekat gelang...");
  vibrate(HAPTIC_CONFIRM);

  if (bleConnected && txCharacteristic != nullptr) {
    const char *startEvt = "{\"event\":\"AI_START\",\"sampleRate\":8000,\"bits\":16,\"channels\":1}";
    txCharacteristic->setValue((const uint8_t*)startEvt, strlen(startEvt));
    txCharacteristic->notify();
  }

  Serial.println("[AI VOICE] Mulai merekam suara dari INMP441 (Maks 5 detik / Klik 1x untuk selesai)...");
}

void stopAiListening(bool notifyComplete) {
  if (!aiListening) return;

  aiListening = false;
  aiMicLevel = 0;
  aiState = AI_PROCESSING;
  aiStateChangedAt = millis();

  if (notifyComplete) {
    snprintf(aiDisplayText, sizeof(aiDisplayText), "Memproses suara di AI HP...");
    vibrate(HAPTIC_TAP);

    if (bleConnected && txCharacteristic != nullptr) {
      char endEvt[96];
      int n = snprintf(endEvt, sizeof(endEvt),
                       "{\"event\":\"AI_END\",\"bytes\":%lu}",
                       (unsigned long)aiBytesSent);
      txCharacteristic->setValue((const uint8_t*)endEvt, n);
      txCharacteristic->notify();
    }
    Serial.printf("[AI VOICE] Rekaman selesai (%lu byte terkirim). Menunggu jawaban AI dari Flutter...\n",
                  (unsigned long)aiBytesSent);
  } else {
    aiState = AI_IDLE;
    snprintf(aiDisplayText, sizeof(aiDisplayText), "Rekaman AI dibatalkan.");
    Serial.println("[AI VOICE] Rekaman dibatalkan.");
  }

  requestBleNow = true;
}

void updateAiMicrophone(uint32_t now) {
  if (!aiListening) {
    // Jika dalam 15 detik aplikasi belum mengirim balasan teks AI, kembalikan petunjuk awal
    if (aiState == AI_PROCESSING && (now - aiStateChangedAt >= 15000)) {
      aiState = AI_IDLE;
      snprintf(aiDisplayText, sizeof(aiDisplayText), "Klik 2x tombol untuk bicara ke AI HajiCare");
    }
    return;
  }

  if (now - aiListenStartAt >= AI_MAX_LISTEN_MS) {
    stopAiListening(true);
    return;
  }

  size_t bytesRead = 0;
  esp_err_t err = i2s_read(I2S_PORT, i2sRawBuffer, sizeof(i2sRawBuffer), &bytesRead, 0);
  if (err != ESP_OK || bytesRead == 0) return;

  size_t samplesRead = bytesRead / sizeof(int32_t);
  int32_t peakAbs = 0;

  for (size_t i = 0; i < samplesRead; ++i) {
    int32_t shifted = i2sRawBuffer[i] >> AI_DIGITAL_GAIN_SHIFT;
    if (shifted > 32767) shifted = 32767;
    else if (shifted < -32768) shifted = -32768;

    pcmTxBuffer[i] = (int16_t)shifted;
    int32_t absVal = abs(shifted);
    if (absVal > peakAbs) peakAbs = absVal;
  }

  // Hitung persentase bar indikator suara (0-100%) untuk ditampilkan di OLED
  uint8_t instLevel = (uint8_t)constrain((peakAbs * 100L) / 18000L, 0L, 100L);
  aiMicLevel = (uint8_t)((aiMicLevel * 2 + instLevel * 3) / 5);

  // Kirim paket PCM 16-bit ke aplikasi Flutter melalui BLE Audio Characteristic
  if (bleConnected && audioCharacteristic != nullptr) {
    size_t payloadBytes = samplesRead * sizeof(int16_t);
    audioCharacteristic->setValue((uint8_t*)pcmTxBuffer, payloadBytes);
    audioCharacteristic->notify();
    aiBytesSent += payloadBytes;
  }
}

// ====================================================================
// HELPER I2C & SENSOR SUHU MCP9808
// ====================================================================
void recoverI2CBus() {
  pinMode(PIN_SDA, INPUT_PULLUP);
  pinMode(PIN_SCL, OUTPUT);
  for (int i = 0; i < 9; ++i) {
    digitalWrite(PIN_SCL, LOW);
    delayMicroseconds(5);
    digitalWrite(PIN_SCL, HIGH);
    delayMicroseconds(5);
  }
}

bool read16(uint8_t address, uint8_t reg, uint16_t &out) {
  Wire.beginTransmission(address);
  Wire.write(reg);
  if (Wire.endTransmission(false) != 0) return false;
  if (Wire.requestFrom(address, (uint8_t)2) != (uint8_t)2) return false;
  out = ((uint16_t)Wire.read() << 8) | Wire.read();
  return true;
}

bool write8(uint8_t address, uint8_t reg, uint8_t val) {
  Wire.beginTransmission(address);
  Wire.write(reg);
  Wire.write(val);
  return Wire.endTransmission() == 0;
}

bool isDevice(uint8_t address) {
  Wire.beginTransmission(address);
  return Wire.endTransmission() == 0;
}

void scanI2C() {
  Serial.print("[I2C SCAN] devices:");
  unsigned count = 0;
  for (uint8_t address = 0x08; address <= 0x77; ++address) {
    if (isDevice(address)) {
      Serial.printf(" 0x%02X", address);
      ++count;
    }
  }
  Serial.printf(" (%u found)\n", count);
}

void initTemp() {
  for (uint8_t addr = 0x18; addr <= 0x1F; ++addr) {
    uint16_t man = 0, dev = 0;
    if (read16(addr, 0x06, man) && read16(addr, 0x07, dev) && man == 0x0054 && (dev >> 8) == 0x04) {
      mcpAddr = addr;
      uint16_t cfg = 0;
      if (read16(addr, 0x01, cfg) && (cfg & 0x0100)) {
        Wire.beginTransmission(addr);
        Wire.write((uint8_t)0x01);
        Wire.write((uint8_t)((cfg & ~0x0100) >> 8));
        Wire.write((uint8_t)(cfg & 0xFF));
        Wire.endTransmission();
      }
      write8(addr, 0x08, 0x02);
      mcpReady = true;
      Serial.printf("[MCP9808] DFRobot-compatible found 0x%02X (device 0x%04X)\n", addr, dev);
      return;
    }
  }
  Serial.println("[MCP9808] NOT FOUND (DFRobot usually address 0x1F)");
}

void readTemp() {
  if (!mcpReady) return;
  uint16_t raw = 0;
  if (!read16(mcpAddr, 0x05, raw)) {
    temperatureC = NAN;
    return;
  }
  float t = (raw & 0x0FFF) / 16.0f;
  if (raw & 0x1000) t -= 256.0f;
  if (t >= -40.0f && t <= 125.0f) {
    temperatureC = t;
    lastTempOK = millis();
  } else {
    temperatureC = NAN;
  }
}

// ====================================================================
// FUNGSI MPU6050 & PEDOMETER 3-SUMBU (PENGHITUNG LANGKAH)
// ====================================================================
bool writeRegister(uint8_t reg, uint8_t value) {
  Wire.beginTransmission(mpuAddress);
  Wire.write(reg);
  Wire.write(value);
  return Wire.endTransmission() == 0;
}

bool readRegisters(uint8_t reg, uint8_t *buffer, uint8_t len) {
  Wire.beginTransmission(mpuAddress);
  Wire.write(reg);
  if (Wire.endTransmission(false) != 0) return false;

  uint8_t count = Wire.requestFrom(mpuAddress, len, (uint8_t)true);
  if (count != len) {
    while (Wire.available()) Wire.read();
    return false;
  }
  for (uint8_t i = 0; i < len; i++) {
    buffer[i] = Wire.read();
  }
  return true;
}

int16_t makeInt16(uint8_t highByte, uint8_t lowByte) {
  return (int16_t)(((uint16_t)highByte << 8) | lowByte);
}

void initMPU() {
  mpuAddress = 0;
  mpuReady = false;

  for (uint8_t addr = 0x68; addr <= 0x69; addr++) {
    Wire.beginTransmission(addr);
    if (Wire.endTransmission() == 0) {
      mpuAddress = addr;
      break;
    }
  }

  if (mpuAddress == 0) {
    Serial.println("[ERROR] MPU6050 tidak ditemukan!");
    return;
  }

  Serial.printf("[OK] MPU6050 ditemukan pada alamat 0x%02X\n", mpuAddress);

  uint8_t whoAmI = 0;
  if (!readRegisters(0x75, &whoAmI, 1)) {
    Serial.println("[ERROR] Gagal membaca WHO_AM_I.");
    return;
  }
  Serial.printf("WHO_AM_I = 0x%02X\n", whoAmI);

  if (!writeRegister(0x6B, 0x00)) {
    Serial.println("[ERROR] Gagal membangunkan sensor.");
    return;
  }
  delay(100);

  writeRegister(0x1A, 0x03); // DLPF ~44Hz
  writeRegister(0x1B, 0x00); // Gyro +/-250 dps
  writeRegister(0x1C, 0x10); // Accel +/-8g
  delay(100);

  mpuReady = true;
  Serial.println("[OK] Gyroscope, Accelerometer & Step Counter MPU6050 aktif!");
}

bool readMPU() {
  if (!mpuReady) return false;

  uint8_t rawData[14];
  if (!readRegisters(0x3B, rawData, sizeof(rawData))) return false;

  int16_t axRaw = makeInt16(rawData[0],  rawData[1]);
  int16_t ayRaw = makeInt16(rawData[2],  rawData[3]);
  int16_t azRaw = makeInt16(rawData[4],  rawData[5]);
  int16_t gxRaw = makeInt16(rawData[8],  rawData[9]);
  int16_t gyRaw = makeInt16(rawData[10], rawData[11]);
  int16_t gzRaw = makeInt16(rawData[12], rawData[13]);

  ax = axRaw / 4096.0f;
  ay = ayRaw / 4096.0f;
  az = azRaw / 4096.0f;

  gx = gxRaw / 131.0f;
  gy = gyRaw / 131.0f;
  gz = gzRaw / 131.0f;

  totalG = sqrtf(ax * ax + ay * ay + az * az);
  totalDps = sqrtf(gx * gx + gy * gy + gz * gz);

  if (!gravityInitialized) {
    gravityX = refX = ax;
    gravityY = refY = ay;
    gravityZ = refZ = az;
    stepBaselineG = totalG;
    gravityInitialized = true;
  } else {
    constexpr float k = 0.14f;
    gravityX += k * (ax - gravityX);
    gravityY += k * (ay - gravityY);
    gravityZ += k * (az - gravityZ);
  }
  lastMpuOK = millis();
  return true;
}

void resetSteps() {
  stepCount = 0;
  stepDistanceMeters = 0.0f;
  stepPeakArmed = false;
  currentStepPeakG = 0.0f;
  Serial.println("[STEP] Hitungan langkah di-reset ke 0.");
  sendSoon();
}

void registerOneStep(uint32_t now, float peakVal) {
  ++stepCount;
  stepDistanceMeters = stepCount * STRIDE_LENGTH_M;
  lastStepAt = now;
  stepPeakArmed = false;
  currentStepPeakG = 0.0f;

  Serial.printf("[STEP] Langkah ke-%lu terdeteksi! | Est. Jarak: %.2f m | Simpangan: %.2fg | Gyro: %.0fdps\n",
                (unsigned long)stepCount, stepDistanceMeters, peakVal, totalDps);
}

void updateStepCounter(uint32_t now) {
  if (!mpuReady || !gravityInitialized) return;

  if (fallState == FALL_COUNTDOWN || fallState == FALL_ALERT) {
    stepPeakArmed = false;
    return;
  }

  const float dx = ax - gravityX;
  const float dy = ay - gravityY;
  const float dz = az - gravityZ;
  const float linG = constrain(sqrtf(dx * dx + dy * dy + dz * dz), 0.0f, 1.5f);

  stepBaselineG += 0.04f * (totalG - stepBaselineG);
  const float signedDevG = totalG - stepBaselineG;
  const float absDevG = constrain(fabsf(signedDevG), 0.0f, 1.5f);

  const float swingBoost = (totalDps >= STEP_SWING_GYRO_DPS && totalDps <= 220.0f)
                           ? min(0.06f, (totalDps - STEP_SWING_GYRO_DPS) * 0.0012f)
                           : 0.0f;
  const float rawEnergy = max(linG, absDevG) + swingBoost;
  stepLinFiltered += 0.45f * (rawEnergy - stepLinFiltered);

  const float waveNow = signedDevG + 0.30f * (dx + dy + dz);
  const bool signCrossed = (waveNow * stepWavePrev < 0.0f);
  stepWavePrev = waveNow;

  if (stepLinFiltered < 0.028f && totalDps < 14.0f) {
    if (stepPeakArmed && (now - lastStepAt >= STEP_MIN_INTERVAL_MS)) {
      registerOneStep(now, currentStepPeakG);
    }
    stepPeakArmed = false;
    return;
  }

  const bool stepMotionValid = (stepLinFiltered >= STEP_TRIGGER_LIN_G) ||
                               (absDevG >= STEP_MIN_DEV_G && totalDps >= 15.0f) ||
                               (linG >= 0.040f && totalDps >= 22.0f);

  if (stepMotionValid) {
    if (!stepPeakArmed) {
      stepPeakArmed = true;
      stepPeakAt = now;
      currentStepPeakG = stepLinFiltered;
    } else if (stepLinFiltered > currentStepPeakG) {
      currentStepPeakG = stepLinFiltered;
    }
  }

  if (stepPeakArmed && (now - lastStepAt >= STEP_MIN_INTERVAL_MS)) {
    const bool valleyReached = (stepLinFiltered <= STEP_RELEASE_LIN_G) ||
                               (stepLinFiltered <= currentStepPeakG * 0.62f);
    const bool swingReversed = signCrossed && (now - stepPeakAt >= 120);
    const bool continuousWalk = (now - stepPeakAt >= 420) && stepMotionValid;

    if (valleyReached || swingReversed || continuousWalk) {
      registerOneStep(now, currentStepPeakG);
    }
  }
}

float postureDelta() {
  float a = sqrtf(gravityX * gravityX + gravityY * gravityY + gravityZ * gravityZ);
  float b = sqrtf(refX * refX + refY * refY + refZ * refZ);
  if (a < 0.05f || b < 0.05f) return 0;
  float cosine = (gravityX * refX + gravityY * refY + gravityZ * refZ) / (a * b);
  cosine = constrain(cosine, -1.0f, 1.0f);
  return acosf(cosine) * 180.0f / PI;
}

const char* fallText() {
  switch (fallState) {
    case FALL_LOW_G:       return "FREEFALL_CHECK";
    case FALL_POST_IMPACT: return "IMPACT_CHECK";
    case FALL_COUNTDOWN:   return "FALL_COUNTDOWN";
    case FALL_ALERT:       return "FALL_CONFIRMED";
    case FALL_COOLDOWN:    return "COOLDOWN";
    default:               return mpuReady ? "NORMAL" : "UNAVAILABLE";
  }
}

// ====================================================================
// HAPTIC MOTOR CONTROLLER (SOS, FALL, SAFE RADIUS, & UI TAP)
// ====================================================================
void motorWrite(bool on) {
  motorOn = on;
  digitalWrite(PIN_MOTOR, (on == MOTOR_ACTIVE_HIGH) ? HIGH : LOW);
}

void vibrate(HapticPattern requested) {
  if (requested == HAPTIC_NONE) return;
  if (hapticPattern != HAPTIC_NONE && requested < hapticPattern) return;
  if (hapticPattern == requested && hapticPattern != HAPTIC_NONE) return;

  hapticPattern = requested;
  pulseNumber = 0;
  motorStageAt = millis();
  motorWrite(true);
}

void updateHaptic(uint32_t now) {
  if (hapticPattern == HAPTIC_NONE) return;

  if (hapticPattern == HAPTIC_EMERGENCY) {
    constexpr uint32_t EMERGENCY_ON_MS  = 700;
    constexpr uint32_t EMERGENCY_OFF_MS = 350;
    if (motorOn && now - motorStageAt >= EMERGENCY_ON_MS) {
      motorWrite(false);
      motorStageAt = now;
    } else if (!motorOn && now - motorStageAt >= EMERGENCY_OFF_MS) {
      motorWrite(true);
      motorStageAt = now;
    }
    return;
  }

  if (hapticPattern == HAPTIC_SAFE_RADIUS) {
    constexpr uint32_t RAD_ON_MS    = 250;
    constexpr uint32_t RAD_OFF_MS   = 150;
    constexpr uint32_t RAD_PAUSE_MS = 1000;
    if (motorOn && now - motorStageAt >= RAD_ON_MS) {
      motorWrite(false);
      motorStageAt = now;
      ++pulseNumber;
    } else if (!motorOn) {
      uint32_t waitMs = (pulseNumber >= 3) ? RAD_PAUSE_MS : RAD_OFF_MS;
      if (now - motorStageAt >= waitMs) {
        if (pulseNumber >= 3) pulseNumber = 0;
        motorWrite(true);
        motorStageAt = now;
      }
    }
    return;
  }

  if (hapticPattern == HAPTIC_TAP) {
    if (motorOn && now - motorStageAt >= 35) {
      motorWrite(false);
      hapticPattern = HAPTIC_NONE;
    }
    return;
  }

  uint32_t onTime = 180;
  uint32_t offTime = 140;
  uint8_t nPulses = (hapticPattern == HAPTIC_CONFIRM) ? 1 : 2;
  if (motorOn && now - motorStageAt >= onTime) {
    motorWrite(false);
    motorStageAt = now;
    ++pulseNumber;
    if (pulseNumber >= nPulses) hapticPattern = HAPTIC_NONE;
  } else if (!motorOn && hapticPattern != HAPTIC_NONE && now - motorStageAt >= offTime) {
    motorWrite(true);
    motorStageAt = now;
  }
}

// ====================================================================
// ALARM, FALL DETECTION, & SAFE RADIUS EVALUATOR
// ====================================================================
void sendSoon() {
  requestBleNow = true;
}

void newAlarm(const char* reason) {
  if (aiListening) stopAiListening(false);
  ++alertEventSequence;
  activeEventId = alertEventSequence;
  alertSince = millis();
  Serial.printf("[ALERT] %s event=%lu -> Motor Emergency ON & BLE Notify\n",
                reason, (unsigned long)activeEventId);
  vibrate(HAPTIC_EMERGENCY);
  sendSoon();
}

void enterCooldown(uint32_t now) {
  fallState = FALL_COOLDOWN;
  cooldownAt = now;
  lowGAt = impactAt = stillAt = countdownAt = 0;
}

void cancelLocalAlarms() {
  const bool wasSosOrFall = sosActive || fallState == FALL_ALERT || fallState == FALL_COUNTDOWN;
  const bool wasRadius = radiusAlertActive;

  sosActive = false;
  if (fallState == FALL_ALERT || fallState == FALL_COUNTDOWN || fallState == FALL_POST_IMPACT) {
    enterCooldown(millis());
  }
  if (radiusAlertActive) {
    radiusAlertActive = false;
    appForcedRadiusAlert = false;
    radiusSnoozeUntil = millis() + RADIUS_SNOOZE_MS;
  }

  hapticPattern = HAPTIC_NONE;
  motorWrite(false);
  vibrate(HAPTIC_CONFIRM);

  if (wasSosOrFall || wasRadius) {
    Serial.println("[ALERT] Dibatalkan secara lokal oleh pengguna melalui Action Button.");
    sendSoon();
  }
}

void beginPostImpact(uint32_t now, bool lowG) {
  fallState = FALL_POST_IMPACT;
  impactAt = now;
  stillAt = 0;

  peakG = totalG;
  peakDps = totalDps;
  hadLowG = lowG;

  Serial.printf(
    "[FALL] IMPACT captured: %.2fg, gyro %.0fdps, lowG=%s\n",
    peakG,
    peakDps,
    hadLowG ? "YES" : "NO"
  );
}

void updateFall(uint32_t now) {
  now = millis();

  if (!mpuReady || !gravityInitialized || (now - lastMpuOK > 200)) {
    return;
  }

  if (fallState == FALL_ALERT) return;

  if (fallState == FALL_COOLDOWN) {
    if (now - cooldownAt >= FALL_COOLDOWN_MS) {
      fallState = FALL_MONITORING;
      Serial.println("[FALL] Monitoring aktif kembali.");
    }
    return;
  }

  if (fallState == FALL_COUNTDOWN) {
    vibrate(HAPTIC_EMERGENCY);

    if (now - countdownAt >= CANCEL_WINDOW_MS) {
      fallState = FALL_ALERT;
      newAlarm("FALL CONFIRMED - countdown selesai");
    }
    return;
  }

  if (fallState == FALL_MONITORING) {
    if (totalG > 0.90f && totalG < 1.10f && totalDps < 12.0f) {
      constexpr float adapt = 0.015f;
      refX += adapt * (gravityX - refX);
      refY += adapt * (gravityY - refY);
      refZ += adapt * (gravityZ - refZ);
    }

    if (totalG < FREEFALL_THRESHOLD_G) {
      fallState = FALL_LOW_G;
      lowGAt = now;
      peakG = 0;
      peakDps = 0;
      Serial.printf("[FALL] LOW-G: %.2fg\n", totalG);
    } else if (totalG >= IMPACT_THRESHOLD_G) {
      beginPostImpact(now, false);
    }

    return;
  }

  if (fallState == FALL_LOW_G) {
    if (totalG >= IMPACT_THRESHOLD_G &&
        now - lowGAt <= LOWG_TO_IMPACT_MS) {
      beginPostImpact(now, true);
    } else if (now - lowGAt > LOWG_TO_IMPACT_MS) {
      fallState = FALL_MONITORING;
      Serial.println("[FALL] Freefall tanpa benturan. Reset.");
    }
    return;
  }

  if (fallState == FALL_POST_IMPACT) {
    if (totalG > peakG) peakG = totalG;
    if (totalDps > peakDps) peakDps = totalDps;

    const float angle = postureDelta();
    const bool impactSeen       = peakG >= IMPACT_THRESHOLD_G;
    const bool freefallImpact   = hadLowG && impactSeen;
    const bool strongImpact     = peakG >= STRONG_IMPACT_G;
    const bool postureEvidence  = angle >= POSTURE_CHANGE_DEG;
    const bool rotationEvidence = peakDps >= IMPACT_ROTATION_DPS;

    const bool still =
      (totalG >= STILL_MIN_G &&
       totalG <= STILL_MAX_G &&
       totalDps < STILL_GYRO_DPS);

    if (still) {
      if (stillAt == 0) stillAt = now;
    } else {
      stillAt = 0;
    }

    const bool stillConfirmed =
      (stillAt != 0 && now - stillAt >= STILL_REQUIRED_MS);

    const bool freefallConfirmed   = freefallImpact && stillConfirmed;
    const bool postureConfirmed    = impactSeen && postureEvidence && stillConfirmed;
    const bool strongFallConfirmed = strongImpact && rotationEvidence && stillConfirmed;

    if (freefallConfirmed || postureConfirmed || strongFallConfirmed) {
      if (aiListening) stopAiListening(false);
      fallState = FALL_COUNTDOWN;
      countdownAt = now;

      Serial.println();
      Serial.println("================================");
      Serial.println("[FALL] JATUH TERDETEKSI!");
      Serial.printf("Peak G       : %.2fg\n", peakG);
      Serial.printf("Peak Gyro    : %.0f dps\n", peakDps);
      Serial.printf("Posture      : %.1f derajat\n", angle);
      Serial.printf("Freefall     : %s\n", hadLowG ? "YES" : "NO");
      Serial.printf("Still        : %s\n", stillConfirmed ? "YES" : "NO");
      Serial.println("STATUS       : COUNTDOWN AKTIF");
      Serial.println("VIBRATOR     : EMERGENCY ON");
      Serial.println("================================");

      vibrate(HAPTIC_EMERGENCY);
      sendSoon();
      return;
    }

    if (now - impactAt >= AFTER_IMPACT_MS) {
      Serial.println("[FALL] Tidak memenuhi seluruh kriteria jatuh.");
      Serial.printf("Peak G: %.2fg | Peak Gyro: %.0fdps | Tilt: %.1f deg\n",
                    peakG, peakDps, angle);

      fallState = FALL_MONITORING;
      stillAt = 0;
      hadLowG = false;
    }
  }
}

// ====================================================================
// ACTION BUTTON (1x Klik = Page/Stop, 2x Klik = AI Mic, Tahan 3s = SOS)
// ====================================================================
void updateButton(uint32_t now) {
  bool raw = digitalRead(PIN_ACTION);
  if (raw != buttonRawLast) buttonDebounceAt = now;

  if (now - buttonDebounceAt >= BUTTON_DEBOUNCE_MS && raw != buttonStable) {
    buttonStable = raw;
    if (raw == LOW) {
      buttonDownAt = now;
      buttonLongHandled = false;
    } else {
      if (!buttonLongHandled) {
        uint32_t held = now - buttonDownAt;
        if (held >= 45) {
          const bool anyAlarmActive = sosActive ||
                                      fallState == FALL_ALERT ||
                                      fallState == FALL_COUNTDOWN ||
                                      radiusAlertActive;
          if (anyAlarmActive) {
            pendingSingleClick = false;
            cancelLocalAlarms();
          } else if (aiListening) {
            // Jika sedang merekam suara AI, klik 1x langsung menyelesaikan rekaman
            pendingSingleClick = false;
            stopAiListening(true);
          } else if (pendingSingleClick && (now - lastClickReleaseAt <= DOUBLE_CLICK_MS)) {
            // Klik ke-2 terdeteksi dalam jendela DOUBLE_CLICK_MS -> Aktifkan Rekam Suara AI
            pendingSingleClick = false;
            startAiListening();
          } else {
            // Tunggu sebentar untuk memastikan apakah ada klik ke-2
            pendingSingleClick = true;
            lastClickReleaseAt = now;
            vibrate(HAPTIC_TAP);
          }
        }
      }
    }
  }

  // Eksekusi Klik 1x (pindah halaman OLED) setelah lewat waktu tunggu Double-Click
  if (pendingSingleClick && buttonStable == HIGH && (now - lastClickReleaseAt > DOUBLE_CLICK_MS)) {
    pendingSingleClick = false;
    bootFinished = true;
    currentPage = (currentPage + 1) % TOTAL_PAGES;
    lastPageAt = now;
    Serial.printf("[ACTION BUTTON] Pindah ke halaman OLED %u\n", (unsigned)currentPage);
  }

  // Deteksi Tahan 3 Detik untuk Manual SOS
  if (buttonStable == LOW && !buttonLongHandled) {
    if (now - buttonDownAt >= SOS_HOLD_MS) {
      buttonLongHandled = true;
      pendingSingleClick = false;
      bootFinished = true;
      if (!sosActive) {
        sosActive = true;
        newAlarm("MANUAL SOS (Tahan 3 Detik)");
      } else {
        cancelLocalAlarms();
      }
    }
  }

  buttonRawLast = raw;
}

// ====================================================================
// SERIAL TEST COMMANDS
// ====================================================================
void handleSerialTestCommands() {
  while (Serial.available() > 0) {
    const char command = (char)Serial.read();
    if (command == 'v' || command == 'V') {
      hapticPattern = HAPTIC_NONE;
      motorWrite(false);
      vibrate(HAPTIC_WARNING);
      Serial.println("[TEST] Getar WARNING 2 pulsa.");
    } else if (command == 'e' || command == 'E') {
      hapticPattern = HAPTIC_NONE;
      motorWrite(false);
      vibrate(HAPTIC_EMERGENCY);
      Serial.println("[TEST] Getar EMERGENCY berulang. Kirim X untuk berhenti.");
    } else if (command == 'r' || command == 'R') {
      appForcedRadiusAlert = !appForcedRadiusAlert;
      radiusSnoozeUntil = 0;
      Serial.printf("[TEST] Simulasi Safe Radius Alert: %s\n", appForcedRadiusAlert ? "ON" : "OFF");
    } else if (command == 'x' || command == 'X') {
      if (aiListening) stopAiListening(false);
      cancelLocalAlarms();
      Serial.println("[TEST] Semua alarm & motor dihentikan.");
    } else if (command == 'f' || command == 'F') {
      fallState = FALL_COUNTDOWN;
      countdownAt = millis();
      vibrate(HAPTIC_EMERGENCY);
      sendSoon();
      Serial.println("[TEST] Simulasi jatuh aktif (getar darurat langsung menyala).");
    } else if (command == 's' || command == 'S') {
      ++stepCount;
      stepDistanceMeters = stepCount * STRIDE_LENGTH_M;
      sendSoon();
      Serial.printf("[TEST STEP] Simulasi +1 langkah | Total: %lu langkah (%.2f m)\n",
                    (unsigned long)stepCount, stepDistanceMeters);
    } else if (command == '0') {
      resetSteps();
    } else if (command == 'm' || command == 'M') {
      if (aiListening) stopAiListening(true);
      else startAiListening();
    }
  }
}

// ====================================================================
// GPS ATGM336H
// ====================================================================
void updateGPS() {
  while (GPSport.available() > 0) {
    char c = (char)GPSport.read();
    gps.encode(c);
    ++gpsBytes;

    if (c == '\n') {
      if (gpsNmeaLength > 0) {
        gpsNmeaLine[gpsNmeaLength] = '\0';
        if (DEBUG_RAW_NMEA) {
          Serial.print("[NMEA] ");
          Serial.println(gpsNmeaLine);
        }
      }
      gpsNmeaLength = 0;
    } else if (c != '\r') {
      if (gpsNmeaLength < sizeof(gpsNmeaLine) - 1) {
        gpsNmeaLine[gpsNmeaLength++] = c;
      } else {
        gpsNmeaLength = 0;
      }
    }
  }

  gpsFix = gps.location.isValid() && gps.location.age() < 5000;
  gpsSatellites = (gps.satellites.isValid() && gps.satellites.age() < 5000)
                  ? (uint8_t)min((uint32_t)255, gps.satellites.value()) : 0;

  TinyGPSCustom *q = nullptr, *sat = nullptr, *h = nullptr;
  if (gnFixQuality.isUpdated() && gnFixQuality.isValid()) {
    q = &gnFixQuality; sat = &gnSatsUsed; h = &gnHdop;
  } else if (gpFixQuality.isUpdated() && gpFixQuality.isValid()) {
    q = &gpFixQuality; sat = &gpSatsUsed; h = &gpHdop;
  }
  if (q) {
    gpsQuality = atoi(q->value());
    if (sat->isValid()) gpsUsed = atoi(sat->value());
    if (h->isValid()) gpsHdop = atof(h->value());
    gpsQualityUpdatedAt = millis();
  }

  if (gpsQualityUpdatedAt && millis() - gpsQualityUpdatedAt > 7000) {
    gpsQuality = -1;
    gpsUsed = -1;
    gpsHdop = NAN;
  }
  if (gpsQuality == 0) gpsFix = false;
}

// ====================================================================
// MAX30102 HEART RATE (DENGAN DEBOUNCE KONTAK & FILTER STABIL)
// ====================================================================
void clearBpm() {
  bpm = 0;
  lastBeatAt = 0;
  bpmSampleCount = 0;
  bpmIndex = 0;
  memset(bpmSamples, 0, sizeof(bpmSamples));
}

void updateHeartRate() {
  if (!maxReady) return;
  pulse.check();
  uint32_t now = millis();
  int consumed = 0;

  while (pulse.available() && consumed++ < 16) {
    long ir = pulse.getFIFOIR();
    irRaw = ir;
    lastOpticalAt = now;

    bool rawTouch = opticalContact ? (ir > IR_CONTACT_OFF_THRESHOLD) : (ir > IR_CONTACT_ON_THRESHOLD);
    if (rawTouch) {
      opticalContact = true;
      contactLostAt = 0;
    } else if (opticalContact) {
      if (contactLostAt == 0) contactLostAt = now;
      if (now - contactLostAt >= CONTACT_LOST_GRACE_MS) {
        opticalContact = false;
        contactLostAt = 0;
        clearBpm();
      }
    }

    if (opticalContact && checkForBeat(ir)) {
      if (lastBeatAt > 0) {
        uint32_t delta = now - lastBeatAt;
        if (delta >= 342 && delta <= 1428) {
          int nextBpm = (int)(60000.0f / delta);

          if (bpm > 0 && abs(nextBpm - bpm) > (bpm * 30 / 100)) {
            nextBpm = (bpm * 3 + nextBpm) / 4;
          }

          bpmSamples[bpmIndex] = (byte)constrain(nextBpm, 42, 175);
          bpmIndex = (bpmIndex + 1) % 8;
          if (bpmSampleCount < 8) ++bpmSampleCount;

          int total = 0;
          for (uint8_t i = 0; i < bpmSampleCount; ++i) total += bpmSamples[i];
          bpm = total / bpmSampleCount;
        }
      }
      lastBeatAt = now;
    }

    pulse.nextSample();
  }

  if (opticalContact && lastBeatAt && (now - lastBeatAt > BEAT_HOLD_TIMEOUT_MS)) {
    clearBpm();
  }
  if (lastOpticalAt && (now - lastOpticalAt > 3000)) {
    opticalContact = false;
    clearBpm();
  }
}

// ====================================================================
// BLE SERVER & DYNAMIC SAFE RADIUS + AI COMMAND PARSER
// ====================================================================
bool extractJsonNumber(const String &src, const char *key, float &outVal) {
  int idx = src.indexOf(key);
  if (idx < 0) return false;
  int colon = src.indexOf(':', idx);
  if (colon < 0) return false;
  int start = colon + 1;
  while (start < (int)src.length() && (src[start] == ' ' || src[start] == '\"')) start++;
  if (start >= (int)src.length()) return false;
  outVal = src.substring(start).toFloat();
  return true;
}

bool extractJsonString(const String &src, const char *key, String &outStr) {
  int idx = src.indexOf(key);
  if (idx < 0) return false;
  int colon = src.indexOf(':', idx);
  if (colon < 0) return false;
  int firstQuote = src.indexOf('\"', colon + 1);
  if (firstQuote < 0) return false;
  int secondQuote = src.indexOf('\"', firstQuote + 1);
  if (secondQuote < 0) return false;
  outStr = src.substring(firstQuote + 1, secondQuote);
  return true;
}

void showAiReplyOnOled(const String &replyText) {
  aiListening = false;
  aiState = AI_REPLY_SHOWN;
  aiStateChangedAt = millis();
  strncpy(aiDisplayText, replyText.c_str(), sizeof(aiDisplayText) - 1);
  aiDisplayText[sizeof(aiDisplayText) - 1] = '\0';
  currentPage = PAGE_AI;
  bootFinished = true;
  lastPageAt = millis();
  vibrate(HAPTIC_CONFIRM);
  Serial.printf("[AI REPLY] Ditampilkan di OLED: %s\n", aiDisplayText);
}

void parseIncomingBleCommand(const String &cmd) {
  Serial.printf("[BLE RX] Received: %s\n", cmd.c_str());

  if (cmd == "PING") {
    requestBleNow = true;
    return;
  }

  if (cmd == "CANCEL" || cmd == "ALARM:OFF") {
    cancelLocalAlarms();
    return;
  }

  if (cmd == "RESET_STEPS" || cmd == "STEPS:0") {
    resetSteps();
    return;
  }

  // Perintah kontrol perekaman mikrofon AI dari aplikasi Flutter
  if (cmd == "AI_LISTEN:1" || cmd == "AI_START") {
    startAiListening();
    return;
  }
  if (cmd == "AI_LISTEN:0" || cmd == "AI_STOP") {
    stopAiListening(true);
    return;
  }

  // Perintah menampilkan teks ringkasan jawaban AI di layar OLED
  if (cmd.startsWith("AI:") || cmd.startsWith("AI_TEXT:")) {
    int colon = cmd.indexOf(':');
    String reply = cmd.substring(colon + 1);
    reply.trim();
    if (reply.length() > 0) {
      showAiReplyOnOled(reply);
    }
    return;
  }

  if (cmd.startsWith("PAGE:")) {
    int requested = cmd.substring(5).toInt();
    if (requested >= 0 && requested < TOTAL_PAGES) {
      currentPage = (uint8_t)requested;
      lastPageAt = millis();
      bootFinished = true;
    }
    return;
  }

  if (cmd.startsWith("RADIUS:") || cmd.startsWith("SAFE_RADIUS:")) {
    int colon = cmd.indexOf(':');
    float r = cmd.substring(colon + 1).toFloat();
    if (r >= 1.0f && r <= 5000.0f) {
      safeRadiusMeters = r;
      safeRadiusEnabled = true;
      vibrate(HAPTIC_TAP);
      requestBleNow = true;
      Serial.printf("[SAFE RADIUS] Batas radius diperbarui via BLE: %.1f meter\n", safeRadiusMeters);
    } else if (r <= 0.0f) {
      safeRadiusEnabled = false;
      radiusAlertActive = false;
      appForcedRadiusAlert = false;
      requestBleNow = true;
      Serial.println("[SAFE RADIUS] Fitur safe radius dinonaktifkan oleh aplikasi.");
    }
    return;
  }

  if (cmd.startsWith("RADIUS_ALERT:") || cmd.startsWith("OUT_OF_RANGE:")) {
    int colon = cmd.indexOf(':');
    String val = cmd.substring(colon + 1);
    val.toUpperCase();
    bool active = (val == "1" || val == "TRUE" || val == "ON");
    appForcedRadiusAlert = active;
    if (active) radiusSnoozeUntil = 0;
    requestBleNow = true;
    return;
  }

  if (cmd.startsWith("DIST:")) {
    String payload = cmd.substring(5);
    int comma = payload.indexOf(',');
    if (comma > 0) {
      currentDistanceM = payload.substring(0, comma).toFloat();
      float newRad = payload.substring(comma + 1).toFloat();
      if (newRad >= 1.0f) safeRadiusMeters = newRad;
    } else {
      currentDistanceM = payload.toFloat();
    }
    requestBleNow = true;
    return;
  }

  if (cmd.startsWith("COMP:") || cmd.startsWith("COMPANION:")) {
    int colon = cmd.indexOf(':');
    String payload = cmd.substring(colon + 1);
    int c1 = payload.indexOf(',');
    int c2 = payload.indexOf(',', c1 + 1);
    if (c1 > 0) {
      companionLat = payload.substring(0, c1).toDouble();
      if (c2 > c1) {
        companionLon = payload.substring(c1 + 1, c2).toDouble();
        float newRad = payload.substring(c2 + 1).toFloat();
        if (newRad >= 1.0f) safeRadiusMeters = newRad;
      } else {
        companionLon = payload.substring(c1 + 1).toDouble();
      }
      companionUpdatedAt = millis();
      requestBleNow = true;
    }
    return;
  }

  if (cmd.startsWith("{")) {
    float val = 0;
    if (extractJsonNumber(cmd, "safeRadius", val) || extractJsonNumber(cmd, "radius", val)) {
      if (val >= 1.0f && val <= 5000.0f) {
        safeRadiusMeters = val;
        safeRadiusEnabled = true;
        vibrate(HAPTIC_TAP);
      }
    }
    if (extractJsonNumber(cmd, "distance", val) || extractJsonNumber(cmd, "distanceM", val)) {
      if (val >= 0.0f) currentDistanceM = val;
    }
    double cLat = 0, cLon = 0;
    float fLat = 0, fLon = 0;
    if (extractJsonNumber(cmd, "companionLat", fLat) && extractJsonNumber(cmd, "companionLon", fLon)) {
      cLat = fLat; cLon = fLon;
      if (cLat != 0.0 || cLon != 0.0) {
        companionLat = cLat;
        companionLon = cLon;
        companionUpdatedAt = millis();
      }
    }
    String aiText;
    if (extractJsonString(cmd, "aiReply", aiText) || extractJsonString(cmd, "aiText", aiText)) {
      if (aiText.length() > 0) showAiReplyOnOled(aiText);
    }
    if (cmd.indexOf("\"radiusAlert\":true") >= 0 || cmd.indexOf("\"outOfRange\":true") >= 0) {
      appForcedRadiusAlert = true;
      radiusSnoozeUntil = 0;
    } else if (cmd.indexOf("\"radiusAlert\":false") >= 0 || cmd.indexOf("\"outOfRange\":false") >= 0) {
      appForcedRadiusAlert = false;
    }
    if (cmd.indexOf("\"resetSteps\":true") >= 0) {
      resetSteps();
    }
    requestBleNow = true;
  }
}

class HajiCareCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *s) override {
    (void)s;
    bleConnected = true;
    bleRestart = false;
    negotiatedMTU = 23;
    pendingJsonLen = 0;
    requestBleNow = true;
    Serial.println("[BLE] connected; app must request MTU 247 + subscribe TX & AUDIO notifications");
  }
  void onDisconnect(BLEServer *s) override {
    (void)s;
    bleConnected = false;
    bleRestart = true;
    bleDisconnectedAt = millis();
    pendingJsonLen = 0;
    negotiatedMTU = 23;
    if (aiListening) stopAiListening(false);
    Serial.println("[BLE] disconnected; restarting advertising shortly");
  }
#if defined(CONFIG_BLUEDROID_ENABLED)
  void onMtuChanged(BLEServer *s, esp_ble_gatts_cb_param_t *event) override {
    (void)s;
    negotiatedMTU = event->mtu.mtu;
    pendingJsonLen = 0;
    requestBleNow = true;
    Serial.printf("[BLE] negotiated ATT MTU=%u\n", (unsigned)negotiatedMTU);
  }
#endif
};

class HajiCareRxCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *c) override {
    String incoming = c->getValue();
    incoming.trim();
    if (incoming.length() > 0) {
      parseIncomingBleCommand(incoming);
    }
  }
};

void initBLE() {
  BLEDevice::init(DEVICE_NAME);
  BLEDevice::setMTU(BLE_LOCAL_MTU);
  bleServer = BLEDevice::createServer();
  bleServer->setCallbacks(new HajiCareCallbacks());
  BLEService *svc = bleServer->createService(BLE_SERVICE_UUID);

  txCharacteristic = svc->createCharacteristic(
    BLE_TX_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
  );
  txCharacteristic->addDescriptor(new BLE2902());
  txCharacteristic->setValue("{\"status\":\"ready\"}");

  rxCharacteristic = svc->createCharacteristic(
    BLE_RX_UUID,
    BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR
  );
  rxCharacteristic->setCallbacks(new HajiCareRxCallbacks());

  // Karakteristik khusus stream audio PCM 16-bit dari INMP441 ke Flutter
  audioCharacteristic = svc->createCharacteristic(
    BLE_AUDIO_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
  );
  audioCharacteristic->addDescriptor(new BLE2902());

  svc->start();

  BLEAdvertising *adv = BLEDevice::getAdvertising();
  adv->addServiceUUID(BLE_SERVICE_UUID);
  adv->setScanResponse(true);
  BLEDevice::startAdvertising();
  Serial.println("[BLE] advertising " DEVICE_NAME);
}

void sendNextFragment(uint32_t now) {
  if (!pendingJsonLen || !bleConnected || !txCharacteristic) return;
  if (now - lastFragmentAt < BLE_FRAGMENT_SPACING_MS) return;

  uint16_t offset = (uint16_t)pendingIndex * pendingDataBytes;
  if (offset >= pendingJsonLen || pendingIndex >= pendingTotal) {
    pendingJsonLen = 0;
    return;
  }

  size_t remaining = pendingJsonLen - offset;
  uint8_t take = (uint8_t)min((size_t)pendingDataBytes, remaining);
  char fragment[252];
  int hdr = snprintf(fragment, sizeof(fragment), "~%02X%02X%02X:",
                     pendingSeq, pendingIndex, pendingTotal);
  if (hdr != 8 || (size_t)hdr + take > sizeof(fragment)) {
    pendingJsonLen = 0;
    return;
  }

  memcpy(fragment + hdr, pendingJson + offset, take);
  txCharacteristic->setValue((const uint8_t*)fragment, hdr + take);
  txCharacteristic->notify();
  lastFragmentAt = now;
  ++pendingIndex;
  if (pendingIndex >= pendingTotal) pendingJsonLen = 0;
}

void sendBLE(uint32_t now) {
  if (!bleConnected || !txCharacteristic) return;
  // Tahan pengiriman JSON telemetri rutin selama 5 detik saat jamaah sedang merekam suara AI
  // agar bandwidth BLE 100% fokus untuk pengiriman paket suara INMP441 tanpa putus-putus
  if (aiListening) return;

  const bool urgent = sosActive || fallState == FALL_ALERT || fallState == FALL_COUNTDOWN || radiusAlertActive;
  const uint32_t interval = urgent ? BLE_ALARM_PERIOD : BLE_PERIOD;

  if (pendingJsonLen && requestBleNow) pendingJsonLen = 0;
  if (pendingJsonLen) {
    sendNextFragment(now);
    return;
  }
  if (!requestBleNow && now - lastBleAt < interval) return;
  requestBleNow = false;
  lastBleAt = now;

  char lat[24], lon[24], temp[18], motion[18], dist[18];
  if (gpsFix) {
    snprintf(lat, sizeof(lat), "%.6f", gps.location.lat());
    snprintf(lon, sizeof(lon), "%.6f", gps.location.lng());
  } else {
    strcpy(lat, "null");
    strcpy(lon, "null");
  }

  if (mcpReady && !isnan(temperatureC) && now - lastTempOK <= 5000)
    snprintf(temp, sizeof(temp), "%.2f", temperatureC);
  else
    strcpy(temp, "null");

  if (mpuReady && !isnan(totalG) && totalG > 0)
    snprintf(motion, sizeof(motion), "%.2f", totalG);
  else
    strcpy(motion, "null");

  if (!isnan(currentDistanceM))
    snprintf(dist, sizeof(dist), "%.1f", currentDistanceM);
  else
    strcpy(dist, "null");

  char json[512];
  int n = snprintf(json, sizeof(json),
    "{\"braceletId\":\"%s\",\"heartRate\":%d,\"spo2\":null,\"fingerDetected\":%s,"
    "\"temperatureC\":%s,\"motionG\":%s,\"steps\":%lu,\"stepDistanceM\":%.1f,"
    "\"gpsFix\":%s,\"satellites\":%u,\"latitude\":%s,\"longitude\":%s,"
    "\"fallStatus\":\"%s\",\"sos\":%s,\"safeRadius\":%.0f,\"distanceM\":%s,"
    "\"radiusAlert\":%s,\"aiListening\":%s}",
    BRACELET_ID, (opticalContact ? bpm : 0), opticalContact ? "true" : "false",
    temp, motion, (unsigned long)stepCount, stepDistanceMeters,
    gpsFix ? "true" : "false", (unsigned)gpsSatellites,
    lat, lon, fallText(), sosActive ? "true" : "false",
    safeRadiusMeters, dist, radiusAlertActive ? "true" : "false",
    aiListening ? "true" : "false"
  );

  if (n <= 0 || n >= (int)sizeof(json)) {
    Serial.println("[BLE] JSON overflow: not sent");
    return;
  }

  const uint16_t actualMtu = negotiatedMTU >= 23 ? negotiatedMTU : 23;
  const size_t capacity = min((size_t)(actualMtu - 3), (size_t)(BLE_LOCAL_MTU - 3));
  if ((size_t)n <= capacity) {
    txCharacteristic->setValue((const uint8_t*)json, n);
    txCharacteristic->notify();
  } else {
    if (capacity <= 8) return;
    memcpy(pendingJson, json, n + 1);
    pendingJsonLen = n;
    pendingDataBytes = (uint8_t)(capacity - 8);
    pendingTotal = (uint8_t)((n + pendingDataBytes - 1) / pendingDataBytes);
    pendingIndex = 0;
    ++pendingSeq;
    lastFragmentAt = now - BLE_FRAGMENT_SPACING_MS;
    sendNextFragment(now);
  }
}

// ====================================================================
// UI OLED 128x64 (7 HALAMAN + AI VOICE + HOLD SOS BAR + ALARM SCREEN)
// ====================================================================
void label(int x, int y, const char* value, uint8_t size = 1) {
  screen.setTextColor(SSD1306_WHITE);
  screen.setTextSize(size);
  screen.setCursor(x, y);
  screen.print(value);
}

void heartGlyph(int16_t cx, int16_t cy, bool full) {
  screen.drawCircle(cx - 4, cy - 3, 4, SSD1306_WHITE);
  screen.drawCircle(cx + 4, cy - 3, 4, SSD1306_WHITE);
  screen.drawLine(cx - 8, cy - 1, cx, cy + 8, SSD1306_WHITE);
  screen.drawLine(cx + 8, cy - 1, cx, cy + 8, SSD1306_WHITE);
  if (full) screen.fillCircle(cx, cy, 2, SSD1306_WHITE);
}

void header() {
  label(2, 2, "HAJICARE");
  screen.drawFastHLine(0, 11, 128, SSD1306_WHITE);
  label(83, 2, bleConnected ? "BLE ON" : "BLE --");
}

void footer(uint8_t page) {
  screen.drawFastHLine(0, 54, 128, SSD1306_WHITE);
  for (uint8_t i = 0; i < TOTAL_PAGES; ++i) {
    int x = 40 + i * 8;
    if (page == i) screen.fillCircle(x, 60, 2, SSD1306_WHITE);
    else screen.drawCircle(x, 60, 2, SSD1306_WHITE);
  }
}

void drawPulseLine(uint32_t now) {
  int mid = 47;
  screen.drawFastHLine(2, mid, 124, SSD1306_WHITE);
  int c = (now / 38) % 145;
  if (c >= 12 && c < 115) {
    screen.drawLine(c - 10, mid, c - 6, mid - 2, SSD1306_WHITE);
    screen.drawLine(c - 6, mid - 2, c - 3, mid + 1, SSD1306_WHITE);
    screen.drawLine(c - 3, mid + 1, c, mid - 10, SSD1306_WHITE);
    screen.drawLine(c, mid - 10, c + 4, mid + 4, SSD1306_WHITE);
    screen.drawLine(c + 4, mid + 4, c + 8, mid, SSD1306_WHITE);
  }
}

void drawHR(uint32_t now) {
  header();
  label(4, 14, opticalContact ? "DETAK JANTUNG" : "TEMPELKAN KULIT");
  char num[12];
  if (bpm > 0 && opticalContact) snprintf(num, sizeof(num), "%d", bpm);
  else strcpy(num, "--");
  label(4, 25, num, 2);
  label(53, 30, "BPM");
  heartGlyph(110, 29, (now / 450) % 2 == 0 && opticalContact);
  drawPulseLine(now);
  footer(0);
}

void drawGPS(uint32_t now) {
  (void)now;

  label(2, 2, "GPS ATGM336H");
  screen.drawFastHLine(0, 11, 128, SSD1306_WHITE);

  char txt[32];

  snprintf(txt, sizeof(txt), "BYTE:%lu", (unsigned long)gpsBytes);
  label(2, 14, txt);

  snprintf(txt, sizeof(txt), "SAT:%u %s",
           (unsigned)gpsSatellites, gpsFix ? "[LOCKED]" : "[SEARCH]");
  label(2, 23, txt);

  if (gpsFix) {
    snprintf(txt, sizeof(txt), "LAT: %.6f", gps.location.lat());
    label(2, 32, txt);
    snprintf(txt, sizeof(txt), "LON: %.6f", gps.location.lng());
    label(2, 41, txt);
  } else {
    label(2, 32, "LAT: --");
    label(2, 41, "LON: --");
  }

  footer(1);
}

void drawTempPage() {
  header();
  label(3, 15, "SUHU SENSOR");
  char line[26];
  if (mcpReady && !isnan(temperatureC)) snprintf(line, sizeof(line), "%.1f C", temperatureC);
  else strcpy(line, "--.- C");
  label(3, 27, line, 2);
  label(3, 45, "Klik 2x: Bicara ke AI");
  footer(2);
}

void drawMotion() {
  header();
  label(3, 14, "MONITOR JATUH");
  char val[24];
  if (mpuReady) snprintf(val, sizeof(val), "%.2f g", totalG);
  else strcpy(val, "SENSOR ERR");
  label(3, 24, val, 2);

  char info[28];
  snprintf(info, sizeof(info), "%s | %lu Lkh",
           mpuReady ? fallText() : "MPU ERR", (unsigned long)stepCount);
  label(3, 44, info, 1);
  footer(3);
}

void drawStepsPage() {
  header();
  label(3, 14, "LANGKAH JALAN");

  char num[20];
  snprintf(num, sizeof(num), "%lu", (unsigned long)stepCount);
  label(3, 25, num, 2);

  char distTxt[28];
  if (stepDistanceMeters >= 1000.0f) {
    snprintf(distTxt, sizeof(distTxt), "Jarak: %.2f km", stepDistanceMeters / 1000.0f);
  } else {
    snprintf(distTxt, sizeof(distTxt), "Jarak: %.1f meter", stepDistanceMeters);
  }
  label(3, 44, distTxt, 1);
  footer(4);
}

void drawSafeRadiusPage() {
  header();
  label(3, 14, "SAFE RADIUS");
  char buf[28];
  snprintf(buf, sizeof(buf), "Batas : %.0f m", safeRadiusMeters);
  label(3, 25, buf);

  if (!isnan(currentDistanceM)) {
    snprintf(buf, sizeof(buf), "Jarak : %.1f m", currentDistanceM);
  } else if (stepDistanceMeters > 0.0f) {
    snprintf(buf, sizeof(buf), "Jarak : %.1f m*", stepDistanceMeters);
  } else {
    snprintf(buf, sizeof(buf), "Jarak : %s", bleConnected ? "Aman (App)" : "Menunggu BLE");
  }
  label(3, 35, buf);
  label(3, 45, radiusAlertActive ? "STATUS: DI LUAR!" : "STATUS: AMAN");
  footer(5);
}

void drawAiPage(uint32_t now) {
  if (aiListening) {
    uint32_t elapsed = now - aiListenStartAt;
    uint32_t remainSec = (AI_MAX_LISTEN_MS > elapsed) ? ((AI_MAX_LISTEN_MS - elapsed + 999) / 1000) : 0;
    char topTitle[24];
    snprintf(topTitle, sizeof(topTitle), "MENDENGARKAN.. %lus", (unsigned long)remainSec);
    label(2, 2, topTitle);
    screen.drawFastHLine(0, 11, 128, SSD1306_WHITE);

    label(3, 15, "Bicara di dekat gelang");

    // Visual bar kekuatan suara mikrofon INMP441 secara real-time
    screen.drawRect(3, 27, 122, 11, SSD1306_WHITE);
    int barW = (aiMicLevel * 118) / 100;
    barW = constrain(barW, 2, 118);
    screen.fillRect(5, 29, barW, 7, SSD1306_WHITE);

    label(3, 42, "Klik 1x: Kirim ke AI");
  } else {
    label(2, 2, "HAJICARE AI");
    screen.drawFastHLine(0, 11, 128, SSD1306_WHITE);
    label(83, 2, micReady ? "MIC OK" : "NO MIC");

    // Aktifkan word-wrap sementara agar balasan teks AI otomatis turun ke baris berikutnya
    screen.setTextWrap(true);
    screen.setTextSize(1);
    screen.setTextColor(SSD1306_WHITE);
    screen.setCursor(2, 14);
    screen.print(aiDisplayText);
    screen.setTextWrap(false);
  }
  footer(PAGE_AI);
}

void drawSosHoldProgress(uint32_t heldMs) {
  screen.drawRect(0, 0, 128, 64, SSD1306_WHITE);
  label(16, 8, "TAHAN UNTUK SOS", 1);
  uint32_t remainSec = (SOS_HOLD_MS - heldMs + 999) / 1000;
  char sub[24];
  snprintf(sub, sizeof(sub), "Aktif dalam %lu dtk...", (unsigned long)remainSec);
  label(14, 22, sub, 1);

  screen.drawRect(10, 38, 108, 14, SSD1306_WHITE);
  int fillW = (int)((heldMs * 104UL) / SOS_HOLD_MS);
  fillW = constrain(fillW, 0, 104);
  screen.fillRect(12, 40, fillW, 10, SSD1306_WHITE);
}

void drawWarning(uint32_t now) {
  bool light = (now / 400) % 2 == 0;
  if (light) {
    screen.fillRect(0, 0, 128, 64, SSD1306_WHITE);
    screen.setTextColor(SSD1306_BLACK);
  } else {
    screen.drawRect(0, 0, 128, 64, SSD1306_WHITE);
    screen.setTextColor(SSD1306_WHITE);
  }

  screen.setTextSize(1);
  screen.setCursor(34, 6);
  screen.print("HAJICARE");

  if (sosActive) {
    screen.setTextSize(2);
    screen.setCursor(43, 20);
    screen.print("SOS!");
    screen.setTextSize(1);
    screen.setCursor(11, 42);
    screen.print("SINYAL DARURAT AKTIF");
    screen.setCursor(8, 53);
    screen.print("Klik 1x: Matikan SOS");
  } else if (fallState == FALL_COUNTDOWN || fallState == FALL_ALERT) {
    screen.setTextSize(2);
    screen.setCursor(10, 20);
    screen.print("TERJATUH!");
    screen.setTextSize(1);
    if (fallState == FALL_COUNTDOWN) {
      uint32_t secs = (CANCEL_WINDOW_MS - (now - countdownAt) + 999) / 1000;
      if (secs > 10) secs = 10;
      screen.setCursor(14, 42);
      screen.printf("KIRIM DARURAT: %lus", (unsigned long)secs);
    } else {
      screen.setCursor(10, 42);
      screen.print("ALARM JATUH TERKIRIM");
    }
    screen.setCursor(8, 53);
    screen.print("Klik 1x: Batal Alarm");
  } else if (radiusAlertActive) {
    screen.setTextSize(1);
    screen.setCursor(12, 18);
    screen.print("PERINGATAN JARAK!");
    screen.setTextSize(2);
    screen.setCursor(16, 29);
    screen.print("MENJAUH");
    screen.setTextSize(1);
    screen.setCursor(8, 51);
    screen.print("Klik 1x: Senyapkan");
  }

  screen.setTextColor(SSD1306_WHITE);
}

void drawOLED(uint32_t now) {
  if (!oledReady || now - lastOledAt < OLED_PERIOD) return;
  lastOledAt = now;
  screen.clearDisplay();

  if (buttonStable == LOW && !buttonLongHandled && (now - buttonDownAt >= 350)) {
    drawSosHoldProgress(now - buttonDownAt);
    screen.display();
    return;
  }

  if (sosActive || fallState == FALL_ALERT || fallState == FALL_COUNTDOWN || radiusAlertActive) {
    drawWarning(now);
    screen.display();
    return;
  }

  if (!bootFinished && now - bootAt < INTRO_FRAMES_TOTAL) {
    const uint8_t n = ((now - bootAt) / INTRO_FRAME_MS) % 4;
    screen.drawBitmap(0, 0, introFrames[n], 128, 64, SSD1306_WHITE);
    screen.display();
    return;
  }

  if (!bootFinished) {
    bootFinished = true;
    lastPageAt = now;
  }

  if (AUTO_CYCLE_PAGES && !aiListening && (now - lastPageAt >= PAGE_MS)) {
    lastPageAt = now;
    currentPage = (currentPage + 1) % TOTAL_PAGES;
  }

  switch (currentPage) {
    case 0:      drawHR(now); break;
    case 1:      drawGPS(now); break;
    case 2:      drawTempPage(); break;
    case 3:      drawMotion(); break;
    case 4:      drawStepsPage(); break;
    case 5:      drawSafeRadiusPage(); break;
    case PAGE_AI:
    default:     drawAiPage(now); break;
  }
  screen.display();
}

// ====================================================================
// DIAGNOSTICS SERIAL
// ====================================================================
void diagnostics(uint32_t now) {
  if (now - lastSerialAt >= SERIAL_PERIOD) {
    lastSerialAt = now;
    Serial.printf("[STATUS] HR=%d contact=%d IR=%ld temp=%.2f motion=%.2fg gyro=%.0fdps steps=%lu (%.1fm) ",
                  bpm, opticalContact, irRaw, temperatureC, totalG, totalDps,
                  (unsigned long)stepCount, stepDistanceMeters);
    Serial.printf("fall=%s sos=%s radius=%.0fm dist=%.1fm radAlert=%u AI=%s(lvl=%u%%) page=%u BLE=%s\n",
                  fallText(), sosActive ? "YES" : "NO", safeRadiusMeters,
                  isnan(currentDistanceM) ? -1.0f : currentDistanceM,
                  radiusAlertActive ? 1 : 0,
                  aiListening ? "REC" : (micReady ? "READY" : "NO_MIC"),
                  (unsigned)aiMicLevel, (unsigned)currentPage,
                  bleConnected ? "ON" : "OFF");
  }

  if (now - lastGpsReportAt >= GPS_REPORT_PERIOD) {
    lastGpsReportAt = now;

    Serial.println();
    Serial.println("========== STATUS GPS ==========");

    Serial.print("Total Byte       : ");
    Serial.println(gpsBytes);

    Serial.print("Karakter diproses: ");
    Serial.println(gps.charsProcessed());

    Serial.print("Checksum berhasil: ");
    Serial.println(gps.passedChecksum());

    Serial.print("Checksum gagal   : ");
    Serial.println(gps.failedChecksum());

    Serial.print("Satelit          : ");
    if (gps.satellites.isValid() && gps.satellites.age() < 5000) {
      Serial.println(gps.satellites.value());
    } else {
      Serial.println("Belum tersedia");
    }

    Serial.print("HDOP             : ");
    if (!isnan(gpsHdop)) {
      Serial.println(gpsHdop, 2);
    } else if (gps.hdop.isValid() && gps.hdop.age() < 7000) {
      Serial.println(gps.hdop.hdop(), 2);
    } else {
      Serial.println("Belum tersedia");
    }

    if (gpsFix) {
      const double latitude = gps.location.lat();
      const double longitude = gps.location.lng();

      Serial.println("--------------------------------");
      Serial.print("Latitude  : ");
      Serial.println(latitude, 6);
      Serial.print("Longitude : ");
      Serial.println(longitude, 6);
      Serial.print("Google Maps: https://www.google.com/maps?q=");
      Serial.print(latitude, 6);
      Serial.print(",");
      Serial.println(longitude, 6);
      Serial.println("Status: GPS FIX");
    } else {
      Serial.println("--------------------------------");
      Serial.println("Latitude  : Belum tersedia");
      Serial.println("Longitude : Belum tersedia");
      Serial.println("Status    : MENCARI SINYAL GPS");
    }

    if (gpsBytes == 0) {
      Serial.printf(
        "[GPS] NO UART DATA: TX GPS -> GPIO%d, GND, power, baud=9600\n",
        PIN_GPS_RX
      );
    }

    Serial.println("================================");
    Serial.println();
  }
}

// ====================================================================
// SAFE RADIUS EVALUATOR
// ====================================================================
void updateSafeRadius(uint32_t now) {
  if (!safeRadiusEnabled) {
    if (radiusAlertActive) {
      radiusAlertActive = false;
      requestBleNow = true;
    }
    if (hapticPattern == HAPTIC_SAFE_RADIUS) {
      hapticPattern = HAPTIC_NONE;
      motorWrite(false);
    }
    return;
  }

  if (gpsFix && companionUpdatedAt != 0 &&
      !isnan(companionLat) && !isnan(companionLon)) {
    const double measuredDistance = TinyGPSPlus::distanceBetween(
      gps.location.lat(), gps.location.lng(),
      companionLat, companionLon
    );

    if (isfinite(measuredDistance) && measuredDistance >= 0.0) {
      currentDistanceM = (float)measuredDistance;
    }
  }

  if (radiusSnoozeUntil != 0) {
    if ((int32_t)(radiusSnoozeUntil - now) > 0) {
      if (radiusAlertActive) {
        radiusAlertActive = false;
        requestBleNow = true;
      }
      if (hapticPattern == HAPTIC_SAFE_RADIUS) {
        hapticPattern = HAPTIC_NONE;
        motorWrite(false);
      }
      return;
    }
    radiusSnoozeUntil = 0;
  }

  float effectiveDistance = currentDistanceM;
  if ((isnan(effectiveDistance) || effectiveDistance <= 0.0f) && stepDistanceMeters > 0.0f) {
    effectiveDistance = stepDistanceMeters;
  }

  const bool validDistance =
    !isnan(effectiveDistance) && isfinite(effectiveDistance) && effectiveDistance >= 0.0f;

  const bool shouldAlert =
    appForcedRadiusAlert ||
    (validDistance && effectiveDistance > safeRadiusMeters);

  if (shouldAlert != radiusAlertActive) {
    radiusAlertActive = shouldAlert;
    requestBleNow = true;

    if (radiusAlertActive) {
      Serial.printf(
        "[SAFE RADIUS] DI LUAR BATAS! Jarak=%.1fm, batas=%.1fm\n",
        effectiveDistance, safeRadiusMeters
      );
    } else {
      Serial.println("[SAFE RADIUS] Kembali dalam batas aman / alert dinonaktifkan.");
      if (hapticPattern == HAPTIC_SAFE_RADIUS) {
        hapticPattern = HAPTIC_NONE;
        motorWrite(false);
      }
    }
  }
}

// ====================================================================
// SETUP & LOOP UTAMA
// ====================================================================
void setup() {
  Serial.begin(SERIAL_BAUD);
  delay(450);
  Serial.println("\n=== HAJICARE SMARTBAND PRO v2.3 / ESP32-S3 + AI MIC ===");
  Serial.println("[SERIAL TEST] V=getar, E=darurat, R=radius, F=jatuh, S=+1 langkah, 0=reset, M=tes Mic AI, X=stop.");

  pinMode(PIN_ACTION, INPUT_PULLUP);
  pinMode(PIN_MOTOR, OUTPUT);
  motorWrite(false);

  // Pulihkan jalur I2C terlebih dahulu agar OLED & sensor tidak gagal terdeteksi saat cold boot
  recoverI2CBus();
  Wire.begin(PIN_SDA, PIN_SCL);
  Wire.setClock(100000);
  delay(50);
  scanI2C();

  for (uint8_t attempt = 0; attempt < 2 && !oledReady; ++attempt) {
    if (isDevice(0x3C)) oledAddr = 0x3C;
    else if (isDevice(0x3D)) oledAddr = 0x3D;
    if (oledAddr) {
      oledReady = screen.begin(SSD1306_SWITCHCAPVCC, oledAddr, false, false);
      if (oledReady) {
        screen.clearDisplay();
        screen.setTextWrap(false);
        screen.display();
      }
    }
    if (!oledReady) delay(80);
  }
  Serial.printf("[OLED] %s address=0x%02X\n", oledReady ? "READY" : "NOT FOUND", oledAddr);

  if (pulse.begin(Wire, I2C_SPEED_STANDARD)) {
    pulse.setup(0x24, 4, 2, 100, 411, 4096);
    pulse.setPulseAmplitudeRed(0x0A);
    pulse.setPulseAmplitudeIR(0x24);
    pulse.setPulseAmplitudeGreen(0);
    maxReady = true;
    Serial.println("[MAX30102] READY (Optimized IR 0x24 + Contact Hysteresis)");
  } else {
    Serial.println("[MAX30102] NOT FOUND");
  }

  initTemp();
  initMPU();
  if (mpuReady) readMPU();
  Wire.setClock(100000);

  // Inisialisasi Mikrofon I2S INMP441
  initMicrophone();

  GPSport.setRxBufferSize(1024);
  GPSport.begin(GPS_BAUD, SERIAL_8N1, PIN_GPS_RX, PIN_GPS_TX);
  initBLE();

  bootAt = millis();
  lastPageAt = bootAt;
  Serial.println("[SYSTEM] READY. Klik 1x = Ganti Page, Klik 2x = Bicara ke AI, Tahan 3 Detik = SOS.");
}

void loop() {
  uint32_t now = millis();
  updateGPS();
  handleSerialTestCommands();
  updateButton(now);
  updateAiMicrophone(now);
  updateHeartRate();

  if (now - lastMpuAt >= MPU_PERIOD) {
    lastMpuAt = now;
    if (readMPU()) {
      updateFall(now);
      updateStepCounter(now);
    }
  }

  if (now - lastTempAt >= TEMP_PERIOD) {
    lastTempAt = now;
    readTemp();
  }

  updateSafeRadius(now);

  if (sosActive || fallState == FALL_ALERT || fallState == FALL_COUNTDOWN) {
    vibrate(HAPTIC_EMERGENCY);
  } else if (radiusAlertActive) {
    vibrate(HAPTIC_SAFE_RADIUS);
  }

  updateHaptic(now);

  if (bleRestart && !bleConnected && now - bleDisconnectedAt >= 400) {
    bleRestart = false;
    BLEDevice::startAdvertising();
    Serial.println("[BLE] advertising restarted");
  }

  sendBLE(now);
  drawOLED(now);
  diagnostics(now);
  delay(1);
}

apakah kode ini sudah cukup untuk membuat sistem yang seperti ini :

microphone modul inmp441 -> ditangkap oleh ble -> lalu di tulis kembali menjadi text output dari speech to text smartband microphone inmp441

ini adalah output nya

=== DIAGNOSTIK MIC INMP441 + OLED + LED ===
[OK] OLED SSD1306 aktif di alamat 0x3C
[OK] Driver I2S INMP441 aktif (SCK=4, WS=5, SD=6)

--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=1200 | Silakan ucapkan: 'HALO HAJICARE'
[SUARA TERDETEKSI] Merekam kata yang diucapkan...
==========================================
HASIL TEST MIC : BERHASIL (MIC OK!)
Level Puncak   : 100% (Peak Raw: 32366)
Suku Kata      : 2 bagian kata terdeteksi
Status Kabel   : DATA I2S NORMAL
==========================================

--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=1200 | Silakan ucapkan: 'HALO HAJICARE'
[SUARA TERDETEKSI] Merekam kata yang diucapkan...
==========================================
HASIL TEST MIC : BERHASIL (MIC OK!)
Level Puncak   : 78% (Peak Raw: 6312)
Suku Kata      : 2 bagian kata terdeteksi
Status Kabel   : DATA I2S NORMAL
==========================================

--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=1200 | Silakan ucapkan: 'HALO HAJICARE'
[SUARA TERDETEKSI] Merekam kata yang diucapkan...
==========================================
HASIL TEST MIC : BERHASIL (MIC OK!)
Level Puncak   : 90% (Peak Raw: 7249)
Suku Kata      : 5 bagian kata terdeteksi
Status Kabel   : DATA I2S NORMAL
==========================================

=== DIAGNOSTIK MIC INMP441 + OLED + LED ===
[OK] OLED SSD1306 aktif di alamat 0x3C
[OK] Driver I2S INMP441 aktif (SCK=4, WS=5, SD=6)

--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=1200 | Silakan ucapkan: 'HALO HAJICARE'
[SUARA TERDETEKSI] Merekam kata yang diucapkan...
==========================================
HASIL TEST MIC : BERHASIL (MIC OK!)
Level Puncak   : 100% (Peak Raw: 12157)
Suku Kata      : 2 bagian kata terdeteksi
Status Kabel   : DATA I2S NORMAL
==========================================

--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=1200 | Silakan ucapkan: 'HALO HAJICARE'
[SUARA TERDETEKSI] Merekam kata yang diucapkan...
==========================================
HASIL TEST MIC : BERHASIL (MIC OK!)
Level Puncak   : 78% (Peak Raw: 6257)
Suku Kata      : 1 bagian kata terdeteksi
Status Kabel   : DATA I2S NORMAL
==========================================

--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=840 | Silakan ucapkan: 'HALO HAJICARE'
[SUARA TERDETEKSI] Merekam kata yang diucapkan...
==========================================
HASIL TEST MIC : BERHASIL (MIC OK!)
Level Puncak   : 100% (Peak Raw: 131019)
Suku Kata      : 1 bagian kata terdeteksi
Status Kabel   : DATA I2S NORMAL
==========================================

--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=1200 | Silakan ucapkan: 'HALO HAJICARE'
[SUARA TERDETEKSI] Merekam kata yang diucapkan...
==========================================
HASIL TEST MIC : BERHASIL (MIC OK!)
Level Puncak   : 100% (Peak Raw: 18979)
Suku Kata      : 4 bagian kata terdeteksi
Status Kabel   : DATA I2S NORMAL
==========================================

--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=1200 | Silakan ucapkan: 'HALO HAJICARE'
[SUARA TERDETEKSI] Merekam kata yang diucapkan...
==========================================
HASIL TEST MIC : BERHASIL (MIC OK!)
Level Puncak   : 100% (Peak Raw: 49375)
Suku Kata      : 1 bagian kata terdeteksi
Status Kabel   : DATA I2S NORMAL
==========================================

--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=1200 | Silakan ucapkan: 'HALO HAJICARE'
[SUARA TERDETEKSI] Merekam kata yang diucapkan...
==========================================
HASIL TEST MIC : BERHASIL (MIC OK!)
Level Puncak   : 100% (Peak Raw: 73444)
Suku Kata      : 1 bagian kata terdeteksi
Status Kabel   : DATA I2S NORMAL
==========================================

--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=1200 | Silakan ucapkan: 'HALO HAJICARE'
[SUARA TERDETEKSI] Merekam kata yang diucapkan...
==========================================
HASIL TEST MIC : BERHASIL (MIC OK!)
Level Puncak   : 100% (Peak Raw: 20614)
Suku Kata      : 6 bagian kata terdeteksi
Status Kabel   : DATA I2S NORMAL
==========================================

--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=1200 | Silakan ucapkan: 'HALO HAJICARE'
[SUARA TERDETEKSI] Merekam kata yang diucapkan...
==========================================
HASIL TEST MIC : BERHASIL (MIC OK!)
Level Puncak   : 100% (Peak Raw: 38820)
Suku Kata      : 3 bagian kata terdeteksi
Status Kabel   : DATA I2S NORMAL
==========================================

--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=1200 | Silakan ucapkan: 'HALO HAJICARE'
[SUARA TERDETEKSI] Merekam kata yang diucapkan...
==========================================
HASIL TEST MIC : BERHASIL (MIC OK!)
Level Puncak   : 100% (Peak Raw: 42450)
Suku Kata      : 2 bagian kata terdeteksi
Status Kabel   : DATA I2S NORMAL
==========================================

--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=1200 | Silakan ucapkan: 'HALO HAJICARE'
[SUARA TERDETEKSI] Merekam kata yang diucapkan...
==========================================
HASIL TEST MIC : BERHASIL (MIC OK!)
Level Puncak   : 100% (Peak Raw: 64152)
Suku Kata      : 1 bagian kata terdeteksi
Status Kabel   : DATA I2S NORMAL
==========================================

--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=1200 | Silakan ucapkan: 'HALO HAJICARE'
[SUARA TERDETEKSI] Merekam kata yang diucapkan...
==========================================
HASIL TEST MIC : BERHASIL (MIC OK!)
Level Puncak   : 100% (Peak Raw: 20460)
Suku Kata      : 5 bagian kata terdeteksi
Status Kabel   : DATA I2S NORMAL
==========================================

--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=1200 | Silakan ucapkan: 'HALO HAJICARE'
[SUARA TERDETEKSI] Merekam kata yang diucapkan...
==========================================
HASIL TEST MIC : BERHASIL (MIC OK!)
Level Puncak   : 100% (Peak Raw: 22408)
Suku Kata      : 3 bagian kata terdeteksi
Status Kabel   : DATA I2S NORMAL
==========================================

--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=1200 | Silakan ucapkan: 'HALO HAJICARE'
[SUARA TERDETEKSI] Merekam kata yang diucapkan...
==========================================
HASIL TEST MIC : BERHASIL (MIC OK!)
Level Puncak   : 100% (Peak Raw: 13919)
Suku Kata      : 3 bagian kata terdeteksi
Status Kabel   : DATA I2S NORMAL
==========================================

--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=1200 | Silakan ucapkan: 'HALO HAJICARE'
[SUARA TERDETEKSI] Merekam kata yang diucapkan...
==========================================
HASIL TEST MIC : BERHASIL (MIC OK!)
Level Puncak   : 100% (Peak Raw: 14160)
Suku Kata      : 4 bagian kata terdeteksi
Status Kabel   : DATA I2S NORMAL
==========================================

=== DIAGNOSTIK MIC INMP441 + OLED + LED ===
[OK] OLED SSD1306 aktif di alamat 0x3C
[OK] Driver I2S INMP441 aktif (SCK=4, WS=5, SD=6)

--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=1200 | Silakan ucapkan: 'HALO HAJICARE'
[SUARA TERDETEKSI] Merekam kata yang diucapkan...
==========================================
HASIL TEST MIC : BERHASIL (MIC OK!)
Level Puncak   : 99% (Peak Raw: 7928)
Suku Kata      : 1 bagian kata terdeteksi
Status Kabel   : DATA I2S NORMAL
==========================================

--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=1200 | Silakan ucapkan: 'HALO HAJICARE'

=== DIAGNOSTIK & ECHO MIC INMP441 + OLED + LED ===
[OK] OLED SSD1306 aktif di alamat 0x3C
[OK] Driver I2S INMP441 aktif (SCK=4, WS=5, SD=6)

--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=168 | Ambang Trigger=382
>>> SILAKAN BICARA KE MIC SEKARANG (Ucapkan: 'HALO HAJICARE') <<<

[SUARA MASUK!] Menangkap ucapan Anda secara live:
  -> Tangkap [....................] Vol:  4% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  4% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  0% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  4% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  1% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  4% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  4% | Frek:   0 Hz | Suku Kata:2 (Jeda)
  -> Tangkap [#...................] Vol:  7% | Frek:   0 Hz | Suku Kata:2 (Jeda)
  -> Tangkap [....................] Vol:  4% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [....................] Vol:  4% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [#...................] Vol:  5% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [#...................] Vol:  6% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [....................] Vol:  0% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [....................] Vol:  0% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [....................] Vol:  0% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [....................] Vol:  0% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [....................] Vol:  2% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [....................] Vol:  3% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [....................] Vol:  1% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [....................] Vol:  1% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [....................] Vol:  1% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [....................] Vol:  1% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [....................] Vol:  0% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [....................] Vol:  1% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [....................] Vol:  0% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [....................] Vol:  0% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [....................] Vol:  0% | Frek:   0 Hz | Suku Kata:3 (Jeda)

╔══════════════════════════════════════════════════════════════════╗
║         BALIKAN (ECHO) SUARA YANG DITANGKAP DARI MIC             ║
╠══════════════════════════════════════════════════════════════════╣
║ Status Tangkap : SUARA TERLALU PELAN / TIDAK JELAS
║ Volume Puncak  : 15% (Amplitudo Puncak: 713)
║ Frekuensi Vokal: Rata-rata 0 Hz (Ketukan/Desis)
║ Suku Kata      : 3 Suku Kata
║ Pola Ucapan    : 3 Suku Kata -> Mirip: "HA-JI-CARE" / "TES SA-TU"
╠══════════════════════════════════════════════════════════════════╣
║ REPLAY GELOMBANG SUARA ANDA (0.0 dtk s/d 3.0 dtk):               ║
║ 0.1 dtk [#........................]   4% (   0 Hz)
║ 0.2 dtk [#........................]   4% (   0 Hz)
║ 0.3 dtk [.........................]   0% (   0 Hz)
║ 0.4 dtk [#........................]   4% (   0 Hz)
║ 0.5 dtk [.........................]   1% (   0 Hz)
║ 0.6 dtk [#........................]   4% (   0 Hz)
║ 0.7 dtk [#........................]   4% (   0 Hz)
║ 0.8 dtk [#........................]   7% (   0 Hz)
║ 0.9 dtk [#........................]   4% (   0 Hz)
║ 1.0 dtk [#........................]   4% (   0 Hz)
║ 1.1 dtk [#........................]   5% (   0 Hz)
║ 1.2 dtk [#........................]   6% (   0 Hz)
║ 1.3 dtk [.........................]   0% (   0 Hz)
║ 1.4 dtk [.........................]   0% (   0 Hz)
║ 1.5 dtk [.........................]   0% (   0 Hz)
║ 1.6 dtk [.........................]   0% (   0 Hz)
║ 1.7 dtk [.........................]   2% (   0 Hz)
║ 1.8 dtk [.........................]   3% (   0 Hz)
║ 1.9 dtk [.........................]   1% (   0 Hz)
║ 2.0 dtk [.........................]   1% (   0 Hz)
║ 2.1 dtk [.........................]   1% (   0 Hz)
║ 2.2 dtk [.........................]   1% (   0 Hz)
║ 2.3 dtk [.........................]   0% (   0 Hz)
║ 2.4 dtk [.........................]   1% (   0 Hz)
║ 2.5 dtk [.........................]   0% (   0 Hz)
║ 2.6 dtk [.........................]   0% (   0 Hz)
║ 2.7 dtk [.........................]   0% (   0 Hz)
╠══════════════════════════════════════════════════════════════════╣
║ Data Sampel Audio PCM 16-bit: [ 0 0 0 0 0 0 0 0 ]
╚══════════════════════════════════════════════════════════════════╝


--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=97 | Ambang Trigger=238
>>> SILAKAN BICARA KE MIC SEKARANG (Ucapkan: 'HALO HAJICARE') <<<
[MENUNGGU SUARA...] Level saat ini: 3% (Amplitudo=52, Ambang=234) -> Silakan bicara!

[SUARA MASUK!] Menangkap ucapan Anda secara live:
  -> Tangkap [#...................] Vol:  6% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [#...................] Vol:  5% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [#...................] Vol:  5% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  4% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  2% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  2% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  4% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  4% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [#...................] Vol:  7% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [#...................] Vol:  6% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [#...................] Vol:  7% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  4% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [#...................] Vol:  7% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  3% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  4% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  4% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [#...................] Vol:  5% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  3% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  3% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  2% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  3% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [#...................] Vol:  5% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [#...................] Vol:  5% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [#...................] Vol:  6% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [#...................] Vol:  8% | Frek:   0 Hz | Suku Kata:2 (Jeda)
  -> Tangkap [#...................] Vol:  5% | Frek:   0 Hz | Suku Kata:2 (Jeda)
  -> Tangkap [#...................] Vol:  5% | Frek:   0 Hz | Suku Kata:2 (Jeda)
  -> Tangkap [....................] Vol:  3% | Frek:   0 Hz | Suku Kata:2 (Jeda)

╔══════════════════════════════════════════════════════════════════╗
║         BALIKAN (ECHO) SUARA YANG DITANGKAP DARI MIC             ║
╠══════════════════════════════════════════════════════════════════╣
║ Status Tangkap : SUARA TERLALU PELAN / TIDAK JELAS
║ Volume Puncak  : 13% (Amplitudo Puncak: 574)
║ Frekuensi Vokal: Rata-rata 93 Hz (Karakter Suara Manusia)
║ Suku Kata      : 2 Suku Kata
║ Pola Ucapan    : 2 Suku Kata -> Mirip: "HA-LO" / "SA-TU"
╠══════════════════════════════════════════════════════════════════╣
║ REPLAY GELOMBANG SUARA ANDA (0.0 dtk s/d 3.0 dtk):               ║
║ 0.1 dtk [#........................]   6% (   0 Hz)
║ 0.2 dtk [#........................]   5% (   0 Hz)
║ 0.3 dtk [#........................]   5% (   0 Hz)
║ 0.4 dtk [#........................]   4% (   0 Hz)
║ 0.5 dtk [.........................]   2% (   0 Hz)
║ 0.6 dtk [.........................]   2% (   0 Hz)
║ 0.7 dtk [#........................]   4% (   0 Hz)
║ 0.8 dtk [#........................]   4% (   0 Hz)
║ 0.9 dtk [#........................]   7% (   0 Hz)
║ 1.0 dtk [#........................]   6% (   0 Hz)
║ 1.1 dtk [#........................]   7% (   0 Hz)
║ 1.2 dtk [#........................]   4% (   0 Hz)
║ 1.3 dtk [#........................]   7% (   0 Hz)
║ 1.4 dtk [.........................]   3% (   0 Hz)
║ 1.5 dtk [#........................]   4% (   0 Hz)
║ 1.6 dtk [#........................]   4% (   0 Hz)
║ 1.7 dtk [#........................]   5% (   0 Hz)
║ 1.8 dtk [.........................]   3% (   0 Hz)
║ 1.9 dtk [.........................]   3% (   0 Hz)
║ 2.0 dtk [.........................]   2% (   0 Hz)
║ 2.1 dtk [.........................]   3% (   0 Hz)
║ 2.2 dtk [#........................]   5% (   0 Hz)
║ 2.3 dtk [#........................]   5% (   0 Hz)
║ 2.4 dtk [#........................]   6% (   0 Hz)
║ 2.5 dtk [##.......................]   8% (   0 Hz)
║ 2.6 dtk [#........................]   5% (   0 Hz)
║ 2.7 dtk [#........................]   5% (   0 Hz)
║ 2.8 dtk [.........................]   3% (   0 Hz)
╠══════════════════════════════════════════════════════════════════╣
║ Data Sampel Audio PCM 16-bit: [ -227 -235 -237 -229 -247 -351 -363 -291 ]
╚══════════════════════════════════════════════════════════════════╝


--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=96 | Ambang Trigger=216
>>> SILAKAN BICARA KE MIC SEKARANG (Ucapkan: 'HALO HAJICARE') <<<

[SUARA MASUK!] Menangkap ucapan Anda secara live:
  -> Tangkap [#...................] Vol:  7% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  4% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  3% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  2% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  4% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  1% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  4% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [#...................] Vol:  6% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [#...................] Vol:  6% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [#...................] Vol:  6% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  4% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  4% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  2% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  4% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [#...................] Vol:  6% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  2% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  4% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  4% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  2% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  2% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  2% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  3% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  3% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  1% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  3% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [#...................] Vol:  6% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [#...................] Vol:  6% | Frek:   0 Hz | Suku Kata:1 (Jeda)

╔══════════════════════════════════════════════════════════════════╗
║         BALIKAN (ECHO) SUARA YANG DITANGKAP DARI MIC             ║
╠══════════════════════════════════════════════════════════════════╣
║ Status Tangkap : SUARA TERLALU PELAN / TIDAK JELAS
║ Volume Puncak  : 14% (Amplitudo Puncak: 599)
║ Frekuensi Vokal: Rata-rata 187 Hz (Karakter Suara Manusia)
║ Suku Kata      : 2 Suku Kata
║ Pola Ucapan    : 2 Suku Kata -> Mirip: "HA-LO" / "SA-TU"
╠══════════════════════════════════════════════════════════════════╣
║ REPLAY GELOMBANG SUARA ANDA (0.0 dtk s/d 3.0 dtk):               ║
║ 0.1 dtk [#........................]   7% (   0 Hz)
║ 0.2 dtk [#........................]   4% (   0 Hz)
║ 0.3 dtk [.........................]   3% (   0 Hz)
║ 0.4 dtk [.........................]   2% (   0 Hz)
║ 0.5 dtk [#........................]   4% (   0 Hz)
║ 0.6 dtk [.........................]   1% (   0 Hz)
║ 0.7 dtk [#........................]   4% (   0 Hz)
║ 0.8 dtk [#........................]   6% (   0 Hz)
║ 0.9 dtk [#........................]   6% (   0 Hz)
║ 1.0 dtk [#........................]   6% (   0 Hz)
║ 1.1 dtk [#........................]   4% (   0 Hz)
║ 1.2 dtk [#........................]   4% (   0 Hz)
║ 1.3 dtk [.........................]   2% (   0 Hz)
║ 1.4 dtk [#........................]   4% (   0 Hz)
║ 1.5 dtk [#........................]   6% (   0 Hz)
║ 1.6 dtk [.........................]   2% (   0 Hz)
║ 1.7 dtk [#........................]   4% (   0 Hz)
║ 1.8 dtk [#........................]   4% (   0 Hz)
║ 1.9 dtk [.........................]   2% (   0 Hz)
║ 2.0 dtk [.........................]   2% (   0 Hz)
║ 2.1 dtk [.........................]   2% (   0 Hz)
║ 2.2 dtk [.........................]   3% (   0 Hz)
║ 2.3 dtk [.........................]   3% (   0 Hz)
║ 2.4 dtk [.........................]   1% (   0 Hz)
║ 2.5 dtk [.........................]   3% (   0 Hz)
║ 2.6 dtk [#........................]   6% (   0 Hz)
║ 2.7 dtk [#........................]   6% (   0 Hz)
╠══════════════════════════════════════════════════════════════════╣
║ Data Sampel Audio PCM 16-bit: [ 181 193 199 193 237 248 251 242 ]
╚══════════════════════════════════════════════════════════════════╝


--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=237 | Ambang Trigger=524
>>> SILAKAN BICARA KE MIC SEKARANG (Ucapkan: 'HALO HAJICARE') <<<

[SUARA MASUK!] Menangkap ucapan Anda secara live:
  -> Tangkap [....................] Vol:  0% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  0% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [#...................] Vol:  7% | Frek:   0 Hz | Suku Kata:2 (Jeda)
  -> Tangkap [....................] Vol:  0% | Frek:   0 Hz | Suku Kata:2 (Jeda)
  -> Tangkap [....................] Vol:  3% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [#...................] Vol:  6% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [##..................] Vol: 11% | Frek:   0 Hz | Suku Kata:4 (Jeda)
  -> Tangkap [##..................] Vol: 12% | Frek:   0 Hz | Suku Kata:4 <-- [SUARA DITANGKAP]
  -> Tangkap [##..................] Vol: 11% | Frek:   0 Hz | Suku Kata:4 (Jeda)
  -> Tangkap [....................] Vol:  3% | Frek:   0 Hz | Suku Kata:4 (Jeda)
  -> Tangkap [#...................] Vol:  5% | Frek:   0 Hz | Suku Kata:4 (Jeda)
  -> Tangkap [#...................] Vol:  7% | Frek:   0 Hz | Suku Kata:4 (Jeda)
  -> Tangkap [....................] Vol:  2% | Frek:   0 Hz | Suku Kata:4 (Jeda)
  -> Tangkap [....................] Vol:  1% | Frek:   0 Hz | Suku Kata:4 (Jeda)
  -> Tangkap [....................] Vol:  0% | Frek:   0 Hz | Suku Kata:5 (Jeda)
  -> Tangkap [....................] Vol:  3% | Frek:   0 Hz | Suku Kata:5 (Jeda)
  -> Tangkap [#...................] Vol:  9% | Frek:   0 Hz | Suku Kata:5 (Jeda)
  -> Tangkap [....................] Vol:  3% | Frek:   0 Hz | Suku Kata:5 (Jeda)
  -> Tangkap [....................] Vol:  1% | Frek:   0 Hz | Suku Kata:5 (Jeda)
  -> Tangkap [....................] Vol:  0% | Frek:   0 Hz | Suku Kata:6 (Jeda)
  -> Tangkap [####................] Vol: 21% | Frek:   0 Hz | Suku Kata:6 <-- [SUARA DITANGKAP]
  -> Tangkap [##..................] Vol: 12% | Frek:   0 Hz | Suku Kata:6 <-- [SUARA DITANGKAP]
  -> Tangkap [#############.......] Vol: 65% | Frek:   0 Hz | Suku Kata:6 <-- [SUARA DITANGKAP]
  -> Tangkap [###################.] Vol: 99% | Frek: 375 Hz | Suku Kata:6 <-- [SUARA DITANGKAP]
  -> Tangkap [#######.............] Vol: 39% | Frek:   0 Hz | Suku Kata:6 <-- [SUARA DITANGKAP]
  -> Tangkap [#...................] Vol:  6% | Frek:   0 Hz | Suku Kata:6 (Jeda)
  -> Tangkap [####................] Vol: 21% | Frek:   0 Hz | Suku Kata:6 <-- [SUARA DITANGKAP]

╔══════════════════════════════════════════════════════════════════╗
║         BALIKAN (ECHO) SUARA YANG DITANGKAP DARI MIC             ║
╠══════════════════════════════════════════════════════════════════╣
║ Status Tangkap : BERHASIL DITANGKAP & DIKEMBALIKAN
║ Volume Puncak  : 100% (Amplitudo Puncak: 4364)
║ Frekuensi Vokal: Rata-rata 204 Hz (Karakter Suara Manusia)
║ Suku Kata      : 6 Suku Kata
║ Pola Ucapan    : 4-6 Suku Kata -> Cocok dgn: "HA-LO HA-JI-CARE"!
╠══════════════════════════════════════════════════════════════════╣
║ REPLAY GELOMBANG SUARA ANDA (0.0 dtk s/d 3.0 dtk):               ║
║ 0.1 dtk [.........................]   0% (   0 Hz)
║ 0.2 dtk [.........................]   0% (   0 Hz)
║ 0.3 dtk [#........................]   7% (   0 Hz)
║ 0.4 dtk [.........................]   0% (   0 Hz)
║ 0.5 dtk [.........................]   3% (   0 Hz)
║ 0.6 dtk [#........................]   6% (   0 Hz)
║ 0.7 dtk [##.......................]  11% (   0 Hz)
║ 0.8 dtk [###......................]  12% (   0 Hz)
║ 0.9 dtk [##.......................]  11% (   0 Hz)
║ 1.0 dtk [.........................]   3% (   0 Hz)
║ 1.1 dtk [#........................]   5% (   0 Hz)
║ 1.2 dtk [#........................]   7% (   0 Hz)
║ 1.3 dtk [.........................]   2% (   0 Hz)
║ 1.4 dtk [.........................]   1% (   0 Hz)
║ 1.5 dtk [.........................]   0% (   0 Hz)
║ 1.6 dtk [.........................]   3% (   0 Hz)
║ 1.7 dtk [##.......................]   9% (   0 Hz)
║ 1.8 dtk [.........................]   3% (   0 Hz)
║ 1.9 dtk [.........................]   1% (   0 Hz)
║ 2.0 dtk [.........................]   0% (   0 Hz)
║ 2.1 dtk [#####....................]  21% (   0 Hz)
║ 2.2 dtk [###......................]  12% (   0 Hz)
║ 2.3 dtk [################.........]  65% (   0 Hz)
║ 2.4 dtk [########################.]  99% ( 375 Hz)
║ 2.5 dtk [#########................]  39% (   0 Hz)
║ 2.6 dtk [#........................]   6% (   0 Hz)
║ 2.7 dtk [#####....................]  21% (   0 Hz)
╠══════════════════════════════════════════════════════════════════╣
║ Data Sampel Audio PCM 16-bit: [ -4092 -4617 -4807 -3605 -2642 -2057 -2080 -1959 ]
╚══════════════════════════════════════════════════════════════════╝


--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=338 | Ambang Trigger=726
>>> SILAKAN BICARA KE MIC SEKARANG (Ucapkan: 'HALO HAJICARE') <<<

[SUARA MASUK!] Menangkap ucapan Anda secara live:
  -> Tangkap [###.................] Vol: 19% | Frek:   0 Hz | Suku Kata:1 <-- [SUARA DITANGKAP]
  -> Tangkap [....................] Vol:  2% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [###.................] Vol: 15% | Frek:   0 Hz | Suku Kata:2 <-- [SUARA DITANGKAP]
  -> Tangkap [....................] Vol:  4% | Frek:   0 Hz | Suku Kata:2 (Jeda)
  -> Tangkap [#...................] Vol:  7% | Frek:   0 Hz | Suku Kata:2 (Jeda)
  -> Tangkap [##..................] Vol: 11% | Frek:   0 Hz | Suku Kata:2 (Jeda)
  -> Tangkap [....................] Vol:  4% | Frek:   0 Hz | Suku Kata:2 (Jeda)
  -> Tangkap [....................] Vol:  2% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [########............] Vol: 40% | Frek:   0 Hz | Suku Kata:3 <-- [SUARA DITANGKAP]
  -> Tangkap [#########...........] Vol: 49% | Frek: 625 Hz | Suku Kata:3 <-- [SUARA DITANGKAP]
  -> Tangkap [######..............] Vol: 34% | Frek:  62 Hz | Suku Kata:3 <-- [SUARA DITANGKAP]
  -> Tangkap [##..................] Vol: 12% | Frek:   0 Hz | Suku Kata:3 <-- [SUARA DITANGKAP]
  -> Tangkap [########............] Vol: 42% | Frek:   0 Hz | Suku Kata:3 <-- [SUARA DITANGKAP]
  -> Tangkap [########............] Vol: 44% | Frek: 250 Hz | Suku Kata:3 <-- [SUARA DITANGKAP]
  -> Tangkap [##..................] Vol: 11% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [#...................] Vol:  9% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [########............] Vol: 40% | Frek:   0 Hz | Suku Kata:3 <-- [SUARA DITANGKAP]
  -> Tangkap [######..............] Vol: 34% | Frek:   0 Hz | Suku Kata:3 <-- [SUARA DITANGKAP]
  -> Tangkap [#######.............] Vol: 38% | Frek:   0 Hz | Suku Kata:3 <-- [SUARA DITANGKAP]
  -> Tangkap [###.................] Vol: 16% | Frek:   0 Hz | Suku Kata:3 <-- [SUARA DITANGKAP]
  -> Tangkap [############........] Vol: 62% | Frek:   0 Hz | Suku Kata:3 <-- [SUARA DITANGKAP]
  -> Tangkap [#...................] Vol:  8% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [....................] Vol:  0% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [####################] Vol:100% | Frek:  62 Hz | Suku Kata:3 <-- [SUARA DITANGKAP]
  -> Tangkap [###############.....] Vol: 76% | Frek:  62 Hz | Suku Kata:3 <-- [SUARA DITANGKAP]
  -> Tangkap [##..................] Vol: 11% | Frek:   0 Hz | Suku Kata:3 (Jeda)
  -> Tangkap [#...................] Vol:  9% | Frek:   0 Hz | Suku Kata:3 (Jeda)

╔══════════════════════════════════════════════════════════════════╗
║         BALIKAN (ECHO) SUARA YANG DITANGKAP DARI MIC             ║
╠══════════════════════════════════════════════════════════════════╣
║ Status Tangkap : BERHASIL DITANGKAP & DIKEMBALIKAN
║ Volume Puncak  : 100% (Amplitudo Puncak: 7139)
║ Frekuensi Vokal: Rata-rata 168 Hz (Karakter Suara Manusia)
║ Suku Kata      : 4 Suku Kata
║ Pola Ucapan    : 4-6 Suku Kata -> Cocok dgn: "HA-LO HA-JI-CARE"!
╠══════════════════════════════════════════════════════════════════╣
║ REPLAY GELOMBANG SUARA ANDA (0.0 dtk s/d 3.0 dtk):               ║
║ 0.1 dtk [####.....................]  19% (   0 Hz)
║ 0.2 dtk [.........................]   2% (   0 Hz)
║ 0.3 dtk [###......................]  15% (   0 Hz)
║ 0.4 dtk [#........................]   4% (   0 Hz)
║ 0.5 dtk [#........................]   7% (   0 Hz)
║ 0.6 dtk [##.......................]  11% (   0 Hz)
║ 0.7 dtk [#........................]   4% (   0 Hz)
║ 0.8 dtk [.........................]   2% (   0 Hz)
║ 0.9 dtk [##########...............]  40% (   0 Hz)
║ 1.0 dtk [############.............]  49% ( 625 Hz)
║ 1.1 dtk [########.................]  34% (  62 Hz)
║ 1.2 dtk [###......................]  12% (   0 Hz)
║ 1.3 dtk [##########...............]  42% (   0 Hz)
║ 1.4 dtk [###########..............]  44% ( 250 Hz)
║ 1.5 dtk [##.......................]  11% (   0 Hz)
║ 1.6 dtk [##.......................]   9% (   0 Hz)
║ 1.7 dtk [##########...............]  40% (   0 Hz)
║ 1.8 dtk [########.................]  34% (   0 Hz)
║ 1.9 dtk [#########................]  38% (   0 Hz)
║ 2.0 dtk [####.....................]  16% (   0 Hz)
║ 2.1 dtk [###############..........]  62% (   0 Hz)
║ 2.2 dtk [##.......................]   8% (   0 Hz)
║ 2.3 dtk [.........................]   0% (   0 Hz)
║ 2.4 dtk [#########################] 100% (  62 Hz)
║ 2.5 dtk [###################......]  76% (  62 Hz)
║ 2.6 dtk [##.......................]  11% (   0 Hz)
║ 2.7 dtk [##.......................]   9% (   0 Hz)
╠══════════════════════════════════════════════════════════════════╣
║ Data Sampel Audio PCM 16-bit: [ 262 226 179 130 93 107 132 131 ]
╚══════════════════════════════════════════════════════════════════╝


--- MEMULAI KALIBRASI & TES MIKROFON BARU ---
[KALIBRASI SELESAI] Noise Floor=161 | Ambang Trigger=370
>>> SILAKAN BICARA KE MIC SEKARANG (Ucapkan: 'HALO HAJICARE') <<<

[SUARA MASUK!] Menangkap ucapan Anda secara live:
  -> Tangkap [#...................] Vol:  7% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  1% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [....................] Vol:  3% | Frek:   0 Hz | Suku Kata:1 (Jeda)
  -> Tangkap [###.................] Vol: 16% | Frek: 250 Hz | Suku Kata:2 <-- [SUARA DITANGKAP]
  -> Tangkap [##..................] Vol: 11% | Frek:   0 Hz | Suku Kata:2 (Jeda)
  -> Tangkap [##########..........] Vol: 52% | Frek: 250 Hz | Suku Kata:2 <-- [SUARA DITANGKAP]
  -> Tangkap [#######.............] Vol: 39% | Frek: 312 Hz | Suku Kata:2 <-- [SUARA DITANGKAP]
  -> Tangkap [########............] Vol: 44% | Frek: 500 Hz | Suku Kata:2 <-- [SUARA DITANGKAP]
  -> Tangkap [########............] Vol: 41% | Frek: 312 Hz | Suku Kata:2 <-- [SUARA DITANGKAP]
  -> Tangkap [###.................] Vol: 19% | Frek: 187 Hz | Suku Kata:2 <-- [SUARA DITANGKAP]
  -> Tangkap [#######.............] Vol: 37% | Frek: 187 Hz | Suku Kata:2 <-- [SUARA DITANGKAP]
  -> Tangkap [####................] Vol: 22% | Frek:   0 Hz | Suku Kata:2 <-- [SUARA DITANGKAP]
  -> Tangkap [##..................] Vol: 11% | Frek:   0 Hz | Suku Kata:2 (Jeda)
  -> Tangkap [####................] Vol: 23% | Frek: 312 Hz | Suku Kata:2 <-- [SUARA DITANGKAP]
  -> Tangkap [######..............] Vol: 33% | Frek: 312 Hz | Suku Kata:2 <-- [SUARA DITANGKAP]
  -> Tangkap [######..............] Vol: 33% | Frek:   0 Hz | Suku Kata:2 <-- [SUARA DITANGKAP]
  -> Tangkap [#########...........] Vol: 47% | Frek: 187 Hz | Suku Kata:2 <-- [SUARA DITANGKAP]
  -> Tangkap [#...................] Vol:  8% | Frek:   0 Hz | Suku Kata:2 (Jeda)
  -> Tangkap [#...................] Vol:  8% | Frek:   0 Hz | Suku Kata:2 (Jeda)
  -> Tangkap [###.................] Vol: 16% | Frek:   0 Hz | Suku Kata:2 <-- [SUARA DITANGKAP]
  -> Tangkap [....................] Vol:  0% | Frek:   0 Hz | Suku Kata:2 (Jeda)
  -> Tangkap [....................] Vol:  2% | Frek:   0 Hz | Suku Kata:2 (Jeda)
  -> Tangkap [....................] Vol:  0% | Frek:   0 Hz | Suku Kata:2 (Jeda)
  -> Tangkap [#...................] Vol:  5% | Frek:   0 Hz | Suku Kata:2 (Jeda)
  -> Tangkap [....................] Vol:  0% | Frek:   0 Hz | Suku Kata:2 (Jeda)
  -> Tangkap [....................] Vol:  0% | Frek:   0 Hz | Suku Kata:2 (Jeda)
  -> Tangkap [....................] Vol:  0% | Frek:   0 Hz | Suku Kata:2 (Jeda)

╔══════════════════════════════════════════════════════════════════╗
║         BALIKAN (ECHO) SUARA YANG DITANGKAP DARI MIC             ║
╠══════════════════════════════════════════════════════════════════╣
║ Status Tangkap : BERHASIL DITANGKAP & DIKEMBALIKAN
║ Volume Puncak  : 86% (Amplitudo Puncak: 3186)
║ Frekuensi Vokal: Rata-rata 276 Hz (Karakter Suara Manusia)
║ Suku Kata      : 2 Suku Kata
║ Pola Ucapan    : 2 Suku Kata -> Mirip: "HA-LO" / "SA-TU"
╠══════════════════════════════════════════════════════════════════╣
║ REPLAY GELOMBANG SUARA ANDA (0.0 dtk s/d 3.0 dtk):               ║
║ 0.1 dtk [#........................]   7% (   0 Hz)
║ 0.2 dtk [.........................]   1% (   0 Hz)
║ 0.3 dtk [.........................]   3% (   0 Hz)
║ 0.4 dtk [####.....................]  16% ( 250 Hz)
║ 0.5 dtk [##.......................]  11% (   0 Hz)
║ 0.6 dtk [#############............]  52% ( 250 Hz)
║ 0.7 dtk [#########................]  39% ( 312 Hz)
║ 0.8 dtk [###########..............]  44% ( 500 Hz)
║ 0.9 dtk [##########...............]  41% ( 312 Hz)
║ 1.0 dtk [####.....................]  19% ( 187 Hz)
║ 1.1 dtk [#########................]  37% ( 187 Hz)
║ 1.2 dtk [#####....................]  22% (   0 Hz)
║ 1.3 dtk [##.......................]  11% (   0 Hz)
║ 1.4 dtk [#####....................]  23% ( 312 Hz)
║ 1.5 dtk [########.................]  33% ( 312 Hz)
║ 1.6 dtk [########.................]  33% (   0 Hz)
║ 1.7 dtk [###########..............]  47% ( 187 Hz)
║ 1.8 dtk [##.......................]   8% (   0 Hz)
║ 1.9 dtk [##.......................]   8% (   0 Hz)
║ 2.0 dtk [####.....................]  16% (   0 Hz)
║ 2.1 dtk [.........................]   0% (   0 Hz)
║ 2.2 dtk [.........................]   2% (   0 Hz)
║ 2.3 dtk [.........................]   0% (   0 Hz)
║ 2.4 dtk [#........................]   5% (   0 Hz)
║ 2.5 dtk [.........................]   0% (   0 Hz)
║ 2.6 dtk [.........................]   0% (   0 Hz)
║ 2.7 dtk [.........................]   0% (   0 Hz)
╠══════════════════════════════════════════════════════════════════╣
║ Data Sampel Audio PCM 16-bit: [ -1350 -1519 -1707 -1932 -2297 -2470 -2074 -1156 ]
╚══════════════════════════════════════════════════════════════════╝


</USER_REQUEST>
<ADDITIONAL_METADATA>
The current local time is: 2026-11-02T10:51:08+07:00.

The user's current state is as follows:
Other open documents:
- c:\Users\Ferdi Ahyana yusri\Downloads\hajicare new\hajicare\lib\main.dart (LANGUAGE_UNSPECIFIED)
- c:\Users\Ferdi Ahyana yusri\Downloads\hajicare new\hajicare\lib\features\ai_assistant\services\smartband_ai_bridge_service.dart (LANGUAGE_UNSPECIFIED)
- c:\Users\Ferdi Ahyana yusri\Downloads\hajicare new\hajicare\lib\features\ai_assistant\models\ai_server_config.dart (LANGUAGE_UNSPECIFIED)
- c:\Users\Ferdi Ahyana yusri\Downloads\hajicare new\hajicare\scripts\extract_and_generate_report.py (LANGUAGE_UNSPECIFIED)
- c:\Users\Ferdi Ahyana yusri\Downloads\hajicare new\hajicare\scripts\test_overpass.py (LANGUAGE_UNSPECIFIED)
</ADDITIONAL_METADATA>