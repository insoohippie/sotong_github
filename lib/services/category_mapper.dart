
// - 카테고리 변환/정규화/검증/이동 로직을 한 곳으로 모으는 파일
// - 규칙:
//   1) categoryKey는 A(플랜) 또는 B(참고) 중 한 곳에만 존재해야 함.
//   2) 이동은 "remove + insert"로 구현 (A <-> B 이동 포함)
//   3) A/B 모두 정렬(order) 가능. 저장 전에 order 0..n-1 정규화.
//   4) 소비 입력 BottomSheet에서는 수정/삭제/정렬 없이 "참고 추가"만 가능하도록,
//      이 Mapper는 '추가 시 key 생성'은 외부(VM)에서 하고, 여기서는 검증만 제공.

import '../../model/refData/entry.dart';

/// 편집 화면에서만 쓰는 Draft 모델(권장)
/// - Entry로 바로 편집하지 말고 Draft로 편집하고 저장 시 Entry로 변환하는 게 안전함.
enum CategorySource { plan, ref }

class CategoryEditItem {
  final String key;     // categoryKey (불변)
  final String name;    // display name
  final String emoji;   // display emoji
  final int order;      // 정렬용 (0..n-1로 정규화 대상)
  final CategorySource source;

  const CategoryEditItem({
    required this.key,
    required this.name,
    required this.emoji,
    required this.order,
    required this.source,
  });

  CategoryEditItem copyWith({
    String? key,
    String? name,
    String? emoji,
    int? order,
    CategorySource? source,
  }) {
    return CategoryEditItem(
      key: key ?? this.key,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      order: order ?? this.order,
      source: source ?? this.source,
    );
  }
}

/// 참고 카테고리(B) 저장용 모델(권장)
/// - ref prefs(또는 Firestore 별도 문서)에 저장하는 “참고 카테고리 리스트”
/// - dailyConsume Entry와 분리 (너가 원한 구조)
class RefCategoryItem {
  final String key;    // categoryKey
  final String name;
  final String emoji;
  final int order;

  const RefCategoryItem({
    required this.key,
    required this.name,
    required this.emoji,
    required this.order,
  });

  RefCategoryItem copyWith({
    String? key,
    String? name,
    String? emoji,
    int? order,
  }) {
    return RefCategoryItem(
      key: key ?? this.key,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      order: order ?? this.order,
    );
  }
}

/// 검증 실패를 UI에서 토스트/다이얼로그로 보여주기 위한 에러 타입
class CategoryValidationError implements Exception {
  final String message;
  CategoryValidationError(this.message);

  @override
  String toString() => message;
}

class CategoryMapper {
  // ----------------------------
  // A) Entry <-> Draft 변환
  // ----------------------------

  /// RefData.dailyConsume.entries(=플랜 카테고리 A) -> Draft(plan)
  static List<CategoryEditItem> planDraftFromDailyEntries(List<Entry> entries) {
    final sorted = List<Entry>.from(entries)
      ..sort((a, b) => a.order.compareTo(b.order));

    return [
      for (final e in sorted)
        CategoryEditItem(
          key: e.categoryKey,
          name: (e.category.isNotEmpty) ? e.category : e.categoryKey,
          emoji: e.emoji,
          order: e.order,
          source: CategorySource.plan,
        )
    ];
  }

  /// 참고카테고리(B) -> Draft(ref)
  static List<CategoryEditItem> refDraftFromRefItems(List<RefCategoryItem> items) {
    final sorted = List<RefCategoryItem>.from(items)
      ..sort((a, b) => a.order.compareTo(b.order));

    return [
      for (final c in sorted)
        CategoryEditItem(
          key: c.key,
          name: c.name,
          emoji: c.emoji,
          order: c.order,
          source: CategorySource.ref,
        )
    ];
  }

  /// Draft(plan) -> RefData.dailyConsume.entries 로 “플랜카테고리 A” 만들기
  ///
  /// ⚠️ amount 규칙
  /// - 플랜 수정/RefData는 최대한 안 건드린다고 했으니,
  ///   여기서는 amount를 0으로 만들지 말고,
  ///   기존 Entry가 있으면 기존 amount를 유지, 없으면 defaultAmount 사용.
  static List<Entry> dailyEntriesFromPlanDraft({
    required List<CategoryEditItem> planDraft,
    required List<Entry> previousEntries,   // 기존 dailyConsume.entries
    double defaultAmount = 0.0,
  }) {
    final normalized = normalizeOrder(planDraft);

    final prevMap = {for (final e in previousEntries) e.categoryKey: e};

    return [
      for (final d in normalized)
        Entry(
          idx: prevMap[d.key]?.idx ?? 0,
          order: d.order,
          amount: prevMap[d.key]?.amount ?? defaultAmount,
          categoryKey: d.key,
          category: d.name,
          emoji: d.emoji,
          note: prevMap[d.key]?.note ?? '',
          type: EntryType.daily, // dailyConsume용
          dateTime: prevMap[d.key]?.dateTime,
        )
    ];
  }

  /// Draft(ref) -> 참고카테고리(B) 저장 리스트 만들기
  static List<RefCategoryItem> refItemsFromRefDraft(List<CategoryEditItem> refDraft) {
    final normalized = normalizeOrder(refDraft);
    return [
      for (final d in normalized)
        RefCategoryItem(
          key: d.key,
          name: d.name,
          emoji: d.emoji,
          order: d.order,
        )
    ];
  }

  // ----------------------------
  // B) 공통 정규화 / 검증
  // ----------------------------

  /// order를 0..n-1로 다시 부여(현재 정렬 순서 기준)
  static List<CategoryEditItem> normalizeOrder(List<CategoryEditItem> items) {
    final sorted = List<CategoryEditItem>.from(items)
      ..sort((a, b) => a.order.compareTo(b.order));

    return [
      for (int i = 0; i < sorted.length; i++)
        sorted[i].copyWith(order: i)
    ];
  }

  /// 핵심 규칙: key는 A/B 중 한 곳에만 존재해야 함.
  /// + Draft 내부에서도 중복 key 금지
  static void validateUniqueKeys({
    required List<CategoryEditItem> planDraft,
    required List<CategoryEditItem> refDraft,
  }) {
    final planKeys = planDraft.map((e) => e.key).toList();
    final refKeys = refDraft.map((e) => e.key).toList();

    // 내부 중복
    final dupPlan = _findDuplicates(planKeys);
    if (dupPlan.isNotEmpty) {
      throw CategoryValidationError('플랜 카테고리에 중복 key가 있어요: ${dupPlan.join(', ')}');
    }

    final dupRef = _findDuplicates(refKeys);
    if (dupRef.isNotEmpty) {
      throw CategoryValidationError('참고 카테고리에 중복 key가 있어요: ${dupRef.join(', ')}');
    }

    // 교차 중복
    final cross = planKeys.toSet().intersection(refKeys.toSet());
    if (cross.isNotEmpty) {
      throw CategoryValidationError('카테고리 key는 A/B 중 한 곳에만 존재해야 해요. 중복: ${cross.join(', ')}');
    }
  }

  /// name 중복 정책(선택)
  /// - 너는 key 중심으로 간다고 했고, name 중복은 UX상 헷갈릴 수만 있어서 "경고" 정도로만 쓰는 걸 추천.
  static List<String> findDuplicateNames({
    required List<CategoryEditItem> planDraft,
    required List<CategoryEditItem> refDraft,
  }) {
    final names = [...planDraft, ...refDraft].map((e) => e.name.trim()).toList();
    return _findDuplicates(names);
  }

  static List<String> _findDuplicates(List<String> arr) {
    final seen = <String>{};
    final dup = <String>{};
    for (final x in arr) {
      if (seen.contains(x)) dup.add(x);
      seen.add(x);
    }
    return dup.toList();
  }

  // ----------------------------
  // C) 이동(remove + insert) 유틸
  // ----------------------------

  /// A/B 내부 재정렬 (같은 source 안에서)
  /// - fromIndex -> toIndex 로 이동
  static List<CategoryEditItem> moveWithin({
    required List<CategoryEditItem> list,
    required int fromIndex,
    required int toIndex,
  }) {
    if (fromIndex < 0 || fromIndex >= list.length) return list;
    if (toIndex < 0) toIndex = 0;
    if (toIndex >= list.length) toIndex = list.length - 1;

    final temp = List<CategoryEditItem>.from(list)
      ..sort((a, b) => a.order.compareTo(b.order));

    final moved = temp.removeAt(fromIndex);
    temp.insert(toIndex, moved);

    // order 재부여
    return normalizeOrder(temp);
  }

  /// A <-> B 이동 (remove + insert)
  ///
  /// - key로 대상을 찾고, 원본 리스트에서 제거 후 대상 리스트 특정 위치에 삽입
  /// - 삽입 시 source 변경
  static ({
  List<CategoryEditItem> nextPlan,
  List<CategoryEditItem> nextRef,
  }) moveAcross({
    required List<CategoryEditItem> plan,
    required List<CategoryEditItem> ref,
    required String key,
    required CategorySource from,
    required int insertIndex, // target list index
  }) {
    final planSorted = List<CategoryEditItem>.from(plan)
      ..sort((a, b) => a.order.compareTo(b.order));
    final refSorted = List<CategoryEditItem>.from(ref)
      ..sort((a, b) => a.order.compareTo(b.order));

    CategoryEditItem? picked;

    if (from == CategorySource.plan) {
      final idx = planSorted.indexWhere((e) => e.key == key);
      if (idx == -1) return (nextPlan: plan, nextRef: ref);
      picked = planSorted.removeAt(idx).copyWith(source: CategorySource.ref);
      // insert into ref
      final safeIndex = insertIndex.clamp(0, refSorted.length);
      refSorted.insert(safeIndex, picked);
    } else {
      final idx = refSorted.indexWhere((e) => e.key == key);
      if (idx == -1) return (nextPlan: plan, nextRef: ref);
      picked = refSorted.removeAt(idx).copyWith(source: CategorySource.plan);
      // insert into plan
      final safeIndex = insertIndex.clamp(0, planSorted.length);
      planSorted.insert(safeIndex, picked);
    }

    final nextPlan = normalizeOrder(planSorted.map((e) => e.copyWith(source: CategorySource.plan)).toList());
    final nextRef  = normalizeOrder(refSorted.map((e) => e.copyWith(source: CategorySource.ref)).toList());

    // 최종 규칙 검증(방어)
    validateUniqueKeys(planDraft: nextPlan, refDraft: nextRef);

    return (nextPlan: nextPlan, nextRef: nextRef);
  }

  // ----------------------------
  // D) 소비입력 BottomSheet용 “참고 추가” 검증
  // ----------------------------

  /// BottomSheet에서 "참고 카테고리 추가"만 할 때,
  /// - 이름이 비었는지
  /// - (선택) 이름 중복 방지
  /// - key 중복은 '키 생성' 전에 잡기 어렵기 때문에,
  ///   보통은 "같은 이름" 중복을 막고,
  ///   key는 VM이 생성 후 validateUniqueKeys로 최종 검증.
  static void validateBottomSheetAddRef({
    required String name,
    required List<CategoryEditItem> planDraft,
    required List<CategoryEditItem> refDraft,
    bool forbidDuplicateName = true,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw CategoryValidationError('카테고리 이름을 입력해주세요.');
    }
    if (!forbidDuplicateName) return;

    final exists = [...planDraft, ...refDraft].any((e) => e.name.trim() == trimmed);
    if (exists) {
      throw CategoryValidationError('이미 같은 이름의 카테고리가 있어요.');
    }
  }
}
