String? convertYouTubeUrlToId(String url) {
  assert(url.isNotEmpty, 'Url cannot be empty');
  if (!url.contains('http') && (url.length == 11)) return url;
  url = url.trim();

  for (var exp in [
    RegExp(
        r'^https:\/\/(?:www\.|m\.)?youtube\.com\/watch\?v=([_\-a-zA-Z0-9]{11}).*$'),
    RegExp(
        r'^https:\/\/(?:www\.|m\.)?youtube(?:-nocookie)?\.com\/embed\/([_\-a-zA-Z0-9]{11}).*$'),
    RegExp(r'^https:\/\/youtu\.be\/([_\-a-zA-Z0-9]{11}).*$')
  ]) {
    Match? match = exp.firstMatch(url);
    if (match != null && match.groupCount >= 1) return match.group(1);
  }

  return null;
}

String? convertCoubUrlToId(String url) {
  assert(url.isNotEmpty, 'Url cannot be empty');
  url = url.trim();

  for (var exp in [
    RegExp(
        r'^https:\/\/(?:www\.|m\.)?coub(?:-nocookie)?\.com\/embed\/([_\-a-zA-Z0-9]+).*$'),
  ]) {
    Match? match = exp.firstMatch(url);
    if (match != null && match.groupCount >= 1) return match.group(1);
  }

  return null;
}

String? convertVimeoUrlToId(String url) {
  assert(url.isNotEmpty, 'Url cannot be empty');
  url = url.trim();

  for (var exp in [
    RegExp(
        r'https?:\/\/(?:www\.|player\.)?vimeo.com\/(?:channels\/(?:\w+\/)?|groups\/([^\/]*)\/videos\/|album\/(\d+)\/video\/|video\/|)(\d+)(?:$|\/|\?)'),
  ]) {
    Match? match = exp.firstMatch(url);
    if (match != null && match.groupCount >= 1) return match.group(3);
  }

  return null;
}

String? getSoundCloudUrl(String url) {
  assert(url.isNotEmpty, 'Url cannot be empty');
  try {
    final uri = Uri.parse(url);
    return uri.queryParameters['url'];
  } on Exception {
    return null;
  }
}
