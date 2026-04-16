import 'package:flutter/material.dart';

/// 알림 설정 모델 (저장/로드용)
class NotificationSettings {
  const NotificationSettings({
    this.attendanceEnabled = false,
    this.attendanceHour = 9,
    this.attendanceMinute = 0,
    this.motivationEnabled = false,
    this.motivationHour = 18,
    this.motivationMinute = 0,
    this.weeklyReportEnabled = false,
    this.emotionReportEnabled = false,
  });

  final bool attendanceEnabled;
  final int attendanceHour;
  final int attendanceMinute;
  final bool motivationEnabled;
  final int motivationHour;
  final int motivationMinute;
  final bool weeklyReportEnabled;
  final bool emotionReportEnabled;

  TimeOfDay get attendanceTime =>
      TimeOfDay(hour: attendanceHour, minute: attendanceMinute);
  TimeOfDay get motivationTime =>
      TimeOfDay(hour: motivationHour, minute: motivationMinute);

  NotificationSettings copyWith({
    bool? attendanceEnabled,
    int? attendanceHour,
    int? attendanceMinute,
    bool? motivationEnabled,
    int? motivationHour,
    int? motivationMinute,
    bool? weeklyReportEnabled,
    bool? emotionReportEnabled,
  }) {
    return NotificationSettings(
      attendanceEnabled: attendanceEnabled ?? this.attendanceEnabled,
      attendanceHour: attendanceHour ?? this.attendanceHour,
      attendanceMinute: attendanceMinute ?? this.attendanceMinute,
      motivationEnabled: motivationEnabled ?? this.motivationEnabled,
      motivationHour: motivationHour ?? this.motivationHour,
      motivationMinute: motivationMinute ?? this.motivationMinute,
      weeklyReportEnabled: weeklyReportEnabled ?? this.weeklyReportEnabled,
      emotionReportEnabled: emotionReportEnabled ?? this.emotionReportEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'attendanceEnabled': attendanceEnabled,
    'attendanceHour': attendanceHour,
    'attendanceMinute': attendanceMinute,
    'motivationEnabled': motivationEnabled,
    'motivationHour': motivationHour,
    'motivationMinute': motivationMinute,
    'weeklyReportEnabled': weeklyReportEnabled,
    'emotionReportEnabled': emotionReportEnabled,
  };

  static NotificationSettings fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      attendanceEnabled: json['attendanceEnabled'] as bool? ?? false,
      attendanceHour: (json['attendanceHour'] as num?)?.toInt() ?? 9,
      attendanceMinute: (json['attendanceMinute'] as num?)?.toInt() ?? 0,
      motivationEnabled: json['motivationEnabled'] as bool? ?? false,
      motivationHour: (json['motivationHour'] as num?)?.toInt() ?? 18,
      motivationMinute: (json['motivationMinute'] as num?)?.toInt() ?? 0,
      weeklyReportEnabled: json['weeklyReportEnabled'] as bool? ?? false,
      emotionReportEnabled: json['emotionReportEnabled'] as bool? ?? false,
    );
  }
}
