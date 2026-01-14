import 'dart:async';

/// ✅ 특정 날짜의 소비가 저장/수정되었다는 이벤트
class SpendingUpdatedEvent {
  final DateTime date;
  SpendingUpdatedEvent(this.date);
}

/// ✅ 소비 이벤트를 브로드캐스트하는 EventBus
class SpendingEventBus {
  final _controller = StreamController<SpendingUpdatedEvent>.broadcast();

  Stream<SpendingUpdatedEvent> get stream => _controller.stream;

  void fire(SpendingUpdatedEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}
