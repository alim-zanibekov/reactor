import '../../core/api/api.dart';
import '../../core/api/types.dart';
import '../../core/content/types/module.dart';

class PostLoader {
  static const maxLoads = 20;
  final Api _api;
  final String path;
  final bool user, subscriptions;
  final PostListType postListType;
  final String prefix;
  final String favorite;

  PostLoader({
    this.path,
    this.prefix,
    this.postListType = PostListType.ALL,
    this.user = false,
    this.subscriptions = false,
    this.favorite,
  }) : _api = prefix == null ? Api() : Api.withPrefix(prefix);

  int _loadCount = 0;
  final List<ContentPage<Post>> _pages = [];
  final List<Post> _posts = [];
  final Set<int> _postIds = Set();

  bool get complete => (_pages.last?.isLast ?? false) || _complete;

  ContentPage<Post> get firstPage => _pages.first;

  bool _complete = false;
  bool _destroyed = false;

  destroy() {
    _destroyed = true;
    _complete = true;
  }

  get posts {
    return _posts;
  }

  Future<ContentPage<Post>> _loader() {
    if (favorite != null) {
      return _api.loadFavorite(favorite);
    } else if (user) {
      return _api.loadUser(path);
    } else if (subscriptions) {
      return _api.loadSubscriptions();
    } else if (path == null) {
      return _api.load(postListType);
    } else {
      return _api.loadTag(path, postListType);
    }
  }

  Future<ContentPage<Post>> _loaderNext(int id) {
    if (favorite != null) {
      return _api.loadFavoriteByPageId(favorite, id);
    } else if (user) {
      return _api.loadUserByPageId(path, id);
    } else if (subscriptions) {
      return _api.loadSubscriptionsByPageId(id);
    } else if (path == null) {
      return _api.loadByPageId(id, postListType);
    } else {
      return _api.loadTagByPageId(path, id, postListType);
    }
  }

  Future<List<Post>> load() async {
    final page = await _loader();
    _pages.add(page);
    page.content.forEach((post) => _postIds.add(post.id));
    _posts.addAll(page.content);
    if (_posts.length == 0) {
      _complete = true;
    }
    _loadCount += 1;
    return List.of(page.content);
  }

  void reset() {
    _loadCount = 0;
    _complete = false;
    _pages.clear();
    _posts.clear();
    _postIds.clear();
  }

  Future<List<Post>> loadNext() async {
    if (_posts.length == 0 || _complete) {
      return [];
    }
    final List<Post> newPosts = [];

    int id = _pages.last.id - 1;
    int i;

    for (i = 0;
        _posts.length + newPosts.length < (_loadCount + 1) * 10 &&
            id > 0 &&
            i < maxLoads &&
            !_destroyed;
        i++) {
      if (i < maxLoads - 1) {
        if (i > maxLoads / 2 && newPosts.isEmpty) {
          i = maxLoads;
          break;
        }
        await Future.delayed(
            Duration(milliseconds: i * 400 > 2000 ? 2000 : i * 400));

        final page = await _loaderNext(id);
        _pages.add(page);

        final pagePosts =
        page.content.where((page) => !_postIds.contains(page.id)).toList();
        newPosts.addAll(pagePosts);

        page.content.forEach((post) => _postIds.add(post.id));

        id--;
      }
    }

    _loadCount += 1;
    _posts.addAll(newPosts);

    if (id <= 0 || i >= maxLoads) {
      _complete = true;
    }

    return newPosts;
  }

  Future<Post> loadContent(int id) async {
    final post = await _api.loadPostContent(id);
    int index = _posts.indexWhere((element) => element.id == id);
    if (index >= 0) {
      _posts[index] = post;
    }
    return post;
  }
}
