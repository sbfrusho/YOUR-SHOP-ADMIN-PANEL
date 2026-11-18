/// The current time. Replaced in tests and screenshots so "today" is fixed.
class Clock {
  const Clock();

  DateTime now() => DateTime.now();
}

/// Always returns [at].
class FixedClock extends Clock {
  const FixedClock(this.at);

  final DateTime at;

  @override
  DateTime now() => at;
}
