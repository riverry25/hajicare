class PrayerScheduleItem {
  final String name;
  final String arabicName;
  final DateTime time;
  final String formattedTime;
  final bool isNext;
  final bool isCurrent;

  const PrayerScheduleItem({
    required this.name,
    required this.arabicName,
    required this.time,
    required this.formattedTime,
    this.isNext = false,
    this.isCurrent = false,
  });

  PrayerScheduleItem copyWith({
    String? name,
    String? arabicName,
    DateTime? time,
    String? formattedTime,
    bool? isNext,
    bool? isCurrent,
  }) {
    return PrayerScheduleItem(
      name: name ?? this.name,
      arabicName: arabicName ?? this.arabicName,
      time: time ?? this.time,
      formattedTime: formattedTime ?? this.formattedTime,
      isNext: isNext ?? this.isNext,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }
}
