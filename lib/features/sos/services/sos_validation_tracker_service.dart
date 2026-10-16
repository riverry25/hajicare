import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a single logged test trial for SOS Darurat (TC-07).
class SosTestLog {
  final String id;
  final DateTime timestamp;
  final String userName;
  final String roomName;
  final double? latitude;
  final double? longitude;
  final double durationSeconds;
  final bool isSuccess;
  final String? eventId;
  final String? errorMessage;

  SosTestLog({
    required this.id,
    required this.timestamp,
    required this.userName,
    required this.roomName,
    this.latitude,
    this.longitude,
    required this.durationSeconds,
    required this.isSuccess,
    this.eventId,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'userName': userName,
        'roomName': roomName,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'durationSeconds': durationSeconds,
        'isSuccess': isSuccess,
        if (eventId != null) 'eventId': eventId,
        if (errorMessage != null) 'errorMessage': errorMessage,
      };

  factory SosTestLog.fromJson(Map<String, dynamic> json) => SosTestLog(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        userName: json['userName'] as String? ?? 'Jamaah',
        roomName: json['roomName'] as String? ?? 'Rombongan',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 0.0,
        isSuccess: json['isSuccess'] as bool? ?? false,
        eventId: json['eventId'] as String?,
        errorMessage: json['errorMessage'] as String?,
      );
}

/// Service to track and persist validation test trials for SOS Darurat (TC-07).
class SosValidationTrackerService {
  SosValidationTrackerService._();
  static final SosValidationTrackerService instance =
      SosValidationTrackerService._();

  static const String _storageKey = 'hajicare_sos_validation_logs';
  final ValueNotifier<List<SosTestLog>> logsNotifier =
      ValueNotifier<List<SosTestLog>>([]);

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        logsNotifier.value = decoded
            .map((item) => SosTestLog.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[SosValidationTracker] Failed to load logs: $e');
    }
    _isInitialized = true;
  }

  Future<void> logTrial({
    required String userName,
    required String roomName,
    double? latitude,
    double? longitude,
    required double durationSeconds,
    required bool isSuccess,
    String? eventId,
    String? errorMessage,
  }) async {
    await init();
    final entry = SosTestLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      userName: userName,
      roomName: roomName,
      latitude: latitude,
      longitude: longitude,
      durationSeconds: durationSeconds,
      isSuccess: isSuccess,
      eventId: eventId,
      errorMessage: errorMessage,
    );

    final current = List<SosTestLog>.from(logsNotifier.value);
    current.add(entry);
    logsNotifier.value = current;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(current.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (e) {
      debugPrint('[SosValidationTracker] Failed to persist log: $e');
    }
  }

  Future<void> clearLogs() async {
    logsNotifier.value = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('[SosValidationTracker] Failed to clear logs: $e');
    }
  }
}
