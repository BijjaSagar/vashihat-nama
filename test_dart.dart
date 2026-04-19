import 'dart:core';
void main() {
  String apiString = "2026-02-26T10:38:30.000Z";
  DateTime lastCheckIn = DateTime.tryParse(apiString)!;
  print("Parsed from API: $lastCheckIn, isUtc: ${lastCheckIn.isUtc}");
  
  DateTime nextDue = lastCheckIn.add(Duration(minutes: 5));
  print("Next Due: $nextDue, isUtc: ${nextDue.isUtc}");
  
  DateTime now = DateTime.now();
  print("Now: $now, isUtc: ${now.isUtc}");
  
  bool isBefore = nextDue.isBefore(now);
  print("is nextDue before now? $isBefore");
}
