enum NotificationCategory {
  attendance, // 출석
  home, // 홈
  report, // 레포트
  communication, // 소통
}

enum NotificationType {
  recordReminder, // 출석 알림 (소비 기록 유도)
  timeValue, // 시간으로 변환 알림 (절약/초과)
  report, // 레포트 알림 (소비 카테고리 리포트)
  emotion, // 소통 알림 (감정 기반 리포트)
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationCategory category;
  final DateTime createdAt;
  final String? targetRoute;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.category,
    required this.createdAt,
    this.targetRoute,
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
      isRead: isRead ?? this.isRead,
    );
  }
}
