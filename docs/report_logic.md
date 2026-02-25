## 1. 기본 구조

Report 화면은 아래 3가지 데이터를 사용한다.

- 예산: `RefData.dailyConsume`
- 소비: `users/{uid}/records`
- 카테고리 정보: dailyConsume + record

모든 집계 기준은 **categoryKey 중심**으로 처리한다.

---

## 2. 기간(range) 계산

### 주간

- 기준: 월요일 ~ 일요일
- 현재 날짜 기준

### 월간

- 기준: 선택된 연/월의 1일 ~ 말일

날짜 비교 시 시간은 제거하고 `yyyy-mm-dd`만 사용한다.

---

## 3. 소비(spent) 계산 방식

### 필터 조건

```
rangeStart <= entry.date <= rangeEnd
```

- 오늘 제한 없음
- 미래 기록 포함
- Inclusive 범위

### 집계 기준

- categoryKey 기준으로 합산
- 이름 변경/이동 영향 없음

---

## 4. 예산(planned) 계산 방식

dailyConsume 문서는 기간별로 쪼개져 있다.

따라서 예산은 **overlap 방식**으로 계산한다.

### 계산 흐름

1. dailyConsume 문서 기간과 report 기간이 겹치는 일수 계산
2. 겹친 일수 × 일일 예산
3. categoryKey 기준 누적

공식:

```
planned += dailyAmount × overlapDays
```

dailyConsume 내부 entries는 전부 일일 예산으로 처리한다.

---

## 5. 차트 카테고리 구성 규칙

### 기본 원칙

- 기준: planned에 있는 categoryKey들
- 
    - 기타(etc)

### 기타 처리

- spent에만 있고 planned에 없는 카테고리 → etc로 통합

예산 중심 구조를 유지하기 위함이다.

---

## 6. 카테고리 이름 표시 기준

표시 이름은 다음 순서로 결정한다.

1. 플랜(dailyConsume)
2. 기록(record) 마지막 이름
3. fallback

```
Plan > Record > Fallback
```

---

## 7. 인사이트 배너 기준



---

## 8. 데이터 갱신 흐름

### 초기 로드 / 변경 시

```
loadInitial / setRangeType
 → _rebuildAll()
```

### rebuild 순서

1. 월 기록 로드
2. RefData 로드
3. 차트 계산
4. notifyListeners