import 'package:flutter/material.dart';

class Alarm {
  final TimeOfDay time;
  final String description;
  bool isActive;

  Alarm({required this.time, required this.description, this.isActive = true});
}
