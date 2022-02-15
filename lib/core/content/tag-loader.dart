import '../api/api.dart';
import '../api/types.dart';
import '../parsers/types/module.dart';
import 'loader.dart';

class TagLoader extends Loader<ExtendedTag> {
  final Api _api;
  final String path;
  final TagListType tagListType;

  TagLoader({
    required this.path,
    this.tagListType = TagListType.BEST,
    String? prefix,
  }) : _api = prefix == null ? Api() : Api.withPrefix(prefix);

  final List<ContentPage<ExtendedTag>> _pages = [];
  final List<ExtendedTag> _tags = [];

  bool get complete {
    return _pages.last.isLast || _complete;
  }

  List<ExtendedTag> get elements {
    return _tags;
  }

  ContentPage<ExtendedTag> get firstPage => _pages.first;

  bool _complete = false;

  void destroy() {
    _complete = true;
  }

  void reset() {
    _pages.clear();
    _tags.clear();
    _complete = false;
  }

  Future<List<ExtendedTag>> load() async {
    final page = await _api.loadMainTag(path, tagListType);
    _pages.add(page);
    _complete = _pages.last.content.isEmpty || _pages.last.isLast;
    _tags.addAll(page.content);
    return page.content;
  }

  Future<List<ExtendedTag>> loadNext() async {
    if (_pages.isEmpty || _pages.last.isLast || _complete) {
      return [];
    }
    int id = _pages.last.id + 1;
    final page = await _api.loadMainTagByPageId(id, path, tagListType);
    if (page.id == _pages.last.id) {
      _complete = true;
      return [];
    }
    _pages.add(page);
    _tags.addAll(page.content);

    return page.content;
  }
}
