---

## Sync Policy (Record / Category 공통)

### 0. 목적

Sotong 앱은 “로컬 우선(offline-first)”을 기본으로 하며, 로그인(uid)은 **데이터 분리/동기화 키**로만 사용한다.

따라서 **uid가 없는 상태에서는 캐시(Hive)와 서버(Firestore)를 절대 사용하지 않는다.**

---

## 1. 용어 정의

### 1) Local Cache (Hive)

- `categories` box: 카테고리 리스트 JSON(String) 저장
- `monthly_spending` box: 월별 소비 JSON(String) 저장

### 2) Remote (Firestore)

- categories: `users/{uid}/categories/...` (구현에 따라)
- record: `users/{uid}/monthly/{yyyy-MM}` 같은 구조

### 3) Dirty Flag

- 의미: “이 기기에서 로컬 데이터가 수정되었고, 서버 반영이 **확정되지 않음**”
- Hive에 `...:dirty` 키로 저장
- 네트워크 실패/오프라인이면 dirty가 유지됨

### 4) updatedAt (Remote timestamp)

- Firestore 서버 시간 기준 최신성 기록
- **정렬/최신성 판단/디버깅**에 도움
- 현재 정책에서는 “결정적인 충돌 해결용”이라기보다 안전장치/기록용 성격이 큼

---

## 2. 공통 원칙 (핵심)

### A. uid 없으면 (로그인 전)

- Record: `MonthlySpending.empty(monthKey)`만 반환
- Category: `CategoryListModel.initial()`만 반환
- **Hive 캐시 저장/조회 금지**
- **Firestore 접근 금지**
- 즉, “게스트 모드”는 항상 메모리/기본값 기반

### B. uid 있으면 (로그인 후)

- Hive는 유저별 prefix로 키를 분리한다.
    - Category: `"$uid:categoryList"`
    - Record: `"$uid:$monthKey"` (monthKey = "yyyy-MM")
- 로딩은 “캐시 우선 반환”을 목표로 한다.
- 온라인일 경우, **백그라운드(또는 load 내부)에서 서버와 동기화**를 시도한다.

### C. 네트워크 상태

- `isOnline = true/false`로 정책 분기 (나중에 `connectivity_plus`로 실제 반영)
- 오프라인이면:
    - 캐시가 있으면 캐시 사용
    - 캐시가 없으면 초기값 생성 + dirty 처리(Record에서만 의미가 큼)

---

## 3. 저장 정책 (Save)

### CategoryRepository.saveCategoryList()

조건: uid 필수

1. Hive 저장
2. dirty = true
3. 온라인이면 Firestore 업로드
4. 업로드 성공 시 dirty = false

   업로드 실패 시 dirty 유지


### RecordRepository.saveMonthlySpending()

조건: uid 필수

1. Hive 저장
2. dirty = true (기본)
3. 온라인이면 Firestore 업로드
4. 업로드 성공 시 dirty = false

   업로드 실패 시 dirty 유지


### RecordRepository.upsertDaySpending(day)

- “일(day) 저장”을 월(month) 구조에 반영하기 위한 편의 API
- 내부 동작:
    1. `loadMonthlySpending(monthKey)`로 현재 월 상태 확보 (캐시/서버/초기값)
    2. `days[dateKey] = day`로 해당 날짜만 교체(upsert)
    3. `saveMonthlySpending(updatedMonthly)`로 월 전체 저장 + dirty/업로드 처리

> 즉, upsertDaySpending은 “일 단위 수정 요청”을 “월 단위 저장 정책”으로 통일하는 함수다.
>

---

## 4. 로드 정책 (Load)

### CategoryRepository.loadCategoryList()

조건: uid 있으면 offline-first 동작

1. **Hive 캐시 확인**
    - 있으면 즉시 반환
    - 온라인이면 `_syncWithRemote(uid, cache)` 실행
2. 캐시 없고 온라인이면 Firestore 로드
    - 있으면 캐시에 저장(dirty=false) 후 반환
3. 둘다 없으면 initial 생성
    - 캐시에 저장(dirty=false)
    - 온라인이면 서버에도 저장(updatedAt 포함)

### RecordRepository.loadMonthlySpending(monthKey)

조건: uid 있으면 offline-first 동작

1. **Hive 캐시 확인**
    - 있으면 즉시 반환
    - 온라인이면 Firestore와 비교하여 동기화
2. 캐시 없고 온라인이면 Firestore 로드
    - 있으면 캐시에 저장(dirty=false) 후 반환
3. 둘다 없으면 empty 생성
    - 캐시에 저장 + 서버 저장
4. 오프라인 + 캐시 없음이면 empty 생성
    - 캐시에 저장 + dirty=true (나중 업로드 대상)

---

## 5. 동기화 정책 (Sync)

### 공통: dirty 기반의 단순 정책

- dirty=true이면 **로컬 우선**
- dirty=false이면 **서버 우선(서버와 다르면 서버로 갱신)**

### CategoryRepository._syncWithRemote(uid, cache)

1. 서버 문서 없음
    - dirty=true: 로컬 → 서버 업로드 후 dirty=false
    - dirty=false: 로컬을 서버에 업로드(서버에 기본 문서 마련)
2. 서버 문서 있음
    - dirty=true:
        - remote != cache 이면 로컬 → 서버 업로드
        - dirty=false로 해제
    - dirty=false:
        - remote != cache 이면 서버 → 로컬 캐시 갱신

### RecordRepository.loadMonthlySpending() 내부 sync

카테고리와 동일한 원칙을 월 단위에 적용한다.

---

## 6. 로그아웃 정책 (Logout)

### SettingViewModel.logout()

순서가 중요하다 (uid가 필요하므로)

1. **현재 유저 캐시 삭제**
    - `CategoryRepository.clearMyCategoryCache()`
    - `RecordRepository.resetAllCacheForCurrentUser()`
2. `AuthRepository.logout()`

---

## 7. 충돌/다기기 정책 (현재/미래)

### 현재 가정 (MVP)

- 한 기기 + 한 계정이 대부분
- 그래서 dirty 기반 정책만으로 충분

### 미래 확장 시 고려

- 다기기 동시 사용이 늘면 “서버와 로컬 중 누가 최신인지” 판단이 필요해짐
- 이때 `updatedAt` 비교 + merge 전략(부분 병합 or last-write-wins)을 추가할 수 있음
- 현재는 기록용으로만 넣되, 확장 포인트로 유지