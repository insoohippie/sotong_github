import '../data_source/auth_data_source.dart';
import '../data_source/ref_data_data_source.dart';
import '../model/refData/daily_consume.dart';
import '../model/refData/monthly_consume.dart';
import '../model/refData/monthly_income.dart';
import '../model/refData/ref_data.dart';

/// Repository responsible for loading and persisting refData entities.
class RefDataRepository {
  RefDataRepository(this._ds, this._auth);

  final RefDataDataSource _ds;
  final AuthDataSource _auth;

  String _uidOrThrow() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('로그인이 필요합니다.');
    return uid;
  }

  /// Loads every refData document beneath the user and hydrates [RefData].
  Future<RefData> loadAll() async {
    final uid = _uidOrThrow();
    final results = await Future.wait([
      _ds.fetchMonthlyIncomes(uid),
      _ds.fetchMonthlyConsumes(uid),
      _ds.fetchDailyConsumes(uid),
    ]);

    final monthlyIncomes = {
      for (final doc in results[0])
        doc.id: MonthlyIncome.fromMap(doc.id, doc.data()),
    };
    final monthlyConsumes = {
      for (final doc in results[1])
        doc.id: MonthlyConsume.fromMap(doc.id, doc.data()),
    };
    final dailyConsumes = {
      for (final doc in results[2])
        doc.id: DailyConsume.fromMap(doc.id, doc.data()),
    };

    return RefData(
      planId: '',
      monthlyIncomes: monthlyIncomes,
      monthlyConsumes: monthlyConsumes,
      dailyConsumes: dailyConsumes,
    );
  }

  Future<void> saveMonthlyIncome(MonthlyIncome income) async {
    final uid = _uidOrThrow();
    await _ds.upsertMonthlyIncome(uid, income.id, income.toMap());
  }

  Future<void> saveMonthlyConsume(MonthlyConsume consume) async {
    final uid = _uidOrThrow();
    await _ds.upsertMonthlyConsume(uid, consume.id, consume.toMap());
  }

  Future<void> saveDailyConsume(DailyConsume consume) async {
    final uid = _uidOrThrow();
    await _ds.upsertDailyConsume(uid, consume.id, consume.toMap());
  }

  Future<void> deleteMonthlyIncome(String id) async {
    final uid = _uidOrThrow();
    await _ds.deleteMonthlyIncome(uid, id);
  }

  Future<void> deleteMonthlyConsume(String id) async {
    final uid = _uidOrThrow();
    await _ds.deleteMonthlyConsume(uid, id);
  }

  Future<void> deleteDailyConsume(String id) async {
    final uid = _uidOrThrow();
    await _ds.deleteDailyConsume(uid, id);
  }
}
