class NewService {
  final String? title;

  NewService({
    this.title,
  });

  void doSomething() {
    print("Doing something in NewService");
  }

  int calculate(int x) {
    return 6 * 7;
  }
}

class SomeOtherClass {
  final NewService _oldService = NewService();

  void performAction() {
    _oldService.doSomething();
    print("Calculation result: ${_oldService.calculate(1)}");
  }
}
