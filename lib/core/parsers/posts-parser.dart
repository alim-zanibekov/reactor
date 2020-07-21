import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;

import './types/module.dart';
import 'comments-parser.dart';
import 'content-parser.dart';
import 'quiz-parser.dart';
import 'tag-parser.dart';
import 'types/post.dart';

class PostsParser {
  final _quizParser = QuizParser();
  final _commentsParser = CommentsParser();
  final _contentParser = ContentParser();

  Post parsePost(int id, String c) {
    final parsedPage = parser.parse(c);
    return _parse(id, parsedPage.querySelector('.postContainer'), true);
  }

  Post parseInner(int id, String c) {
    final parsedPage = parser.parse(c);
    return _parse(id, parsedPage.body, false);
  }

  Post _parse(int id, Element parsedPage, bool parseComments) {
    final tags = _parseTags(parsedPage);
    final contentBlock = parsedPage.querySelector('.post_content');
    List<ContentUnit> content = [];
    bool censored = false;
    if (contentBlock == null) {
      censored = _isCensored(parsedPage);
    } else {
      content = _contentParser.parse(contentBlock);
    }
    final footer = parsedPage.querySelector('.ufoot');

    final ratingContainer = footer.querySelector('.post_rating');

    final rating = _parseRating(ratingContainer);
    final quiz = _quizParser.parseQuizFromPost(parsedPage);
    final votedUp =
        ratingContainer.querySelector('.vote-minus.vote-change') != null;
    final votedDown =
        ratingContainer.querySelector('.vote-plus.vote-change') != null;
    final canVote = ratingContainer.querySelector('.vote-plus') != null;
    final comments = parseComments
        ? _commentsParser.parsePostComments(parsedPage, id)
        : null;
    final bestComment = _commentsParser.parseBestCommentElement(parsedPage, id);
    final user = _parseUser(parsedPage);
    final dateTime = _parseDate(parsedPage);
    final favorite = _parseFavorite(parsedPage);
    final commentsCount = int.parse(parsedPage
        .querySelector('.toggleComments')
        .text
        .replaceAll(RegExp(r'[^0-9]+'), ''));

    final hidden =
        (footer.querySelector('.hidden_link a')?.attributes ?? {})['href']
            ?.contains('delete');

    final unsafe = contentBlock?.children?.length == 1 &&
        ((contentBlock.children[0]?.attributes ?? {})['src']
                ?.contains('unsafe') ??
            false);

    return Post(
      id: id,
      censored: censored,
      tags: tags,
      content: content,
      rating: rating,
      favorite: favorite,
      comments: comments,
      user: user,
      hidden: hidden ?? false,
      votedUp: votedUp,
      votedDown: votedDown,
      canVote: canVote,
      dateTime: dateTime,
      unsafe: unsafe,
      commentsCount: commentsCount,
      bestComment: bestComment,
      quiz: quiz,
    );
  }

  ContentPage<Post> parsePage(String c) {
    final parsedPage = parser.parse(c);
    final current = parsedPage.querySelector('.pagination_expanded .current');
    final pageId = current != null
        ? int.tryParse(
              parsedPage.querySelector('.pagination_expanded .current')?.text,
            ) ??
            0
        : 0;

    final pageInfo =
        TagParser.parsePageInfo(parsedPage.getElementById('tagArticle'));

    return ContentPage<Post>(
      authorized: parsedPage.querySelector('#topbar .login #settings') != null,
      pageInfo: pageInfo,
      isLast: pageId <= 1,
      content: parsedPage
          .querySelectorAll('.postContainer')
          .map((e) {
            final id = int.tryParse(
                e.attributes['id'].replaceAll('postContainer', ''));
            return _parse(id ?? 0, e, false);
          })
          .where((element) => element != null)
          .toList(),
      id: pageId,
    );
  }

  bool _isCensored(Element parsedPage) {
    final img = parsedPage.querySelector('.post_top > img');
    return img != null && img.attributes['alt'] == 'Censorship';
  }

  List<Tag> _parseTags(Element parsedPage) {
    final tags = parsedPage.querySelectorAll('.taglist a');
    return tags.map((tag) {
      final attributes = tag?.attributes ?? {};

      final value = tag.text;
      return Tag(
        value,
        isMain: Tag.parseIsMain(attributes['href']),
        prefix: Tag.parsePrefix(attributes['href']),
        link: Tag.parseLink(attributes['href']),
      );
    }).toList();
  }

  UserShort _parseUser(Element parsedPage) {
    final nick = parsedPage.querySelector('.uhead_nick');
    final img = nick?.querySelector('img');
    final avatar = img.attributes['src'];
    final username = img.attributes['alt'];
    final userLink =
        (nick?.querySelector('a')?.attributes ?? {})['href']?.split('/')?.last;
    return UserShort(avatar: avatar, username: username, link: userLink);
  }

  bool _parseFavorite(Element parsedPage) {
    final favorite = parsedPage.querySelector('.favorite_link');
    if (favorite != null) {
      return favorite.classes.contains('favorite');
    }
    return false;
  }

  DateTime _parseDate(Element parsedPage) {
    final date = parsedPage.querySelector('.date > span');
    final timestamp = int.parse(date.attributes['data-time']);
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }

  double _parseRating(Element ratingContainer) {
    if (ratingContainer != null) {
      final text = ratingContainer.text.trim();
      return text == '--' ? null : double.tryParse(text);
    }
    return null;
  }
}
