import 'package:hive_flutter/hive_flutter.dart';
import '../model/notification/notification_settings.dart';

const _boxName = 'notification_settings';
const _settingsPrefix = 'settings';
const _keyAppliedSignupDefaultsPrefix = 'applied_signup_defaults';

/// 회원가입+플랜 생성 시 기본 알림 설정 (일간 3 + 주간 2 ON)
/// 출석: 22:00, 동기부여: 11:30, 결석: 10:00, 주간 2개: 일요일 20:00
NotificationSettings get defaultSignupNotificationSettings =>
    const NotificationSettings(
      attendanceEnabled: true,
      attendanceHour: 22,
      attendanceMinute: 0,
      motivationEnabled: true,
      motivationHour: 11,
      motivationMinute: 30,
      absenceEnabled: true,
      absenceHour: 10,
      absenceMinute: 0,
      weeklyReportEnabled: true,
      emotionReportEnabled: true,
    );

class NotificationSettingsStorage {
  NotificationSettingsStorage._();

  static final NotificationSettingsStorage _instance =
  NotificationSettingsStorage._();

  static NotificationSettingsStorage get instance => _instance;

  Box<dynamic>? _box;

  Future<void> ensureOpen() async {
    _box ??= await Hive.openBox(_boxName);
  }

  String _settingsKey(String uid) => '${_settingsPrefix}_$uid';

  String _appliedSignupDefaultsKey(String uid) =>
      '${_keyAppliedSignupDefaultsPrefix}_$uid';

  Future<NotificationSettings> load(String uid) async {
    await ensureOpen();

    final data = _box!.get(_settingsKey(uid));

    if (data is Map) {
      return NotificationSettings.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    return const NotificationSettings();
  }

  Future<void> save(String uid, NotificationSettings settings) async {
    await ensureOpen();

    await _box!.put(
      _settingsKey(uid),
      settings.toJson(),
    );
  }

  Future<bool> hasAppliedSignupDefaults(String uid) async {
    await ensureOpen();

    return _box!.get(
      _appliedSignupDefaultsKey(uid),
      defaultValue: false,
    ) as bool;
  }

  Future<void> markSignupDefaultsApplied(String uid) async {
    await ensureOpen();

    await _box!.put(
      _appliedSignupDefaultsKey(uid),
      true,
    );
  }

  Future<void> clearForUid(String uid) async {
    await ensureOpen();

    await _box!.delete(_settingsKey(uid));
    await _box!.delete(_appliedSignupDefaultsKey(uid));
  }
}
