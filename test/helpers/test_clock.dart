class TestClock {
  TestClock(this.now);

  DateTime now;

  DateTime call() => now;

  void advance(Duration by) => now = now.add(by);
}

class SequentialIds {
  int _next = 0;

  String call() => 'id-${_next++}';
}
