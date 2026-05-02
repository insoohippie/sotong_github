import 'package:flutter/material.dart';

import '../../model/notification/alarm.dart';

class AlarmViewModel extends ChangeNotifier {
  final List<Alarm> _alarms = [];

  List<Alarm> get alarms => List.unmodifiable(_alarms);

  void addAlarm(Alarm alarm) {
    _alarms.add(alarm);
    notifyListeners();
  }

  void removeAlarm(int index) {
    if (index >= 0 && index < _alarms.length) {
      _alarms.removeAt(index);
      notifyListeners();
    }
  }

  void toggleAlarm(int index) {
    if (index >= 0 && index < _alarms.length) {
      _alarms[index].isActive = !_alarms[index].isActive;
      notifyListeners();
    }
  }
}
