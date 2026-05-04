import 'package:flutter/material.dart';

enum NotificationCategory {
  attendance,
  home,
  report,
  communication,
}

enum NotificationType {
  recordReminder,
  timeValue,
  report,
  emotion,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationCategory category;
  final DateTime createdAt;
  final String? targetRoute;
  final DateTime? targetDate;
  final int? targetTabIndex;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.category,
    required this.createdAt,
    this.targetRoute,
    this.targetDate,
    this.targetTabIndex,
    this.isRead = false,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationCategory? category,
    DateTime? createdAt,
    String? targetRoute,
    DateTime? targetDate,
    int? targetTabIndex,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      targetRoute: targetRoute ?? this.targetRoute,
      targetDate: targetDate ?? this.targetDate,
      targetTabIndex: targetTabIndex ?? this.targetTabIndex,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// 알림 설정 모델 (저장/로드용)
class NotificationSettings {
  const NotificationSettings({
    this.attendanceEnabled = false,
    this.attendanceHour = 9,
    this.attendanceMinute = 0,
    this.motivationEnabled = false,
    this.motivationHour = 18,
    this.motivationMinute = 0,
    this.absenceEnabled = false,
    this.absenceHour = 10,
    this.absenceMinute = 0,
    this.weeklyReportEnabled = false,
    this.emotionReportEnabled = false,
  });

  final bool attendanceEnabled;
  final int attendanceHour;
  final int attendanceMinute;
  final bool motivationEnabled;
  final int motivationHour;
  final int motivationMinute;
  final bool absenceEnabled;
  final int absenceHour;
  final int absenceMinute;
  final bool weeklyReportEnabled;
  final bool emotionReportEnabled;

  TimeOfDay get attendanceTime =>
      TimeOfDay(hour: attendanceHour, minute: attendanceMinute);

  TimeOfDay get motivationTime =>
      TimeOfDay(hour: motivationHour, minute: motivationMinute);

  TimeOfDay get absenceTime =>
      TimeOfDay(hour: absenceHour, minute: absenceMinute);

  NotificationSettings copyWith({
    bool? attendanceEnabled,
    int? attendanceHour,
    int? attendanceMinute,
    bool? motivationEnabled,
    int? motivationHour,
    int? motivationMinute,
    bool? absenceEnabled,
    int? absenceHour,
    int? absenceMinute,
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
      absenceEnabled: absenceEnabled ?? this.absenceEnabled,
      absenceHour: absenceHour ?? this.absenceHour,
      absenceMinute: absenceMinute ?? this.absenceMinute,
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
    'absenceEnabled': absenceEnabled,
    'absenceHour': absenceHour,
    'absenceMinute': absenceMinute,
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
      absenceEnabled: json['absenceEnabled'] as bool? ?? false,
      absenceHour: (json['absenceHour'] as num?)?.toInt() ?? 10,
      absenceMinute: (json['absenceMinute'] as num?)?.toInt() ?? 0,
      weeklyReportEnabled: json['weeklyReportEnabled'] as bool? ?? false,
      emotionReportEnabled: json['emotionReportEnabled'] as bool? ?? false,
    );
  }
}

class Alarm {
  final TimeOfDay time;
  final String description;
  bool isActive;

  Alarm({
    required this.time,
    required this.description,
    this.isActive = true,
  });
}