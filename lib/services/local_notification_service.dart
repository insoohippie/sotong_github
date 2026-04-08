import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../model/notification/notification_settings.dart';

/// 알림 ID 상수
class _NotificationIds {
  static const int attendance = 1;
  static const int motivation = 2;
  static const int absence = 5;
  static const int weeklyReport = 3;
  static const int emotionReport = 4;
}

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService _instance =
  LocalNotificationService._();
  static LocalNotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// 초기화 (main에서 호출)
  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // 알림 탭 시 앱 열기 등 처리
  }

  /// 권한 요청 (iOS)
  Future<bool> requestPermission() async {
    final result = await _plugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
    >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return result ?? true;
  }

  /// 설정에 따라 스케줄 갱신
  Future<void> updateSchedules(NotificationSettings settings) async {
    if (!_initialized) return;

    await _plugin.cancelAll();

    if (settings.attendanceEnabled) {
      await _scheduleDaily(
        id: _NotificationIds.attendance,
        hour: settings.attendanceHour,
        minute: settings.attendanceMinute,
        title: '출석알림',
        body: '오늘 소비를 기록하셨나요? 지금 입력해보세요!',
      );
    }

    if (settings.motivationEnabled) {
      await _scheduleDaily(
        id: _NotificationIds.motivation,
        hour: settings.motivationHour,
        minute: settings.motivationMinute,
        title: '동기부여 알림',
        body: '오늘도 소비 통제 파이팅 💪',
      );
    }

    if (settings.absenceEnabled) {
      await _scheduleDaily(
        id: _NotificationIds.absence,
        hour: settings.absenceHour,
        minute: settings.absenceMinute,
        title: '결석 알림',
        body: '플랜 기간 중 기록이 비어 있는 날이 있는지 확인해 볼까요?',
      );
    }

    if (settings.weeklyReportEnabled) {
      await _scheduleWeekly(
        id: _NotificationIds.weeklyReport,
        weekday: DateTime.sunday,
        hour: 20,
        minute: 0,
        title: '소비통계레포트',
        body: '이번 주 소비 패턴을 확인해보세요!',
      );
    }

    if (settings.emotionReportEnabled) {
      await _scheduleWeekly(
        id: _NotificationIds.emotionReport,
        weekday: 7, // Sunday
        hour: 20,
        minute: 0,
        title: '감정 분석 레포트',
        body: '이번 주 감정 기록을 확인해보세요!',
      );
    }
  }

  /// 매일 반복 알림
  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily',
          '일간 알림',
          channelDescription: '출석·동기부여·결석 알림',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// 매주 반복 알림 (일요일 저녁)
  Future<void> _scheduleWeekly({
    required int id,
    required int weekday,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    var daysToAdd = (weekday - now.weekday + 7) % 7;
    if (daysToAdd == 0 && scheduledDate.isBefore(now)) {
      daysToAdd = 7;
    }
    scheduledDate = scheduledDate.add(Duration(days: daysToAdd));

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly',
          '주간 알림',
          channelDescription: '소비통계·감정 분석 레포트',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// 테스트용: N초 후 알림
  Future<void> scheduleTest(int seconds) async {
    final scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(seconds: seconds));
    await _plugin.zonedSchedule(
      999,
      '테스트 알림',
      '로컬 알림이 정상 작동합니다!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test',
          '테스트',
          channelDescription: '테스트 알림',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
