class CountFormatter {
  final _cases = [2, 0, 1, 1, 1, 2];

  final List<String> titles;

  CountFormatter(
      {required String few, required String one, required String two})
      : titles = [one, two, few];

  String format(int number) {
    return titles[number % 100 > 4 && number % 100 < 20
        ? 2
        : _cases[number % 10 < 5 ? number % 10 : 5]];
  }
}
