library;

export 'suggestor/suggestor.dart';

class OldService {
  final String lyrics;
  final String? title;

  OldService({
    required this.lyrics,
    this.title,
  });

  void doSomething() {
    print("I am singing $lyrics");
    calculate(x: 3);
  }

  int calculate({int? x}) {
    return 6 * 7;
  }
}

class Daniella {
  void sing() {
    final OldService oldService = OldService(
      lyrics: 'hello world',
      title: 'hola',
    );

    oldService.doSomething();
  }
}
