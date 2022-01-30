import 'dart:math';

import '../api/api.dart';
import '../api/types.dart';
import '../parsers/types/module.dart';
import 'loader.dart';

class PostLoader extends Loader<Post> {
  static const maxLoads = 20;
  final Api _api;
  final String? path;
  final bool user, subscriptions, search;
  final PostListType postListType;
  final String? prefix;
  final String? favorite;
  final String? query;
  final String? author;
  final List<String?>? tags;

  PostLoader({
    this.path,
    this.prefix,
    this.search = false,
    this.query,
    this.author,
    this.tags,
    this.postListType = PostListType.ALL,
    this.user = false,
    this.subscriptions = false,
    this.favorite,
  }) : _api = prefix == null ? Api() : Api.withPrefix(prefix);

  int _loadCount = 0;
  final List<ContentPage<Post>> _pages = [];
  final List<Post> _posts = [];
  final Set<int?> _postIds = Set();

  bool get complete => _complete;

  ContentPage<Post> get firstPage => _pages.first;

  List<Post> get elements {
    return _posts;
  }

  bool _complete = false;
  bool _destroyed = false;
  bool _reversedPagination = false;
  bool _reversedLoading = false;
  int _postsPerPage = 10;
  int? _startPageId;

  void destroy() {
    _destroyed = true;
    _complete = true;
  }

  void reset() {
    _loadCount = 0;
    _complete = false;
    _pages.clear();
    _posts.clear();
    _postIds.clear();
  }

  void toggleReverse({int? startPageId}) {
    reset();
    _reversedLoading = !_reversedLoading;
    _startPageId = startPageId;
  }

  Future<ContentPage<Post>> _loadPage() {
    if (search) {
      return _api.search(query: query, author: author, tags: tags);
    } else if (favorite != null) {
      return _api.loadFavorite(favorite!);
    } else if (user) {
      return _api.loadUser(path!);
    } else if (subscriptions) {
      return _api.loadSubscriptions();
    } else if (path == null) {
      return _api.load(postListType);
    } else {
      return _api.loadTag(path!, postListType);
    }
  }

  Future<ContentPage<Post>> _loadPageById(int id) {
    if (search) {
      return _api.searchByPageId(id, query: query, author: author, tags: tags);
    } else if (favorite != null) {
      return _api.loadFavoriteByPageId(favorite!, id);
    } else if (user) {
      return _api.loadUserByPageId(path!, id);
    } else if (subscriptions) {
      return _api.loadSubscriptionsByPageId(id);
    } else if (path == null) {
      return _api.loadByPageId(id, postListType);
    } else {
      return _api.loadTagByPageId(path!, id, postListType);
    }
  }

  Future<List<Post>> _load() async {
    final pageId = _startPageId;
    final page = await (pageId != null ? _loadPageById(pageId) : _loadPage());

    _reversedPagination = page.reversedPagination ?? false;
    _pages.add(page);
    final posts = _reversedLoading ? page.content.reversed : page.content;

    posts.forEach((post) => _postIds.add(post.id));
    _posts.addAll(posts);
    _complete = (_posts.isEmpty ||
        ((_pages.last.isLast ?? false) && !_reversedLoading));
    _loadCount += 1;
    _postsPerPage = posts.length;

    return List.of(posts);
  }

  Future<List<Post>> load() async {
    return _load();
  }

  Future<List<Post>> loadNext() async {
    if (_posts.isEmpty || _complete) {
      return [];
    }
    final List<Post> newPosts = [];

    final reverse = _reversedPagination ? !_reversedLoading : _reversedLoading;

    int id = reverse ? _pages.last.id - 1 : _pages.last.id + 1;

    int i;

    for (i = 0;
        _posts.length + newPosts.length < (_loadCount + 1) * _postsPerPage &&
            id > 0 &&
            i < maxLoads &&
            !_complete &&
            !_destroyed;
        i++) {
      if (i < maxLoads - 1) {
        if (i > maxLoads / 2 && newPosts.isEmpty) {
          i = maxLoads;
          break;
        }
        await Future.delayed(
          Duration(milliseconds: i * 400 > 2500 ? 2500 : i * 400),
        );

        final page = await _loadPageById(id);
        _postsPerPage = max(page.content.length, _postsPerPage);
        _pages.add(page);

        if (page.content.isEmpty || (page.isLast ?? false)) {
          _complete = true;
        }
        final posts = _reversedLoading ? page.content.reversed : page.content;

        final pagePosts =
            posts.where((page) => !_postIds.contains(page.id)).toList();
        newPosts.addAll(pagePosts);

        posts.forEach((post) => _postIds.add(post.id));

        id = reverse ? id - 1 : id + 1;
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
