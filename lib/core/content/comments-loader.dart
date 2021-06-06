import '../api/api.dart';
import '../parsers/types/module.dart';
import 'loader.dart';

class CommentsLoader extends Loader<PostComment> {
  final _api = Api();
  final String username;

  CommentsLoader(this.username);

  final List<ContentPage<PostComment>> _pages = [];
  final List<PostComment> _comments = [];

  bool get complete {
    return (_pages.last.isLast ?? false) || _complete;
  }

  List<PostComment> get elements {
    return _comments;
  }

  ContentPage<PostComment> get firstPage => _pages.first;

  bool _complete = false;

  void destroy() {
    _complete = true;
  }

  void reset() {
    _pages.clear();
    _comments.clear();
    _complete = false;
  }

  Future<List<PostComment>> load() async {
    final page = await _api.loadUserComments(username);
    _pages.add(page);
    _comments.addAll(page.content);
    return page.content;
  }

  Future<List<PostComment>> loadNext() async {
    if (_pages.last.isLast! || _complete) {
      return [];
    }
    int id = _pages.last.id! + 1;
    final page = await _api.loadUserCommentsByPageId(id, username);
    if (page.id == _pages.last.id) {
      _complete = true;
      return [];
    }
    _pages.add(page);
    _comments.addAll(page.content);

    return page.content;
  }
}
