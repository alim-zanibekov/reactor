class Utils {
  static double? getNumberDouble(String? str) =>
      str != null ? double.tryParse(str.replaceAll(_numberRegex, '')) : null;

  static int? getNumberInt(String? str) =>
      str != null ? int.tryParse(str.replaceAll(_numberRegex, '')) : null;

  static String fulfillUrl(String url) =>
      url.startsWith('//') ? "https:$url" : url;

  static final _numberRegex = RegExp(r'[^\-0-9\.]');
}
