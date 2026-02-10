

/*
await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .collection('plans')
    .doc('myPlan')
    .set({
  'incomes_custom': refDate.toMap()['fixedIncomes'],
  'consumptions_custom': refDate.toMap()['fixedConsumptions'],
});
--------------------
-
final incomeEntry = DateEntry(dateEntry: [...]);
final consumptionEntry = DateEntry(dateEntry: [...]);

await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .collection('plans')
    .doc('main')
    .set({
  'date_incomes': incomeEntry.toMap(),
  'date_consumptions': consumptionEntry.toMap(),
});
--------------------
final map = snapshot.data();
final incomeEntry = DateEntry.fromMap(map['date_incomes']);
final consumptionEntry = DateEntry.fromMap(map['date_consumptions']);
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'entry.dart';

class DateEntry {
  DateTime? date;
  List<Entry> dateEntry;

  DateEntry({required this.dateEntry, this.date});

  Map<String, dynamic> toMap() {
    return {
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'dateEntry': dateEntry.map((e) => e.toMap()).toList(growable: false),
    };
  }

  factory DateEntry.fromMap(Map<String, dynamic> map) {
    DateTime? parsedDate;
    final rawDate = map['date'];
    if (rawDate is Timestamp) parsedDate = rawDate.toDate();
    if (rawDate is String) parsedDate = DateTime.tryParse(rawDate);
    if (rawDate is DateTime) parsedDate = rawDate;

    final entries = (map['dateEntry'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Entry.fromMap)
        .toList(growable: false);

    return DateEntry(date: parsedDate, dateEntry: entries);
  }

  double get amount => dateEntry.fold(0.0, (sum, e) => sum + e.amount);

  void fillDateToEntries() {
    final d = date;
    if (d == null) return;

    dateEntry = dateEntry
        .map((e) => e.copyWith(dateTime: d))
        .toList(growable: false);
  }
}
