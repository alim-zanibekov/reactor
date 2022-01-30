import 'package:html/parser.dart' as parser;

import './types/module.dart';
import 'comments-parser.dart';
import 'types/post.dart';
import 'utils.dart';

class UserCommentsParser {
  final _commentsParser = CommentsParser();

  ContentPage<PostComment> parsePage(String c) {
    final parsedPage = parser.parse(c);
    final current = parsedPage.querySelector('.pagination_expanded .current');
    final pageId = current != null
        ? Utils.getNumberInt(parsedPage
                .querySelector('.pagination_expanded .current')
                ?.text) ??
            0
        : 0;

    return ContentPage<PostComment>(
      authorized: parsedPage.querySelector('#topbar .login #settings') != null,
      isLast: current == null ||
          pageId == 0 ||
          parsedPage.querySelector('.pagination_main.pLeft') != null,
      content: parsedPage
          .querySelectorAll('.post_comment_list > .comment')
          .where((element) =>
              Utils.getNumberInt(element.attributes['parent']) != null)
          .map((element) {
        final id = Utils.getNumberInt(element.attributes['parent'])!;
        return _commentsParser.parseComment(element, id);
      }).toList(),
      id: pageId,
    );
  }
}
