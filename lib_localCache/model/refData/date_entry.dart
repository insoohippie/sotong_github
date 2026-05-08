import 'package:cloud_firestore/cloud_firestore.dart';
import 'entry.dart';

class DateEntry {
  final DateTime? date;        // 불변
  final List<Entry> dateEntry; // 불변 리스트(참조 자체는 final)

  const DateEntry({
    required this.dateEntry,
    this.date,
  });

  /// date를 entries에 채워 넣은 "새 DateEntry" 반환
  DateEntry filledDateToEntries() {
    if (date == null) return this;
    final normalized = DateTime(date!.year, date!.month, date!.day);

    return DateEntry(
      date: normalized,
      dateEntry: dateEntry
          .map((e) => e.copyWith(dateTime: normalized))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // Firestore 호환: Timestamp로 저장
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'dateEntry': dateEntry.map((e) => e.toMap()).toList(),
    };
  }

  factory DateEntry.fromMap(Map<String, dynamic> map) {
    final rawDate = map['date'];
    final DateTime? parsedDate = rawDate is Timestamp
        ? rawDate.toDate()
        : rawDate is DateTime
        ? rawDate
        : null;

    final entries = (map['dateEntry'] as List<dynamic>?)
        ?.map((e) => Entry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList() ??
        const <Entry>[];

    final normalizedDate = parsedDate == null
        ? null
        : DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

    // date가 있으면 entries에도 dateTime 채워진 상태로 복원
    if (normalizedDate == null) {
      return DateEntry(date: null, dateEntry: entries);
    }

    return DateEntry(
      date: normalizedDate,
      dateEntry: entries
          .map((e) => e.copyWith(dateTime: normalizedDate))
          .toList(growable: false),
    );
  }

  double get amount => dateEntry.fold<double>(0.0, (sum, entry) => sum + entry.amount);

  /// 선택: 외부에서 날짜만 바꾸고 싶을 때
  DateEntry copyWith({
    DateTime? date,
    List<Entry>? dateEntry,
  }) {
    return DateEntry(
      date: date ?? this.date,
      dateEntry: dateEntry ?? this.dateEntry,
    );
  }
}

extension DateEntryExtension on DateEntry {
  DateEntry fillDateToEntries() => filledDateToEntries();
}