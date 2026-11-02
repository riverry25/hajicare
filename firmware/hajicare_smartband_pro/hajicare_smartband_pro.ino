/*
  HAJICARE SMARTBAND PRO — ESP32-S3 SUPER MINI / ATGM336H / BLE / OLED / INMP441
  VERSION: 2.8.2 — Full Dynamic Sync with Flutter App (Pendamping-Authoritative Safe Radius);
                   Real-time OLED Page Sync ("page"), Dynamic Peer MTU Detection,
                   Non-Aborting BLE Fragment Queue, & Hybrid GPS/App Distance Fallback;
                   Immediate Safe Radius Trigger & Haptic Vibration;
                   Fall/step anti-false-positive + OLED 0.96in SSD1306 + GPS distance to companion phone;
                   Action Button (1x Page/Mute, 2x AI Voice, 3s SOS);
                   INMP441 I2S Microphone Bridge for AI Voice Assistant (Flutter TTS).

  CONNECTIONS:
    Shared I2C: SDA=GPIO8, SCL=GPIO9
       MAX30102 (0x57), DFRobot MCP9808 (normally 0x1F), MPU6050 (0x68/69),
       0.96-inch SSD1306 MONOCHROME OLED 128x64 (I2C 0x3C/0x3D)
    GPS ATGM336H TX -> ESP32-S3 GPIO44 (UART1 RX only; GPS RX unconnected)
    INMP441 I2S MIC: SCK=GPIO10, WS=GPIO11, SD=GPIO12, L/R=GND, VDD=3.3V
    ACTION / SOS switch GPIO13 -> GND; INPUT_PULLUP
    Vibration MODULE input GPIO7 (active HIGH by default)

  ACTION BUTTON (GPIO13):
   - Normal Idle + 1x Short Press (<3s) : Pindah halaman OLED berikutnya (+ haptic tap + sync ke Flutter)
   - Normal Idle + 2x Quick Click       : Mulai Rekam Suara AI via INMP441 (maks 5 detik)
   - Saat Rekam AI + 1x Short Press     : Selesai rekam lebih cepat & kirim ke Flutter AI
   - Normal Idle + Hold 3 Detik         : Aktifkan Manual SOS (getar darurat + kirim BLE)
   - Saat Alarm Aktif + 1x Short Press  : Matikan/batalkan getaran alarm lokal (SOS/Fall/Radius)

  BLE COMMANDS (RX on 6e400002-b5a3-f393-e0a9-e50e24dcca9e):
   - Radius dari Flutter         : "RADIUS:50", "RADIUS:200", "RADIUS:0" (OFF) atau "{\"safeRadius\":200}"
   - Lokasi HP pendamping + acc  : "COMP_GPS:-6.123456,106.123456,12.0"
   - Jarak dari Flutter (hybrid) : "DIST:14.5" atau "DIST:14.5,200"
   - Trigger alert langsung      : "RADIUS_ALERT:1" (ON) / "RADIUS_ALERT:0" (OFF)
   - Pindah halaman OLED         : "PAGE:0" s/d "PAGE:6"
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

#if __has_include("HajiCare_IntroFrames.h")
  #include "HajiCare_IntroFrames.h"
  #define HAJICARE_CUSTOM_INTRO 1
#else
  #define HAJICARE_CUSTOM_INTRO 0
#endif

#if !defined(CONFIG_IDF_TARGET_ESP32S3)
  #error "Select Tools > Board > ESP32S3 Dev Module (or your exact ESP32-S3 board)."
#endif

#define BRACELET_ID      "HCG-001"
#define DEVICE_NAME      "HajiCare-Gelang-001"
#define BLE_SERVICE_UUID "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
#define BLE_TX_UUID      "6e400003-b5a3-f393-e0a9-e50e24dcca9e"
#define BLE_RX_UUID      "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
#define BLE_AUDIO_UUID   "6e400004-b5a3-f393-e0a9-e50e24dcca9e" // Stream audio PCM 16-bit

constexpr uint8_t PIN_SDA = 8, PIN_SCL = 9, PIN_ACTION = 13, PIN_MOTOR = 7;
constexpr int PIN_GPS_RX = 44, PIN_GPS_TX = -1;
constexpr int PIN_I2S_SCK = 10, PIN_I2S_WS = 11, PIN_I2S_SD = 12;
constexpr uint32_t GPS_BAUD = 9600, SERIAL_BAUD = 115200;
constexpr bool MOTOR_ACTIVE_HIGH = true; // set false HANYA jika modul vibrator active LOW
constexpr bool AUTO_CYCLE_PAGES = false; // false = pindah page via klik tombol Action
constexpr bool DEBUG_RAW_NMEA = false;

constexpr uint16_t BLE_LOCAL_MTU = 512;
constexpr uint8_t OLED_WIDTH = 128;
constexpr uint8_t OLED_HEIGHT = 64;
constexpr uint32_t MPU_PERIOD = 10, TEMP_PERIOD = 1000, OLED_PERIOD = 200;
constexpr uint32_t BLE_PERIOD = 2000, BLE_ALARM_PERIOD = 1000;
constexpr uint32_t SERIAL_PERIOD = 2000, GPS_REPORT_PERIOD = 5000;
#if HAJICARE_CUSTOM_INTRO
  constexpr uint32_t INTRO_FRAME_MS = 55;
  constexpr uint32_t INTRO_FRAMES_TOTAL = HajiCareIntro::DURATION_MS;
#else
  constexpr uint32_t INTRO_FRAME_MS = 270, INTRO_FRAMES_TOTAL = 8 * INTRO_FRAME_MS;
#endif
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
Adafruit_SSD1306 screen(OLED_WIDTH, OLED_HEIGHT, &Wire, -1, 400000UL, 100000UL);
static_assert(OLED_WIDTH == 128 && OLED_HEIGHT == 64,
              "Asset intro dan antarmuka HajiCare memerlukan OLED SSD1306 128x64");

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
constexpr uint32_t AI_SAMPLE_RATE = 8000;      // 8 kHz Mono 16-bit PCM
constexpr size_t AI_PCM_SAMPLES_PER_PKT = 110; // 110 sampel x 2 byte = 220 byte
constexpr uint32_t AI_MAX_LISTEN_MS = 5000;    // Maks 5 detik
constexpr int AI_DIGITAL_GAIN_SHIFT = 13;

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
uint8_t aiMicLevel = 0;

constexpr uint8_t AI_WAVE_COLUMNS = 30;
uint8_t aiWaveHistory[AI_WAVE_COLUMNS] = {0};
uint8_t aiWaveCursor = 0;
uint32_t aiWaveLastSampleAt = 0;
constexpr uint32_t AI_WAVE_SAMPLE_MS = 35;

constexpr uint8_t AI_REPLY_WIDTH = 20;
constexpr uint8_t AI_REPLY_MAX_LINES = 10;
constexpr uint8_t AI_REPLY_VISIBLE_LINES = 4;
char aiReplyLines[AI_REPLY_MAX_LINES][AI_REPLY_WIDTH + 1] = {{0}};
uint8_t aiReplyLineCount = 0;
bool aiReplyTimedOut = false;
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

// Heart rate (MAX30102)
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

// Pedometer 3-Sumbu
uint32_t stepCount = 0;
float stepDistanceMeters = 0.0f;
constexpr float STRIDE_LENGTH_M = 0.65f;
constexpr float STEP_PEAK_G = 0.115f;
constexpr float STEP_VALLEY_G = 0.045f;
constexpr uint32_t STEP_MIN_INTERVAL_MS = 330;
constexpr uint32_t STEP_MAX_INTERVAL_MS = 1500;
constexpr uint32_t STEP_PEAK_TO_VALLEY_MIN_MS = 110;
constexpr uint32_t STEP_PEAK_TO_VALLEY_MAX_MS = 620;
constexpr uint8_t STEP_CONFIRM_CYCLES = 3;
constexpr uint32_t SENSOR_STARTUP_GUARD_MS = 3000;

float stepBaselineG = 1.0f;
float stepBandG = 0.0f;
float stepPeakG = 0.0f;
bool stepPeakArmed = false;
uint32_t stepPeakAt = 0;
uint32_t lastCandidateStepAt = 0;
uint8_t stepCadenceStreak = 0;

constexpr uint32_t MOTOR_SETTLE_MS = 500;
uint32_t lastMotorActivityAt = 0;
bool motorMotionQuarantine(uint32_t now);

// Fall state machine
enum FallState : uint8_t {
  FALL_MONITORING, FALL_LOW_G, FALL_POST_IMPACT, FALL_COUNTDOWN, FALL_ALERT, FALL_COOLDOWN
};
FallState fallState = FALL_MONITORING;

constexpr float FREEFALL_THRESHOLD_G = 0.55f;
constexpr uint32_t FREEFALL_MIN_DURATION_MS = 50;
constexpr float IMPACT_THRESHOLD_G = 2.35f;
constexpr float DIRECT_IMPACT_G = 2.65f;
constexpr float STRONG_IMPACT_G = 3.40f;
constexpr float DIRECT_ROTATION_DPS = 130.0f;
constexpr float STRONG_ROTATION_DPS = 150.0f;
constexpr float FREEFALL_ROTATION_DPS = 65.0f;
constexpr float DIRECT_POSTURE_DEG = 50.0f;
constexpr float STRONG_POSTURE_DEG = 45.0f;
constexpr float FREEFALL_POSTURE_DEG = 30.0f;
constexpr float STILL_GYRO_DPS = 15.0f;
constexpr float STILL_MIN_G = 0.87f;
constexpr float STILL_MAX_G = 1.13f;
constexpr uint32_t LOWG_TO_IMPACT_MS = 1100;
constexpr uint32_t AFTER_IMPACT_MS = 5000;
constexpr uint32_t STILL_REQUIRED_MS = 1800;
constexpr uint32_t POST_IMPACT_SETTLE_MS = 350;
constexpr uint32_t FALL_REJECT_GUARD_MS = 1000;
constexpr uint32_t CANCEL_WINDOW_MS = 10000;
constexpr uint32_t FALL_COOLDOWN_MS = 15000;

uint32_t lowGAt = 0, impactAt = 0, stillAt = 0, countdownAt = 0, cooldownAt = 0, fallRejectUntil = 0;
float peakG = 0, peakDps = 0;
bool hadLowG = false;

// Safe Radius state (Dinamis dari Aplikasi / Pendamping)
float safeRadiusMeters = 200.0f; // Default 200m jika belum ada setting masuk
bool safeRadiusConfigured = false;
uint32_t safeRadiusReceivedAt = 0;
portMUX_TYPE safeRadiusRxMux = portMUX_INITIALIZER_UNLOCKED;
bool radiusRxPending = false;
float radiusRxMeters = NAN;
volatile bool radiusNeedsResync = false;

float currentDistanceM = NAN;
float phoneReportedDistanceM = NAN;
uint32_t phoneReportedDistanceAt = 0;
double companionLat = NAN;
double companionLon = NAN;
uint32_t companionUpdatedAt = 0;
bool companionSeen = false;
float companionAccuracyM = NAN;
portMUX_TYPE companionPositionMux = portMUX_INITIALIZER_UNLOCKED;
constexpr uint32_t COMPANION_POSITION_TTL_MS = 15000;
constexpr float MAX_COMPANION_ACCURACY_M = 60.0f;
constexpr float MAX_BAND_HDOP = 6.0f;
constexpr float RADIUS_GPS_GUARD_M = 5.0f;
constexpr uint32_t RADIUS_CONFIRM_MS = 2500;
uint32_t radiusOverLimitSince = 0;

enum DistanceStatus : uint8_t {
  DIST_READY, DIST_BLE_OFF, DIST_BAND_NO_FIX, DIST_BAND_POOR,
  DIST_PHONE_MISSING, DIST_PHONE_STALE, DIST_PHONE_POOR
};
DistanceStatus distanceStatus = DIST_PHONE_MISSING;

bool validCoordinates(double lat, double lon) {
  return isfinite(lat) && isfinite(lon) && lat >= -90.0 && lat <= 90.0 &&
         lon >= -180.0 && lon <= 180.0 && !(lat == 0.0 && lon == 0.0);
}

double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
  constexpr double rad = 0.017453292519943295769;
  constexpr double earthRadiusMeters = 6371000.0;
  const double dLat = (lat2 - lat1) * rad;
  const double dLon = (lon2 - lon1) * rad;
  const double aSin = sin(dLat * 0.5);
  const double bSin = sin(dLon * 0.5);
  double a = aSin * aSin + cos(lat1 * rad) * cos(lat2 * rad) * bSin * bSin;
  if (a < 0.0) a = 0.0;
  if (a > 1.0) a = 1.0;
  return 2.0 * earthRadiusMeters * atan2(sqrt(a), sqrt(1.0 - a));
}

const char* distanceStatusName(DistanceStatus s) {
  switch (s) {
    case DIST_READY:          return "READY";
    case DIST_BLE_OFF:        return "BLE_OFF";
    case DIST_BAND_NO_FIX:    return "BAND_NO_GPS";
    case DIST_BAND_POOR:      return "BAND_GPS_WEAK";
    case DIST_PHONE_MISSING:  return "PHONE_NO_GPS";
    case DIST_PHONE_STALE:    return "PHONE_GPS_STALE";
    case DIST_PHONE_POOR:     return "PHONE_GPS_WEAK";
  }
  return "UNKNOWN";
}

bool safeRadiusEnabled = true;
bool appForcedRadiusAlert = false;
bool radiusAlertActive = false;
uint32_t radiusSnoozeUntil = 0;
uint32_t radiusUiChangedAt = 0;
constexpr uint32_t RADIUS_SNOOZE_MS = 30000;

// Action Button
bool sosActive = false;
uint32_t buttonDebounceAt = 0, buttonDownAt = 0;
bool buttonRawLast = HIGH, buttonStable = HIGH, buttonLongHandled = false;
bool pendingSingleClick = false;
uint32_t lastClickReleaseAt = 0;
constexpr uint32_t BUTTON_DEBOUNCE_MS = 40;
constexpr uint32_t DOUBLE_CLICK_MS    = 280;
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
void layoutAiReply();

void layoutAiReply() {
  aiReplyLineCount = 0;
  const char* p = aiDisplayText;
  while (*p && aiReplyLineCount < AI_REPLY_MAX_LINES) {
    while (*p == ' ' || *p == '\r' || *p == '\t') ++p;
    if (*p == '\n') { ++p; continue; }
    if (!*p) break;

    uint8_t length = 0;
    uint8_t lastSpace = 0;
    while (p[length] && p[length] != '\n' && length < AI_REPLY_WIDTH) {
      if (p[length] == ' ') lastSpace = length;
      ++length;
    }
    if (length == AI_REPLY_WIDTH && p[length] && p[length] != ' ' &&
        p[length] != '\n' && lastSpace >= 7) {
      length = lastSpace;
    }
    if (length == 0) { ++p; continue; }
    memcpy(aiReplyLines[aiReplyLineCount], p, length);
    aiReplyLines[aiReplyLineCount][length] = '\0';
    ++aiReplyLineCount;
    p += length;
    while (*p == ' ') ++p;
    if (*p == '\n') ++p;
  }
  if (aiReplyLineCount == 0) {
    strcpy(aiReplyLines[0], "Balasan kosong");
    aiReplyLineCount = 1;
  }
}

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
    sendSoon();
    return;
  }

  if (!bleConnected) {
    currentPage = PAGE_AI;
    bootFinished = true;
    lastPageAt = millis();
    aiState = AI_IDLE;
    snprintf(aiDisplayText, sizeof(aiDisplayText), "Sambungkan aplikasi HajiCare terlebih dahulu");
    vibrate(HAPTIC_WARNING);
    Serial.println("[AI VOICE] Belum terhubung ke Flutter; rekaman tidak dimulai.");
    return;
  }

  i2s_zero_dma_buffer(I2S_PORT);
  memset(aiWaveHistory, 0, sizeof(aiWaveHistory));
  aiWaveCursor = 0;
  aiWaveLastSampleAt = millis();
  aiReplyTimedOut = false;
  aiListening = true;
  aiState = AI_LISTENING;
  aiListenStartAt = millis();
  aiStateChangedAt = aiListenStartAt;
  aiBytesSent = 0;
  aiMicLevel = 0;
  currentPage = PAGE_AI;
  bootFinished = true;
  lastPageAt = aiListenStartAt;
  pendingJsonLen = 0;

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
    if (aiState == AI_PROCESSING && (now - aiStateChangedAt >= 15000)) {
      aiState = AI_IDLE;
      aiReplyTimedOut = true;
      snprintf(aiDisplayText, sizeof(aiDisplayText), "Belum ada balasan aplikasi; coba lagi");
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

  uint8_t instLevel = (uint8_t)constrain((peakAbs * 100L) / 18000L, 0L, 100L);
  aiMicLevel = (uint8_t)((aiMicLevel * 2 + instLevel * 3) / 5);

  if (now - aiWaveLastSampleAt >= AI_WAVE_SAMPLE_MS) {
    aiWaveHistory[aiWaveCursor] = aiMicLevel;
    aiWaveCursor = (aiWaveCursor + 1) % AI_WAVE_COLUMNS;
    aiWaveLastSampleAt = now;
  }

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
// FUNGSI MPU6050 & PEDOMETER 3-SUMBU
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

  writeRegister(0x1A, 0x04);
  writeRegister(0x1B, 0x08);
  writeRegister(0x1C, 0x10);
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

  gx = gxRaw / 65.5f;
  gy = gyRaw / 65.5f;
  gz = gzRaw / 65.5f;

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

void clearStepCandidate() {
  stepPeakArmed = false;
  stepPeakG = 0.0f;
  stepPeakAt = 0;
  lastCandidateStepAt = 0;
  stepCadenceStreak = 0;
}

void resetSteps() {
  stepCount = 0;
  stepDistanceMeters = 0.0f;
  clearStepCandidate();
  stepBaselineG = totalG;
  stepBandG = 0.0f;
  Serial.println("[STEP] Reset 0; cadence history cleared.");
  sendSoon();
}

void registerStepCandidate(uint32_t now, float peakVal) {
  if (lastCandidateStepAt == 0 || (now - lastCandidateStepAt > STEP_MAX_INTERVAL_MS) ||
      (now - lastCandidateStepAt < STEP_MIN_INTERVAL_MS)) {
    stepCadenceStreak = 1;
  } else if (stepCadenceStreak < 250) {
    ++stepCadenceStreak;
  }
  lastCandidateStepAt = now;
  if (stepCadenceStreak == STEP_CONFIRM_CYCLES) {
    stepCount += STEP_CONFIRM_CYCLES;
  } else if (stepCadenceStreak > STEP_CONFIRM_CYCLES) {
    ++stepCount;
  }
  stepDistanceMeters = stepCount * STRIDE_LENGTH_M;
  if (stepCadenceStreak >= STEP_CONFIRM_CYCLES) {
    Serial.printf("[STEP] %lu confirmed | wave %.3fg | cadence streak %u\n",
                  (unsigned long)stepCount, peakVal, (unsigned)stepCadenceStreak);
  }
}

bool motorMotionQuarantine(uint32_t now) {
  return motorOn || (lastMotorActivityAt != 0 &&
                     (uint32_t)(now - lastMotorActivityAt) < MOTOR_SETTLE_MS);
}

void updateStepCounter(uint32_t now) {
  if (!mpuReady || !gravityInitialized) return;
  if ((bootAt != 0 && now - bootAt < SENSOR_STARTUP_GUARD_MS) ||
      motorMotionQuarantine(now) || fallState != FALL_MONITORING) {
    clearStepCandidate();
    stepBaselineG = totalG;
    stepBandG = 0.0f;
    return;
  }
  stepBaselineG += 0.018f * (totalG - stepBaselineG);
  const float deviation = totalG - stepBaselineG;
  stepBandG += 0.22f * (deviation - stepBandG);

  if (stepCadenceStreak > 0 && now - lastCandidateStepAt > STEP_MAX_INTERVAL_MS) {
    stepCadenceStreak = 0;
    lastCandidateStepAt = 0;
  }
  if (totalG > 1.9f || totalG < 0.45f || totalDps > 220.0f) {
    clearStepCandidate();
    return;
  }

  if (!stepPeakArmed) {
    if (stepBandG >= STEP_PEAK_G) {
      stepPeakArmed = true;
      stepPeakAt = now;
      stepPeakG = stepBandG;
    }
    return;
  }
  if (stepBandG > stepPeakG) stepPeakG = stepBandG;
  const uint32_t pulseWidth = now - stepPeakAt;
  if (pulseWidth > STEP_PEAK_TO_VALLEY_MAX_MS) {
    stepPeakArmed = false;
    return;
  }
  if (pulseWidth >= STEP_PEAK_TO_VALLEY_MIN_MS && stepBandG <= -STEP_VALLEY_G) {
    registerStepCandidate(now, stepPeakG);
    stepPeakArmed = false;
    stepPeakG = 0;
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
  if (motorOn != on) lastMotorActivityAt = millis();
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

  // Pola getar 3 ketukan ritmik Safe Radius
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
  clearStepCandidate();
  Serial.printf("[FALL] Candidate: %.2fg gyro %.0fdps lowG=%d (awaiting posture + stillness)\n",
                peakG, peakDps, hadLowG ? 1 : 0);
}

void rejectFallCandidate(uint32_t now, const char* why) {
  fallState = FALL_MONITORING;
  lowGAt = impactAt = stillAt = 0;
  hadLowG = false;
  peakG = peakDps = 0;
  fallRejectUntil = now + FALL_REJECT_GUARD_MS;
  clearStepCandidate();
  Serial.printf("[FALL] Candidate rejected: %s\n", why);
}

void updateFall(uint32_t now) {
  if (!mpuReady || !gravityInitialized || now - lastMpuOK > 200) return;

  if (fallState == FALL_ALERT) return;
  if (fallState == FALL_COOLDOWN) {
    if (now - cooldownAt >= FALL_COOLDOWN_MS) {
      fallState = FALL_MONITORING;
      fallRejectUntil = now + FALL_REJECT_GUARD_MS;
      Serial.println("[FALL] Monitoring restored after cooldown.");
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

  if ((bootAt != 0 && now - bootAt < SENSOR_STARTUP_GUARD_MS) ||
      motorMotionQuarantine(now)) {
    if (fallState == FALL_LOW_G || fallState == FALL_POST_IMPACT) {
      rejectFallCandidate(now, "motor/settling");
    }
    return;
  }
  if ((int32_t)(fallRejectUntil - now) > 0) return;

  if (fallState == FALL_MONITORING) {
    if (totalG > 0.93f && totalG < 1.07f && totalDps < 10.0f) {
      constexpr float adapt = 0.007f;
      refX += adapt * (gravityX - refX);
      refY += adapt * (gravityY - refY);
      refZ += adapt * (gravityZ - refZ);
    }
    if (totalG < FREEFALL_THRESHOLD_G) {
      fallState = FALL_LOW_G;
      lowGAt = now;
      peakG = peakDps = 0;
    } else if (totalG >= DIRECT_IMPACT_G && totalDps >= DIRECT_ROTATION_DPS) {
      beginPostImpact(now, false);
    }
    return;
  }

  if (fallState == FALL_LOW_G) {
    const uint32_t elapsed = now - lowGAt;
    const bool lowGConfirmed = elapsed >= FREEFALL_MIN_DURATION_MS;
    if (totalG >= IMPACT_THRESHOLD_G && lowGConfirmed && elapsed <= LOWG_TO_IMPACT_MS) {
      beginPostImpact(now, true);
    } else if ((totalG > 0.85f && !lowGConfirmed) || elapsed > LOWG_TO_IMPACT_MS) {
      rejectFallCandidate(now, "low-g too brief or no impact");
    }
    return;
  }

  if (fallState == FALL_POST_IMPACT) {
    if (totalG > peakG) peakG = totalG;
    if (totalDps > peakDps) peakDps = totalDps;
    const float angle = postureDelta();
    const bool canBeStill = (now - impactAt >= POST_IMPACT_SETTLE_MS);
    const bool still = canBeStill && totalG >= STILL_MIN_G &&
                       totalG <= STILL_MAX_G && totalDps < STILL_GYRO_DPS;
    if (still) {
      if (stillAt == 0) stillAt = now;
    } else {
      stillAt = 0;
    }
    const bool stillConfirmed = stillAt && now - stillAt >= STILL_REQUIRED_MS;
    const bool freefallSequence = hadLowG && peakG >= IMPACT_THRESHOLD_G &&
      (peakDps >= FREEFALL_ROTATION_DPS || angle >= FREEFALL_POSTURE_DEG);
    const bool directSequence = !hadLowG && peakG >= DIRECT_IMPACT_G &&
      peakDps >= DIRECT_ROTATION_DPS && angle >= DIRECT_POSTURE_DEG;
    const bool strongSequence = !hadLowG && peakG >= STRONG_IMPACT_G &&
      peakDps >= STRONG_ROTATION_DPS && angle >= STRONG_POSTURE_DEG;

    if (stillConfirmed && (freefallSequence || directSequence || strongSequence)) {
      if (aiListening) stopAiListening(false);
      clearStepCandidate();
      fallState = FALL_COUNTDOWN;
      countdownAt = now;
      Serial.printf("[FALL] VERIFIED candidate: %.2fg gyro %.0fdps angle %.1fdeg lowG %d. Countdown.\n",
                    peakG, peakDps, angle, hadLowG ? 1 : 0);
      vibrate(HAPTIC_EMERGENCY);
      sendSoon();
      return;
    }
    if (now - impactAt >= AFTER_IMPACT_MS) {
      Serial.printf("[FALL] Not verified: peak=%.2fg gyro=%.0fdps angle=%.1fdeg still=%d\n",
                    peakG, peakDps, angle, stillConfirmed ? 1 : 0);
      rejectFallCandidate(now, "requirements not met");
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
            pendingSingleClick = false;
            stopAiListening(true);
          } else if (pendingSingleClick && (now - lastClickReleaseAt <= DOUBLE_CLICK_MS)) {
            pendingSingleClick = false;
            startAiListening();
          } else {
            pendingSingleClick = true;
            lastClickReleaseAt = now;
            vibrate(HAPTIC_TAP);
          }
        }
      }
    }
  }

  if (pendingSingleClick && buttonStable == HIGH && (now - lastClickReleaseAt > DOUBLE_CLICK_MS)) {
    pendingSingleClick = false;
    bootFinished = true;
    currentPage = (currentPage + 1) % TOTAL_PAGES;
    lastPageAt = now;
    sendSoon(); // Langsung sinkronkan halaman OLED terbaru ke aplikasi Flutter
    Serial.printf("[ACTION BUTTON] Pindah ke halaman OLED %u\n", (unsigned)currentPage);
  }

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
// MAX30102 HEART RATE
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
bool parseStrictDouble(String token, double &out) {
  token.trim();
  if (token.length() == 0) return false;
  char *end = nullptr;
  const char* begin = token.c_str();
  double parsed = strtod(begin, &end);
  if (end == begin || *end != '\0' || !isfinite(parsed)) return false;
  out = parsed;
  return true;
}

bool queueFlutterRadius(double meters) {
  if (!isfinite(meters) || meters < 0.0 || meters > 5000.0 ||
      (meters > 0.0 && meters < 1.0)) return false;
  portENTER_CRITICAL(&safeRadiusRxMux);
  radiusRxMeters = (float)meters;
  radiusRxPending = true;
  portEXIT_CRITICAL(&safeRadiusRxMux);
  return true;
}

void applyFlutterRadiusUpdate(uint32_t now) {
  if (radiusNeedsResync) {
    radiusNeedsResync = false;
    safeRadiusConfigured = false;
    safeRadiusEnabled = false;
    safeRadiusMeters = 200.0f; // Standby default
    appForcedRadiusAlert = false;
    radiusOverLimitSince = 0;
    radiusAlertActive = false;
    if (hapticPattern == HAPTIC_SAFE_RADIUS) {
      hapticPattern = HAPTIC_NONE;
      motorWrite(false);
    }
    requestBleNow = true;
    Serial.println("[RADIUS] BLE session ended; standby safe radius");
  }

  float candidate = NAN;
  bool hasCandidate = false;
  portENTER_CRITICAL(&safeRadiusRxMux);
  if (radiusRxPending) {
    candidate = radiusRxMeters;
    hasCandidate = true;
    radiusRxPending = false;
  }
  portEXIT_CRITICAL(&safeRadiusRxMux);
  if (!hasCandidate) return;

  const bool changed = !safeRadiusConfigured ||
      !isfinite(safeRadiusMeters) || fabsf(safeRadiusMeters - candidate) >= 0.01f;
  safeRadiusConfigured = true;
  safeRadiusMeters = candidate;
  safeRadiusEnabled = candidate >= 1.0f;
  safeRadiusReceivedAt = now;
  if (changed) {
    radiusUiChangedAt = now;
    radiusOverLimitSince = 0;
  }

  if (!safeRadiusEnabled) {
    radiusAlertActive = false;
    appForcedRadiusAlert = false;
    if (hapticPattern == HAPTIC_SAFE_RADIUS) {
      hapticPattern = HAPTIC_NONE;
      motorWrite(false);
    }
  }
  requestBleNow = true;
  Serial.printf("[RADIUS] Diterima dari Flutter -> %s %.1f meter\n",
                safeRadiusEnabled ? "ENABLED" : "DISABLED", safeRadiusMeters);
}

bool extractJsonDoublePrecise(const String &src, const char *key, double &out) {
  const String needle = String("\"") + key + "\"";
  const int idx = src.indexOf(needle);
  if (idx < 0) return false;
  const int colon = src.indexOf(':', idx + needle.length());
  if (colon < 0) return false;
  int a = colon + 1;
  while (a < (int)src.length() && (src[a] == ' ' || src[a] == '\t')) ++a;
  int b = a;
  while (b < (int)src.length() && src[b] != ',' && src[b] != '}' && src[b] != ' ' && src[b] != '\n') ++b;
  return parseStrictDouble(src.substring(a, b), out);
}

void acceptCompanionGps(double lat, double lon, float accuracy, bool hasAccuracy) {
  if (!validCoordinates(lat, lon)) {
    Serial.println("[DIST] Koordinat HP tidak valid; ditolak");
    return;
  }
  if (hasAccuracy && (!isfinite(accuracy) || accuracy < 0.0f)) {
    Serial.println("[DIST] Nilai akurasi HP tidak valid; ditolak");
    return;
  }
  portENTER_CRITICAL(&companionPositionMux);
  companionLat = lat;
  companionLon = lon;
  companionAccuracyM = hasAccuracy ? accuracy : NAN;
  companionUpdatedAt = millis();
  companionSeen = true;
  portEXIT_CRITICAL(&companionPositionMux);
}

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
  aiReplyTimedOut = false;
  strncpy(aiDisplayText, replyText.c_str(), sizeof(aiDisplayText) - 1);
  aiDisplayText[sizeof(aiDisplayText) - 1] = '\0';
  layoutAiReply();
  currentPage = PAGE_AI;
  bootFinished = true;
  lastPageAt = millis();
  vibrate(HAPTIC_CONFIRM);
  requestBleNow = true;
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

  // Kontrol Mikrofon AI
  if (cmd == "AI_LISTEN:1" || cmd == "AI_START") {
    startAiListening();
    return;
  }
  if (cmd == "AI_LISTEN:0" || cmd == "AI_STOP") {
    stopAiListening(true);
    return;
  }

  // Tampilkan Jawaban AI di OLED
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
      requestBleNow = true;
    }
    return;
  }

  // Ubah batas Safe Radius Dinamis (Otoritas dari Pendamping)
  if (cmd.startsWith("RADIUS:") || cmd.startsWith("SAFE_RADIUS:")) {
    const int colon = cmd.indexOf(':');
    double radiusFromApp = NAN;
    if (parseStrictDouble(cmd.substring(colon + 1), radiusFromApp)) {
      if (queueFlutterRadius(radiusFromApp)) {
        safeRadiusConfigured = true;
        safeRadiusEnabled = (radiusFromApp >= 1.0);
        Serial.printf("[RADIUS] Konfigurasi radius masuk: %.1f m\n", radiusFromApp);
      }
    }
    return;
  }

  // TRIGGER ALERT LANGSUNG DARI APLIKASI
  if (cmd.startsWith("RADIUS_ALERT:") || cmd.startsWith("OUT_OF_RANGE:")) {
    int colon = cmd.indexOf(':');
    String val = cmd.substring(colon + 1);
    val.toUpperCase();
    bool active = (val == "1" || val == "TRUE" || val == "ON");

    if (active && !safeRadiusConfigured) {
      safeRadiusMeters = 200.0f;
      safeRadiusConfigured = true;
      safeRadiusEnabled = true;
      Serial.println("[SAFE RADIUS] Auto-configured 200m fallback dari RADIUS_ALERT");
    }

    appForcedRadiusAlert = active;
    if (active) radiusSnoozeUntil = 0;
    requestBleNow = true;
    return;
  }

  if (cmd.startsWith("DIST:")) {
    // Mendukung format "DIST:14.5" maupun "DIST:14.5,200"
    int colon = cmd.indexOf(':');
    String payload = cmd.substring(colon + 1);
    int comma = payload.indexOf(',');
    String distToken = (comma > 0) ? payload.substring(0, comma) : payload;
    double d = NAN;
    if (parseStrictDouble(distToken, d) && isfinite(d) && d >= 0.0) {
      portENTER_CRITICAL(&companionPositionMux);
      phoneReportedDistanceM = (float)d;
      phoneReportedDistanceAt = millis();
      portEXIT_CRITICAL(&companionPositionMux);
      currentDistanceM = (float)d;
      distanceStatus = DIST_READY;
    }
    if (comma > 0) {
      double rad = NAN;
      if (parseStrictDouble(payload.substring(comma + 1), rad)) {
        if (queueFlutterRadius(rad)) {
          safeRadiusConfigured = true;
          safeRadiusEnabled = (rad >= 1.0);
        }
      }
    }
    return;
  }

  // Titik GPS Pendamping Realtime
  if (cmd.startsWith("COMP_GPS:") || cmd.startsWith("COMP:") || cmd.startsWith("COMPANION:")) {
    const bool hasAccuracy = cmd.startsWith("COMP_GPS:");
    const int colon = cmd.indexOf(':');
    const String payload = cmd.substring(colon + 1);
    const int c1 = payload.indexOf(',');
    const int c2 = (c1 < 0) ? -1 : payload.indexOf(',', c1 + 1);
    if (c1 <= 0) return;

    double lat = NAN, lon = NAN, third = NAN;
    const String latToken = payload.substring(0, c1);
    const String lonToken = c2 > c1 ? payload.substring(c1 + 1, c2) : payload.substring(c1 + 1);
    if (!parseStrictDouble(latToken, lat) || !parseStrictDouble(lonToken, lon)) return;
    if (c2 > c1) {
      if (!parseStrictDouble(payload.substring(c2 + 1), third)) return;
    }
    if (!validCoordinates(lat, lon)) return;
    if (hasAccuracy) {
      acceptCompanionGps(lat, lon, (float)third, true);
    } else {
      acceptCompanionGps(lat, lon, NAN, false);
    }
    return;
  }

  // Format JSON
  if (cmd.startsWith("{")) {
    double radiusFromApp = NAN;
    if (extractJsonDoublePrecise(cmd, "safeRadius", radiusFromApp) ||
        extractJsonDoublePrecise(cmd, "radius", radiusFromApp)) {
      if (queueFlutterRadius(radiusFromApp)) {
        safeRadiusConfigured = true;
        safeRadiusEnabled = (radiusFromApp >= 1.0);
      }
    }
    double cLat = NAN, cLon = NAN, cAccuracy = NAN;
    if (extractJsonDoublePrecise(cmd, "companionLat", cLat) &&
        extractJsonDoublePrecise(cmd, "companionLon", cLon)) {
      const bool hasAccuracy = extractJsonDoublePrecise(cmd, "companionAccuracyM", cAccuracy);
      if (!hasAccuracy || cAccuracy >= 0.0) {
        acceptCompanionGps(cLat, cLon, (float)cAccuracy, hasAccuracy);
      }
    }
    String aiText;
    if (extractJsonString(cmd, "aiReply", aiText) || extractJsonString(cmd, "aiText", aiText)) {
      if (aiText.length() > 0) showAiReplyOnOled(aiText);
    }
    if (cmd.indexOf("\"radiusAlert\":true") >= 0 || cmd.indexOf("\"outOfRange\":true") >= 0) {
      if (!safeRadiusConfigured) {
        safeRadiusMeters = 200.0f;
        safeRadiusConfigured = true;
        safeRadiusEnabled = true;
      }
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
    Serial.println("[BLE] Gelang terhubung ke HP HajiCare.");
  }
  void onDisconnect(BLEServer *s) override {
    (void)s;
    bleConnected = false;
    bleRestart = true;
    bleDisconnectedAt = millis();
    radiusNeedsResync = true;
    portENTER_CRITICAL(&safeRadiusRxMux);
    radiusRxPending = false;
    portEXIT_CRITICAL(&safeRadiusRxMux);
    portENTER_CRITICAL(&companionPositionMux);
    companionSeen = false;
    companionUpdatedAt = 0;
    phoneReportedDistanceM = NAN;
    phoneReportedDistanceAt = 0;
    portEXIT_CRITICAL(&companionPositionMux);
    pendingJsonLen = 0;
    negotiatedMTU = 23;
    if (aiListening) stopAiListening(false);
    Serial.println("[BLE] Gelang terputus dari HP; memulai ulang advertising.");
  }
#if defined(CONFIG_BLUEDROID_ENABLED)
  void onMtuChanged(BLEServer *s, esp_ble_gatts_cb_param_t *event) override {
    (void)s;
    negotiatedMTU = event->mtu.mtu;
    pendingJsonLen = 0;
    requestBleNow = true;
    Serial.printf("[BLE] ATT MTU=%u\n", (unsigned)negotiatedMTU);
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
  Serial.println("[BLE] Advertising started: " DEVICE_NAME);
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
  if (aiListening) return;

  // Periksa MTU peer secara dinamis jika onMtuChanged belum terpicu
  if (bleServer && negotiatedMTU <= 23) {
    uint16_t peerMtu = bleServer->getPeerMTU(bleServer->getConnId());
    if (peerMtu > 23) {
      negotiatedMTU = peerMtu;
    }
  }

  const bool urgent = sosActive || fallState == FALL_ALERT || fallState == FALL_COUNTDOWN || radiusAlertActive;
  const uint32_t interval = urgent ? BLE_ALARM_PERIOD : BLE_PERIOD;

  // Jangan membatalkan fragmen JSON yang sedang dikirim agar paket tidak pernah terpotong
  if (pendingJsonLen) {
    sendNextFragment(now);
    return;
  }
  if (!requestBleNow && now - lastBleAt < interval) return;
  requestBleNow = false;
  lastBleAt = now;

  char lat[24], lon[24], temp[18], motion[18], dist[18], radiusJson[20];
  if (safeRadiusConfigured && isfinite(safeRadiusMeters))
    snprintf(radiusJson, sizeof(radiusJson), "%.1f", safeRadiusMeters);
  else
    strcpy(radiusJson, "null");
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

  if (distanceStatus == DIST_READY && isfinite(currentDistanceM))
    snprintf(dist, sizeof(dist), "%.1f", currentDistanceM);
  else
    strcpy(dist, "null");

  char json[512];
  int n = snprintf(json, sizeof(json),
    "{\"braceletId\":\"%s\",\"heartRate\":%d,\"fingerDetected\":%s,\"irRaw\":%ld,"
    "\"temperatureC\":%s,\"motionG\":%s,\"steps\":%lu,\"stepDistanceM\":%.1f,"
    "\"gpsFix\":%s,\"satellites\":%u,\"latitude\":%s,\"longitude\":%s,"
    "\"fallStatus\":\"%s\",\"sos\":%s,\"safeRadius\":%s,\"distanceM\":%s,"
    "\"distanceStatus\":\"%s\",\"radiusAlert\":%s,\"aiListening\":%s,\"page\":%u}",
    BRACELET_ID, (opticalContact ? bpm : 0), opticalContact ? "true" : "false", irRaw,
    temp, motion, (unsigned long)stepCount, stepDistanceMeters,
    gpsFix ? "true" : "false", (unsigned)gpsSatellites,
    lat, lon, fallText(), sosActive ? "true" : "false",
    radiusJson, dist,
    distanceStatusName(distanceStatus),
    radiusAlertActive ? "true" : "false", aiListening ? "true" : "false",
    (unsigned)currentPage
  );

  if (n <= 0 || n >= (int)sizeof(json)) return;

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
// UI OLED 128x64
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

void uiBluetoothGlyph(uint8_t x, uint8_t y, bool connected, uint32_t now) {
  if (!connected && (now / 550) % 2 == 0) return;
  screen.drawLine(x + 3, y, x + 3, y + 8, SSD1306_WHITE);
  screen.drawLine(x + 3, y, x + 6, y + 2, SSD1306_WHITE);
  screen.drawLine(x + 6, y + 2, x + 1, y + 6, SSD1306_WHITE);
  screen.drawLine(x + 1, y + 2, x + 6, y + 6, SSD1306_WHITE);
  screen.drawLine(x + 6, y + 6, x + 3, y + 8, SSD1306_WHITE);
}

void header() {
  const uint32_t now = millis();
  label(3, 2, "HAJICARE");
  uiBluetoothGlyph(90, 2, bleConnected, now);
  label(101, 2, bleConnected ? "ON" : "--");
  screen.drawFastHLine(0, 11, 128, SSD1306_WHITE);
}

void footer(uint8_t page) {
  screen.drawFastHLine(0, 54, 128, SSD1306_WHITE);
  char number[8];
  snprintf(number, sizeof(number), "%u/7", (unsigned)(page + 1));
  label(3, 56, number);
  for (uint8_t i = 0; i < TOTAL_PAGES; ++i) {
    const int x = 51 + i * 9;
    if (page == i) {
      screen.fillCircle(x, 59, 2, SSD1306_WHITE);
      screen.drawCircle(x, 59, 3, SSD1306_WHITE);
    } else {
      screen.drawPixel(x, 59, SSD1306_WHITE);
    }
  }
}

void uiHeartIcon(int16_t x, int16_t y, uint32_t now, bool live) {
  const uint8_t phase = (now / 300) % 4;
  heartGlyph(x, y, live && phase < 2);
  if (live && phase == 0) {
    screen.drawCircle(x, y, 11, SSD1306_WHITE);
  }
}

void uiGpsIcon(int16_t x, int16_t y, uint32_t now, bool lock) {
  screen.drawCircle(x, y, 12, SSD1306_WHITE);
  screen.drawCircle(x, y, 5, SSD1306_WHITE);
  screen.drawFastHLine(x - 15, y, 7, SSD1306_WHITE);
  screen.drawFastHLine(x + 8, y, 7, SSD1306_WHITE);
  screen.drawFastVLine(x, y - 15, 7, SSD1306_WHITE);
  screen.drawFastVLine(x, y + 8, 7, SSD1306_WHITE);
  if (lock) {
    screen.fillCircle(x, y, 2, SSD1306_WHITE);
    if ((now / 700) % 2 == 0) screen.drawCircle(x, y, 9, SSD1306_WHITE);
  } else {
    const uint8_t p = (now / 180) % 8;
    static const int8_t dx[8] = {0, 7, 10, 7, 0, -7, -10, -7};
    static const int8_t dy[8] = {-10, -7, 0, 7, 10, 7, 0, -7};
    screen.fillCircle(x + dx[p], y + dy[p], 2, SSD1306_WHITE);
  }
}

void drawHR(uint32_t now) {
  header();
  label(3, 15, opticalContact ? "DETAK JANTUNG" : "MENUNGGU KULIT");
  char val[16];
  if (opticalContact && bpm > 0) snprintf(val, sizeof(val), "%d", bpm);
  else strcpy(val, "--");
  label(4, 26, val, 2);
  label(54, 32, "BPM");
  uiHeartIcon(106, 34, now, opticalContact && bpm > 0);
  label(3, 45, opticalContact ? "SENSOR AKTIF" : "PASANG GELANG");
  footer(0);
}

void drawGPS(uint32_t now) {
  header();
  label(3, 14, gpsFix ? "GPS TERHUBUNG" : "MENCARI SATELIT");
  char str[26];
  snprintf(str, sizeof(str), "SAT: %u", (unsigned)gpsSatellites);
  label(3, 24, str);
  if (gpsFix) {
    snprintf(str, sizeof(str), "%.5f", gps.location.lat());
    label(3, 35, str);
    snprintf(str, sizeof(str), "%.5f", gps.location.lng());
    label(3, 45, str);
  } else {
    label(3, 35, "LAT --");
    label(3, 45, "LON --");
  }
  uiGpsIcon(106, 34, now, gpsFix);
  footer(1);
}

void uiThermometer(int16_t x, int16_t y, uint32_t now, bool valid) {
  screen.drawRoundRect(x - 4, y - 15, 8, 24, 3, SSD1306_WHITE);
  screen.drawCircle(x, y + 12, 6, SSD1306_WHITE);
  if (valid) {
    const int fill = constrain((int)((temperatureC - 10.0f) * 16.0f / 35.0f), 0, 16);
    if (fill > 0) screen.fillRect(x - 2, y + 6 - fill, 4, fill + 3, SSD1306_WHITE);
    screen.fillCircle(x, y + 12, 4, SSD1306_WHITE);
    if ((now / 550) % 2 == 0) screen.drawPixel(x + 8, y - 8, SSD1306_WHITE);
  } else {
    screen.drawLine(x - 7, y - 17, x + 8, y + 17, SSD1306_WHITE);
  }
}

void drawTempPage(uint32_t now) {
  header();
  label(3, 15, "SUHU SENSOR");
  const bool valid = mcpReady && isfinite(temperatureC) && now - lastTempOK <= 5000;
  char line[22];
  if (valid) snprintf(line, sizeof(line), "%.1f", temperatureC);
  else strcpy(line, "--.-");
  label(3, 27, line, 2);
  label(66, 33, "C");
  uiThermometer(107, 30, now, valid);
  label(3, 45, valid ? "MCP9808 LIVE" : "DATA BELUM ADA");
  footer(2);
}

void uiMotionIcon(int16_t x, int16_t y, uint32_t now) {
  screen.drawCircle(x, y, 14, SSD1306_WHITE);
  screen.drawCircle(x, y, 7, SSD1306_WHITE);
  screen.drawFastHLine(x - 17, y, 5, SSD1306_WHITE);
  screen.drawFastHLine(x + 12, y, 5, SSD1306_WHITE);
  static const int8_t dx[8] = {0, 6, 9, 6, 0, -6, -9, -6};
  static const int8_t dy[8] = {-9, -6, 0, 6, 9, 6, 0, -6};
  const uint8_t p = (now / 210) % 8;
  screen.fillCircle(x + dx[p], y + dy[p], 2, SSD1306_WHITE);
}

void drawMotion(uint32_t now) {
  header();
  label(3, 14, "MONITOR JATUH");
  char val[22];
  if (mpuReady) snprintf(val, sizeof(val), "%.2f", totalG);
  else strcpy(val, "--.--");
  label(3, 26, val, 2);
  label(63, 32, "g");
  uiMotionIcon(105, 33, now);
  const bool normal = fallState == FALL_MONITORING;
  label(3, 45, !mpuReady ? "MPU OFFLINE" : normal ? "MEMANTAU" : "CEK KONDISI");
  footer(3);
}

void formatCompanionDistance(char* out, size_t outSize) {
  if (distanceStatus != DIST_READY || !isfinite(currentDistanceM)) {
    snprintf(out, outSize, "HP: --");
  } else if (currentDistanceM >= 1000.0f) {
    snprintf(out, outSize, "HP: %.2f km", currentDistanceM / 1000.0f);
  } else {
    snprintf(out, outSize, "HP: %.0f m", currentDistanceM);
  }
}

void uiFootprint(int16_t x, int16_t y, uint32_t now, bool recentlyStepped) {
  const bool lift = recentlyStepped && (now / 180) % 2 == 0;
  screen.drawRoundRect(x - 11, y - 12 - (lift ? 2 : 0), 8, 15, 3, SSD1306_WHITE);
  screen.fillCircle(x - 7, y - 13 - (lift ? 2 : 0), 2, SSD1306_WHITE);
  screen.drawRoundRect(x + 3, y - 1 + (lift ? 2 : 0), 8, 15, 3, SSD1306_WHITE);
  screen.fillCircle(x + 7, y - 2 + (lift ? 2 : 0), 2, SSD1306_WHITE);
}

void drawStepsPage(uint32_t now) {
  static uint32_t prevSteps = 0;
  static uint32_t lastRealStepAt = 0;
  if (stepCount != prevSteps) {
    prevSteps = stepCount;
    lastRealStepAt = now;
  }
  header();
  label(3, 14, "LANGKAH & JARAK");
  char num[20];
  if (stepCount > 99999UL) snprintf(num, sizeof(num), "%.1fk", stepCount / 1000.0f);
  else snprintf(num, sizeof(num), "%lu", (unsigned long)stepCount);
  label(3, 25, num, 2);
  uiFootprint(108, 34, now, lastRealStepAt > 0 && now - lastRealStepAt <= 650);
  char dist[28];
  formatCompanionDistance(dist, sizeof(dist));
  label(3, 45, dist);
  if (distanceStatus == DIST_READY) screen.fillCircle(91, 47, 2, SSD1306_WHITE);
  else if ((now / 500) % 2 == 0) screen.drawCircle(91, 47, 2, SSD1306_WHITE);
  footer(4);
}

void uiRadiusRadar(int16_t cx, int16_t cy, uint32_t now, bool active, bool validGps) {
  screen.drawCircle(cx, cy, 14, SSD1306_WHITE);
  screen.drawCircle(cx, cy, 5, SSD1306_WHITE);
  screen.fillCircle(cx, cy, 2, SSD1306_WHITE);
  if (!active) {
    screen.drawLine(cx - 11, cy + 11, cx + 11, cy - 11, SSD1306_WHITE);
    return;
  }
  if (!validGps) {
    if ((now / 500) % 2 == 0) screen.drawCircle(cx, cy, 10, SSD1306_WHITE);
    return;
  }
  const float ratio = currentDistanceM / safeRadiusMeters;
  const int markerX = cx + constrain((int)(ratio * 12.0f), 0, 18);
  screen.fillCircle(markerX, cy, 2, SSD1306_WHITE);
  if (ratio > 1.0f && (now / 300) % 2 == 0) {
    screen.drawCircle(markerX, cy, 4, SSD1306_WHITE);
  }
}

void drawSafeRadiusPage(uint32_t now) {
  header();
  label(3, 14, "SAFE RADIUS");
  const bool justChanged = safeRadiusConfigured && (now - radiusUiChangedAt < 1400);

  if (!safeRadiusEnabled) {
    label(3, 25, "STATUS: OFF");
    label(3, 36, "DARI APP");
    label(3, 46, "TIDAK DIPANTAU");
  } else {
    char line[24];
    snprintf(line, sizeof(line), "BATAS: %.0f m", safeRadiusMeters);
    label(3, 25, line);
    formatCompanionDistance(line, sizeof(line));
    label(3, 35, line);

    if (radiusAlertActive) label(3, 46, "STATUS: LUAR BATAS!");
    else if (distanceStatus != DIST_READY) label(3, 46, "STATUS: MENUNGGU GPS");
    else label(3, 46, "STATUS: AMAN");
  }

  uiRadiusRadar(107, 34, now, safeRadiusConfigured && safeRadiusEnabled,
                distanceStatus == DIST_READY);
  if (justChanged && (now / 180) % 2 == 0) screen.fillRect(123, 13, 3, 3, SSD1306_WHITE);
  footer(5);
}

void aiHeader(const char* title, uint32_t now, bool recording) {
  if (recording) {
    if ((now / 220) % 2 == 0) screen.fillCircle(5, 5, 3, SSD1306_WHITE);
    else screen.drawCircle(5, 5, 3, SSD1306_WHITE);
  } else {
    screen.drawRoundRect(1, 1, 10, 9, 2, SSD1306_WHITE);
    screen.drawPixel(4, 4, SSD1306_WHITE);
    screen.drawPixel(7, 4, SSD1306_WHITE);
    screen.drawFastHLine(4, 7, 4, SSD1306_WHITE);
  }
  label(15, 2, title);
  if (bleConnected) {
    screen.drawCircle(120, 5, 2, SSD1306_WHITE);
    screen.drawLine(114, 5, 117, 5, SSD1306_WHITE);
    screen.drawLine(122, 5, 125, 5, SSD1306_WHITE);
  } else {
    screen.drawLine(113, 2, 126, 9, SSD1306_WHITE);
    screen.drawCircle(120, 5, 3, SSD1306_WHITE);
  }
  screen.drawFastHLine(0, 11, 128, SSD1306_WHITE);
}

void aiFooter(const char* instruction) {
  screen.drawFastHLine(0, 54, 128, SSD1306_WHITE);
  label(4, 56, instruction);
}

void aiMicIcon(int16_t cx, int16_t cy, uint32_t now, bool active) {
  uint8_t phase = (now / 250) % 6;
  if (phase < 3) screen.drawCircle(cx, cy, 13 + phase, SSD1306_WHITE);
  else screen.drawCircle(cx, cy, 18 - phase, SSD1306_WHITE);
  screen.fillRoundRect(cx - 3, cy - 7, 7, 12, 3, SSD1306_WHITE);
  screen.drawLine(cx - 6, cy + 1, cx - 6, cy + 5, SSD1306_WHITE);
  screen.drawLine(cx + 7, cy + 1, cx + 7, cy + 5, SSD1306_WHITE);
  screen.drawFastHLine(cx - 6, cy + 5, 14, SSD1306_WHITE);
  screen.drawFastVLine(cx, cy + 5, 4, SSD1306_WHITE);
  screen.drawFastHLine(cx - 4, cy + 9, 9, SSD1306_WHITE);
  if (!active) screen.drawLine(cx - 10, cy - 9, cx + 10, cy + 10, SSD1306_WHITE);
}

void aiDrawIdle(uint32_t now) {
  aiHeader("HAJICARE AI", now, false);
  if (!micReady) {
    aiMicIcon(23, 34, now, false);
    label(44, 19, "I2S BELUM SIAP");
    label(45, 31, "Periksa kabel");
    label(45, 42, "GPIO 10/11/12");
    aiFooter("MIC: PERIKSA MODUL");
  } else if (!bleConnected) {
    aiMicIcon(23, 34, now, false);
    label(44, 19, "BELUM KONEK");
    label(44, 31, "Buka aplikasi");
    label(44, 42, "Sambungkan BLE");
    aiFooter("I2S SIAP  |  BLE OFF");
  } else if (aiReplyTimedOut) {
    aiMicIcon(23, 34, now, true);
    label(44, 18, "BELUM ADA");
    label(44, 29, "BALASAN AI");
    label(44, 42, "Klik 2x lagi");
    aiFooter("KLIK 2x: ULANGI");
  } else {
    aiMicIcon(23, 34, now, true);
    label(44, 18, "SIAP BICARA");
    label(44, 30, "Klik 2x tombol");
    label(44, 42, "untuk mulai");
    aiFooter("INMP441  |  BLE SIAP");
  }
}

void aiDrawListening(uint32_t now) {
  const uint32_t elapsed = min(now - aiListenStartAt, AI_MAX_LISTEN_MS);
  const uint32_t remain = (AI_MAX_LISTEN_MS - elapsed + 999) / 1000;
  aiHeader("MENDENGARKAN", now, true);
  char counter[12];
  snprintf(counter, sizeof(counter), "%02lus", (unsigned long)remain);
  label(99, 2, counter);

  label(4, 15, aiMicLevel > 12 ? "SUARA AKTIF" : "SILAKAN BICARA");
  char pct[8];
  snprintf(pct, sizeof(pct), "%u%%", (unsigned)aiMicLevel);
  int pctX = 127 - (int)strlen(pct) * 6;
  label(pctX, 15, pct);

  for (uint8_t i = 0; i < AI_WAVE_COLUMNS; ++i) {
    const uint8_t amplitude = aiWaveHistory[(aiWaveCursor + i) % AI_WAVE_COLUMNS];
    const int halfHeight = 1 + (amplitude * 9) / 100;
    screen.drawFastVLine(4 + (int)i * 4, 35 - halfHeight,
                         2 * halfHeight + 1, SSD1306_WHITE);
  }
  screen.drawRoundRect(3, 47, 122, 6, 2, SSD1306_WHITE);
  const int fill = (int)((elapsed * 118UL) / AI_MAX_LISTEN_MS);
  if (fill > 0) screen.fillRect(5, 49, fill, 2, SSD1306_WHITE);
  aiFooter("KLIK 1x: KIRIM AUDIO");
}

void aiDrawProcessing(uint32_t now) {
  aiHeader("HAJICARE AI", now, false);
  static const int8_t orbitX[8] = {0, 7, 10, 7, 0, -7, -10, -7};
  static const int8_t orbitY[8] = {-10, -7, 0, 7, 10, 7, 0, -7};
  const uint8_t phase = (now / 130) % 8;
  for (uint8_t i = 0; i < 8; ++i) {
    const uint8_t distance = (phase + 8 - i) % 8;
    if (distance == 0) screen.fillCircle(23 + orbitX[i], 33 + orbitY[i], 3, SSD1306_WHITE);
    else if (distance < 3) screen.fillCircle(23 + orbitX[i], 33 + orbitY[i], 2, SSD1306_WHITE);
    else screen.drawPixel(23 + orbitX[i], 33 + orbitY[i], SSD1306_WHITE);
  }
  label(43, 18, "SUARA TERKIRIM");
  label(43, 30, "Menunggu jawab");
  if (bleConnected) label(43, 42, "dari aplikasi");
  else label(43, 42, "BLE TERPUTUS");
  aiFooter("MENUNGGU RESPONS HP");
}

void aiDrawReply(uint32_t now) {
  aiHeader("BALASAN HAJICARE", now, false);
  screen.fillRect(112, 0, 16, 11, SSD1306_BLACK);
  screen.drawCircle(120, 5, 4, SSD1306_WHITE);
  screen.drawLine(118, 5, 120, 7, SSD1306_WHITE);
  screen.drawLine(120, 7, 123, 3, SSD1306_WHITE);

  uint8_t scroll = 0;
  const uint32_t age = now - aiStateChangedAt;
  if (aiReplyLineCount > AI_REPLY_VISIBLE_LINES && age > 3600) {
    const uint8_t positions = aiReplyLineCount - AI_REPLY_VISIBLE_LINES + 1;
    scroll = ((age - 3600) / 2600) % positions;
  }

  const uint32_t revealChars = 2U + age / 24U;
  uint16_t remainingChars = (uint16_t)(revealChars < 128U ? revealChars : 128U);
  for (uint8_t i = 0; i < scroll; ++i) {
    remainingChars = (remainingChars > strlen(aiReplyLines[i]))
      ? remainingChars - strlen(aiReplyLines[i]) : 0;
  }
  for (uint8_t row = 0; row < AI_REPLY_VISIBLE_LINES; ++row) {
    const uint8_t index = scroll + row;
    if (index >= aiReplyLineCount) break;
    const uint8_t lineLen = strlen(aiReplyLines[index]);
    const uint8_t visible = min((uint16_t)lineLen, remainingChars);
    char piece[AI_REPLY_WIDTH + 1];
    memcpy(piece, aiReplyLines[index], visible);
    piece[visible] = '\0';
    label(4, 15 + 9 * row, piece);
    remainingChars = (remainingChars >= lineLen) ? remainingChars - lineLen : 0;
  }

  screen.drawFastHLine(0, 54, 128, SSD1306_WHITE);
  if (aiReplyLineCount > AI_REPLY_VISIBLE_LINES) {
    char pageInfo[22];
    snprintf(pageInfo, sizeof(pageInfo), "PESAN %u/%u  GULIR",
             (unsigned)(scroll + 1),
             (unsigned)(aiReplyLineCount - AI_REPLY_VISIBLE_LINES + 1));
    label(4, 56, pageInfo);
  } else {
    label(4, 56, "RESPONS DARI APP");
  }
}

void drawAiPage(uint32_t now) {
  if (aiListening) aiDrawListening(now);
  else if (aiState == AI_PROCESSING) aiDrawProcessing(now);
  else if (aiState == AI_REPLY_SHOWN) aiDrawReply(now);
  else aiDrawIdle(now);
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
  #if HAJICARE_CUSTOM_INTRO
    const uint32_t currentOledPeriod = (!bootFinished && now - bootAt < INTRO_FRAMES_TOTAL) ? 50 : OLED_PERIOD;
  #else
    const uint32_t currentOledPeriod = OLED_PERIOD;
  #endif
  if (!oledReady || now - lastOledAt < currentOledPeriod) return;
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
    #if HAJICARE_CUSTOM_INTRO
      HajiCareIntro::render(screen, now - bootAt);
    #else
      const uint32_t introAge = now - bootAt;
      const int16_t orbit = (introAge / 180) % 8;
      screen.drawRoundRect(1, 1, 126, 62, 7, SSD1306_WHITE);
      screen.drawCircle(24, 30, 11, SSD1306_WHITE);
      screen.fillCircle(24, 30, 4 + (orbit % 3), SSD1306_WHITE);
      screen.drawLine(24, 14, 24, 18, SSD1306_WHITE);
      screen.drawLine(24, 42, 24, 47, SSD1306_WHITE);
      label(43, 19, "HAJICARE", 1);
      label(43, 32, "SMARTBAND", 1);
      screen.drawFastHLine(43, 46, (introAge * 76UL) / INTRO_FRAMES_TOTAL, SSD1306_WHITE);
    #endif
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
    sendSoon();
  }

  switch (currentPage) {
    case 0:      drawHR(now); break;
    case 1:      drawGPS(now); break;
    case 2:      drawTempPage(now); break;
    case 3:      drawMotion(now); break;
    case 4:      drawStepsPage(now); break;
    case 5:      drawSafeRadiusPage(now); break;
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
    Serial.printf("fall=%s sos=%s radius=%.0fm distHP=%.1fm gpsStatus=%s radAlert=%u AI=%s(lvl=%u%%) page=%u BLE=%s\n",
                  fallText(), sosActive ? "YES" : "NO", isfinite(safeRadiusMeters) ? safeRadiusMeters : -1.0f,
                  isnan(currentDistanceM) ? -1.0f : currentDistanceM, distanceStatusName(distanceStatus),
                  radiusAlertActive ? 1 : 0,
                  aiListening ? "REC" : (micReady ? "READY" : "NO_MIC"),
                  (unsigned)aiMicLevel, (unsigned)currentPage,
                  bleConnected ? "ON" : "OFF");
  }

  if (now - lastGpsReportAt >= GPS_REPORT_PERIOD) {
    lastGpsReportAt = now;
    Serial.println();
    Serial.println("========== STATUS GPS ==========");
    Serial.print("Total Byte       : "); Serial.println(gpsBytes);
    Serial.print("Karakter diproses: "); Serial.println(gps.charsProcessed());
    Serial.print("Checksum berhasil: "); Serial.println(gps.passedChecksum());
    Serial.print("Satelit          : ");
    if (gps.satellites.isValid() && gps.satellites.age() < 5000) {
      Serial.println(gps.satellites.value());
    } else {
      Serial.println("Belum tersedia");
    }

    if (gpsFix) {
      Serial.printf("Latitude  : %.6f\n", gps.location.lat());
      Serial.printf("Longitude : %.6f\n", gps.location.lng());
      Serial.println("Status: GPS FIX");
    } else {
      Serial.println("Status: MENCARI SINYAL GPS");
    }
    Serial.println("================================");
    Serial.println();
  }
}

// ====================================================================
// SAFE RADIUS EVALUATOR (EVALUASI JARAK AMAN)
// ====================================================================
void updateSafeRadius(uint32_t now) {
  currentDistanceM = NAN;
  distanceStatus = DIST_PHONE_MISSING;
  double phoneLatSnapshot, phoneLonSnapshot;
  float accuracySnapshot;
  uint32_t phoneUpdatedSnapshot;
  bool phoneSeenSnapshot;
  float reportedDistSnapshot;
  uint32_t reportedDistAtSnapshot;

  portENTER_CRITICAL(&companionPositionMux);
  phoneLatSnapshot = companionLat;
  phoneLonSnapshot = companionLon;
  accuracySnapshot = companionAccuracyM;
  phoneUpdatedSnapshot = companionUpdatedAt;
  phoneSeenSnapshot = companionSeen;
  reportedDistSnapshot = phoneReportedDistanceM;
  reportedDistAtSnapshot = phoneReportedDistanceAt;
  portEXIT_CRITICAL(&companionPositionMux);

  if (!bleConnected) {
    distanceStatus = DIST_BLE_OFF;
  } else if (!gpsFix || !gps.location.isValid() || gps.location.age() > 5000 ||
             !validCoordinates(gps.location.lat(), gps.location.lng())) {
    distanceStatus = DIST_BAND_NO_FIX;
  } else if (isfinite(gpsHdop) && gpsHdop > MAX_BAND_HDOP) {
    distanceStatus = DIST_BAND_POOR;
  } else if (!phoneSeenSnapshot || !validCoordinates(phoneLatSnapshot, phoneLonSnapshot)) {
    distanceStatus = DIST_PHONE_MISSING;
  } else if (now - phoneUpdatedSnapshot > COMPANION_POSITION_TTL_MS) {
    distanceStatus = DIST_PHONE_STALE;
  } else if (isfinite(accuracySnapshot) && accuracySnapshot > MAX_COMPANION_ACCURACY_M) {
    distanceStatus = DIST_PHONE_POOR;
  } else {
    const double d = haversineMeters(gps.location.lat(), gps.location.lng(),
                                     phoneLatSnapshot, phoneLonSnapshot);
    if (isfinite(d) && d >= 0.0) {
      currentDistanceM = (float)d;
      distanceStatus = DIST_READY;
    }
  }

  // Fallback hybrid: jika GPS gelang sedang indoor/belum fix, gunakan jarak valid dari aplikasi Flutter ("DIST:...")
  if (bleConnected && distanceStatus != DIST_READY &&
      isfinite(reportedDistSnapshot) && reportedDistAtSnapshot != 0 &&
      (now - reportedDistAtSnapshot <= COMPANION_POSITION_TTL_MS)) {
    currentDistanceM = reportedDistSnapshot;
    distanceStatus = DIST_READY;
  }

  // Jika Safe Radius dimatikan dari aplikasi dan tidak ada paksaan alert:
  if ((!safeRadiusConfigured || !safeRadiusEnabled) && !appForcedRadiusAlert) {
    if (radiusAlertActive) {
      radiusAlertActive = false;
      requestBleNow = true;
    }
    radiusOverLimitSince = 0;
    if (hapticPattern == HAPTIC_SAFE_RADIUS) {
      hapticPattern = HAPTIC_NONE;
      motorWrite(false);
    }
    return;
  }

  // Cek jika pengguna sedang melakukan Snooze (Tekan 1x tombol Action)
  if (radiusSnoozeUntil != 0) {
    if ((int32_t)(radiusSnoozeUntil - now) > 0) {
      if (radiusAlertActive) {
        radiusAlertActive = false;
        requestBleNow = true;
      }
      radiusOverLimitSince = 0;
      if (hapticPattern == HAPTIC_SAFE_RADIUS) {
        hapticPattern = HAPTIC_NONE;
        motorWrite(false);
      }
      return;
    }
    radiusSnoozeUntil = 0;
  }

  // Evaluasi batas jarak mandiri GPS / hybrid
  const bool validDistance = distanceStatus == DIST_READY;
  const bool beyond = validDistance && currentDistanceM > safeRadiusMeters + RADIUS_GPS_GUARD_M;
  if (beyond) {
    if (radiusOverLimitSince == 0) radiusOverLimitSince = now;
  } else {
    radiusOverLimitSince = 0;
  }
  const bool sustained = beyond && (now - radiusOverLimitSince >= RADIUS_CONFIRM_MS);

  // Trigger jika aplikasi memerintahkan alert ATAU kalkulasi jarak melebihi batas
  bool shouldAlert = appForcedRadiusAlert || sustained;
  if (radiusAlertActive && validDistance &&
      currentDistanceM >= safeRadiusMeters - RADIUS_GPS_GUARD_M) {
    shouldAlert = true; // Hysteresis
  }

  if (shouldAlert != radiusAlertActive) {
    radiusAlertActive = shouldAlert;
    requestBleNow = true;
    if (radiusAlertActive) {
      if (validDistance) {
        Serial.printf("[SAFE RADIUS] ALERT! Jarak ke HP = %.1fm (Batas = %.1fm)\n",
                      currentDistanceM, safeRadiusMeters);
      } else {
        Serial.println("[SAFE RADIUS] ALERT AKTIF (Diperintahkan oleh aplikasi HP)!");
      }
    } else {
      Serial.printf("[SAFE RADIUS] Alert padam; kembali ke status aman (%s)\n",
                    distanceStatusName(distanceStatus));
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
  Serial.println("\n=== HAJICARE SMARTBAND PRO v2.8.2 / ESP32-S3 + OLED 0.96 IN 128x64 ===");
  Serial.println("[SERIAL TEST] V=getar, E=darurat, R=radius, F=jatuh, S=+1 langkah, 0=reset, M=tes Mic AI, X=stop.");

  pinMode(PIN_ACTION, INPUT_PULLUP);
  pinMode(PIN_MOTOR, OUTPUT);
  motorWrite(false);

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
  Serial.printf("[OLED 0.96in] %s | SSD1306 %ux%u | I2C SDA=%u SCL=%u | address=0x%02X\n",
                oledReady ? "READY" : "NOT FOUND", OLED_WIDTH, OLED_HEIGHT,
                PIN_SDA, PIN_SCL, oledAddr);

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

  applyFlutterRadiusUpdate(now);
  updateSafeRadius(now);

  if (aiListening && (sosActive || fallState == FALL_ALERT ||
                      fallState == FALL_COUNTDOWN || radiusAlertActive)) {
    stopAiListening(false);
  }

  // Picu pola getar haptic
  if (sosActive || fallState == FALL_ALERT || fallState == FALL_COUNTDOWN) {
    vibrate(HAPTIC_EMERGENCY);
  } else if (radiusAlertActive) {
    vibrate(HAPTIC_SAFE_RADIUS); // 3x getar pulsa Safe Radius
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

