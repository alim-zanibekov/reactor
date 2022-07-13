import 'package:html/parser.dart' as parser;

import './types/module.dart';
import '../common/pair.dart';
import 'comments-parser.dart';
import 'types/post.dart';
import 'utils.dart';

class UserCommentsParser {
  final _commentsParser = CommentsParser();

  ContentPage<PostComment> parsePage(String c) {
    final parsedPage = parser.parse(c);
    final current = parsedPage.querySelector('.pagination_expanded .current');
    final pageIdText =
        parsedPage.querySelector('.pagination_expanded .current')?.text;

    final pageId = current != null ? Utils.getNumberInt(pageIdText) ?? 0 : 0;

    final content = parsedPage
        .querySelectorAll('.post_comment_list > .comment')
        .map((it) => Pair(it, Utils.getNumberInt(it.attributes['parent'])))
        .where((it) => it.right != null)
        .map((it) => _commentsParser.parseComment(it.left, it.right!))
        .toList();

    return ContentPage<PostComment>(
      authorized: parsedPage.querySelector('#topbar .login #settings') != null,
      isLast: current == null ||
          pageId == 0 ||
          parsedPage.querySelector('.pagination_main.pLeft') != null,
      content: content,
      id: pageId,
    );
  }
}
