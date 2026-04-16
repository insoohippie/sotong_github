import 'dart:async';

/// 특정 날짜의 기록(수입/소비)이 저장/수정되었다는 이벤트
class RecordUpdatedEvent {
  final DateTime date;
  RecordUpdatedEvent(this.date);
}

/// 기록 이벤트를 브로드캐스트하는 EventBus
class RecordEventBus {
  final _controller = StreamController<RecordUpdatedEvent>.broadcast();

  Stream<RecordUpdatedEvent> get stream => _controller.stream;

  void fire(RecordUpdatedEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}