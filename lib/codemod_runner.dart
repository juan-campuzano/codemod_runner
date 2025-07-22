library;

export 'suggestor/suggestor.dart';

class OldService {
  void doSomething() {
    print("Doing something in OldService");
    calculate(x: 3);
  }

  int calculate({int? x}) {
    return 6 * 7;
  }
}
