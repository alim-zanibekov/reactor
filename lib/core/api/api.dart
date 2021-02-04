import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../auth/auth.dart';
import '../common/in-app-notifications-manager.dart';
import '../common/pair.dart';
import '../external/error-reporter.dart';
import '../http/session.dart';
import '../parsers/comments-parser.dart';
import '../parsers/content-parser.dart';
import '../parsers/posts-parser.dart';
import '../parsers/quiz-parser.dart';
import '../parsers/stats-parser.dart';
import '../parsers/tag-parser.dart';
import '../parsers/types/module.dart';
import '../parsers/user-comments-parser.dart';
import '../parsers/user-parser.dart';
import 'types.dart';

class Api {
  static final _api = Api._internal();
  static final _postsParser = PostsParser();
  static final _commentsParser = CommentsParser();
  static final _contentParser = ContentParser();
  static final _quizParser = QuizParser();
  static final _tagParser = TagParser();
  static final _userParser = UserParser();
  static final _sidebarParser = StatsParser();
  static final _userCommentsParser = UserCommentsParser();
  static final _session = Session();
  static final _auth = Auth();
  static final _dio = Dio();
  String _host = 'http://joyreactor.cc';

  factory Api() {
    return _api;
  }

  static Api withPrefix(String prefix) {
    final instance = Api._internal();
    instance._host = 'http://$prefix.reactor.cc';
    return instance;
  }

  void sethHost(String host) {
    _host = 'http://$host';
  }

  Api._internal();

  String _postTypeToString(PostListType type) {
    switch (type) {
      case PostListType.ALL:
        return '/all';
      case PostListType.GOOD:
        return '';
      case PostListType.BEST:
        return '/best';
      case PostListType.NEW:
        return '/new';
    }
    return null;
  }

  String _voteToString(VoteType type) {
    switch (type) {
      case VoteType.UP:
        return 'plus';
      case VoteType.DOWN:
        return 'minus';
    }
    return null;
  }

  String _tagTypeToString(TagListType type) {
    switch (type) {
      case TagListType.BEST:
        return '/rating';
      case TagListType.NEW:
        return '/subtags';
    }
    return null;
  }

  Future<Post> loadPost(int id) async {
    final res = await _session.get('$_host/post/${id.toString()}');
    return _postsParser.parsePost(id, res.data);
  }

  Future<UserFull> loadUserPage(String link) async {
    final res = await _session.get('$_host/user/$link');
    return _userParser.parse(res.data, link);
  }

  Future<ContentPage<Post>> _loadPage(String url) async {
    final res = await _session.get(url);
    if (res.headers != null &&
        !(res.headers[HttpHeaders.contentTypeHeader]?.first
                ?.contains('text/html') ??
            false)) {
      final err =
          UnimplementedError('url: $url; headers: ${jsonEncode(res.headers)}');
      ErrorReporter.reportError(err, err.stackTrace);
      return ContentPage.empty<Post>();
    }
    final page = _postsParser.parsePage(res.data);
    if (_auth.authorized && !page.authorized) {
      Future.microtask(() {
        _auth.logout();
        InAppNotificationsManager.show(
          'Ключ авторизации недействителен, ключ удален',
        );
      });
    }
    return page;
  }

  Future<ContentPage<Post>> load(PostListType type) =>
      _loadPage('$_host${_postTypeToString(type)}');

  Future<ContentPage<Post>> loadByPageId(int pageId, PostListType type) =>
      _loadPage(
        '$_host${_postTypeToString(type)}/$pageId',
      );

  Future<ContentPage<Post>> loadTag(String tag, PostListType type) =>
      _loadPage('$_host/tag/$tag${_postTypeToString(type)}');

  Future<ContentPage<Post>> loadTagByPageId(
          String tag, int pageId, PostListType type) =>
      _loadPage(
        '$_host/tag/$tag${_postTypeToString(type)}/$pageId',
      );

  Future<ContentPage<Post>> loadUser(String username) =>
      _loadPage('$_host/user/$username');

  Future<ContentPage<Post>> loadUserByPageId(String username, int pageId) =>
      _loadPage('$_host/user/$username/$pageId');

  Future<ContentPage<Post>> loadSubscriptions() =>
      _loadPage('$_host/subscriptions');

  Future<ContentPage<Post>> loadSubscriptionsByPageId(int id) =>
      _loadPage('$_host/subscriptions/$id');

  Future<ContentPage<Post>> loadFavorite(String username) =>
      _loadPage('$_host/user/$username/favorite');

  Future<ContentPage<Post>> loadFavoriteByPageId(String username, int id) =>
      _loadPage('$_host/user/$username/favorite/$id');

  Future<List<ContentUnit>> loadComment(int id) async {
    final res = await _session.get('$_host/post/comment/$id');
    return _contentParser.parseContent(res.data);
  }

  Future<List<PostComment>> loadComments(int id) async {
    final res = await _session.get('$_host/post/comments/$id');
    return _commentsParser.parseComments(res.data, id);
  }

  Future<void> setFavorite(int postId, bool state) {
    return _session.get(
        '$_host/favorite/${state ? 'create' : 'delete'}/$postId?token=${_session.apiToken}');
  }

  Future<Pair<double, bool>> votePost(int id, VoteType type) async {
    final res = await _session.get(
        '$_host/post_vote/add/$id/${_voteToString(type)}?token=${_session.apiToken}&abyss=0');
    final str = res.data.toString().replaceFirst('<span>', '');
    return Pair(double.tryParse(str.substring(0, str.indexOf('<'))),
        res.data.toString().indexOf('vote-plus') != -1);
  }

  Future<double> voteComment(int id, VoteType type) async {
    final res = await _session.get(
        '$_host/comment_vote/add/$id/${_voteToString(type)}?token=${_session.apiToken}');
    final str = res.data.toString().replaceFirst('<span>', '');
    return double.tryParse(str.substring(0, str.indexOf('<')));
  }

  Future<void> setTagFavorite(int id, bool state) async {
    return _session.get(
      '$_host/favorite/${state ? 'create' : 'delete'}Blog/$id${state ? '/1' : ''}?token=${_session.apiToken}',
    );
  }

  Future<void> setTagBlock(int id, bool state) async {
    return _session.get(
        '$_host/favorite/${state ? 'create' : 'delete'}Blog/$id${state ? '/-1' : ''}?token=${_session.apiToken}');
  }

  Future<Post> loadPostContent(int id) async {
    final res = await _session
        .get('$_host/hidden/delete/$id?token=${_session.apiToken}');
    return _postsParser.parseInner(id, res.data);
  }

  Future<ContentPage<ExtendedTag>> loadMainTag(
      String tag, TagListType type) async {
    final res = await _session.get('$_host/tag/$tag${_tagTypeToString(type)}');
    return _tagParser.parsePage(res.data);
  }

  Future<ContentPage<ExtendedTag>> loadMainTagByPageId(
      int id, String tag, TagListType type) async {
    final res =
        await _session.get('$_host/tag/$tag${_tagTypeToString(type)}/$id');
    return _tagParser.parsePage(res.data);
  }

  Future<ContentPage<PostComment>> loadUserComments(String username) async {
    final res = await _session.get('$_host/user/$username/comments');
    return _userCommentsParser.parsePage(res.data);
  }

  Future<ContentPage<PostComment>> loadUserCommentsByPageId(
      int id, String username) async {
    final res = await _session.get('$_host/user/$username/comments/$id');
    return _userCommentsParser.parsePage(res.data);
  }

  Future<Stats> loadSidebar() async {
    final res = await _session.get('$_host/search');
    return _sidebarParser.parse(res.data);
  }

  Future<void> createComment(
    int postId,
    int parentId,
    String text,
    File picture, {
    ProgressCallback onSendProgress,
  }) async {
    final file =
        picture != null ? (await MultipartFile.fromFile(picture.path)) : null;

    final formData = FormData.fromMap({
      'parent_id': parentId,
      'post_id': postId,
      'token': _session.apiToken,
      'comment_text': text,
      'comment_picture': file,
      'comment_picture_url': null,
    });

    return _session.post(
      '$_host/post_comment/create',
      formData,
      onSendProgress: onSendProgress,
    );
  }

  Future<bool> checkHost(String host) async {
    final res = await _session.get('http://$host');
    final page = _postsParser.parsePage(res.data);
    return page.content.isNotEmpty;
  }

  Future<List<Tag>> autocompleteTags(String tag) async {
    final res = await _session.get<String>(
      '$_host/autocomplete/tag?term=${Uri.encodeComponent(tag)}',
    );
    final List<String> tags =
        jsonDecode(res.data).map<String>((i) => i.toString()).toList();
    return tags.map((e) => Tag(e)).toList();
  }

  Future<ContentPage<Post>> search(
      {String query, String author, List<String> tags}) async {
    final queryParams = {
      if (query != null && query.isNotEmpty) 'q': query,
      if (author != null && author.isNotEmpty) 'user': author,
      if (tags != null && tags.isNotEmpty) 'tags': tags.join(',')
    };
    final uri = Uri.http(_host.split('//').last, '/search', queryParams);
    return _loadPage(uri.toString());
  }

  Future<ContentPage<Post>> searchByPageId(int pageId,
      {String query, String author, List<String> tags}) async {
    final queryParams = {
      if (author != null && author.isNotEmpty) 'user': author,
      if (tags != null && tags.isNotEmpty) 'tags': tags.join(',')
    };
    final uri = Uri.http(
        _host.split('//').last,
        '/search/${query != null && query.isNotEmpty ? Uri.encodeComponent(query) : '+'}/$pageId',
        queryParams);
    return _loadPage(uri.toString());
  }

  Future<Response> deleteComment(int commentId) {
    return _session.get(
      '$_host/post_comment/delete/$commentId?token=${_session.apiToken}',
    );
  }

  Future<Quiz> voteQuiz(int quizId) async {
    final res = await _session
        .get('$_host/poll/vote/$quizId?token=${_session.apiToken}');
    return _quizParser.parseQuizResponse(res.data);
  }

  Future<Uint8List> downloadFile(
    String url, {
    ProgressCallback onReceiveProgress,
    Map<String, dynamic> headers,
  }) async {
    final res = await _dio.get<Uint8List>(
      url,
      options: Options(
        headers: headers,
        responseType: ResponseType.bytes,
      ),
      onReceiveProgress: onReceiveProgress,
    );
    return res.data;
  }
}
