import 'package:flutter/material.dart';
import '../../model/notification/notification_item.dart';

class NotificationViewModel extends ChangeNotifier {
  List<NotificationItem> _notifications = [];

  // 알림 메시지 템플릿
  static const List<String> recordReminderMessages = [
    "오늘 소비 기록하셨나요? ✍️ 하루 한 번, 출석 체크처럼 기록해보세요!",
    "지금 소비를 기록하면 하루가 더 뿌듯해져요 😊",
    "앗! 어제 소비 기록을 깜빡하신 것 같아요. 지금 추가해볼까요?",
    "하루 5분! 소비 기록으로 내 돈 흐름을 이해해요 💸",
    "빠진 소비가 있어요 😢 기록하고 분석을 완성해봐요!",
  ];

  static const List<String> timeValueMessages = [
    "오늘은 13,000원 절약! ⏰ 1시간 15분을 번 셈이에요 💪",
    "이번 주, 총 3시간 20분을 절약했어요. 이 시간 어떻게 쓸까요? 😊",
    "소비가 예상보다 많았어요 😢 약 1시간 45분 일한 셈이에요…",
    "오늘은 딱 목표만큼 소비했어요! 시간과 돈 모두 균형 잡힌 하루 🎯",
    "이번 달 초과 소비로 약 9시간 일한 셈이에요... 다음 달엔 같이 줄여봐요!",
  ];

  static const List<String> reportMessages = [
    "이번 주, '배달🍕'에 가장 많이 썼어요! 혹시 반복된 습관일까요?",
    "'카페☕' 지출이 눈에 띄어요. 다음 주엔 하루 건너뛰기 도전?",
    "식비가 이번 주 지출의 40%를 차지했어요! 계획에 맞게 잘 쓰고 있나요?",
    "이번 달, 고정비 외에 '쇼핑🛍️'이 가장 컸어요. 리뷰로 확인해볼까요?",
    "주간 소비 총액 158,000원! 저번 주보다 7% 감소했어요. 굿 👍",
  ];

  static const List<String> emotionMessages = [
    "이번 주에는 '짜증남' 태그가 가장 많았어요 😤 스트레스 소비였을까요?",
    "이번 달, '기쁨😊' 감정이 많았던 날엔 소비도 줄었어요!",
    "소비와 감정이 연결되어 있어요. 이번 주 내 감정 흐름을 돌아볼까요?",
    "'충동'이라는 태그가 자주 보였어요. 다음 주엔 조금 더 천천히 🌿",
    "감정 기반 소비 분석이 준비됐어요! 어떤 날에 지출이 많았을까요?",
  ];

  List<NotificationItem> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // 알림 생성
  void addNotification(
    NotificationType type,
    NotificationCategory category, {
    String? customMessage,
    DateTime? createdAt,
  }) {
    final messages = _getMessagesByType(type);
    final randomMessage =
        messages[DateTime.now().millisecondsSinceEpoch % messages.length];

    final notification = NotificationItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_notifications.length}',
      title: _getTitleByType(type),
      message: customMessage ?? randomMessage,
      type: type,
      category: category,
      createdAt: createdAt ?? DateTime.now(),
      targetRoute: _getRouteByType(type),
    );

    _notifications.insert(0, notification);
    notifyListeners();
  }

  // 알림 삭제
  void removeNotification(String id) {
    _notifications.removeWhere((notification) => notification.id == id);
    notifyListeners();
  }

  // 알림 읽음 처리
  void markAsRead(String id) {
    final index = _notifications.indexWhere(
      (notification) => notification.id == id,
    );
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  // 모든 알림 읽음 처리
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  // 테스트용 샘플 알림 생성
  void generateSampleNotifications() {
    _notifications.clear();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));
    final threeDaysAgo = today.subtract(const Duration(days: 3));

    // 오늘 알림들
    addNotification(
      NotificationType.recordReminder,
      NotificationCategory.attendance,
      createdAt: today.add(const Duration(hours: 9, minutes: 30)),
    );
    addNotification(
      NotificationType.timeValue,
      NotificationCategory.home,
      createdAt: today.add(const Duration(hours: 14, minutes: 15)),
    );

    // 어제 알림들
    addNotification(
      NotificationType.report,
      NotificationCategory.report,
      createdAt: yesterday.add(const Duration(hours: 20, minutes: 0)),
    );
    addNotification(
      NotificationType.emotion,
      NotificationCategory.communication,
      createdAt: yesterday.add(const Duration(hours: 18, minutes: 45)),
    );

    // 2일 전 알림들
    addNotification(
      NotificationType.recordReminder,
      NotificationCategory.attendance,
      createdAt: twoDaysAgo.add(const Duration(hours: 10, minutes: 0)),
    );
    addNotification(
      NotificationType.timeValue,
      NotificationCategory.home,
      createdAt: twoDaysAgo.add(const Duration(hours: 16, minutes: 30)),
    );

    // 3일 전 알림들
    addNotification(
      NotificationType.report,
      NotificationCategory.report,
      createdAt: threeDaysAgo.add(const Duration(hours: 19, minutes: 15)),
    );
    addNotification(
      NotificationType.emotion,
      NotificationCategory.communication,
      createdAt: threeDaysAgo.add(const Duration(hours: 12, minutes: 20)),
    );
  }

  // 타입별 메시지 가져오기
  List<String> _getMessagesByType(NotificationType type) {
    switch (type) {
      case NotificationType.recordReminder:
        return recordReminderMessages;
      case NotificationType.timeValue:
        return timeValueMessages;
      case NotificationType.report:
        return reportMessages;
      case NotificationType.emotion:
        return emotionMessages;
    }
  }

  // 타입별 제목 가져오기
  String _getTitleByType(NotificationType type) {
    switch (type) {
      case NotificationType.recordReminder:
        return '출석 알림';
      case NotificationType.timeValue:
        return '시간으로 변환 알림';
      case NotificationType.report:
        return '레포트 알림';
      case NotificationType.emotion:
        return '소통 알림';
    }
  }

  // 타입별 라우트 가져오기
  String? _getRouteByType(NotificationType type) {
    switch (type) {
      case NotificationType.recordReminder:
        return '/expense_input'; // 소비 입력 화면
      case NotificationType.timeValue:
        return '/time_summary'; // 시간 기반 소비 요약 화면
      case NotificationType.report:
        return '/category_report'; // 소비 리포트 화면
      case NotificationType.emotion:
        return '/emotion_report'; // 감정 리포트 화면
    }
  }
}
