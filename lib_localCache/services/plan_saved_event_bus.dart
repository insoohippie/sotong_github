import 'dart:async';

/// Broadcasts plan-saved events so other view models can react (e.g., refresh).
class PlanSavedEventBus {
  PlanSavedEventBus() : _controller = StreamController<void>.broadcast();

  final StreamController<void> _controller;

  Stream<void> get stream => _controller.stream;

  void notify() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  void dispose() {
    _controller.close();
  }
}
