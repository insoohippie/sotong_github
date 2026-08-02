# Sotong(소통) 아키텍처 가이드

> 방금 합류한 개발자를 위한 문서입니다. 이 문서 하나로 "앱이 무엇을 하는지 → 코드가 어떻게 쌓여 있는지 → 돈 계산이 어디서 일어나는지"를 따라갈 수 있게 쓰였습니다.

---

## 1. 이 앱은 무엇인가

**목돈 저축용 가계부**입니다. 사용자가 목표 금액(예: 여행 자금 500만 원)을 정하면,

```
(월고정수입 − 월고정지출 − 하루소비한도 × 일수) = 매달 모이는 돈
```

이 공식으로 **"이 페이스면 언제 목표에 도달하는지"** 를 계산해 보여주고, 매일의 실제 소비 기록과 비교하며 진행률을 추적합니다.

- **플랜(Plan)** = 저축 계획. "매달 얼마 벌고, 얼마 나가고, 하루에 얼마까지 쓸게요"라는 가정의 묶음.
- **레코드(Record)** = 실제 소비/수입 기록. 플랜(계획)과 레코드(실제)를 날짜로 조인해서 "지금까지 실제로 모인 돈"을 계산합니다.

기술 스택: **Flutter + Provider(MVVM) + Cloud Firestore(원격) + Hive(로컬 캐시)**. 앱 버전 `1.0.4+2`, `lib/` 약 21k LOC.

---

## 2. 폴더 구조 = 레이어 구조

```
lib/
├── main.dart              앱 진입점. Hive 박스 열기 + Firebase 초기화 + 전체 Provider 등록(DI)
├── route.dart             ~30개의 네임드 라우트 테이블
├── data_source/           Firebase/Hive에 실제로 읽고 쓰는 최하층. 비즈니스 로직 없음
├── repository/            "로컬이냐 원격이냐"를 결정하는 정책 계층 (오프라인 우선, dirty flag)
├── services/              이벤트 버스, 로컬 알림, iOS 위젯 동기화 등 공통 인프라
├── model/                 순수 데이터 클래스 (fromMap/toMap/copyWith). 도메인별 하위 폴더
├── view_model/            화면 상태를 들고 있는 ChangeNotifier들
│   └── services/          Provider에 등록되지 않는 순수 계산기들 (저축 계산 등)
├── view/pages/            화면(페이지)과 그 화면 전용 위젯
└── component/             공용 디자인 시스템 (테마, 버튼, 차트, 인풋 등)
```

**의존 방향은 위에서 아래로만 흐릅니다:**

```
View ──watch/read──▶ ViewModel ──▶ Repository ──▶ DataSource ──▶ Firestore / Hive
                        ▲
                        └──이벤트──  services/ 의 EventBus
```

실제로 지켜지는 규칙:
- View와 ViewModel은 절대 DataSource를 직접 만지지 않는다.
- Firestore 경로 문자열은 전부 `data_source/` 안에만 있다.
- ViewModel끼리 직접 호출하지 않는다 — 대신 **이벤트 버스**(아래 §5)로 통신한다.

---

## 3. 데이터는 어디에 저장되는가

### 3.1 원격 — Cloud Firestore (전부 `users/{uid}` 아래)

```
users/{uid}
  ├── plans/{planId}            ← TotalPlan 전체 트리가 문서 1개에 통째로 저장됨
  ├── records/{yyyy-MM}         ← 한 달치 소비 기록이 문서 1개
  ├── refData/_root/
  │     ├── monthlyIncome/{id}  ← 월고정수입 원본
  │     ├── monthlyConsume/{id} ← 월고정지출 원본
  │     └── dailyConsume/{id}   ← 하루소비한도 원본
  └── refCategories/{docId}     ← 카테고리 사전 (recordSpending | recordAddIncome | planSpendingRegistry)
```

로그인은 FirebaseAuth 이메일/비밀번호지만, 사용자는 **아이디**로 로그인합니다 — `AuthRepository`가 `{id}@sotong.app`으로 변환합니다.

### 3.2 로컬 — Hive (이 앱의 "local cache 최대화"의 실체)

`main.dart`에서 박스 9개를 엽니다: `auth_cache`, `refData`, `ref_categories`, `monthly_spending`, `past_plans`, `settings`, `plan_cache`, `notification_read`, `notification_cache`.

핵심은 **`plan_cache`** 박스입니다 (`PlanCacheRepository`):
- 키 = uid, 값 = `PlanCacheSnapshot { plan, refData, recordCache, needsInitialUpload }` 를 통째로 JSON 인코딩한 문자열 1개.
- 즉 **플랜 + 참조데이터 전체가 로컬에 한 덩어리로 있어서, Firestore를 한 번도 읽지 않고 앱이 완전히 뜰 수 있습니다.**
- `needsInitialUpload` = 로그인 전에 만든 게스트 플랜을 "나중에 서버로 올려야 함" 표시. 로그인 시 업로드됩니다.

### 3.3 동기화 정책 (자세한 원문: `docs/sync_policy.md`)

`RecordRepository`, `RefDataRepository`, `RefCategoryRepository`가 공통으로 따르는 규칙:

1. **uid 없으면 아무것도 안 한다** — Hive도 Firestore도 안 건드리고 빈 값 반환.
2. 모든 Hive 키는 `{uid}:...` 접두사 — 한 기기에 여러 계정이 있어도 충돌 없음. 로그아웃해도 캐시는 **지우지 않는다**(재로그인 시 재활용).
3. 캐시 항목마다 `:dirty` 불리언이 붙는다. **dirty=true → 로컬 승리(서버로 업로드), dirty=false → 원격 승리(캐시 덮어씀).** 업로드 실패 시 dirty는 유지된다 — 낙관적으로 지우지 않음.
4. 쓰기는 월 단위 — 하루를 고치면 그 달 전체 문서를 다시 저장.

⚠️ **주의할 함정 두 가지:**
- `RecordRepository.localMode = true`가 기본값이라 **소비 기록은 현재 로컬 전용**입니다. 로그인 시 하이드레이션과 설정의 수동 "업로드"만 일시적으로 `localMode=false`로 바꿔 서버와 동기화합니다. 버그가 아니라 의도된 상태입니다.
- `isOnline`은 세 리포지토리 모두 하드코딩 `true`입니다 (`TODO: connectivity_plus`). 진짜 네트워크 감지는 아직 없습니다.

---

## 4. 핵심 도메인: 플랜의 3단 구조 + refData 참조

이 앱에서 가장 중요한 설계입니다. 천천히 읽어주세요.

### 4.1 total(전체) − sub(월) − mini(개별 소비계획)

```
TotalPlan  "여행자금 500만원"  (목표금액, 시작일~종료일)
 └─ subPlans: Map<"YYYYMM", SubPlan>          ← 달마다 1개
     └─ miniPlans: 링크드 리스트(prev/nextDocId)  ← 달 안의 연속 구간들
         MiniPlan #1  (1일~14일)   ── nextDocId ──▶  MiniPlan #2  (15일~31일)
```

- **`TotalPlan`** (`model/plan/total_plan.dart`) — 저축 목표 1개. 트리 전체가 Firestore 문서 하나에 직렬화됩니다. 플랜 종료일은 항상 **`modEndDate ?? endDate`** 를 쓰세요(재계산된 종료일이 우선).
- **`SubPlan`** (`sub_plan.dart`) — 달력의 한 달. `orderedMinis()`가 `headDocId`부터 `nextDocId`를 따라 미니 체인을 순회합니다. 체인이 끊기면 `StateError('Broken mini plan chain')`을 던집니다.
- **`MiniPlan`** (`mini_plan.dart`) — **"가정이 동일한 연속 날짜 구간"**. 사용자가 달 중간에 하루소비한도를 바꾸면, 그 지점에서 미니가 `splitAt()`으로 둘로 쪼개집니다. 그래서 "개별 소비계획"입니다.

### 4.2 왜 링크드 리스트 + 참조(refData)인가

MiniPlan은 **금액을 직접 갖지 않습니다.** 대신 세 개의 **문자열 ID**로 원본을 가리킵니다:

```
MiniPlan
 ├─ monthlyIncomeId  ──▶ RefData.monthlyIncomeMap[id]   (월고정수입 원본)
 ├─ monthlyConsumeId ──▶ RefData.monthlyConsumeMap[id]  (월고정지출 원본)
 └─ dailyConsumeId   ──▶ RefData.dailyConsumeMap[id]    (하루소비한도 원본)
```

원본(`MonthlyIncome`/`MonthlyConsume`/`DailyConsume`, `model/refData/`)은 **삭제되지 않고 버전으로 쌓입니다**:
- 월 단위 원본은 `yearMonthList`(적용되는 달 목록)를 갖고, 새 버전이 생기면 이전 버전에서 겹치는 달만 `removeMonths()`로 빼냅니다.
- 일 단위 원본은 `startDate~endDate` 범위를 갖고, 새 버전이 생기면 이전 버전을 `endAt(적용일-1)`로 잘라냅니다.
- ID는 `"YYYYMM-001"` 형식의 월별 시퀀스로 발급됩니다.

**정리하면, "각 날짜가 원본 값을 참조한다"는 이 두 개의 체인으로 구현되어 있습니다:**

```
날짜 d
  → SubPlan["YYYYMM"] → 미니 체인 순회 → d를 포함하는 MiniPlan
  → 그 미니의 3개 ID → RefData 원본 레코드
  → 원본의 entries 합계 = 그 날짜에 적용되는 "원본 값"
```

미니의 경계는 정확히 "세 ID(또는 금액) 중 하나라도 바뀌는 지점"입니다. 이를 가장 명확히 보여주는 코드가 `chat_plan_viewmodel.dart`의 `_materializeSubPlanMonth()` — 한 달을 **하루씩** 돌면서 그날의 (ID 3개 + 금액 3개)를 구하고, 값이 같은 연속 구간을 하나의 MiniPlan으로 합칩니다.

### 4.3 비정규화 캐시 — 미니가 금액 사본도 들고 있는 이유

RefData를 로드하지 않아도 트리를 그릴 수 있도록, 미니는 참조 ID 외에 **합계 사본**(`monthlyIncomeAmount` 등)과 **안분 계산 결과**(`monthlyNetIncome` 등)도 저장합니다. `recalculateNetAmounts()`:

```
monthlyNetIncome  = 반올림(monthlyIncomeAmount  × 구간일수 / 그달일수)   ← 월 금액은 일수만큼 안분
monthlyNetConsume = 반올림(monthlyConsumeAmount × 구간일수 / 그달일수)
dailyNetConsume   = dailyConsumeAmount × 구간일수                        ← 일 금액은 일수만큼 곱셈
```

그리고 `PlanMetrics`(`plan_metrics.dart`)가 세 층위의 숫자를 구분합니다 — **원본 값**(월/일 금액) → **구간 실제 금액**(Net) → **결과**(dailyNetSaving, perSecondSaving). RefData 원본을 고치면 반드시 미니의 사본까지 갱신해야 하는데, 그 일을 하는 것이 아래 뮤테이션 파이프라인입니다.

### 4.4 플랜 수정 파이프라인

플랜 수정은 커맨드 객체로 표현됩니다 (`model/commands/`):

- `UpdateMonthlyCommand` — 월고정수입/지출 변경 (적용 달 범위)
- `UpdateDailyCommand` — 하루소비한도 변경 (적용 날짜 범위)

처리 흐름:

```
ViewModel (chat_plan / plan_edit / category_edit)
  → PlanMutationService  (services/plan_mutation_service.dart)
      범위 클램핑 + 검증 (겹침, 연속성, 미니 체인 무결성 → PlanMutationException)
  → PlanMutationRepository  (repository/plan_mutation_repository.dart, 순수 인메모리)
      새 RefData 버전 생성 → 이전 버전 잘라내기 → 해당 미니 splitAt/패치
      → 이후 달 전체에 전파 → 종료일 재계산되면 뒤쪽 SubPlan 잘라내기/삭제
  → PlanMutationResult { 새 plan + 새 refData + affectedMonths + propagatedMonths }
```

저장은 `ChatPlanViewModel.savePlan()`: **Hive 캐시 먼저** → Firestore(`plans/{planId}` 통째 교체) → RefData 문서별 저장 → `PlanSavedEventBus.notify()`.

### 4.5 소비 기록(Record)과 플랜의 관계

`model/record/`: `MonthlyRecord`(월 문서) → `DayRecord`(하루) → `RecordEntry`(건별).

**플랜과 레코드는 서로 ID로 참조하지 않습니다. 오직 날짜로 조인합니다.** 날짜 d에 대해 플랜 쪽에서 예산(미니의 `dailyConsumeAmount`)을, 레코드 쪽에서 실제 지출(`DayRecord.totalSpendingAmount`)을 가져와 비교합니다. 카테고리 레벨 비교는 `categoryKey`(불변 키)로 합니다.

---

## 5. 상태 관리와 이벤트 흐름

### 5.1 Provider 구성

`main.dart`에 4단 계층으로 한 번에 등록됩니다: **이벤트 버스 → 데이터소스 → 리포지토리/서비스 → 뷰모델(16개)**. `ProxyProvider`, `StreamProvider`, 서비스 로케이터 없음 — 전부 생성자 주입입니다.

주요 뷰모델과 담당 화면:

| ViewModel | 담당 |
|---|---|
| `ChatPlanViewModel` (2.7k LOC) | 플랜 생성 채팅 온보딩, 플랜 저장의 중심 |
| `HomeViewModel` (1.1k LOC) | 홈 화면. 실시간 저축액/진행률 계산 |
| `ReportViewModel` (1.6k LOC) | 주간/월간 리포트 (규칙: `docs/report_logic.md`) |
| `RecordSpendingViewModel` 등 | 소비/수입 기록 |
| `CategoryEditViewModel` (1.6k LOC) | 카테고리 편집 (플랜 뮤테이션까지 발동) |
| `SettingViewModel` | 설정 + **앱 전역 다크모드** (MaterialApp을 감쌈) |
| `NotificationViewModel` | 알림함 + 홈 벨 배지 |

### 5.2 이벤트 버스 — ViewModel 간 통신의 유일한 통로

```
레코드 저장 ──▶ RecordEventBus.fire(date) ──▶ Home/Report/Communication/Notification VM이 각자 refresh
플랜 저장   ──▶ PlanSavedEventBus.notify() ──▶ HomeViewModel, ReportViewModel이 플랜 재로드
```

버스는 페이로드 없는(또는 날짜만 담은) broadcast Stream입니다. 듣는 쪽이 알아서 다시 읽습니다. **"플랜 완료" 이벤트 버스는 아직 없습니다** (§7 참고).

### 5.3 화면 흐름

```
/logo_splash → (세션 판정: AuthRepository.nextRouteBySession)
   ├─ 로그인 안 됨        → /login → (캐시 하이드레이션) → /home_tab_navigator
   ├─ 로그인됨 + 플랜 없음 → /unsuccess_plan_quit → /plan_chat (채팅 온보딩) → /plan_success
   └─ 로그인됨 + 플랜 있음 → /home_tab_navigator (PageView: /report ↔ /home ↔ /communication)
```

---

## 6. 돈 계산기 3형제 — 절대 헷갈리지 말 것

같은 공식을 다루지만 **질문이 다른** 계산기가 세 개 있습니다 (`view_model/services/`):

| 계산기 | 질문 | 비고 |
|---|---|---|
| `SavingPlanCalculator` (saving_calculator.dart) | **"언제 목표에 도달하나?"** | 플랜을 일 단위 타임라인으로 펼쳐 누적 → `goalDateTime` 산출. 결과는 저장 안 함(항상 재계산) |
| `SavingProgressService` (saving_progress_service.dart) | **"지금까지 실제로 얼마 모였나?"** | 플랜 × 레코드를 날짜로 조인. 현재 ReportViewModel만 사용 |
| `HomeViewModel` 내부 로직 | 위와 동일 (홈 화면용) | `_rebuildDailyNetThroughToday()` + 1초 티커로 실시간 누적. **SavingProgressService와 같은 공식이 중복 구현되어 있고 이미 미세하게 드리프트 중** |

하루의 실제 저축액 공식 (둘 다 동일):

```
actualSaved(day) = 계획된 일일저축 + 계획된 하루예산 − 실제 지출 + 추가 수입
```

홈의 목표 달성 판정은 `HomeViewModel.hasReachedSavingTarget` getter 하나입니다:

```dart
bool get hasReachedSavingTarget => target > 0 && actualSavedNow >= target;
```

⚠️ `TotalPlan.currentAmount`는 저장되긴 하지만 **진행률의 원천이 아닙니다** — 진행률은 항상 읽기 시점에 플랜×레코드로 재계산됩니다.

---

## 7. 알림 시스템 현황 (그리고 플랜 완료 알림이 없는 이유)

알림은 두 계층입니다:

1. **인앱 알림함** — `NotificationGenerateService`가 규칙 기반으로 `NotificationItem`을 생성해 Hive(`notification_cache`)에 저장. 현재 5종: 출석, 어제 미기록, 예산 초과/절약, 리포트 최다 카테고리, 감정.
2. **OS 로컬 푸시** — `LocalNotificationService`(flutter_local_notifications). 고정 ID 5개(출석=1, 동기부여=2, 주간리포트=3, 감정리포트=4, 미기록=5)의 반복 스케줄만 지원.

**플랜 완료(목표 달성) 알림은 현재 구조적으로 불가능합니다:**
- `NotificationType` enum에 완료 타입 자체가 없음 (`{recordReminder, timeValue, report, emotion}`).
- `NotificationGenerateService`는 플랜의 `startDate`만 읽고 `endDate`/`targetAmount`는 아예 안 읽음.
- 유일한 감지 지점인 `hasReachedSavingTarget`은 홈 시트의 **글자 색 바꾸는 데만** 쓰이고, 이벤트를 쏘지 않음.
- `LocalNotificationService`에는 즉시 표시(show) API가 없음 (반복 스케줄 + 테스트용만 있음).
- 완료 축하 화면 `CelebrationPlanSuccessPage`는 존재하지만, 데모 페이지(`totalplan.dart`)의 하드코딩 버튼에서만 진입 가능.

이름이 비슷한 페이지 구분:

| 페이지 | 실제 역할 |
|---|---|
| `plan_success_page.dart` (`/plan_success`) | 플랜 **"생성"** 완료 화면 ("플랜이 생성되었어요! 🎉") |
| `celebration_plan_success.dart` (`/celebration_plan_success`) | 플랜 **"달성"** 축하 화면 (콘페티 + `PastPlanSnapshot` 저장). **정상 흐름에서 도달 불가** |

---

## 8. 신규 개발자 추천 학습 경로

1. **`services/plan_debug_printer.dart`** — 플랜 트리를 로그로 출력해줍니다. 실제 트리를 눈으로 먼저 보세요.
2. `model/plan/mini_plan.dart` (`recalculateNetAmounts`, `splitAt`) → `sub_plan.dart` (`orderedMinis`) → `total_plan.dart` (`recalculateTotals`)
3. `model/plan/plan_metrics.dart` — 숫자 세 층위(원본/Net/결과) 구분
4. `model/refData/ref_data.dart` — `_refreshPrimaryIds`, `addMonthlyIncome`, `addDailyConsume`
5. `repository/plan_mutation_repository.dart`의 `applyDaily` — 쪼개기/전파/잘라내기 전체 스토리
6. `view_model/plan/chat_plan_viewmodel.dart`의 `_materializeSubPlanMonth` — "미니플랜 = 가정이 같은 연속 구간"의 가장 명확한 코드
7. `view_model/services/saving_progress_service.dart` — 플랜 × 레코드 조인
8. `docs/sync_policy.md` — 오프라인 우선 정책 원문 (일부 클래스명은 리네임 이전 기준)

---

## 9. 조심해야 할 지뢰 목록

코드를 읽다 발견된, 수정 전 알아두면 좋은 것들:

1. **`MiniPlan.copyWith`는 nullable 필드를 null로 되돌릴 수 없음** (`nextDocId: nextDocId ?? this.nextDocId`). 그런데 `PlanMutationRepository._truncateSubPlan`은 `copyWith(nextDocId: null)`로 꼬리 포인터가 지워지길 기대함 → 잘려나간 미니를 가리키는 포인터가 남아 `orderedMinis()`가 `StateError`를 던질 수 있음. **가장 위험한 버그 후보.**
2. `DailyConsume.copyWith`가 `endedAt`을 유실함 (`endedAt: endedAt`, `?? this.endedAt` 아님).
3. `MiniPlan.fromMap`에 같은 키를 두 번 읽는 오타 (레거시 fallback 키가 누락된 것으로 보임).
4. `PlanMetrics.merge`의 변수명 `sumIncome` 등은 실제로는 합이 아니라 마지막 값 — 이름에 속지 말 것.
5. `RefData.dailyVariableConsumeMap`은 직렬화만 되고 채워지지 않는 죽은 필드.
6. 오프라인 삭제는 재전송 큐가 없음 (`RefDataRepository.deleteX`는 `allDirty`만 올림).
7. `view/pages/total_plan_page.dart`는 아무도 import하지 않는 죽은 중복 페이지 (라우트는 `plan/totalplan.dart`를 씀).
8. `notification_item.dart` 안에 `NotificationSettings`/`Alarm`이 중복 정의되어 있음 — 실제 사용되는 건 별도 파일 쪽. 그림자 정의라 드리프트 위험.
9. `AuthDataSource`/`AuthRepository`가 `print()`로 이메일/uid를 릴리스 빌드에서도 로깅함.
10. 테스트는 3개 파일뿐 (`ref_data_test`, `plan_mutation_repository_test`, `widget_test`).
