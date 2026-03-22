import 'dart:math';

class CategoryKey {
  static final Random _rng = Random.secure();

  /// cat_<고유숫자>
  /// - microsecondsSinceEpoch + 2자리 랜덤(동일 tick 충돌 방지)
  static String newKey() {
    final t = DateTime.now().microsecondsSinceEpoch;
    final s = _rng.nextInt(90) + 10; // 10~99
    return 'cat_${t}${s}';
  }

  static bool isValid(String? key) {
    final k = (key ?? '').trim();
    return k.startsWith('cat_') && k.length > 6;
  }
}