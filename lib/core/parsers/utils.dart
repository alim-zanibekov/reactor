class Utils {
  static double? getNumberDouble(String? str) =>
      str != null ? double.tryParse(str.replaceAll(_numberRegex, '')) : null;

  static int? getNumberInt(String? str) =>
      str != null ? int.tryParse(str.replaceAll(_numberRegex, '')) : null;

  static final _numberRegex = RegExp(r'[^\-0-9\.]');
}
